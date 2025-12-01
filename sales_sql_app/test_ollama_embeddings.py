"""
Test Ollama embeddings specifically
"""
import sys
from chain import setup_vector_store

print("Testing Ollama Embeddings (snowflake-arctic-embed2:568m)...")
print("=" * 60)

try:
    print("\nInitializing vector store (this calls Ollama)...")
    vectorstore = setup_vector_store()
    
    if vectorstore:
        print("\n[SUCCESS] Vector store created/loaded.")
        
        # Test similarity search
        query = "sales in North"
        print(f"\nTesting similarity search for: '{query}'")
        docs = vectorstore.similarity_search(query, k=1)
        
        if docs:
            print(f"\nFound match: {docs[0].page_content}")
            print(f"SQL: {docs[0].metadata['sql']}")
            print("\n" + "=" * 60)
            print("Ollama embeddings are working!")
        else:
            print("[WARN] No matches found.")
    else:
        print("[ERROR] Failed to create vector store.")
        sys.exit(1)
    
except Exception as e:
    print(f"\n[ERROR] {e}")
    print("\nMake sure Ollama is running and you have pulled the model:")
    print("ollama pull snowflake-arctic-embed2:568m")
    sys.exit(1)
