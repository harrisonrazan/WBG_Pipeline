from sqlalchemy.orm import Session
import pandas as pd
from pathlib import Path
from typing import Dict, Any, Optional
import os

class SQLQueryService:
    def __init__(self, queries_dir: str = "queries"):
        """Initialize the SQL query service with the base queries directory."""
        self.queries_dir = Path(queries_dir)
        
    def load_query(self, query_path: str) -> Optional[str]:
        """Load SQL query from file."""
        try:
            full_path = self.queries_dir / query_path
            if not full_path.exists():
                raise FileNotFoundError(f"Query file not found: {query_path}")
                
            with open(full_path, 'r') as f:
                return f.read()
        except Exception as e:
            raise Exception(f"Error loading query {query_path}: {str(e)}")

    def execute_query(self, db: Session, query_path: str) -> Dict[str, Any]:
        """Execute SQL query and return results as JSON-serializable dictionary."""
        try:
            # Load and execute query
            query = self.load_query(query_path)
            result = db.execute(query)
            
            # Convert to DataFrame for easy manipulation
            df = pd.DataFrame(result.fetchall())
            if not df.empty:
                df.columns = result.keys()
            
            # Convert to dictionary format
            records = df.to_dict('records') if not df.empty else []
            
            # Get column names and types
            columns = [
                {
                    "name": col,
                    "type": str(df[col].dtype)
                }
                for col in df.columns
            ] if not df.empty else []
            
            return {
                "data": records,
                "columns": columns,
                "rowCount": len(records)
            }
            
        except Exception as e:
            raise Exception(f"Error executing query {query_path}: {str(e)}")