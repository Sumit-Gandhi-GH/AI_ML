import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

class SnowflakeClient:
    """
    Client for running Snowflake Arctic Text2SQL models locally.
    """
    def __init__(self, model_name="Snowflake/Arctic-Text2SQL-R1-7B"):
        self.model_name = model_name
        self.tokenizer = None
        self.model = None
        self._initialized = False

    def initialize(self):
        """Lazy load the model to save resources until needed."""
        if self._initialized:
            return True
            
        print(f"Loading {self.model_name}... (this may take a while)")
        try:
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_name,
                device_map="auto",
                torch_dtype=torch.float16
            )
            self._initialized = True
            print(f"✓ {self.model_name} loaded successfully!")
            return True
        except Exception as e:
            print(f"Error loading Snowflake model: {e}")
            return False

    def generate_sql(self, query: str, schema: str) -> str:
        """
        Generate SQL from natural language query using Arctic model.
        """
        if not self._initialized:
            if not self.initialize():
                raise Exception("Failed to initialize Snowflake model")

        # Format prompt specifically for Text-to-SQL
        prompt = f"""<|im_start|>system
You are a helpful assistant that writes SQL queries.
Here is the database schema:
{schema}
<|im_end|>
<|im_start|>user
{query}<|im_end|>
<|im_start|>assistant
"""
        
        inputs = self.tokenizer(prompt, return_tensors="pt").to(self.model.device)
        
        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=256,
                temperature=0.0,  # Deterministic for code generation
                do_sample=False,
                pad_token_id=self.tokenizer.eos_token_id
            )
            
        generated_text = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Extract just the SQL part (after "assistant")
        # The model output includes the prompt, so we need to parse it
        if "assistant" in generated_text:
            sql = generated_text.split("assistant")[-1].strip()
        else:
            sql = generated_text.strip()
            
        # Clean up any markdown code blocks
        sql = sql.replace("```sql", "").replace("```", "").strip()
        
        return sql

# Global instance
_snowflake_client = None

def get_snowflake_client():
    global _snowflake_client
    if _snowflake_client is None:
        _snowflake_client = SnowflakeClient()
    return _snowflake_client
