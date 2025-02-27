# pipeline/src/fetcher.py
import requests
import logging
import time
import os
from typing import Dict, Any
from config import API_CONFIG
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor, as_completed

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
    logging.info(f"Creating WorldBankAPIConfig with base_url={API_CONFIG['base_url']}, dataset_id={endpoint_config['dataset_id']}, resource_id={endpoint_config['resource_id']}, records_per_page={API_CONFIG['records_per_page']}")
    return WorldBankAPIConfig(
        base_url=str(API_CONFIG['base_url']),
        dataset_id=str(endpoint_config['dataset_id']),
        resource_id=str(endpoint_config['resource_id']),
        records_per_page=int(API_CONFIG['records_per_page'])
    )

def fetch_page_data(config: WorldBankAPIConfig, page: int) -> List[Dict[str, Any]]:
    """Fetches data for a specific page."""
    url = config.get_url(page)
    retry_count = 0

    while retry_count < API_CONFIG['max_retries']:
        try:
            logging.info(f"Fetching page {page}")
            response = requests.get(url, timeout=API_CONFIG['timeout'])
            response.raise_for_status()
            data = response.json()

            if 'data' not in data or not data['data']:
                return []

            return data['data']

        except requests.RequestException as e:
            retry_count += 1
            logging.warning(f"Retry {retry_count}/{API_CONFIG['max_retries']} for page {page} after error: {str(e)}")
            time.sleep(API_CONFIG['retry_delay'])

    logging.error(f"Failed to fetch page {page} after {API_CONFIG['max_retries']} retries.")
    return []

def fetch_paginated_data(endpoint_name: str) -> Dict[str, Any]:
    """
    Fetches all data from a World Bank API endpoint with pagination support.
    This version spreads the work across multiple cores.
    """
    config = create_api_config(endpoint_name)
    all_data = []
    total_count = 0

    # Fetch first page to determine total count
    first_page_data = fetch_page_data(config, 1)
    if not first_page_data:
        return {'count': total_count, 'data': all_data}

    # Get the total count from the first page response
    first_page_url = config.get_url(1)
    response = requests.get(first_page_url, timeout=API_CONFIG['timeout'])
    response.raise_for_status()
    data = response.json()
    total_count = data.get('count', len(first_page_data))

    all_data.extend(first_page_data)

    # Calculate the total number of pages
    total_pages = (total_count + config.records_per_page - 1) // config.records_per_page

    # Log the number of workers being used
    num_workers = API_CONFIG['num_workers']
    logging.info(f"Using {num_workers} worker threads for parallel fetching.")

    # Use ThreadPoolExecutor to parallelize fetching of remaining pages
    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        futures = {executor.submit(fetch_page_data, config, page): page for page in range(2, total_pages + 1)}

        for future in as_completed(futures):
            page = futures[future]
            try:
                page_data = future.result()
                all_data.extend(page_data)
                logging.info(f"Successfully fetched page {page}")
            except Exception as e:
                logging.error(f"Failed to fetch page {page}: {str(e)}")

    return {'count': total_count, 'data': all_data}

def fetch_wb_endppoints(endpoint_name: str) -> Dict[str, Any]:
    """Fetches all credit statement data"""
    return fetch_paginated_data(endpoint_name)


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
    
def fetch_gef_projects_csv(csv_url: str, tmp_path: str = "/tmp") -> Optional[str]:
    try:
        response = requests.get(csv_url, stream=True)
        response.raise_for_status()
        
        # Create temporary file path
        file_path = os.path.join(tmp_path, "gef_projects.csv")
        
        # Ensure tmp directory exists
        os.makedirs(tmp_path, exist_ok=True)
        
        # Write the file in chunks to handle large files efficiently
        with open(file_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        
        logging.info(f"Successfully downloaded GEF projects CSV file to {file_path}")
        return file_path
    except Exception as e:
        logging.error(f"Error downloading GEF projects CSV file: {str(e)}")
        return None