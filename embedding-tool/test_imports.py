import sys
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

print("Testing imports...")

try:
    print("Importing numpy...")
    import numpy
    print(f"numpy version: {numpy.__version__}")
except Exception as e:
    print(f"numpy failed: {e}")

try:
    print("Importing torch...")
    import torch
    print(f"torch version: {torch.__version__}")
except Exception as e:
    print(f"torch failed: {e}")

try:
    print("Importing sentence_transformers...")
    from sentence_transformers import SentenceTransformer
    print("sentence_transformers imported successfully")
except Exception as e:
    print(f"sentence_transformers failed: {e}")

try:
    print("Importing google.generativeai...")
    import google.generativeai as genai
    print("google.generativeai imported successfully")
except Exception as e:
    print(f"google.generativeai failed: {e}")

print("Import test complete.")
