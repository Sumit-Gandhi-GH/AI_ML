import os
import sqlite3
import pandas as pd
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from dotenv import load_dotenv

from prompts import SYSTEM_PROMPT, FEW_SHOT_EXAMPLES

load_dotenv()

# Initialize Vector Store for Few-Shot Examples
def setup_vector_store():
    embeddings = OpenAIEmbeddings()
    texts = [ex["question"] for ex in FEW_SHOT_EXAMPLES]
    metadatas = [{"sql": ex["sql"]} for ex in FEW_SHOT_EXAMPLES]
    vectorstore = FAISS.from_texts(texts, embeddings, metadatas=metadatas)
    return vectorstore

# Mock Database Setup
def setup_mock_db():
    conn = sqlite3.connect('mock_sales.db')
    cursor = conn.cursor()
    
    # Create tables
    cursor.execute('''CREATE TABLE IF NOT EXISTS LEADS (lead_id INTEGER PRIMARY KEY, first_name TEXT, last_name TEXT, email TEXT, phone TEXT, source TEXT, status TEXT, created_at DATETIME)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS SALES_REPS (rep_id INTEGER PRIMARY KEY, name TEXT, region TEXT, quota FLOAT, email TEXT)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS DEALS (deal_id INTEGER PRIMARY KEY, lead_id INTEGER, rep_id INTEGER, amount FLOAT, stage TEXT, close_date DATE, created_at DATETIME, FOREIGN KEY(lead_id) REFERENCES LEADS(lead_id), FOREIGN KEY(rep_id) REFERENCES SALES_REPS(rep_id))''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS REVENUE (revenue_id INTEGER PRIMARY KEY, deal_id INTEGER, amount FLOAT, recognition_date DATE, FOREIGN KEY(deal_id) REFERENCES DEALS(deal_id))''')
    
    # Insert dummy data if empty
    cursor.execute("SELECT count(*) FROM SALES_REPS")
    if cursor.fetchone()[0] == 0:
        cursor.execute("INSERT INTO SALES_REPS VALUES (1, 'John Doe', 'North', 100000, 'john@example.com')")
        cursor.execute("INSERT INTO SALES_REPS VALUES (2, 'Jane Smith', 'South', 120000, 'jane@example.com')")
        cursor.execute("INSERT INTO LEADS VALUES (1, 'Alice', 'Brown', 'alice@test.com', '555-0101', 'Web', 'New', '2023-01-01')")
        cursor.execute("INSERT INTO DEALS VALUES (1, 1, 1, 5000, 'Closed Won', '2023-01-15', '2023-01-05')")
        cursor.execute("INSERT INTO REVENUE VALUES (1, 1, 5000, '2023-01-15')")
        conn.commit()
    
    conn.close()

def get_schema_context():
    with open('schema_context.md', 'r') as f:
        return f.read()

def get_few_shot_examples(query, vectorstore):
    docs = vectorstore.similarity_search(query, k=2)
    examples = ""
    for doc in docs:
        examples += f"Q: {doc.page_content}\nSQL: {doc.metadata['sql']}\n\n"
    return examples

def generate_sql(query, model_name="gpt-4o"):
    try:
        vectorstore = setup_vector_store()
        examples = get_few_shot_examples(query, vectorstore)
    except Exception as e:
        print(f"Vector store error (likely missing API key): {e}")
        examples = ""

    schema = get_schema_context()
    
    prompt = ChatPromptTemplate.from_messages([
        ("system", SYSTEM_PROMPT),
        ("human", "{query}")
    ])
    
    # Fallback to a simpler model if needed, or use the requested one
    if "gemini" in model_name.lower():
        llm = ChatGoogleGenerativeAI(model=model_name, temperature=0)
    else:
        llm = ChatOpenAI(model=model_name, temperature=0)
    
    chain = (
        {"schema": lambda x: schema, "examples": lambda x: examples, "query": RunnablePassthrough()}
        | prompt
        | llm
        | StrOutputParser()
    )
    
    return chain.invoke(query)

def execute_sql(sql):
    # For now, executing against the mock SQLite DB
    # In production, this would connect to Snowflake
    conn = sqlite3.connect('mock_sales.db')
    try:
        df = pd.read_sql_query(sql, conn)
        return df
    except Exception as e:
        return pd.DataFrame({"error": [str(e)]})
    finally:
        conn.close()
