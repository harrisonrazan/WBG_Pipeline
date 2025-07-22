# pipeline/src/pipeline.py
"""Main script for the World Bank data pipeline"""
import logging
import time
import os
from datetime import datetime
from sqlalchemy import create_engine
from dotenv import load_dotenv
import concurrent.futures
import pandas as pd

# Import our configuration and fetching functions
from config import TABLES, FETCH_INTERVAL, LOG_CONFIG, API_CONFIG
from fetcher import (
    fetch_projects_excel,
    fetch_wb_endppoints,
    fetch_gef_projects_csv
)
from transformer import (
    # process_projects_excel_concurrently,
    process_projects_excel,
    # process_api_call_json,
    process_gef_projects_csv
)
from scraper import enrich_dataframe_with_relationships  
# from loader import load_dataframe

# Setup logging using our centralized configuration
logging.basicConfig(
    level=LOG_CONFIG['level'],
    format=LOG_CONFIG['format']
)
logger = logging.getLogger(__name__)

# Maximum concurrency for API calls
MAX_API_WORKERS = 5

def fetch_api_data_concurrently(endpoints):
    """Fetch data from multiple API endpoints concurrently"""
    api_json_data = {}
    
    def fetch_endpoint(endpoint):
        """Worker function to fetch a single endpoint"""
        try:
            logger.info(f"Fetching data for {endpoint}...")
            data = fetch_wb_endppoints(endpoint)
            return endpoint, data
        except Exception as e:
            logger.error(f"Error fetching {endpoint}: {str(e)}")
            return endpoint, None
    
    # Use ThreadPoolExecutor for API calls (I/O bound)
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_API_WORKERS) as executor:
        future_to_endpoint = {executor.submit(fetch_endpoint, endpoint): endpoint for endpoint in endpoints}
        
        for future in concurrent.futures.as_completed(future_to_endpoint):
            endpoint, data = future.result()
            api_json_data[endpoint] = data
    
    return api_json_data

def process_api_data_worker(item):
    """Worker function to process API data - defined outside for pickling"""
    import logging
    from transformer import process_api_call_json
    
    logger = logging.getLogger(__name__)
    table_name, data = item
    try:
        if data and data.get('data'):
            logger.info(f"Processing data for {table_name}...")
            df = process_api_call_json(data['data'], table_name)
            return table_name, df
        else:
            logger.warning(f"No data found for {table_name}")
            return table_name, None
    except Exception as e:
        logger.error(f"Error processing {table_name}: {str(e)}")
        return table_name, None

def transform_api_data_concurrently(api_json_data):
    """Transform API data concurrently"""
    api_dataframes = {}
    
    # Use ThreadPoolExecutor instead of ProcessPoolExecutor to avoid pickling issues
    with concurrent.futures.ThreadPoolExecutor() as executor:
        future_to_table = {
            executor.submit(process_api_data_worker, (table_name, data)): table_name 
            for table_name, data in api_json_data.items() if data
        }
        
        for future in concurrent.futures.as_completed(future_to_table):
            table_name, df = future.result()
            if df is not None:
                api_dataframes[table_name] = df
    
    return api_dataframes

def load_single_df(item, table_mapping, engine):
    """Worker function to load a single dataframe - defined outside for visibility"""
    import logging
    from loader import load_dataframe
    
    logger = logging.getLogger(__name__)
    table_key, df = item
    try:
        if table_key in table_mapping:
            logger.info(f"Loading {table_key} data...")
            load_dataframe(df, table_mapping[table_key], engine, create_backup=False)
            return table_key, True
        else:
            logger.warning(f"No table mapping found for {table_key}")
            return table_key, False
    except Exception as e:
        logger.error(f"Error loading {table_key}: {str(e)}")
        return table_key, False

def load_dataframes_concurrently(dataframes_dict, table_mapping, engine):
    """Load multiple dataframes to database concurrently"""
    
    # Process dataframes sequentially to avoid any concurrency issues with database
    results = {}
    for table_key, df in dataframes_dict.items():
        table_key, success = load_single_df((table_key, df), table_mapping, engine)
        results[table_key] = success
    
    return results

def run_pipeline(engine):
    """
    Executes the complete data pipeline with optimizations for speed:
    1. Fetches data from all World Bank APIs concurrently
    2. Processes and transforms the data using parallel processing
    3. Loads it into PostgreSQL concurrently
    """
    try:
        start_time = time.time()
        logger.info("Starting pipeline with optimized performance...")
        
        # Fetch data from all sources - run in parallel where possible
        fetch_tasks = {}
        
        # Start Excel fetch
        with concurrent.futures.ThreadPoolExecutor() as executor:
            logger.info("Fetching WBG project excel data...")
            fetch_tasks['excel'] = executor.submit(fetch_projects_excel, API_CONFIG['projects_url'])
            
            # logger.info("Fetching GEF CSV data...")
            # fetch_tasks['gef'] = executor.submit(fetch_gef_projects_csv, API_CONFIG['gef_projects_url'])
            
            # Fetch API data concurrently while Excel/CSV downloads
            logger.info("Fetching API data concurrently...")
            api_json_data = fetch_api_data_concurrently(API_CONFIG['endpoints'])
            
            # Wait for Excel and GEF data to complete
            projects_file = fetch_tasks['excel'].result()
            # gef_file = fetch_tasks['gef'].result()
        
        if not projects_file:
            raise ValueError("Failed to download projects Excel file")
            
        # Process Excel file (CPU intensive)
        logger.info("Processing WBG project excel data...")
        project_dataframes = process_projects_excel(projects_file)
        
        '''
            # Process GEF data
            # logger.info("Processing GEF CSV data...")
            # project_dataframes['gef_projects'] = process_gef_projects_csv(gef_file)
        '''
        
        # Process API data concurrently
        logger.info("Processing API data concurrently...")
        api_dataframes = transform_api_data_concurrently(api_json_data)
        
        '''
            # Enrich world_bank_projects data with project relationship scraping
            # if 'world_bank_projects' in project_dataframes:
            #     try:
            #         logger.info("Scraping project relationships (parent/associated projects)...")
                    
            #         # Get project URLs or IDs
            #         df = project_dataframes['world_bank_projects']
                    
            #         # Explicitly add columns if they don't exist
            #         if 'parent_project' not in df.columns:
            #             df['parent_project'] = None
            #         if 'associated_projects' not in df.columns:
            #             df['associated_projects'] = "[]"
                    
            #         # Start with a very small batch for testing
            #         logger.info(f"Testing relationship scraping with a small sample...")
            #         # Sample a small number of rows for initial testing
            #         sample_size = min(10, len(df))
            #         sample_df = df.sample(sample_size)
                    
            #         # Try enrichment on the sample first
            #         try:
            #             enriched_sample = enrich_dataframe_with_relationships(
            #                 sample_df,
            #                 url_column='project_id_url',
            #                 batch_size=2,  # Very small batch size for testing
            #                 use_cache=True
            #             )
            #             logger.info(f"Sample enrichment successful, proceeding with full dataset")
                        
            #             # If sample succeeded, enrich the full dataframe with conservative settings
            #             enriched_df = enrich_dataframe_with_relationships(
            #                 df,
            #                 url_column='project_id_url',
            #                 batch_size=3,  # Keep batch size small
            #                 use_cache=True
            #             )
                        
            #             # Update the dataframe in the dictionary
            #             project_dataframes['world_bank_projects'] = enriched_df
                        
            #         except Exception as e:
            #             logger.error(f"Error in relationship scraping: {str(e)}")
            #             logger.info("Continuing with pipeline without relationship enrichment")
            #             # Keep the base dataframe with empty relationship columns
            #             project_dataframes['world_bank_projects'] = df
                    
            #         logger.info("Project relationship processing completed")
            #     except Exception as e:
            #         logger.error(f"Failed to process project relationships: {str(e)}")
            #         logger.info("Continuing pipeline without relationship data")
            # else:
            #     logger.warning("world_bank_projects not found in processed data, skipping relationship scraping")
        '''
        
        # Load all dataframes concurrently
        all_dataframes = {**project_dataframes, **api_dataframes}
        logger.info(f"Loading {len(all_dataframes)} datasets to PostgreSQL concurrently...")
        load_results = load_dataframes_concurrently(all_dataframes, TABLES, engine)
        
        # Clean up temporary files
        try:
            os.remove(projects_file)
            logger.info("Cleaned up temporary Excel file")
            # os.remove(gef_file)
            # logger.info("Cleaned up temporary CSV file")
        except Exception as e:
            logger.warning(f"Could not remove temporary files: {str(e)}")
        
        end_time = time.time()
        logger.info(f"Pipeline completed successfully in {end_time - start_time:.2f} seconds")
        return True
        
    except Exception as e:
        logger.error(f"Pipeline error: {str(e)}")
        return False

if __name__ == "__main__":
    # Load environment variables
    load_dotenv()
    
    # Create database engine
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise ValueError("DATABASE_URL environment variable is not set")
        
    engine = create_engine(database_url)

    # Run pipeline continuously
    while True:
        logger.info("Starting pipeline run...")
        run_pipeline(engine)
        
        next_run = datetime.now().timestamp() + FETCH_INTERVAL
        logger.info(f"Next run scheduled for: {datetime.fromtimestamp(next_run)}")
        time.sleep(FETCH_INTERVAL)