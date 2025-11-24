import requests
import os
import time

BASE_URL = "http://127.0.0.1:5000"

def test_enhanced_clustering():
    # Create a test CSV with mixed field types
    csv_file = "test_mixed_data.csv"
    content = "id,description,category,price\n1,red apple,fruit,1.50\n2,green banana,fruit,0.75\n3,toy car,toy,5.99\n4,orange fruit,fruit,1.25\n5,wooden car,toy,12.00"
    
    with open(csv_file, 'w') as f:
        f.write(content)
    
    try:
        # 1. Upload CSV
        print("Uploading CSV...")
        with open(csv_file, 'rb') as f:
            response = requests.post(f"{BASE_URL}/api/upload", files={'file': f})
        
        if response.status_code != 200:
            print(f"Upload failed: {response.text}")
            return
        
        data = response.json()
        job_id = data['session_id']
        print(f"Uploaded CSV, Job ID: {job_id}")
        print(f"Columns: {data['columns']}")
        
        # 2. Generate embeddings for 'description' only
        print("\nGenerating embeddings for 'description'...")
        payload = {
            "session_id": job_id,
            "text_columns": ["description"],
            "metadata_columns": [],
            "provider": "sentence-transformers",
            "combine_columns": False
        }
        response = requests.post(f"{BASE_URL}/api/generate", json=payload)
        if response.status_code not in [200, 202]:
            print(f"Generate failed: {response.text}")
            return
        
        # Wait for completion
        while True:
            status_resp = requests.get(f"{BASE_URL}/api/status/{job_id}")
            status = status_resp.json()
            if status['status'] == 'completed':
                print("Embeddings generated!")
                break
            if status['status'] == 'failed':
                print(f"Failed: {status['error']}")
                return
            time.sleep(1)
        
        # 3. Test Clustering WITHOUT column selection (default: use embeddings)
        print("\n--- Test 1: Cluster using embeddings only ---")
        cluster_payload = {
            "session_id": job_id,
            "n_clusters": 2
            # No cluster_columns specified
        }
        response = requests.post(f"{BASE_URL}/api/cluster", json=cluster_payload)
        if response.status_code == 200:
            result = response.json()
            print(f"Status: {result['status']}")
            print(f"Feature dimensions: {result.get('feature_dim', 'N/A')}")
            print(f"Columns used: {result.get('columns_used', 'N/A')}")
            print(f"Cluster summary: {result.get('summary', [])}")
        else:
            print(f"Clustering failed: {response.text}")
        
        # 4. Test Clustering WITH custom column selection
        print("\n--- Test 2: Cluster using 'category' and 'price' ---")
        cluster_payload2 = {
            "session_id": job_id,
            "n_clusters": 2,
            "cluster_columns": ["category", "price"]  # Categorical + Numerical
        }
        response2 = requests.post(f"{BASE_URL}/api/cluster", json=cluster_payload2)
        if response2.status_code == 200:
            result2 = response2.json()
            print(f"Status: {result2['status']}")
            print(f"Feature dimensions: {result2.get('feature_dim', 'N/A')}")
            print(f"Columns used: {result2.get('columns_used', [])}")
            print(f"Cluster summary: {result2.get('summary', [])}")
        else:
            print(f"Clustering failed: {response2.text}")
        
        # 5. Test Clustering WITH embedded column selection
        print("\n--- Test 3: Cluster using 'description' (embedded column) ---")
        cluster_payload3 = {
            "session_id": job_id,
            "n_clusters": 2,
            "cluster_columns": ["description"]  # This WAS embedded
        }
        response3 = requests.post(f"{BASE_URL}/api/cluster", json=cluster_payload3)
        if response3.status_code == 200:
            result3 = response3.json()
            print(f"Status: {result3['status']}")
            print(f"Feature dimensions: {result3.get('feature_dim', 'N/A')}")
            print(f"Columns used: {result3.get('columns_used', [])}")
            print(f"Cluster summary: {result3.get('summary', [])}")
            print("\nTEST PASSED: Enhanced clustering works!")
        else:
            print(f"Clustering failed: {response3.text}")

    finally:
        # Cleanup
        if os.path.exists(csv_file):
            os.remove(csv_file)

if __name__ == "__main__":
    try:
        test_enhanced_clustering()
    except Exception as e:
        print(f"Test error: {e}")
        import traceback
        traceback.print_exc()
