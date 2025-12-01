from chain import setup_vector_store

def test_sentence_transformers():
    print("Testing Sentence Transformers embeddings...")
    
    try:
        vectorstore = setup_vector_store(use_sentence_transformers=True)
        
        if vectorstore:
            print("✓ Sentence Transformers vector store created successfully!")
            
            # Test similarity search
            results = vectorstore.similarity_search("Show me revenue", k=2)
            print(f"✓ Found {len(results)} similar examples")
            for i, doc in enumerate(results):
                print(f"  {i+1}. {doc.page_content}")
        else:
            print("✗ Failed to create vector store")
    except Exception as e:
        print(f"✗ Error: {e}")

if __name__ == "__main__":
    test_sentence_transformers()
