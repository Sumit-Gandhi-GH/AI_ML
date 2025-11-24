import pandas as pd
import numpy as np

# Generate 1000 rows of sample data
data = {
    'product_id': range(1, 1001),
    'product_name': [f'Product {i}' for i in range(1, 1001)],
    'description': [f'This is a description for product {i}. It has some features and benefits.' for i in range(1, 1001)],
    'category': np.random.choice(['Electronics', 'Clothing', 'Home', 'Books'], 1000),
    'price': np.random.uniform(10, 1000, 1000).round(2)
}

df = pd.DataFrame(data)
df.to_csv('large_sample.csv', index=False)
print("Created large_sample.csv with 1000 rows")
