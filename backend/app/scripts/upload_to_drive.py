import sys
import os
from pathlib import Path
import pandas as pd
from sqlalchemy import text
from app.services import GoogleDriveService
from app.database import engine

def execute_query_and_upload(query_path: str):
    """
    Execute a query and upload its results to Google Drive
    """
    full_query_path = Path('/queries') / query_path
    
    if not full_query_path.exists():
        print(f"Error: Query file not found: {query_path}")
        return
    
    try:
        # Read and execute query
        with open(full_query_path, 'r') as f:
            query = f.read()
        
        print(f"Executing query from {query_path}...")
        with engine.connect() as conn:
            result = conn.execute(text(query))
            df = pd.DataFrame(result.fetchall(), columns=result.keys())
        
        print(f"Query returned {len(df)} rows")
        
        # Upload to Google Drive
        print("Uploading to Google Drive...")
        file_id = drive_service.upload_dataframe(df, query_path)
        
        if file_id:
            print(f"Successfully uploaded to Google Drive. File ID: {file_id}")
        else:
            print(f"Error: No Google Drive mapping found for query: {query_path}")
            
    except Exception as e:
        print(f"Error: {str(e)}")

def list_available_queries():
    """List all available queries"""
    print("\nAvailable queries:")
    for query_file in Path('/queries').rglob('*.sql'):
        relative_path = query_file.relative_to('/queries')
        print(f"  {relative_path}")

if __name__ == '__main__':
    # Initialize Google Drive service
    drive_service = GoogleDriveService(
        credentials_path=os.getenv('GOOGLE_DRIVE_CREDENTIALS_PATH'),
        base_folder_id=os.getenv('GOOGLE_DRIVE_BASE_FOLDER_ID')
    )
    
    if len(sys.argv) < 2:
        print("Usage: python upload_to_drive.py <query_path>")
        print("Example: python upload_to_drive.py Madagascar/CASEF.sql")
        list_available_queries()
    else:
        query_path = sys.argv[1]
        execute_query_and_upload(query_path)