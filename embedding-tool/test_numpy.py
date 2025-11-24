import os

# Set environment variables to restrict threading
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['NUMEXPR_NUM_THREADS'] = '1'

print("Starting numpy import test...")
import numpy
print(f"Numpy imported successfully. Version: {numpy.__version__}")
