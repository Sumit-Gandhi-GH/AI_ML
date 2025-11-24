import unittest
import os
import pandas as pd
from query_engine import SchemaManager, SQLExecutor

class TestQueryEngine(unittest.TestCase):
    
    def setUp(self):
        self.manager = SchemaManager(":memory:")
        self.executor = SQLExecutor(self.manager)
        
        # Create dummy CSVs
        self.table_csv = "test_table.csv"
        self.dict_csv = "test_dict.csv"
        
        pd.DataFrame({
            "id": [1, 2, 3],
            "name": ["Alice", "Bob", "Charlie"],
            "age": [25, 30, 35]
        }).to_csv(self.table_csv, index=False)
        
        pd.DataFrame({
            "Table Name": ["users", "users", "users"],
            "Column Name": ["id", "name", "age"],
            "Description": ["User ID", "User Name", "User Age"]
        }).to_csv(self.dict_csv, index=False)
        
    def tearDown(self):
        if os.path.exists(self.table_csv):
            os.remove(self.table_csv)
        if os.path.exists(self.dict_csv):
            os.remove(self.dict_csv)
            
    def test_load_table(self):
        success, msg = self.manager.load_table("users", self.table_csv)
        self.assertTrue(success)
        
        # Check if table exists
        cols, rows, err = self.executor.execute("SELECT * FROM users")
        self.assertIsNone(err)
        self.assertEqual(len(rows), 3)
        self.assertEqual(cols, ["id", "name", "age"])
        
    def test_load_dictionary(self):
        success, msg = self.manager.load_data_dictionary(self.dict_csv)
        self.assertTrue(success)
        self.assertEqual(len(self.manager.data_dictionary), 3)
        
    def test_sql_execution_error(self):
        cols, rows, err = self.executor.execute("SELECT * FROM non_existent_table")
        self.assertIsNotNone(err)

if __name__ == '__main__':
    unittest.main()
