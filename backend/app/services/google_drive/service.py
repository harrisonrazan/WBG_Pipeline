from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
import os
import yaml
import pandas as pd
from typing import Dict, Optional
from pathlib import Path
from functools import lru_cache

class GoogleDriveService:
    def __init__(self, credentials_path: str, base_folder_id: str):
        """
        Initialize Google Drive service.
        
        Args:
            credentials_path: Path to the service account credentials JSON file
            base_folder_id: Base folder ID where all files will be stored
        """
        self.credentials = service_account.Credentials.from_service_account_file(
            credentials_path,
            scopes=['https://www.googleapis.com/auth/drive.file']
        )
        self.service = build('drive', 'v3', credentials=self.credentials)
        self.base_folder_id = base_folder_id
        self.mappings = self._load_mappings()

    def _load_mappings(self) -> Dict:
        """Load the query to Google Drive mappings from config file."""
        config_path = Path(__file__).parent / 'config' / 'drive_mappings.yaml'
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)

    @lru_cache(maxsize=100)
    def _get_or_create_folder(self, folder_name: str, parent_id: str) -> str:
        """
        Get folder ID by name and parent, create if doesn't exist.
        Uses caching to avoid repeated API calls.
        """
        query = f"mimeType='application/vnd.google-apps.folder' and name='{folder_name}' and '{parent_id}' in parents and trashed=false"
        results = self.service.files().list(q=query, fields="files(id)").execute()
        files = results.get('files', [])
        
        if files:
            return files[0]['id']
            
        # Create folder if it doesn't exist
        folder_metadata = {
            'name': folder_name,
            'mimeType': 'application/vnd.google-apps.folder',
            'parents': [parent_id]
        }
        folder = self.service.files().create(
            body=folder_metadata,
            fields='id'
        ).execute()
        return folder['id']

    @lru_cache(maxsize=100)
    def _get_folder_id_from_path(self, path: str) -> str:
        """
        Get or create nested folders from path.
        Example: "Madagascar/Reports" will ensure both folders exist.
        """
        current_parent = self.base_folder_id
        
        # Split path and create/get each folder level
        for folder_name in path.split('/'):
            if folder_name:  # Skip empty strings
                query = f"name = '{folder_name}' and '{current_parent}' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
                results = self.service.files().list(q=query, fields="files(id)").execute()
                files = results.get('files', [])
                
                if files:
                    current_parent = files[0]['id']
                else:
                    # Create folder if it doesn't exist
                    folder_metadata = {
                        'name': folder_name,
                        'mimeType': 'application/vnd.google-apps.folder',
                        'parents': [current_parent]
                    }
                    folder = self.service.files().create(
                        body=folder_metadata,
                        fields='id'
                    ).execute()
                    current_parent = folder['id']
        
        return current_parent

    def upload_dataframe(self, df: pd.DataFrame, query_path: str) -> Optional[str]:
        """
        Upload a DataFrame to Google Drive based on query mapping.
        
        Args:
            df: Pandas DataFrame to upload
            query_path: Path to the query file relative to queries directory
                
        Returns:
            ID of the uploaded file or None if no mapping exists
        """
        # Use self.mappings.get() directly instead of get_mapping
        mapping = self.mappings.get(query_path)
        if not mapping:
            print(f"No mapping found for query: {query_path}")
            print(f"Available mappings: {list(self.mappings.keys())}")
            return None

        drive_path = mapping.get('drive_path')
        filename = mapping.get('filename')
        
        if not drive_path or not filename:
            print(f"Invalid mapping for query {query_path}. Need both drive_path and filename.")
            return None

        # Get the target folder ID from the path
        folder_id = self._get_folder_id_from_path(drive_path)
        
        # Save DataFrame to temporary file
        temp_path = f"/tmp/{filename}"
        df.to_excel(temp_path, index=False)
        
        try:
            # Prepare media
            media = MediaFileUpload(
                temp_path,
                mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                resumable=True
            )
            
            # Check if file already exists in this folder
            query = f"name='{filename}' and '{folder_id}' in parents and trashed=false"
            results = self.service.files().list(q=query, fields="files(id)").execute()
            existing_files = results.get('files', [])

            if existing_files:
                # Update existing file without changing parents
                file = self.service.files().update(
                    fileId=existing_files[0]['id'],
                    media_body=media
                ).execute()
            else:
                # Create new file
                file_metadata = {
                    'name': filename,
                    'parents': [folder_id]
                }
                file = self.service.files().create(
                    body=file_metadata,
                    media_body=media,
                    fields='id'
                ).execute()
                
            return file.get('id')
            
        finally:
            # Clean up temporary file
            if os.path.exists(temp_path):
                os.remove(temp_path)