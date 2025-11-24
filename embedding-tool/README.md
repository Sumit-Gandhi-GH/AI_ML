# Embedding Generator Tool

Transform your CSV data into vector embeddings for any vector database using OpenAI, Google Gemini, or local Sentence Transformers models.

## Features

- **Multiple Embedding Providers**:
  - 🆓 Sentence Transformers (Free, runs locally, no API key needed)
  - 🤖 OpenAI (text-embedding-3-small/large)
  - 🔮 Google Gemini (text-embedding-004)

- **Flexible CSV Processing**:
  - Select which columns to embed
  - Combine multiple columns into single embeddings
  - Include additional columns as metadata

- **Multiple Output Formats**:
  - Generic JSON
  - JSONL (newline-delimited)
  - Pinecone format
  - Weaviate format
  - Qdrant format

- **Premium Web Interface**:
  - Modern, responsive design
  - Drag-and-drop file upload
  - Real-time progress tracking
  - Results preview

## Installation

1. **Clone or download this repository**

2. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Start the server**:
   ```bash
   python server.py
   ```

4. **Open your browser**:
   Navigate to `http://localhost:5000`

## Usage

### Step 1: Upload CSV
- Click or drag your CSV file into the upload area
- The tool will automatically detect columns

### Step 2: Configure Embeddings
1. **Select Embedding Provider**:
   - Choose between Sentence Transformers (free), OpenAI, or Google
   - Enter API key if using OpenAI or Google
   - Optionally specify a custom model

2. **Select Columns**:
   - Choose which columns to embed (can select multiple)
   - Optionally select metadata columns to include in output
   - Choose whether to combine multiple columns

3. **Generate Embeddings**:
   - Click "Generate Embeddings"
   - Wait for processing to complete

### Step 3: Download Results
- Select your preferred output format
- Click "Download Embeddings"
- Use the file with your vector database

## Embedding Models

### Sentence Transformers (Local, Free)
- **Default**: `all-MiniLM-L6-v2` (384 dimensions)
- **Other options**: `all-mpnet-base-v2`, `paraphrase-multilingual-MiniLM-L12-v2`
- **Pros**: Free, fast, runs locally, no API limits
- **Cons**: Lower quality than commercial models

### OpenAI
- **Default**: `text-embedding-3-small` (1536 dimensions)
- **Alternative**: `text-embedding-3-large` (3072 dimensions)
- **Pros**: High quality, well-tested
- **Cons**: Requires API key, costs money per token

### Google Gemini
- **Default**: `models/text-embedding-004` (768 dimensions)
- **Pros**: Good quality, competitive pricing
- **Cons**: Requires API key, costs money

## Output Formats

### JSON
Standard JSON array format:
```json
[
  {
    "id": "0",
    "text": "Your text here",
    "embedding": [0.1, 0.2, ...],
    "metadata": {"column": "value"}
  }
]
```

### JSONL
One JSON object per line (useful for streaming):
```jsonl
{"id": "0", "text": "...", "embedding": [...], "metadata": {...}}
{"id": "1", "text": "...", "embedding": [...], "metadata": {...}}
```

### Pinecone Format
Ready for Pinecone batch upload:
```json
{
  "vectors": [
    {
      "id": "0",
      "values": [0.1, 0.2, ...],
      "metadata": {"text": "...", ...}
    }
  ]
}
```

### Weaviate Format
Ready for Weaviate batch import:
```json
{
  "objects": [
    {
      "class": "Document",
      "id": "0",
      "properties": {"text": "...", ...},
      "vector": [0.1, 0.2, ...]
    }
  ]
}
```

### Qdrant Format
Ready for Qdrant batch upload:
```json
{
  "points": [
    {
      "id": "0",
      "vector": [0.1, 0.2, ...],
      "payload": {"text": "...", ...}
    }
  ]
}
```

## API Keys

### OpenAI
Get your API key from: https://platform.openai.com/api-keys

### Google Gemini
Get your API key from: https://makersuite.google.com/app/apikey

## Requirements

- Python 3.8+
- See `requirements.txt` for Python packages

## License

MIT License - feel free to use this tool for any purpose!

## Support

For issues or questions, please open an issue on GitHub.
