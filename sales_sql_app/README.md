# Sales SQL App

Natural language to SQL application for sales data using LLMs and RAG.

## Features

✅ **Local Embeddings** - Uses Ollama (`snowflake-arctic-embed2:568m`)  
✅ **Gemini Models** - Support for Gemini 1.5 Pro and 3 Pro Preview  
✅ **Ollama Integration** - Support for local models like `Arctic-Text2SQL`  
✅ **Snowflake Arctic** - Python-based local inference (alternative to Ollama)  
✅ **Mock SQLite Database** - Pre-populated with sample sales data  
✅ **PII Masking** - Automatically masks sensitive information  
✅ **Interactive UI** - Built with Streamlit  

## Setup

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set Environment Variables** (create `.env` file)
   ```
   GOOGLE_API_KEY=your_google_api_key_here
   ```

3. **Install Ollama (Optional but Recommended)**
   - Download from https://ollama.com/
   - Create/Pull the SQL model: `arctic-sql-lite` (Custom model)
   - Pull the Embedding model: `ollama pull snowflake-arctic-embed2:568m`
   - Ensure it's running: `ollama serve`

4. **Run the App**
   ```bash
   streamlit run app.py
   ```

## Usage

1. Select a model from the sidebar:
   - **ollama-arctic-lite**: Best for local privacy (requires Ollama with `arctic-sql-lite`).
   - **gemini-1.5-pro**: Fast, requires API key.
   - **snowflake-arctic-text2sql**: Python-based local model (heavy).
2. Ask questions about sales data in natural language.
3. View generated SQL, results, and charts.

## Example Questions

- "Show me all sales reps in the North region"
- "What is the total revenue for this year?"
- "List the top 5 deals by amount"
- "How many leads came from the Web source?"

## Troubleshooting

### "Connection refused" (Ollama)
- Make sure Ollama is running (`ollama serve`).
- Verify the model is pulled (`ollama list`).

### "API key expired"
- Your Google API key needs renewal.

### "Quota exceeded"  
- You've hit rate limits on Gemini. Switch to Ollama.

## File Structure

```
sales_sql_app/
├── app.py                 # Streamlit UI
├── chain.py               # SQL generation logic
├── snowflake_client.py    # Snowflake Arctic wrapper
├── utils.py               # Helper functions
├── prompts.py             # LLM prompts
├── schema_context.md      # Database schema
├── requirements.txt       # Dependencies
└── mock_sales.db          # SQLite database (auto-created)
```
