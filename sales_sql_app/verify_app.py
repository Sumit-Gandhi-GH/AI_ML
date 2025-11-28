import pandas as pd
from utils import mask_pii, determine_domain
from chain import setup_mock_db, execute_sql

def test_mask_pii():
    print("Testing PII Masking...")
    df = pd.DataFrame({
        'name': ['Alice', 'Bob'],
        'email': ['alice@test.com', 'bob@test.com'],
        'phone': ['123-456-7890', '987-654-3210'],
        'amount': [100, 200]
    })
    masked_df = mask_pii(df)
    
    assert masked_df['email'].iloc[0] == '***@***.com'
    assert masked_df['phone'].iloc[0] == '***-***-****'
    assert masked_df['amount'].iloc[0] == 100
    print("PII Masking Passed!")

def test_determine_domain():
    print("Testing Domain Determination...")
    assert determine_domain("Show me the revenue") == "Sales"
    assert determine_domain("What is the weather?") == "General"
    print("Domain Determination Passed!")

def test_sql_execution():
    print("Testing SQL Execution...")
    setup_mock_db()
    sql = "SELECT * FROM SALES_REPS"
    df = execute_sql(sql)
    assert not df.empty
    assert 'name' in df.columns
    print("SQL Execution Passed!")

if __name__ == "__main__":
    test_mask_pii()
    test_determine_domain()
    test_sql_execution()
