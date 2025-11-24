import requests

URL = "http://localhost:5000/api/upload"
FILE_PATH = "test_upload.csv"

# Create a dummy CSV
with open(FILE_PATH, "w") as f:
    f.write("id,text,category\n1,Hello world,test\n2,Another row,test")

print(f"Uploading {FILE_PATH} to {URL}...")

try:
    with open(FILE_PATH, "rb") as f:
        response = requests.post(URL, files={"file": f})
    
    print(f"Status Code: {response.status_code}")
    print("Response Body:")
    print(response.text)
    
    try:
        print("JSON:", response.json())
    except Exception as e:
        print(f"Failed to parse JSON: {e}")

except Exception as e:
    print(f"Request failed: {e}")
