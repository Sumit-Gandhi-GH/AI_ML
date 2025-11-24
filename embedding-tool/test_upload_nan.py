import requests

URL = "http://localhost:5000/api/upload"
FILE_PATH = "test_nan.csv"

# Create a CSV with missing values (NaN)
with open(FILE_PATH, "w") as f:
    f.write("id,text,category\n1,Hello world,\n2,,test") # Missing category in row 1, missing text in row 2

print(f"Uploading {FILE_PATH} to {URL}...")

try:
    with open(FILE_PATH, "rb") as f:
        response = requests.post(URL, files={"file": f})
    
    print(f"Status Code: {response.status_code}")
    print("Response Body:")
    print(response.text)
    
    # Check if "NaN" is in the text
    if "NaN" in response.text:
        print("CONFIRMED: Response contains NaN")
    else:
        print("Response does not contain NaN")

except Exception as e:
    print(f"Request failed: {e}")
