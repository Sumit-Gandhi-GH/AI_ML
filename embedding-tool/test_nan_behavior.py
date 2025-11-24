import pandas as pd
import numpy as np
import json

# Create a dataframe with NaNs in a float column
df = pd.DataFrame({
    'float_col': [1.0, 2.0, np.nan],
    'str_col': ['a', None, np.nan]
})

print("Original DataFrame:")
print(df)
print(df.dtypes)

# Try the current fix
df_fix1 = df.copy()
df_fix1 = df_fix1.where(pd.notnull(df_fix1), None)

print("\nFix 1 (Current): where(notnull, None)")
print(df_fix1)
print(df_fix1.to_dict('records'))

# Check if NaN is still there
records1 = df_fix1.to_dict('records')
print("JSON dump of Fix 1:")
try:
    print(json.dumps(records1))
except Exception as e:
    print(e)
    
# Try casting to object first
df_fix2 = df.copy()
df_fix2 = df_fix2.astype(object).where(pd.notnull(df_fix2), None)

print("\nFix 2 (Proposed): astype(object).where(notnull, None)")
print(df_fix2)
records2 = df_fix2.to_dict('records')
print("JSON dump of Fix 2:")
print(json.dumps(records2))
