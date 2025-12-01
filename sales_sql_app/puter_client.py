import os
from dotenv import load_dotenv
import asyncio

load_dotenv()

class PuterClient:
    def __init__(self):
        self.client = None
        self._initialized = False
        
    def initialize(self):
        if self._initialized:
            return True
            
        try:
            from putergenai import PuterClient as PuterSDK
            
            username = os.getenv("PUTER_USERNAME")
            password = os.getenv("PUTER_PASSWORD")
            
            if not username or not password:
                print("WARNING: PUTER_USERNAME and PUTER_PASSWORD not found")
                return False
                
            self.client = PuterSDK()
            
            try:
                loop = asyncio.get_event_loop()
            except RuntimeError:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
            
            loop.run_until_complete(self.client.login(username, password))
            self._initialized = True
            print(f"Puter initialized for: {username}")
            return True
        except Exception as e:
            print(f"Puter init error: {e}")
            return False
    
    def chat(self, model, messages, temperature=0):
        if not self._initialized:
            if not self.initialize():
                raise Exception("Puter not initialized")
        
        try:
            options = {"model": model, "temperature": temperature}
            
            try:
                loop = asyncio.get_event_loop()
            except RuntimeError:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
            
            result = loop.run_until_complete(
                self.client.ai_chat(messages=messages, options=options)
            )
            
            return result
                
        except Exception as e:
            raise Exception(f"Puter AI error: {e}")

_puter_client = None

def get_puter_client():
    global _puter_client
    if _puter_client is None:
        _puter_client = PuterClient()
    return _puter_client
