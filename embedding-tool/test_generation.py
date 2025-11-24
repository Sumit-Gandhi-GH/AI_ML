import logging
import sys
from pathlib import Path
import tempfile
import pandas as pd
import database as db
from server import background_processing

# Configure logging to stdout
logging.basicConfig(level=logging.INFO, stream=sys.stdout)
logger = logging.getLogger(__name__)

def test_generation():
    print("Starting test generation...")
    
    # Create a dummy CSV
    csv_path = Path("test_10_rows.csv")
    df = pd.DataFrame({'text': [f'This is row {i}' for i in range(10)], 'category': ['A']*10})
    df.to_csv(csv_path, index=False)
    
    # Create job
    import time
    job_id = f"test_job_{int(time.time())}"
    db.create_job(job_id, str(csv_path.absolute()), 10)
    
    # Run processing synchronously
    try:
        background_processing(
            job_id=job_id,
            file_path=str(csv_path.absolute()),
            text_columns=['text'],
            metadata_columns=['category'],
            provider='sentence-transformers',
            api_key=None,
            model=None,
            combine_columns=False
        )
        print("Processing finished.")
        
        # Check DB
        job = db.get_job(job_id)
        print(f"Job status: {job['status']}")
        print(f"Processed rows: {job['processed_rows']}")
        
    except Exception as e:
        print(f"Test failed: {e}")

if __name__ == "__main__":
    test_generation()
