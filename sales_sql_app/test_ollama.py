"""
Test Ollama integration with Arctic Text2SQL model
"""
import sys
from chain import generate_sql

print("Testing Ollama Arctic Text2SQL model...")
print("=" * 60)

try:
    query = "Show me all sales reps in the North region"
    print(f"\nQuery: {query}")
    print("\nCalling Ollama (ensure 'ollama serve' is running)...")
    
    sql = generate_sql(query, model_name="ollama-arctic-lite")
    
    print(f"\n[SUCCESS] SQL Generated:")
    print(sql)
    print("\n" + "=" * 60)
    print("Ollama integration is working!")
    
except Exception as e:
    print(f"\n[ERROR] {e}")
    print("\nMake sure Ollama is running and you have the model:")
    print("arctic-sql-lite")
    sys.exit(1)
