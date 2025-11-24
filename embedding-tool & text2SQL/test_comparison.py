import requests
import time
import os

BASE_URL = "http://127.0.0.1:5000"

def upload_csv(filename, content):
    with open(filename, 'w') as f:
        f.write(content)
    
    with open(filename, 'rb') as f:
        response = requests.post(f"{BASE_URL}/api/upload", files={'file': f})
    
    if response.status_code != 200:
        print(f"Upload failed: {response.text}")
        return None
    return response.json()

def generate_embeddings(job_id, text_column):
    payload = {
        "session_id": job_id,
        "text_columns": [text_column],
        "metadata_columns": [],
        "provider": "sentence-transformers",
        "combine_columns": False
    }
    response = requests.post(f"{BASE_URL}/api/generate", json=payload)
    if response.status_code not in [200, 202]:
        print(f"Generate failed: {response.text}")
        return None
    return response.json()['job_id']

def wait_for_job(job_id):
    while True:
        response = requests.get(f"{BASE_URL}/api/status/{job_id}")
        status = response.json()
        if status['status'] == 'completed':
            return True
        if status['status'] == 'failed':
            print(f"Job failed: {status['error']}")
            return False
        time.sleep(1)

def test_comparison():
    # File A: Fruits
    csv_a = "test_fruits_a.csv"
    content_a = "id,name\n1,apple\n2,banana\n3,orange"
    data_a = upload_csv(csv_a, content_a)
    job_id_a = data_a['session_id']
    print(f"Job A: {job_id_a}")
    
    generate_embeddings(job_id_a, "name")
    if not wait_for_job(job_id_a):
        return

    # File B: Similar Fruits
    csv_b = "test_fruits_b.csv"
    content_b = "id,description\n101,green apple\n102,yellow banana\n103,car" # Car shouldn't match well
    data_b = upload_csv(csv_b, content_b)
    job_id_b = data_b['session_id']
    print(f"Job B: {job_id_b}")
    
    generate_embeddings(job_id_b, "description")
    if not wait_for_job(job_id_b):
        return

    # Compare
    print("Comparing...")
    payload = {
        "job_id_1": job_id_a,
        "job_id_2": job_id_b,
        "threshold": 0.5 # Low threshold to catch 'apple' -> 'green apple'
    }
    response = requests.post(f"{BASE_URL}/api/compare", json=payload)
    
    if response.status_code == 200:
        result = response.json()
        print("Comparison Success!")
        print(f"Matches found: {result['match_count']}")
        for match in result['matches']:
            print(f"{match['source_row']['text']} <-> {match['target_row']['text']} (Score: {match['score']:.4f})")
            
        # Assertions
        matches = result['matches']
        found_apple = any(m['source_row']['text'] == 'apple' and 'apple' in m['target_row']['text'] for m in matches)
        found_banana = any(m['source_row']['text'] == 'banana' and 'banana' in m['target_row']['text'] for m in matches)
        
        if found_apple and found_banana:
            print("TEST PASSED: Correct matches found.")
        else:
            print("TEST FAILED: Expected matches not found.")
            
    else:
        print(f"Comparison failed: {response.text}")

    # Cleanup
    if os.path.exists(csv_a): os.remove(csv_a)
    if os.path.exists(csv_b): os.remove(csv_b)

if __name__ == "__main__":
    try:
        test_comparison()
    except Exception as e:
        print(f"Test error: {e}")
