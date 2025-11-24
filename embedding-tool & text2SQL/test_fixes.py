import requests
import os

BASE_URL = "http://localhost:5000"

def test_upload_table():
    print("\n--- Testing Table Upload ---")
    # Create a dummy CSV
    with open("test_table.csv", "w") as f:
        f.write("id,name,value\n1,A,10\n2,B,20")
    
    files = {'file': open("test_table.csv", "rb")}
    data = {'table_name': 'test_table'}
    
    try:
        res = requests.post(f"{BASE_URL}/api/upload_table", files=files, data=data)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        files['file'].close()
        os.remove("test_table.csv")

def test_upload_dictionary():
    print("\n--- Testing Dictionary Upload ---")
    # Create a dummy Dictionary
    with open("test_dict.csv", "w") as f:
        f.write("Table Name,Column Name,Description\ntest_table,id,Unique identifier\ntest_table,name,Name of item\ntest_table,value,Value of item")
    
    files = {'file': open("test_dict.csv", "rb")}
    # Use sentence-transformers for local test to avoid API key need
    data = {'provider': 'sentence-transformers'} 
    
    try:
        res = requests.post(f"{BASE_URL}/api/upload_dictionary", files=files, data=data)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        files['file'].close()
        os.remove("test_dict.csv")

def test_query():
    print("\n--- Testing Query ---")
    # We need a valid API key for this to truly work, but we can test the flow.
    # If no key is provided, it should return an error, but not crash.
    
    data = {
        "question": "Show me all items",
        "api_key": "dummy_key", 
        "model": "gemini-1.5-pro"
    }
    
    try:
        res = requests.post(f"{BASE_URL}/api/query", json=data)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_upload_table()
    test_upload_dictionary()
    test_query()
