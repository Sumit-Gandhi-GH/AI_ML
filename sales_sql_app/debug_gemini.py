import os
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings

load_dotenv()

def test_gemini_connection():
    print("Testing Gemini Connection...")
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("ERROR: GOOGLE_API_KEY not found in environment variables.")
        return

    print(f"API Key found: {api_key[:5]}...")

    try:
        print("Testing Embeddings...")
        embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
        vec = embeddings.embed_query("Hello world")
        print(f"Embeddings successful. Vector length: {len(vec)}")
    except Exception as e:
        print(f"ERROR in Embeddings: {e}")

    try:
        print("Testing Chat Model (gemini-3-pro-preview)...")
        llm = ChatGoogleGenerativeAI(model="gemini-3-pro-preview", temperature=0)
        response = llm.invoke("Say hello")
        print(f"Chat Model response: {response.content}")
    except Exception as e:
        print(f"ERROR in Chat Model (gemini-3-pro-preview): {e}")
        
    # try:
    #     print("Testing Chat Model (gemini-1.5-pro)...")
    #     llm = ChatGoogleGenerativeAI(model="gemini-1.5-pro", temperature=0)
    #     response = llm.invoke("Say hello")
    #     print(f"Chat Model response: {response.content}")
    # except Exception as e:
    #     print(f"ERROR in Chat Model (gemini-1.5-pro): {e}")

    try:
        print("Listing available models...")
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                print(m.name)
    except Exception as e:
        print(f"ERROR listing models: {e}")

if __name__ == "__main__":
    test_gemini_connection()
