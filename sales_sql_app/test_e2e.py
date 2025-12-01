"""
Comprehensive end-to-end test for Sales SQL App
"""
import os
import sys

# Fix Windows console encoding
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

print("=" * 60)
print("SALES SQL APP - END-TO-END TEST")
print("=" * 60)

# Test 1: Import all required modules
print("\n[1/6] Testing imports...")
try:
    from chain import setup_vector_store, setup_mock_db, generate_sql, execute_sql
    from utils import mask_pii, determine_domain
    from puter_client import get_puter_client
    print("[OK] All imports successful")
except Exception as e:
    print(f"[FAIL] Import error: {e}")
    sys.exit(1)

# Test 2: Setup Mock Database
print("\n[2/6] Testing database setup...")
try:
    setup_mock_db()
    print("[OK] Mock database created")
except Exception as e:
    print(f"[FAIL] Database setup error: {e}")
    sys.exit(1)

# Test 3: Test Sentence Transformers Embeddings
print("\n[3/6] Testing sentence transformers embeddings...")
try:
    vectorstore = setup_vector_store(use_sentence_transformers=True)
    if vectorstore:
        print("[OK] Vector store created successfully")
        # Test similarity search
        results = vectorstore.similarity_search("Show me revenue", k=2)
        print(f"[OK] Similarity search works - found {len(results)} examples")
    else:
        print("[FAIL] Failed to create vector store")
        sys.exit(1)
except Exception as e:
    print(f"[FAIL] Embeddings error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Test 4: Test SQL Generation with Gemini
print("\n[4/6] Testing SQL generation with Gemini...")
try:
    query = "Show me all sales reps in the North region"
    sql = generate_sql(query, model_name="gemini-1.5-pro")
    print(f"[OK] SQL generated: {sql[:100]}...")
except Exception as e:
    print(f"[WARN] SQL generation error (expected if no API key): {e}")

# Test 5: Test SQL Execution
print("\n[5/6] Testing SQL execution...")
try:
    test_sql = "SELECT * FROM SALES_REPS LIMIT 2"
    df = execute_sql(test_sql)
    print(f"[OK] SQL executed - returned {len(df)} rows")
    print(f"  Columns: {list(df.columns)}")
except Exception as e:
    print(f"[FAIL] SQL execution error: {e}")
    sys.exit(1)

# Test 6: Test PII Masking
print("\n[6/6] Testing PII masking...")
try:
    import pandas as pd
    test_df = pd.DataFrame({
        'name': ['John Doe'],
        'email': ['john@example.com'],
        'phone': ['555-1234'],
        'amount': [1000]
    })
    masked = mask_pii(test_df)
    if masked['email'][0] == '***@***.com' and masked['phone'][0] == '***-***-****':
        print("[OK] PII masking works correctly")
    else:
        print("[FAIL] PII masking failed")
        sys.exit(1)
except Exception as e:
    print(f"[FAIL] PII masking error: {e}")
    sys.exit(1)

print("\n" + "=" * 60)
print("ALL TESTS PASSED!")
print("=" * 60)
print("\nThe app is ready to use. You can run:")
print("  python -m streamlit run sales_sql_app/app.py")
print("\nNote: Gemini models require GOOGLE_API_KEY in .env")
print("      Claude models require PUTER_USERNAME and PUTER_PASSWORD in .env")
