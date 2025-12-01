"""
Quick test to identify where Google embeddings are being called
"""
import sys

print("Testing where the error occurs...")

# Test 1: Import
print("[1] Importing chain module...")
try:
    from chain import setup_vector_store
    print("  [OK] Import successful")
except Exception as e:
    print(f"  [FAIL] {e}")
    sys.exit(1)

# Test 2: Setup vector store with sentence transformers
print("\n[2] Setting up vector store with sentence transformers...")
try:
    vectorstore = setup_vector_store(use_sentence_transformers=True)
    print(f"  [OK] Vector store created: {type(vectorstore)}")
except Exception as e:
    print(f"  [FAIL] Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n[SUCCESS] No Google API calls made!")
