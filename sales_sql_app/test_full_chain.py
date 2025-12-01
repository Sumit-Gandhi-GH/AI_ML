import os
import sys
from dotenv import load_dotenv
from chain import generate_sql, setup_mock_db, execute_sql

load_dotenv()

def test_full_flow():
    print("--- Starting Full Flow Test ---")
    
    # 1. Setup DB
    print("1. Setting up Mock DB...")
    try:
        setup_mock_db()
        print("   DB Setup Complete.")
    except Exception as e:
        print(f"   ERROR setting up DB: {e}")
        return

    # 2. Test SQL Generation
    query = "Show me the total revenue by region"
    print(f"\n2. Testing SQL Generation for query: '{query}'")
    try:
        sql = generate_sql(query, model_name="gemini-3-pro-preview")
        print(f"   Generated SQL: {sql}")
    except Exception as e:
        print(f"   ERROR generating SQL: {e}")
        return

    # 3. Test Execution
    print(f"\n3. Executing SQL...")
    try:
        df = execute_sql(sql)
        print("   Execution Result:")
        print(df)
    except Exception as e:
        print(f"   ERROR executing SQL: {e}")

if __name__ == "__main__":
    test_full_flow()
