
import google.generativeai as genai
import os

# Mock API key to get past initial check if possible, or use a dummy one
# The error reported is about input type, which might happen before auth
os.environ["GOOGLE_API_KEY"] = "dummy_key"
genai.configure(api_key="dummy_key")

try:
    model_name = "models/text-embedding-004"
    print(f"Testing with model: {model_name} (type: {type(model_name)})")
    
    # Try calling it exactly as in embeddings.py
    genai.embed_content(
        model=model_name,
        content="Hello world",
        task_type="retrieval_document"
    )
    print("Call successful (or at least didn't throw type error)")
except Exception as e:
    print(f"Caught error: {type(e).__name__}: {e}")
