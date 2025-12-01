"""
Test Puter client to see if credentials work
"""
import os
from dotenv import load_dotenv

load_dotenv()

print("Testing Puter client initialization...")

# Check for credentials
username = os.getenv("PUTER_USERNAME")
password = os.getenv("PUTER_PASSWORD")

if not username or not password:
    print("[ISSUE FOUND] PUTER_USERNAME or PUTER_PASSWORD not set in .env file!")
    print("\nThis is why Claude models are falling back to Gemini!")
    print("\nTo fix:")
    print("1. Create a free account at https://puter.com")
    print("2. Add to your .env file:")
    print("   PUTER_USERNAME=your_username")
    print("   PUTER_PASSWORD=your_password")
else:
    print(f"[OK] Puter credentials found:")
    print(f"  Username: {username}")
    print(f"  Password: {'*' * len(password)}")
    
    # Try to initialize
    try:
        from puter_client import get_puter_client
        client = get_puter_client()
        if client.initialize():
            print("[OK] Puter client initialized successfully!")
        else:
            print("[FAIL] Puter client failed to initialize")
    except Exception as e:
        print(f"[FAIL] Error initializing Puter: {e}")
