"""
Output formatters for different vector database formats.
"""

import json
from typing import List, Dict, Any


def format_as_json(data: List[Dict[str, Any]]) -> str:
    """
    Format embeddings as a JSON array.
    
    Args:
        data: List of embedding dictionaries
        
    Returns:
        JSON string
    """
    return json.dumps(data, indent=2)


def format_as_jsonl(data: List[Dict[str, Any]]) -> str:
    """
    Format embeddings as JSONL (newline-delimited JSON).
    
    Args:
        data: List of embedding dictionaries
        
    Returns:
        JSONL string
    """
    lines = [json.dumps(item) for item in data]
    return "\n".join(lines)


def format_for_pinecone(data: List[Dict[str, Any]], namespace: str = "") -> str:
    """
    Format embeddings for Pinecone batch upload.
    
    Args:
        data: List of embedding dictionaries
        namespace: Optional namespace for Pinecone
        
    Returns:
        JSON string in Pinecone format
    """
    vectors = []
    for item in data:
        vector = {
            "id": item["id"],
            "values": item["embedding"],
            "metadata": {
                "text": item["text"],
                **item.get("metadata", {})
            }
        }
        vectors.append(vector)
    
    result = {
        "vectors": vectors
    }
    
    if namespace:
        result["namespace"] = namespace
    
    return json.dumps(result, indent=2)


def format_for_weaviate(data: List[Dict[str, Any]], class_name: str = "Document") -> str:
    """
    Format embeddings for Weaviate batch import.
    
    Args:
        data: List of embedding dictionaries
        class_name: Weaviate class name
        
    Returns:
        JSON string in Weaviate format
    """
    objects = []
    for item in data:
        obj = {
            "class": class_name,
            "id": item["id"],
            "properties": {
                "text": item["text"],
                **item.get("metadata", {})
            },
            "vector": item["embedding"]
        }
        objects.append(obj)
    
    return json.dumps({"objects": objects}, indent=2)


def format_for_qdrant(data: List[Dict[str, Any]]) -> str:
    """
    Format embeddings for Qdrant batch upload.
    
    Args:
        data: List of embedding dictionaries
        
    Returns:
        JSON string in Qdrant format
    """
    points = []
    for item in data:
        point = {
            "id": item["id"],
            "vector": item["embedding"],
            "payload": {
                "text": item["text"],
                **item.get("metadata", {})
            }
        }
        points.append(point)
    
    return json.dumps({"points": points}, indent=2)


def get_formatter(format_type: str):
    """
    Get the appropriate formatter function.
    
    Args:
        format_type: One of "json", "jsonl", "pinecone", "weaviate", "qdrant"
        
    Returns:
        Formatter function
    """
    formatters = {
        "json": format_as_json,
        "jsonl": format_as_jsonl,
        "pinecone": format_for_pinecone,
        "weaviate": format_for_weaviate,
        "qdrant": format_for_qdrant
    }
    
    if format_type not in formatters:
        raise ValueError(f"Unsupported format: {format_type}. Choose from {list(formatters.keys())}")
    
    return formatters[format_type]
