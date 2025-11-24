import sqlite3
from pathlib import Path
import tempfile
import pandas as pd

DB_PATH = Path(tempfile.gettempdir()) / "embedding_tool_db" / "embeddings.db"

def inspect_db():
    if not DB_PATH.exists():
        print(f"Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(str(DB_PATH))
    
    print("\n=== JOBS ===")
    try:
        jobs = pd.read_sql_query("SELECT * FROM jobs ORDER BY created_at DESC LIMIT 5", conn)
        print(jobs)
    except Exception as e:
        print(f"Error reading jobs: {e}")
        
    conn.close()

if __name__ == "__main__":
    inspect_db()
