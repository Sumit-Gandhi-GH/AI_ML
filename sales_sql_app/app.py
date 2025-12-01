import streamlit as st
import pandas as pd
import plotly.express as px
from chain import generate_sql, execute_sql, setup_mock_db
from utils import mask_pii, determine_intent

# Initialize Mock DB
setup_mock_db()

st.set_page_config(page_title="Sales Data Assistant", layout="wide")

st.title("Sales Data Assistant 🤖")

# Sidebar
with st.sidebar:
    st.header("Settings")
    model_choice = st.selectbox("Select Model", [
        "ollama-arctic-lite",
        "gemini-1.5-pro",
        "gemini-3-pro-preview",
        "snowflake-arctic-text2sql"
    ], index=0)
    st.info("Using Mock SQLite Database for demonstration.")
    
    if st.button("Clear Chat History"):
        st.session_state.messages = []

# Initialize chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display chat messages
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])
        if "sql" in message:
            with st.expander("View Generated SQL"):
                st.code(message["sql"], language="sql")
        if "data" in message:
            st.dataframe(message["data"])
        if "chart" in message and message["chart"] is not None:
            st.plotly_chart(message["chart"])

# Chat Input
if prompt := st.chat_input("Ask a question about your sales data..."):
    # Add user message to chat history
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    # Determine Intent
    intent = determine_intent(prompt)
    
    if intent == "GREETING":
        response = "Hello! I'm your Sales Data Assistant. I can help you analyze your sales data.\n\n**Try asking:**\n- *Show me sample data*\n- *Who are the top sales reps?*\n- *What is the total revenue?*"
        st.session_state.messages.append({"role": "assistant", "content": response})
        with st.chat_message("assistant"):
            st.markdown(response)
            
    elif intent == "SAMPLE_DATA":
        with st.chat_message("assistant"):
            st.markdown("Here is a preview of the **Leads** and **Sales Reps** data:")
            
            # Fetch sample data directly
            import sqlite3
            conn = sqlite3.connect('mock_sales.db')
            try:
                df_leads = pd.read_sql_query("SELECT * FROM LEADS LIMIT 3", conn)
                df_reps = pd.read_sql_query("SELECT * FROM SALES_REPS LIMIT 3", conn)
                
                st.subheader("Leads (Preview)")
                st.dataframe(mask_pii(df_leads))
                
                st.subheader("Sales Reps (Preview)")
                st.dataframe(mask_pii(df_reps))
                
                response_text = "I've displayed some sample data above."
                st.session_state.messages.append({
                    "role": "assistant", 
                    "content": response_text,
                    "data": mask_pii(df_leads) # Storing one for history simplicity
                })
            except Exception as e:
                st.error(f"Error fetching sample data: {e}")
            finally:
                conn.close()

    elif intent == "GENERAL":
        # Soft fallback instead of blocking
        response = "I see you're asking a general question. While I specialize in Sales data (Leads, Deals, Revenue), I'll try my best or you can rephrase to ask about your data."
        st.session_state.messages.append({"role": "assistant", "content": response})
        with st.chat_message("assistant"):
            st.markdown(response)
            
    else: # SALES_QUERY
        with st.chat_message("assistant"):
            with st.spinner("Generating SQL..."):
                try:
                    # Generate SQL
                    sql_query = generate_sql(prompt, model_name=model_choice)
                    
                    # Execute SQL
                    df_result = execute_sql(sql_query)
                    
                    # Mask PII
                    df_safe = mask_pii(df_result)
                    
                    response_text = "Here is the data you requested:"
                    st.markdown(response_text)
                    
                    with st.expander("View Generated SQL"):
                        st.code(sql_query, language="sql")
                    
                    st.dataframe(df_safe)
                    
                    # Generate Chart if appropriate
                    chart = None
                    if not df_safe.empty and len(df_safe.columns) >= 2:
                        # Simple heuristic: if we have a categorical and a numerical column, plot bar chart
                        num_cols = df_safe.select_dtypes(include=['number']).columns
                        cat_cols = df_safe.select_dtypes(include=['object']).columns
                        
                        if len(num_cols) > 0 and len(cat_cols) > 0:
                            chart = px.bar(df_safe, x=cat_cols[0], y=num_cols[0], title="Visual Representation")
                            st.plotly_chart(chart)
                    
                    # Save to history
                    st.session_state.messages.append({
                        "role": "assistant", 
                        "content": response_text,
                        "sql": sql_query,
                        "data": df_safe,
                        "chart": chart
                    })
                    
                except Exception as e:
                    error_msg = f"An error occurred: {str(e)}"
                    st.error(error_msg)
                    st.session_state.messages.append({"role": "assistant", "content": error_msg})
