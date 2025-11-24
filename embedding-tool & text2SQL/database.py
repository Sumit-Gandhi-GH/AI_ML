"""
Database module for the embedding tool using SQLite.
Handles storage of jobs and embeddings.
"""

import sqlite3
import json
import logging
from pathlib import Path
import tempfile
from typing import Dict, Any, List, Optional, Generator
from datetime import datetime

logger = logging.getLogger(__name__)

# Database path
DB_DIR = Path(tempfile.gettempdir()) / "embedding_tool_db"
DB_DIR.mkdir(exist_ok=True)
DB_PATH = DB_DIR / "embeddings.db"

def get_db_connection():
    """Get a connection to the SQLite database."""
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initialize the database schema."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Jobs table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS jobs (
        id TEXT PRIMARY KEY,
        status TEXT NOT NULL, -- 'pending', 'processing', 'completed', 'failed'
        total_rows INTEGER DEFAULT 0,
        processed_rows INTEGER DEFAULT 0,
        error_message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        input_file_path TEXT,
        provider TEXT,
        model TEXT
    )
    ''')
    
    # Embeddings table
    # We use a separate table for embeddings to allow efficient streaming and storage
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS embeddings (
        job_id TEXT,
        row_index INTEGER,
        text TEXT,
        embedding BLOB, -- Stored as JSON string or binary
        metadata TEXT, -- Stored as JSON string
        cluster_id INTEGER, -- New column for clustering
        PRIMARY KEY (job_id, row_index),
        FOREIGN KEY (job_id) REFERENCES jobs (id)
    )
    ''')
    
    # Migration: Check if cluster_id exists, if not add it
    try:
        cursor.execute('SELECT cluster_id FROM embeddings LIMIT 1')
    except sqlite3.OperationalError:
        logger.info("Migrating database: Adding cluster_id column")
        cursor.execute('ALTER TABLE embeddings ADD COLUMN cluster_id INTEGER')
    
    conn.commit()
    conn.close()
    logger.info(f"Database initialized at {DB_PATH}")

def create_job(job_id: str, input_file_path: str, total_rows: int) -> str:
    """Create a new job record."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        'INSERT INTO jobs (id, status, input_file_path, total_rows) VALUES (?, ?, ?, ?)',
        (job_id, 'pending', input_file_path, total_rows)
    )
    
    conn.commit()
    conn.close()
    return job_id

def update_job_status(job_id: str, status: str, error_message: Optional[str] = None):
    """Update job status."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    if error_message:
        cursor.execute(
            'UPDATE jobs SET status = ?, error_message = ? WHERE id = ?',
            (status, error_message, job_id)
        )
    else:
        cursor.execute(
            'UPDATE jobs SET status = ? WHERE id = ?',
            (status, job_id)
        )
    
    conn.commit()
    conn.close()

def update_job_progress(job_id: str, processed_rows: int):
    """Update job progress."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        'UPDATE jobs SET processed_rows = ? WHERE id = ?',
        (processed_rows, job_id)
    )
    
    conn.commit()
    conn.close()

def get_job(job_id: str) -> Optional[Dict[str, Any]]:
    """Get job details."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute('SELECT * FROM jobs WHERE id = ?', (job_id,))
    row = cursor.fetchone()
    
    conn.close()
    
    if row:
        return dict(row)
    return None

def save_embeddings_batch(job_id: str, embeddings_data: List[Dict[str, Any]]):
    """Save a batch of embeddings."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    values = []
    for item in embeddings_data:
        values.append((
            job_id,
            item['id'], # row_index
            item['text'],
            json.dumps(item['embedding']), # Store as JSON string for simplicity
            json.dumps(item['metadata'])
        ))
    
    cursor.executemany(
        'INSERT INTO embeddings (job_id, row_index, text, embedding, metadata) VALUES (?, ?, ?, ?, ?)',
        values
    )
    
    conn.commit()
    conn.close()

def update_cluster_ids(job_id: str, cluster_map: Dict[int, int]):
    """
    Update cluster IDs for a job.
    cluster_map: {row_index: cluster_id}
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Prepare batch update
    values = [(cluster_id, job_id, row_index) for row_index, cluster_id in cluster_map.items()]
    
    cursor.executemany(
        'UPDATE embeddings SET cluster_id = ? WHERE job_id = ? AND row_index = ?',
        values
    )
    
    conn.commit()
    conn.close()

def get_job_embeddings(job_id: str) -> Generator[Dict[str, Any], None, None]:
    """Yield embeddings for a job efficiently."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Use server-side cursor for large datasets if possible, 
    # but standard cursor with fetchmany is also fine for SQLite
    cursor.execute('SELECT row_index, text, embedding, metadata, cluster_id FROM embeddings WHERE job_id = ? ORDER BY row_index', (job_id,))
    
    while True:
        rows = cursor.fetchmany(1000)
        if not rows:
            break
            
        for row in rows:
            yield {
                "id": str(row['row_index']),
                "text": row['text'],
                "embedding": json.loads(row['embedding']),
                "metadata": json.loads(row['metadata']),
                "cluster_id": row['cluster_id']
            }
    
    conn.close()

# Initialize DB on module load
init_db()
