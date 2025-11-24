"""
Embedding generation module supporting multiple providers:
- Sentence Transformers (local, free)
- OpenAI API
- Google Gemini API
"""

import numpy as np
from typing import List, Dict, Any, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Global cache for models to prevent reloading
_MODEL_CACHE = {}

class EmbeddingGenerator:
    """Unified interface for generating embeddings from multiple providers."""
    
    def __init__(self, provider: str = "sentence-transformers", api_key: Optional[str] = None, model: Optional[str] = None):
        """
        Initialize the embedding generator.
        
        Args:
            provider: One of "sentence-transformers", "openai", or "google"
            api_key: API key for OpenAI or Google (not needed for sentence-transformers)
            model: Specific model to use (optional, uses defaults if not provided)
        """
        self.provider = provider.lower()
        self.api_key = api_key
        self.model = model
        self.embedding_model = None
        self.dimension = 0
        
        self._initialize_model()
    
    def _initialize_model(self):
        """Initialize the embedding model based on the provider."""
        cache_key = f"{self.provider}_{self.model}"
        
        # Check cache first
        if cache_key in _MODEL_CACHE:
            logger.info(f"Using cached model for {cache_key}")
            self.embedding_model, self.dimension = _MODEL_CACHE[cache_key]
            return

        if self.provider == "sentence-transformers":
            logger.info("Importing sentence_transformers...")
            try:
                from sentence_transformers import SentenceTransformer
                logger.info("sentence_transformers imported.")
                model_name = self.model or "all-MiniLM-L6-v2"
                logger.info(f"Loading Sentence Transformer model: {model_name}")
                self.embedding_model = SentenceTransformer(model_name)
                self.dimension = self.embedding_model.get_sentence_embedding_dimension()
                logger.info(f"Model loaded. Embedding dimension: {self.dimension}")
            except Exception as e:
                logger.error(f"Failed to load sentence-transformers: {e}")
                raise e
            
        elif self.provider == "openai":
            if not self.api_key:
                raise ValueError("API key is required for OpenAI embeddings")
            import openai
            openai.api_key = self.api_key
            self.embedding_model = openai
            self.model = self.model or "text-embedding-3-small"
            # Set dimension based on model
            if "large" in self.model:
                self.dimension = 3072
            else:
                self.dimension = 1536
            logger.info(f"Initialized OpenAI with model: {self.model}, dimension: {self.dimension}")
            
        elif self.provider == "google":
            if not self.api_key:
                raise ValueError("API key is required for Google embeddings")
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            self.embedding_model = genai
            self.model = self.model or "models/embedding-001"
            self.dimension = 768
            logger.info(f"Initialized Google Gemini with model: {self.model}, dimension: {self.dimension}")
            
        else:
            raise ValueError(f"Unsupported provider: {self.provider}. Choose from 'sentence-transformers', 'openai', or 'google'")
            
        # Cache the loaded model
        _MODEL_CACHE[cache_key] = (self.embedding_model, self.dimension)
    
    def generate_embeddings(self, texts: List[str], batch_size: int = 32) -> List[List[float]]:
        """
        Generate embeddings for a list of texts.
        
        Args:
            texts: List of text strings to embed
            batch_size: Batch size for processing (used for sentence-transformers)
            
        Returns:
            List of embedding vectors
        """
        if not texts:
            return []
        
        logger.info(f"Generating embeddings for {len(texts)} texts using {self.provider}")
        
        if self.provider == "sentence-transformers":
            embeddings = self.embedding_model.encode(
                texts,
                batch_size=batch_size,
                show_progress_bar=True,
                convert_to_numpy=True
            )
            return embeddings.tolist()
            
        elif self.provider == "openai":
            embeddings = []
            # OpenAI has a limit, process in batches
            for i in range(0, len(texts), batch_size):
                batch = texts[i:i + batch_size]
                logger.info(f"Processing batch {i//batch_size + 1}/{(len(texts)-1)//batch_size + 1}")
                response = self.embedding_model.embeddings.create(
                    input=batch,
                    model=self.model
                )
                batch_embeddings = [item.embedding for item in response.data]
                embeddings.extend(batch_embeddings)
            return embeddings
            
        elif self.provider == "google":
            embeddings = []
            # Google API processes one at a time
            for i, text in enumerate(texts):
                if i % 10 == 0:
                    logger.info(f"Processing {i+1}/{len(texts)}")
                
                # Ensure model is a string
                model_name = str(self.model)
                
                # Helper to try embedding with a specific model name
                def try_embed(m_name, content):
                    return self.embedding_model.embed_content(
                        model=m_name,
                        content=content,
                        task_type="retrieval_document"
                    )

                try:
                    result = try_embed(model_name, text)
                    embeddings.append(result['embedding'])
                except Exception as e:
                    logger.warning(f"Error embedding with {model_name}: {e}. Retrying with fallbacks...")
                    
                    # List of fallback models/formats to try
                    # Some versions want 'models/', some don't. Some models are deprecated.
                    fallbacks = [
                        "models/embedding-001", 
                        "embedding-001",
                        "models/text-embedding-004",
                        "text-embedding-004"
                    ]
                    
                    success = False
                    for fb_model in fallbacks:
                        if fb_model == model_name: continue
                        try:
                            logger.info(f"Retrying with {fb_model}...")
                            result = try_embed(fb_model, text)
                            embeddings.append(result['embedding'])
                            success = True
                            # Update self.model to the working one for future calls
                            self.model = fb_model
                            logger.info(f"Switched default model to {fb_model}")
                            break
                        except Exception as fb_e:
                            logger.warning(f"Fallback {fb_model} failed: {fb_e}")
                    
                    if not success:
                        logger.error(f"All Gemini embedding attempts failed for text. Last error: {e}")
                        raise e
            return embeddings
    
    def get_dimension(self) -> int:
        """Return the dimension of the embeddings."""
        return self.dimension


def process_csv_chunk(
    texts: List[str],
    metadatas: List[Dict[str, Any]],
    start_index: int,
    provider: str,
    api_key: Optional[str] = None,
    model: Optional[str] = None
) -> List[Dict[str, Any]]:
    """
    Process a chunk of texts and generate embeddings.
    """
    # Initialize generator (cached if possible, but recreating is safer for threads)
    logger.info(f"Initializing EmbeddingGenerator for chunk starting at {start_index}")
    generator = EmbeddingGenerator(provider=provider, api_key=api_key, model=model)
    
    # Generate embeddings
    try:
        logger.info(f"Generating embeddings for {len(texts)} texts")
        embeddings = generator.generate_embeddings(texts)
        logger.info(f"Embeddings generated successfully")
    except Exception as e:
        logger.error(f"Error generating embeddings for chunk starting at {start_index}: {e}")
        raise e
    
    # Prepare output
    results = []
    for i, (text, embedding, metadata) in enumerate(zip(texts, embeddings, metadatas)):
        results.append({
            "id": start_index + i,
            "text": text,
            "embedding": embedding,
            "metadata": metadata
        })
        
    return results
