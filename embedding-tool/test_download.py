import requests
import sys

JOB_ID = "3895629140902285919" # Latest completed job
URL = f"http://localhost:5000/api/download/json"

print(f"Testing download for job {JOB_ID}...")

try:
    response = requests.post(URL, json={"session_id": JOB_ID}, stream=True)
    
    if response.status_code == 200:
        print("Download request successful (200 OK)")
        print(f"Headers: {response.headers}")
        
        # Read first chunk to verify content
        chunk = next(response.iter_content(chunk_size=1024))
        print(f"First 100 bytes: {chunk[:100]}")
    else:
        print(f"Download failed with status {response.status_code}")
        print(response.text)
        
except Exception as e:
    print(f"Error: {e}")
