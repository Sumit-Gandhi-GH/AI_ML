"""
Test Claude model specifically
"""
from chain import generate_sql
import sys

print("Testing Claude Sonnet 4.5 model...")
print("=" * 60)

try:
    query = "Show me all sales reps in the North region"
    print(f"\nQuery: {query}")
    print("\nCalling Claude via Puter...")
    
    sql = generate_sql(query, model_name="claude-sonnet-4.5")
    
    print(f"\n[SUCCESS] SQL Generated:")
    print(sql)
    print("\n" + "=" * 60)
    print("Claude integration is working!")
    
except Exception as e:
    print(f"\n[ERROR] {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
