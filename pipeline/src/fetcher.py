# pipeline/src/fetcher.py
import requests
import logging
import time
from typing import Dict, Any
from config import API_CONFIG
from typing import Dict, Any, Optional
from dataclasses import dataclass
import os

@dataclass
class WorldBankAPIConfig:
    """Configuration for World Bank API endpoints"""
    base_url: str
    dataset_id: str
    resource_id: str
    records_per_page: int
    
    def get_url(self, page: int) -> str:
        """Constructs the URL for a specific page"""
        skip = (page - 1) * self.records_per_page
        return (f"{self.base_url}?datasetId={self.dataset_id}"
                f"&resourceId={self.resource_id}&top={self.records_per_page}"
                f"&type=json&skip={skip}")

def create_api_config(endpoint_name: str) -> WorldBankAPIConfig:
    """Creates an API configuration from the config settings"""
    endpoint_config = API_CONFIG['endpoints'][endpoint_name]
    return WorldBankAPIConfig(
        base_url=API_CONFIG['base_url'],
        dataset_id=endpoint_config['dataset_id'],
        resource_id=endpoint_config['resource_id'],
        records_per_page=API_CONFIG['records_per_page']
    )

def fetch_paginated_data(endpoint_name: str) -> Dict[str, Any]:
    """
    Fetches all data from a World Bank API endpoint with pagination support.
    
    Args:
        endpoint_name: Name of the endpoint configuration to use
        
    Returns:
        Dictionary containing total count and all fetched data
    """
    config = create_api_config(endpoint_name)
    all_data = []
    total_count = 0
    page = 1
    
    while True:
        url = config.get_url(page)
        retry_count = 0
        
        while retry_count < API_CONFIG['max_retries']:
            try:
                logging.info(f"Fetching page {page} from {endpoint_name}")
                response = requests.get(url, timeout=API_CONFIG['timeout'])
                response.raise_for_status()
                
                data = response.json()
                
                if 'data' not in data or not data['data']:
                    return {'count': total_count, 'data': all_data}
                
                if page == 1 and 'count' in data:
                    total_count = data['count']
                    logging.info(f"Total records to fetch: {total_count}")
                
                all_data.extend(data['data'])
                page += 1
                break
                
            except requests.RequestException as e:
                retry_count += 1
                if retry_count == API_CONFIG['max_retries']:
                    logging.error(f"Failed to fetch data after {API_CONFIG['max_retries']} attempts: {str(e)}")
                    return {'count': total_count, 'data': all_data}
                
                logging.warning(f"Retry {retry_count}/{API_CONFIG['max_retries']} after error: {str(e)}")
                time.sleep(API_CONFIG['retry_delay'])
        
        time.sleep(1)  # Rate limiting

def fetch_credit_statements() -> Dict[str, Any]:
    """Fetches all credit statement data"""
    return fetch_paginated_data('credit_statements')

def fetch_contract_awards() -> Dict[str, Any]:
    """Fetches all contract awards data"""
    return fetch_paginated_data('contract_awards')

def fetch_projects_excel(url: str, tmp_path: str = "/tmp") -> Optional[str]:
    """
    Downloads the World Bank projects Excel file and saves it temporarily.
    
    This function downloads a comprehensive Excel file containing multiple sheets
    of project data, which is more efficient than making multiple API calls.
    Each sheet contains different aspects of project information.
    
    Args:
        url: URL of the Excel file
        tmp_path: Directory to store the temporary file
        
    Returns:
        Path to the downloaded file or None if download failed
    """
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        # Create temporary file path
        file_path = os.path.join(tmp_path, "world_bank_projects.xlsx")
        
        # Ensure tmp directory exists
        os.makedirs(tmp_path, exist_ok=True)
        
        # Write the file in chunks to handle large files efficiently
        with open(file_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        
        logging.info(f"Successfully downloaded projects file to {file_path}")
        return file_path
        
    except Exception as e:
        logging.error(f"Error downloading projects file: {str(e)}")
        return None