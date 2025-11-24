"""
Flask server for the embedding generation tool.
"""

from flask import Flask, request, jsonify, send_file, Response, stream_with_context
from flask_cors import CORS
import os

# Set environment variables to prevent numpy/mkl threading hangs
# This must be done BEFORE importing pandas/numpy
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['NUMEXPR_NUM_THREADS'] = '1'

import pandas as pd
import io
import logging
import threading
import time
import json
from pathlib import Path
import tempfile
from embeddings import process_csv_chunk
from formatters import get_formatter
import database as db
import numpy as np
from sklearn.cluster import KMeans
from sklearn.metrics.pairwise import cosine_similarity

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
UPLOAD_FOLDER = Path(tempfile.gettempdir()) / "embedding_tool_uploads"
UPLOAD_FOLDER.mkdir(exist_ok=True)

def background_processing(job_id, file_path, text_columns, metadata_columns, provider, api_key, model, combine_columns):
    """Background task for processing CSV and generating embeddings."""
    try:
        logger.info(f"Starting background processing for job {job_id}")
        db.update_job_status(job_id, 'processing')
        
        # Read CSV in chunks to save memory
        chunk_size = 100  # Process 100 rows at a time
        processed_count = 0
        
        logger.info(f"Job {job_id}: Reading CSV from {file_path}")
        
        # Iterate over CSV chunks
        chunk_iterator = pd.read_csv(file_path, chunksize=chunk_size)
        logger.info(f"Job {job_id}: CSV iterator created")
        
        for i, chunk in enumerate(chunk_iterator):
            logger.info(f"Job {job_id}: Processing chunk {i+1}")
            chunk_records = chunk.to_dict('records')
            
            texts = []
            metadatas = []
            
            for row in chunk_records:
                # Prepare text
                if combine_columns:
                    text_parts = [str(row.get(col, "")) for col in text_columns]
                    combined_text = " ".join(text_parts)
                    texts.append(combined_text)
                else:
                    texts.append(str(row.get(text_columns[0], "")))
                
                # Prepare metadata
                meta = {}
                for col in metadata_columns:
                    if col in row:
                        # Handle NaN values which JSON can't serialize
                        val = row[col]
                        if pd.isna(val):
                            val = None
                        meta[col] = val
                metadatas.append(meta)
            
            logger.info(f"Job {job_id}: Generating embeddings for chunk {i+1} ({len(texts)} rows)")
            
            # Generate embeddings for this chunk
            results = process_csv_chunk(
                texts=texts,
                metadatas=metadatas,
                start_index=processed_count,
                provider=provider,
                api_key=api_key,
                model=model
            )
            
            logger.info(f"Job {job_id}: Saving batch for chunk {i+1}")
            # Save to DB
            db.save_embeddings_batch(job_id, results)
            
            # Update progress
            processed_count += len(results)
            db.update_job_progress(job_id, processed_count)
            logger.info(f"Job {job_id}: Progress updated to {processed_count}")
            
        db.update_job_status(job_id, 'completed')
        logger.info(f"Job {job_id} completed successfully. Processed {processed_count} rows.")
        
    except Exception as e:
        logger.error(f"Job {job_id} failed: {str(e)}", exc_info=True)
        db.update_job_status(job_id, 'failed', str(e))

@app.route('/')
def index():
    """Serve the main HTML page."""
    return send_file('index.html')

@app.route('/style.css')
def styles():
    """Serve the CSS file."""
    return send_file('style.css')

@app.route('/app.js')
def scripts():
    """Serve the JavaScript file."""
    return send_file('app.js')

@app.route('/api/upload', methods=['POST'])
def upload_csv():
    """
    Upload CSV file and create a job.
    """
    try:
        logger.info("Upload request received")
        if 'file' not in request.files:
            logger.error("No file part in request")
            return jsonify({"error": "No file provided"}), 400
        
        file = request.files['file']
        logger.info(f"File received: {file.filename}")
        
        if file.filename == '':
            logger.error("No selected file")
            return jsonify({"error": "No file selected"}), 400
        
        if not file.filename.endswith('.csv'):
            logger.error(f"Invalid file type: {file.filename}")
            return jsonify({"error": "File must be a CSV"}), 400
        
        # Save file to disk
        job_id = str(abs(hash(file.filename + str(time.time()))))
        file_path = UPLOAD_FOLDER / f"{job_id}.csv"
        logger.info(f"Saving file to {file_path}")
        file.save(file_path)
        logger.info("File saved successfully")
        
        # Get basic info (columns, row count)
        # Read just the first few lines for columns and preview
        try:
            logger.info("Reading CSV preview...")
            df_preview = pd.read_csv(file_path, nrows=5)
            columns = df_preview.columns.tolist()
            # Replace NaN with None (which becomes null in JSON)
            # JSON standard does not support NaN
            # Must cast to object first, otherwise float columns retain NaN
            df_preview = df_preview.astype(object).where(pd.notnull(df_preview), None)
            preview = df_preview.to_dict('records')
            logger.info(f"CSV preview read. Columns: {columns}")
        except Exception as e:
            logger.error(f"Error reading CSV preview: {e}")
            return jsonify({"error": f"Invalid CSV file: {str(e)}"}), 400
        
        # Count total rows (efficiently)
        try:
            logger.info("Counting rows...")
            with open(file_path, 'rb') as f:
                row_count = sum(1 for _ in f) - 1 # Subtract header
            logger.info(f"Row count: {row_count}")
        except Exception as e:
            logger.error(f"Error counting rows: {e}")
            row_count = 0 # Fallback
            
        # Create job in DB
        logger.info(f"Creating job {job_id} in database")
        db.create_job(job_id, str(file_path), row_count)
        logger.info("Job created successfully")
        
        return jsonify({
            "session_id": job_id, # Keeping 'session_id' key for frontend compatibility
            "columns": columns,
            "preview": preview,
            "row_count": row_count
        })
    
    except Exception as e:
        logger.error(f"Error in upload_csv: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route('/api/generate', methods=['POST'])
def start_generation():
    """
    Start background embedding generation.
    """
    try:
        data = request.json
        job_id = data.get('session_id')
        text_columns = data.get('text_columns', [])
        metadata_columns = data.get('metadata_columns', [])
        provider = data.get('provider', 'sentence-transformers')
        api_key = data.get('api_key')
        model = data.get('model')
        combine_columns = data.get('combine_columns', True)
        
        # Validate job
        job = db.get_job(job_id)
        if not job:
            return jsonify({"error": "Invalid session ID"}), 400
            
        file_path = job['input_file_path']
        
        # Start background thread
        thread = threading.Thread(
            target=background_processing,
            args=(job_id, file_path, text_columns, metadata_columns, provider, api_key, model, combine_columns)
        )
        thread.daemon = True
        thread.start()
        
        return jsonify({
            "success": True,
            "message": "Background processing started",
            "job_id": job_id
        })
    
    except Exception as e:
        logger.error(f"Error starting generation: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/status/<job_id>', methods=['GET'])
def get_status(job_id):
    """Get job status and progress."""
    job = db.get_job(job_id)
    if not job:
        return jsonify({"error": "Job not found"}), 404
        
    return jsonify({
        "status": job['status'],
        "processed": job['processed_rows'],
        "total": job['total_rows'],
        "error": job['error_message']
    })

@app.route('/api/cluster', methods=['POST'])
def cluster_embeddings():
    """
    Cluster embeddings for a job based on selected columns.
    Supports text (embedded), categorical, and numerical fields.
    """
    try:
        data = request.json
        job_id = data.get('session_id')
        n_clusters = int(data.get('n_clusters', 5))
        cluster_columns = data.get('cluster_columns', [])  # NEW: User-selected columns
        
        if not job_id:
            return jsonify({"error": "No session ID provided"}), 400
            
        logger.info(f"Clustering job {job_id} with k={n_clusters}, columns={cluster_columns}")
        
        # Get job info
        job = db.get_job(job_id)
        if not job:
            return jsonify({"error": "Job not found"}), 400
        
        # Fetch all embeddings first
        embeddings_gen = db.get_job_embeddings(job_id)
        
        embedding_rows = []
        for item in embeddings_gen:
            embedding_rows.append({
                'id': int(item['id']),
                'embedding': item['embedding'],
                'metadata': item['metadata'],
                'text': item['text']
            })
            
        if not embedding_rows:
            return jsonify({"error": "No embeddings found for this job"}), 400
        
        # Determine which columns to use for clustering
        # If no columns specified, default to using just the embeddings
        if not cluster_columns:
            logger.info("No cluster_columns specified, using embeddings only")
            X = np.array([row['embedding'] for row in embedding_rows])
        else:
            # Load original CSV to access all columns
            csv_path = job['input_file_path']
            df = pd.read_csv(csv_path)
            
            if len(df) != len(embedding_rows):
                return jsonify({"error": "CSV row count mismatch with embeddings"}), 400
            
            # Build feature matrix
            feature_matrices = []
            
            for col in cluster_columns:
                if col not in df.columns:
                    return jsonify({"error": f"Column '{col}' not found in CSV"}), 400
                
                # Check if this column was embedded by looking at first row's text
                col_data = df[col].astype(str).tolist()
                
                is_embedded = False
                if len(embedding_rows) > 0 and len(col_data) > 0:
                    first_text = embedding_rows[0]['text']
                    first_value = col_data[0]
                    if first_value in first_text:
                        is_embedded = True
                
                if is_embedded:
                    # Use embeddings directly
                    logger.info(f"Column '{col}' appears to be embedded, using embeddings")
                    features = np.array([row['embedding'] for row in embedding_rows])
                else:
                    # Encode the column
                    logger.info(f"Column '{col}' not embedded, encoding...")
                    
                    # Try to detect if numerical
                    try:
                        numeric_data = pd.to_numeric(df[col], errors='coerce')
                        if numeric_data.notna().sum() > len(df) * 0.5:  # More than 50% valid numbers
                            # Treat as numerical
                            logger.info(f"Column '{col}' detected as numerical")
                            numeric_data = numeric_data.fillna(numeric_data.mean())
                            # Standardize (z-score)
                            mean = numeric_data.mean()
                            std = numeric_data.std()
                            if std > 0:
                                features = ((numeric_data - mean) / std).values.reshape(-1, 1)
                            else:
                                features = numeric_data.values.reshape(-1, 1)
                        else:
                            raise ValueError("Not numerical")
                    except:
                        # Treat as categorical
                        logger.info(f"Column '{col}' detected as categorical")
                        from sklearn.preprocessing import LabelEncoder
                        le = LabelEncoder()
                        encoded = le.fit_transform(df[col].astype(str).fillna(''))
                        features = encoded.reshape(-1, 1)
                
                feature_matrices.append(features)
            
            # Concatenate all feature matrices
            if len(feature_matrices) == 0:
                return jsonify({"error": "No valid features for clustering"}), 400
            
            X = np.hstack(feature_matrices)
            logger.info(f"Combined feature matrix shape: {X.shape}")
        
        # Run KMeans
        kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
        labels = kmeans.fit_predict(X)
        
        # Update DB
        ids = [row['id'] for row in embedding_rows]
        cluster_map = {row_id: int(label) for row_id, label in zip(ids, labels)}
        db.update_cluster_ids(job_id, cluster_map)
        
        # Generate summary
        unique, counts = np.unique(labels, return_counts=True)
        summary = [{"cluster": int(u), "count": int(c)} for u, c in zip(unique, counts)]
        
        return jsonify({
            "status": "success",
            "summary": summary,
            "feature_dim": X.shape[1],
            "columns_used": cluster_columns if cluster_columns else ["embeddings_only"]
        })
        
    except Exception as e:
        logger.error(f"Error in clustering: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route('/api/compare', methods=['POST'])
def compare_embeddings():
    """
    Compare embeddings between two jobs.
    """
    try:
        data = request.json
        job_id_1 = data.get('job_id_1')
        job_id_2 = data.get('job_id_2')
        threshold = float(data.get('threshold', 0.8))
        top_k = int(data.get('top_k', 5)) # Max matches per row
        
        if not job_id_1 or not job_id_2:
            return jsonify({"error": "Both job IDs are required"}), 400
            
        logger.info(f"Comparing job {job_id_1} and {job_id_2} with threshold {threshold}")
        
        # Fetch embeddings
        # For simplicity, we load all into memory. 
        # For production with huge datasets, we'd need vector DB or batching.
        
        def get_vectors(jid):
            gen = db.get_job_embeddings(jid)
            ids = []
            vecs = []
            texts = []
            metas = []
            for item in gen:
                ids.append(item['id'])
                vecs.append(item['embedding'])
                texts.append(item['text'])
                metas.append(item['metadata'])
            return ids, np.array(vecs), texts, metas

        ids_1, X_1, texts_1, metas_1 = get_vectors(job_id_1)
        ids_2, X_2, texts_2, metas_2 = get_vectors(job_id_2)
        
        if len(X_1) == 0 or len(X_2) == 0:
             return jsonify({"error": "One or both jobs have no embeddings"}), 400

        # Compute Cosine Similarity
        # Shape: (n_samples_1, n_samples_2)
        similarity_matrix = cosine_similarity(X_1, X_2)
        
        matches = []
        
        # Find matches > threshold
        # Iterate over rows in Job 1
        for i in range(len(X_1)):
            # Get scores for this row against all rows in Job 2
            scores = similarity_matrix[i]
            
            # Find indices where score > threshold
            match_indices = np.where(scores >= threshold)[0]
            
            # Sort by score descending
            match_indices = match_indices[np.argsort(scores[match_indices])[::-1]]
            
            # Take top_k
            match_indices = match_indices[:top_k]
            
            for j in match_indices:
                matches.append({
                    "source_row": {
                        "id": ids_1[i],
                        "text": texts_1[i],
                        "metadata": metas_1[i]
                    },
                    "target_row": {
                        "id": ids_2[j],
                        "text": texts_2[j],
                        "metadata": metas_2[j]
                    },
                    "score": float(scores[j])
                })
                
        return jsonify({
            "status": "success",
            "match_count": len(matches),
            "matches": matches
        })

    except Exception as e:
        logger.error(f"Error in comparison: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route('/api/download/<job_id>/<format_type>', methods=['GET'])
def download_embeddings_get(job_id, format_type):
    """
    Download embeddings via GET request (simpler for browsers).
    """
    return download_logic(job_id, format_type)

@app.route('/api/download/<format_type>', methods=['POST'])
def download_embeddings(format_type):
    """
    Download embeddings, streaming from DB.
    """
    try:
        data = request.json
        job_id = data.get('session_id')
        return download_logic(job_id, format_type)
    except Exception as e:
        logger.error(f"Error in download: {str(e)}")
        return jsonify({"error": str(e)}), 500

def download_logic(job_id, format_type):
    try:
        job = db.get_job(job_id)
        if not job or job['status'] != 'completed':
            return jsonify({"error": "Job not completed or found"}), 400
            
        # Generator for streaming response
        def generate():
            # Get formatter
            formatter = get_formatter(format_type)
            
            # For JSON array, we need to handle the opening/closing brackets manually
            # to stream effectively without loading everything
            if format_type == 'json':
                yield '[\n'
                first = True
                for item in db.get_job_embeddings(job_id):
                    if not first:
                        yield ',\n'
                    yield json.dumps(item, indent=2)
                    first = False
                yield '\n]'
                
            elif format_type == 'jsonl':
                for item in db.get_job_embeddings(job_id):
                    yield json.dumps(item) + '\n'
                    
            elif format_type == 'pinecone':
                # Pinecone format is { "vectors": [...] }
                # Streaming this is tricky, we'll do a simplified stream
                yield '{\n  "vectors": [\n'
                first = True
                for item in db.get_job_embeddings(job_id):
                    vector = {
                        "id": item["id"],
                        "values": item["embedding"],
                        "metadata": {
                            "text": item["text"],
                            "cluster_id": item.get("cluster_id"), # Add cluster_id to metadata
                            **item.get("metadata", {})
                        }
                    }
                    if not first:
                        yield ',\n'
                    yield json.dumps(vector, indent=2)
                    first = False
                yield '\n  ]\n}'
                
            else:
                # Fallback for other formats - load all (not ideal for huge datasets but acceptable for now)
                # Ideally we'd implement streaming for all formatters
                all_items = list(db.get_job_embeddings(job_id))
                yield formatter(all_items)

        # Determine filename
        extension = "jsonl" if format_type == "jsonl" else "json"
        filename = f"embeddings_{format_type}.{extension}"
        
        return Response(
            stream_with_context(generate()),
            mimetype='application/json',
            headers={'Content-Disposition': f'attachment; filename={filename}'}
        )
    
    except Exception as e:
        logger.error(f"Error in download logic: {str(e)}")
        return jsonify({"error": str(e)}), 500


from query_engine import SchemaManager, SQLGenerator, SQLExecutor

# Initialize Query Engine Components
schema_manager = SchemaManager()
sql_executor = SQLExecutor(schema_manager)

@app.route('/api/upload_table', methods=['POST'])
def upload_table():
    """Upload a CSV to be used as a SQL table."""
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file provided"}), 400
        
        file = request.files['file']
        table_name = request.form.get('table_name', file.filename.replace('.csv', ''))
        
        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400
            
        # Save temp
        file_path = UPLOAD_FOLDER / f"table_{table_name}.csv"
        file.save(file_path)
        
        success, msg = schema_manager.load_table(table_name, str(file_path))
        
        if success:
            return jsonify({"message": msg, "table_name": table_name})
        else:
            return jsonify({"error": msg}), 500
            
    except Exception as e:
        logger.error(f"Error uploading table: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/upload_dictionary', methods=['POST'])
def upload_dictionary():
    """Upload Data Dictionary CSV."""
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file provided"}), 400
            
        file = request.files['file']
        file_path = UPLOAD_FOLDER / "data_dictionary.csv"
        file.save(file_path)
        
        # Load
        success, msg = schema_manager.load_data_dictionary(str(file_path))
        if not success:
            return jsonify({"error": msg}), 400
            
        # Index (using default provider for now, or user provided)
        # We can get params from form data
        provider = request.form.get('provider', 'sentence-transformers')
        api_key = request.form.get('api_key')
        model = request.form.get('model')
        
        idx_success, idx_msg = schema_manager.index_dictionary(provider, api_key, model)
        
        if idx_success:
            return jsonify({"message": f"{msg} {idx_msg}"})
        else:
            return jsonify({"warning": f"{msg} But indexing failed: {idx_msg}"})
            
    except Exception as e:
        logger.error(f"Error uploading dictionary: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/query', methods=['POST'])
def process_query():
    """Process a natural language query."""
    try:
        data = request.json
        question = data.get('question')
        api_key = data.get('api_key')
        model = data.get('model', 'gemini-1.5-pro')
        
        if not question or not api_key:
            return jsonify({"error": "Question and API Key are required"}), 400
            
        # 1. Search relevant schema
        relevant_schema = schema_manager.search_relevant_schema(question)
        all_tables = schema_manager.get_all_tables()
        
        # 2. Generate SQL
        generator = SQLGenerator(api_key, model)
        sql = generator.generate_sql(question, relevant_schema, all_tables)
        
        # 3. Execute SQL
        columns, rows, error = sql_executor.execute(sql)
        
        return jsonify({
            "sql": sql,
            "columns": columns,
            "rows": rows,
            "error": error,
            "relevant_schema": relevant_schema
        })
        
    except Exception as e:
        logger.error(f"Error processing query: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"\nStructured Data Query Tool running on http://localhost:{port}")
    print(f"Open your browser and navigate to the URL above\n")
    app.run(debug=False, port=port, host='0.0.0.0')
