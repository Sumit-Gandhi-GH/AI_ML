import requests
import json
import time

BASE_URL = "http://localhost:5000"

def test_clustering():
    # 1. Upload a file
    print("Uploading file...")
    with open("test_upload.csv", "w") as f:
        f.write("text,category\napple,fruit\nbanana,fruit\ncar,vehicle\nbus,vehicle\ncat,animal")
        
    with open("test_upload.csv", "rb") as f:
        files = {"file": f}
        response = requests.post(f"{BASE_URL}/api/upload", files=files)
    
    if response.status_code != 200:
        print(f"Upload failed: {response.text}")
        return
        
    job_id = response.json()['session_id']
    print(f"Job ID: {job_id}")
    
    # 2. Generate embeddings (using local model for speed)
    print("Generating embeddings...")
    payload = {
        "session_id": job_id,
        "text_columns": ["text"],
        "provider": "sentence-transformers",
        "combine_columns": False
    }
    requests.post(f"{BASE_URL}/api/generate", json=payload)
    
    # Wait for completion
    for _ in range(10):
        status = requests.get(f"{BASE_URL}/api/status/{job_id}").json()
        print(f"Status: {status['status']}")
        if status['status'] == 'completed':
            break
        time.sleep(2)
        
    # 3. Cluster
    print("Clustering...")
    payload = {
        "session_id": job_id,
        "n_clusters": 3
    }
    response = requests.post(f"{BASE_URL}/api/cluster", json=payload)
    print(f"Cluster Response: {response.text}")
    
    # 4. Download and check for cluster_id
    print("Downloading...")
    response = requests.get(f"{BASE_URL}/api/download/{job_id}/json")
    data = response.json()
    print("First item:", json.dumps(data[0], indent=2))
    
    if "cluster_id" in data[0]["metadata"]:
        print("SUCCESS: cluster_id found in metadata")
    else:
        print("FAILURE: cluster_id NOT found")

if __name__ == "__main__":
    test_clustering()
