"""
Test Snowflake Arctic Text2SQL model integration
"""
import sys
from chain import generate_sql

print("Testing Snowflake Arctic Text2SQL model...")
print("=" * 60)

try:
    query = "Show me all sales reps in the North region"
    print(f"\nQuery: {query}")
    print("\nCalling Snowflake model (this may take time to load first time)...")
    
    # Note: This will trigger the download of the 7B model if not present
    # It might take a long time and use a lot of RAM
    sql = generate_sql(query, model_name="snowflake-arctic-text2sql")
    
    print(f"\n[SUCCESS] SQL Generated:")
    print(sql)
    print("\n" + "=" * 60)
    print("Snowflake integration is working!")
    
except Exception as e:
    print(f"\n[ERROR] {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
