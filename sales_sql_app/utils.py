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

def determine_domain(user_query: str) -> str:
    """
    Simple router to determine if the query is related to Sales or General.
    """
    sales_keywords = ['lead', 'deal', 'revenue', 'sales', 'rep', 'quota', 'stage', 'close']
    query_lower = user_query.lower()
    
    if any(keyword in query_lower for keyword in sales_keywords):
        return "Sales"
    return "General"
