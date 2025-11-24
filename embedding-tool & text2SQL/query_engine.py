import sqlite3
import pandas as pd
import google.generativeai as genai
from openai import OpenAI
import logging
from typing import List, Dict, Any, Optional, Tuple
import json
import re
from embeddings import EmbeddingGenerator
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

logger = logging.getLogger(__name__)

class SchemaManager:
    """Manages the SQLite database and Data Dictionary."""
    
    def __init__(self, db_path: str = ":memory:"):
        self.db_path = db_path
        self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
        self.cursor = self.conn.cursor()
        self.data_dictionary = [] # List of dicts: {table_name, column_name, description, ...}
        self.table_schemas = {} # {table_name: [col1, col2...]}
        
        # For semantic search
        self.embedding_generator = None
        self.dictionary_embeddings = []
        self.dictionary_texts = []
        
    def load_table(self, table_name: str, csv_path: str):
        """Loads a CSV into a SQLite table."""
        try:
            df = pd.read_csv(csv_path)
            # Sanitize table name
            table_name = re.sub(r'\W+', '_', table_name)
            df.to_sql(table_name, self.conn, if_exists='replace', index=False)
            self.table_schemas[table_name] = df.columns.tolist()
            logger.info(f"Loaded table '{table_name}' with {len(df)} rows.")
            return True, f"Table '{table_name}' loaded successfully."
        except Exception as e:
            logger.error(f"Error loading table {table_name}: {e}")
            return False, str(e)

    def load_data_dictionary(self, csv_path: str):
        """Loads the Data Dictionary CSV."""
        try:
            df = pd.read_csv(csv_path)
            # Expected columns: Table Name, Column Name, Description, Data Type (optional)
            # Normalize columns
            df.columns = [c.lower().replace(' ', '_') for c in df.columns]
            
            required_cols = ['table_name', 'column_name', 'description']
            if not all(col in df.columns for col in required_cols):
                return False, f"Data Dictionary must contain columns: {required_cols}"
            
            self.data_dictionary = df.to_dict('records')
            logger.info(f"Loaded Data Dictionary with {len(self.data_dictionary)} entries.")
            return True, "Data Dictionary loaded successfully."
        except Exception as e:
            logger.error(f"Error loading Data Dictionary: {e}")
            return False, str(e)

    def index_dictionary(self, provider='sentence-transformers', api_key=None, model=None):
        """Creates embeddings for the Data Dictionary entries."""
        if not self.data_dictionary:
            return False, "No Data Dictionary loaded."
            
        self.embedding_generator = EmbeddingGenerator(provider, api_key, model)
        
        # Create text representation for each entry
        self.dictionary_texts = []
        for entry in self.data_dictionary:
            text = f"Table: {entry.get('table_name')} Column: {entry.get('column_name')} Description: {entry.get('description')}"
            self.dictionary_texts.append(text)
            
        # Generate embeddings
        try:
            self.dictionary_embeddings = self.embedding_generator.generate_embeddings(self.dictionary_texts)
            logger.info("Data Dictionary indexed successfully.")
            return True, "Data Dictionary indexed."
        except Exception as e:
            logger.error(f"Error indexing dictionary: {e}")
            return False, str(e)

    def search_relevant_schema(self, query: str, top_k: int = 10) -> List[Dict]:
        """Finds relevant dictionary entries for a user query."""
        if not self.embedding_generator or not self.dictionary_embeddings:
            # Fallback: Return all if no index (or simple keyword match could be added)
            return self.data_dictionary[:20] 
            
        query_embedding = self.embedding_generator.generate_embeddings([query])[0]
        
        # Calculate similarity
        sims = cosine_similarity([query_embedding], self.dictionary_embeddings)[0]
        
        # Get top k
        top_indices = np.argsort(sims)[::-1][:top_k]
        
        results = []
        for idx in top_indices:
            results.append(self.data_dictionary[idx])
            
        return results

    def get_all_tables(self):
        """Returns list of all table names in DB."""
        self.cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        return [row[0] for row in self.cursor.fetchall()]

class SQLGenerator:
    """Generates SQL using Gemini or OpenAI."""
    
    def __init__(self, api_key: str, model_name: str = "gemini-1.5-pro"):
        self.model_name = str(model_name)
        self.api_key = api_key
        self.provider = "google"
        
        if self.model_name.lower().startswith("gpt"):
            self.provider = "openai"
            self.client = OpenAI(api_key=api_key)
        else:
            self.provider = "google"
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel(self.model_name)
        
    def generate_sql(self, question: str, schema_context: List[Dict], all_tables: List[str]) -> str:
        """
        Generates a SQL query based on the question and schema context.
        """
        # Construct the prompt
        schema_text = ""
        for item in schema_context:
            schema_text += f"- Table: {item.get('table_name')}, Column: {item.get('column_name')}, Description: {item.get('description')}\n"
            
        prompt = f"""You are an expert SQL data analyst. 
        Your task is to generate a valid SQLite SQL query to answer the user's question.
        
        Available Tables: {', '.join(all_tables)}
        
        Relevant Schema Information:
        {schema_text}
        
        User Question: {question}
        
        IMPORTANT INSTRUCTIONS:
        1. Return ONLY the SQL query. Do not include markdown formatting (like ```sql), explanations, or any other text.
        2. Use only the tables and columns provided in the schema information or available tables list.
        3. The database is SQLite. Use SQLite syntax.
        4. If the question cannot be answered with the available data, return "SELECT 'Cannot answer question with available data' as error".
        """
        
        try:
            if self.provider == "openai":
                response = self.client.chat.completions.create(
                    model=self.model_name,
                    messages=[
                        {"role": "system", "content": "You are a helpful SQL assistant."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0
                )
                sql = response.choices[0].message.content.strip()
            else:
                # Google Gemini
                response = self.model.generate_content(prompt)
                sql = response.text.strip()
            
            # Clean up markdown if present (just in case)
            if sql.startswith("```sql"):
                sql = sql[6:]
            if sql.startswith("```"):
                sql = sql[3:]
            if sql.endswith("```"):
                sql = sql[:-3]
                
            return sql.strip()
            
        except Exception as e:
            return f"SELECT 'Error generating SQL: {str(e)}' as error"

class SQLExecutor:
    """Executes SQL on the SchemaManager's DB."""
    
    def __init__(self, schema_manager: SchemaManager):
        self.manager = schema_manager
        
    def execute(self, sql: str) -> Tuple[List[str], List[Any], Optional[str]]:
        """
        Executes SQL and returns (columns, rows, error).
        """
        try:
            cursor = self.manager.conn.cursor()
            cursor.execute(sql)
            
            if cursor.description:
                columns = [description[0] for description in cursor.description]
                rows = cursor.fetchall()
                return columns, rows, None
            else:
                # For INSERT/UPDATE/DELETE (though we mainly do SELECT)
                self.manager.conn.commit()
                return [], [], "Query executed successfully (no results)."
                
        except Exception as e:
            logger.error(f"SQL Execution Error: {e}")
            return [], [], str(e)
