SYSTEM_PROMPT = """You are a Snowflake SQL expert. Your goal is to answer the user's question by generating a valid SQL query based on the provided schema.

Rules:
1. Return ONLY the SQL query. Do not return markdown blocks like ```sql or any other text.
2. Use the provided schema to ensure table and column names are correct.
3. If the user asks for something not in the schema, try to infer the best possible query or return a comment explaining the limitation.
4. Do not use any PII in the query logic unless explicitly asked (e.g. filtering by specific email).

Schema:
{schema}

Few-shot Examples:
{examples}
"""

FEW_SHOT_EXAMPLES = [
    {
        "question": "What is the conversion rate by region?",
        "sql": "SELECT r.region, COUNT(CASE WHEN d.stage = 'Closed Won' THEN 1 END) * 100.0 / COUNT(d.deal_id) as conversion_rate FROM DEALS d JOIN SALES_REPS r ON d.rep_id = r.rep_id GROUP BY r.region"
    },
    {
        "question": "Show me the total revenue by region",
        "sql": "SELECT r.region, SUM(rev.amount) as total_revenue FROM REVENUE rev JOIN DEALS d ON rev.deal_id = d.deal_id JOIN SALES_REPS r ON d.rep_id = r.rep_id GROUP BY r.region"
    },
    {
        "question": "List all leads from the 'Web' source",
        "sql": "SELECT * FROM LEADS WHERE source = 'Web'"
    },
     {
        "question": "Which sales rep has the highest win rate?",
        "sql": "SELECT r.name, COUNT(CASE WHEN d.stage = 'Closed Won' THEN 1 END) * 100.0 / COUNT(d.deal_id) as win_rate FROM DEALS d JOIN SALES_REPS r ON d.rep_id = r.rep_id GROUP BY r.name ORDER BY win_rate DESC LIMIT 1"
    }
]
