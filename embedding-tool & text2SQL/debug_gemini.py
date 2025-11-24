import google.generativeai as genai
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_gemini_variations():
    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("Please set GOOGLE_API_KEY environment variable.")
        return

    genai.configure(api_key=api_key)
    
    text = "Hello world"
    
    variations = [
        {"model": "models/text-embedding-004", "task_type": "retrieval_document"},
        {"model": "text-embedding-004", "task_type": "retrieval_document"},
        {"model": "models/embedding-001", "task_type": "retrieval_document"},
        {"model": "embedding-001", "task_type": "retrieval_document"},
        {"model": "models/embedding-001", "task_type": None}, # Try without task_type
        {"model": "embedding-001", "task_type": None},
    ]
    
    print(f"Testing {len(variations)} variations...")
    
    for i, v in enumerate(variations):
        print(f"\n--- Variation {i+1}: Model='{v['model']}', TaskType='{v['task_type']}' ---")
        try:
            if v['task_type']:
                result = genai.embed_content(
                    model=v['model'],
                    content=text,
                    task_type=v['task_type']
                )
            else:
                result = genai.embed_content(
                    model=v['model'],
                    content=text
                )
            print("SUCCESS!")
            print(f"Embedding length: {len(result['embedding'])}")
        except Exception as e:
            print(f"FAILED: {e}")

if __name__ == "__main__":
    test_gemini_variations()
