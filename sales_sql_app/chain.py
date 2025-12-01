import os
import sqlite3
import pandas as pd
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from puter_client import get_puter_client
from snowflake_client import get_snowflake_client
from langchain_ollama import ChatOllama, OllamaEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from dotenv import load_dotenv
import langchain

# Patch for missing verbose attribute in newer langchain versions
if not hasattr(langchain, 'verbose'):
    langchain.verbose = False
if not hasattr(langchain, 'debug'):
    langchain.debug = False
if not hasattr(langchain, 'llm_cache'):
    langchain.llm_cache = None

from prompts import SYSTEM_PROMPT, FEW_SHOT_EXAMPLES

load_dotenv()

# Initialize Vector Store for Few-Shot Examples
def setup_vector_store():
    """
    Setup vector store with Ollama embeddings (snowflake-arctic-embed2:568m).
    """
    # Use Ollama for embeddings
    embeddings = OllamaEmbeddings(
        model="snowflake-arctic-embed2:568m",
        base_url="http://localhost:11434"
    )
    
    # Index directory
    index_path = "faiss_index_ollama"
    
    # Try to load existing index
    if os.path.exists(index_path) and os.path.isdir(index_path):
        try:
            if os.path.exists(os.path.join(index_path, "index.faiss")):
                return FAISS.load_local(index_path, embeddings, allow_dangerous_deserialization=True)
        except Exception as e:
            print(f"Error loading FAISS index: {e}")

    # Create new index
    try:
        print("Creating new vector store with Ollama embeddings...")
        texts = [ex["question"] for ex in FEW_SHOT_EXAMPLES]
        metadatas = [{"sql": ex["sql"]} for ex in FEW_SHOT_EXAMPLES]
        vectorstore = FAISS.from_texts(texts, embeddings, metadatas=metadatas)
        vectorstore.save_local(index_path)
        print("Vector store created and saved.")
        return vectorstore
    except Exception as e:
        print(f"Error creating vector store: {e}")
        return None

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
    schema_path = os.path.join(os.path.dirname(__file__), 'schema_context.md')
    with open(schema_path, 'r') as f:
        return f.read()

def get_few_shot_examples(query, vectorstore):
    docs = vectorstore.similarity_search(query, k=2)
    examples = ""
    for doc in docs:
        examples += f"Q: {doc.page_content}\nSQL: {doc.metadata['sql']}\n\n"
    return examples

def generate_sql(query, model_name="gemini-3-pro-preview"):
    try:
        vectorstore = setup_vector_store()
        if vectorstore:
            examples = get_few_shot_examples(query, vectorstore)
        else:
            examples = "No examples available due to embedding API limits."
    except Exception as e:
        print(f"Vector store error: {e}")
        examples = "No examples available."

    schema = get_schema_context()
    
    prompt = ChatPromptTemplate.from_messages([
        ("system", SYSTEM_PROMPT),
        ("human", "{query}")
    ])
    
    # Route to appropriate LLM based on model name
    if "ollama" in model_name.lower():
        llm = ChatOllama(
            model="arctic-sql-lite",
            temperature=0,
            base_url="http://localhost:11434"
        )
    
    elif "snowflake" in model_name.lower():
        try:
            client = get_snowflake_client()
            return client.generate_sql(query, schema)
        except Exception as e:
            print(f"Error calling Snowflake model: {e}")
            # Fallback to Gemini
            model_name = "gemini-1.5-pro"
            llm = ChatGoogleGenerativeAI(model=model_name, temperature=0)

    elif "claude" in model_name.lower():
        # Use Puter client for Claude models
        puter = get_puter_client()
        
        # Format prompt for Puter
        messages = [
            {"role": "system", "content": SYSTEM_PROMPT.format(schema=schema, examples=examples)},
            {"role": "user", "content": query}
        ]
        
        # Call Puter with Claude model - NO FALLBACK so we see real errors
        response = puter.chat(model_name, messages, temperature=0)
        return response
    
    elif "gemini" in model_name.lower():
        llm = ChatGoogleGenerativeAI(model=model_name, temperature=0)
        
    else:
        # Default to Gemini if unknown
        llm = ChatGoogleGenerativeAI(model="gemini-3-pro-preview", temperature=0)
    
    chain = (
        {"schema": lambda x: schema, "examples": lambda x: examples, "query": RunnablePassthrough()}
        | prompt
        | llm
        | StrOutputParser()
        | clean_sql_output
    )
    
    return chain.invoke(query)

def clean_sql_output(text):
    """Extract SQL from markdown code blocks or raw text."""
    import re
    # Look for ```sql ... ``` or ``` ... ```
    match = re.search(r"```(?:sql)?\s*(.*?)```", text, re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1).strip()
    # If no code block, return original text (cleaned of whitespace)
    return text.strip()

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
