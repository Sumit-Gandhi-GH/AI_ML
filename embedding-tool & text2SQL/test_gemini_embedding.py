import google.generativeai as genai
import os
from embeddings import EmbeddingGenerator

# You can set your API key here or via environment variable
# os.environ["GOOGLE_API_KEY"] = "YOUR_API_KEY"

def test_gemini_embedding():
    print("Testing Gemini Embedding...")
    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("Skipping test: GOOGLE_API_KEY not found in environment.")
        return

    try:
        generator = EmbeddingGenerator(provider="google", api_key=api_key)
        texts = ["This is a test sentence.", "Another sentence for embedding."]
        embeddings = generator.generate_embeddings(texts)
        
        print(f"Successfully generated {len(embeddings)} embeddings.")
        print(f"Embedding dimension: {len(embeddings[0])}")
        
    except Exception as e:
        print(f"Test Failed: {e}")

if __name__ == "__main__":
    test_gemini_embedding()
