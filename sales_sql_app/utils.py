import pandas as pd
import re

def mask_pii(df: pd.DataFrame) -> pd.DataFrame:
    """
    Masks columns containing emails or phone numbers in the dataframe.
    """
    df_masked = df.copy()
    
    # Identify potential PII columns based on name or content
    for col in df_masked.columns:
        col_lower = col.lower()
        if 'email' in col_lower:
            df_masked[col] = df_masked[col].apply(lambda x: '***@***.com' if pd.notnull(x) else x)
        elif 'phone' in col_lower:
            df_masked[col] = df_masked[col].apply(lambda x: '***-***-****' if pd.notnull(x) else x)
            
    return df_masked

def format_markdown(text: str) -> str:
    """
    Helper to ensure text is properly formatted as markdown.
    """
    return text

def determine_intent(user_query: str) -> str:
    """
    Classifies the user's intent into: SAMPLE_DATA, GREETING, SALES_QUERY, or GENERAL.
    """
    query_lower = user_query.lower()
    
    # Check for Sample Data requests
    sample_keywords = ['sample', 'example', 'show data', 'preview', 'dummy data', 'mock data']
    if any(keyword in query_lower for keyword in sample_keywords):
        return "SAMPLE_DATA"
        
    # Check for Greetings
    greeting_keywords = ['hi', 'hello', 'hey', 'help', 'start', 'guide']
    # Exact match or starts with greeting
    if query_lower in greeting_keywords or any(query_lower.startswith(w + " ") for w in greeting_keywords):
        return "GREETING"
        
    # Check for Sales/SQL Queries
    sales_keywords = [
        'lead', 'deal', 'revenue', 'sales', 'rep', 'quota', 'stage', 'close', 
        'count', 'sum', 'average', 'how many', 'list', 'show', 'what is', 'top', 'bottom'
    ]
    if any(keyword in query_lower for keyword in sales_keywords):
        return "SALES_QUERY"
        
    return "GENERAL"
