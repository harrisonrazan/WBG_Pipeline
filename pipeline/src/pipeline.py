# pipeline/src/pipeline.py
"""Main script for the World Bank data pipeline"""
import logging
import time
import os
from datetime import datetime
from sqlalchemy import create_engine
from dotenv import load_dotenv

# Import our configuration and fetching functions
from config import TABLES, FETCH_INTERVAL, LOG_CONFIG, API_CONFIG
from fetcher import (
    fetch_projects_excel,
    fetch_wb_endppoints,
    fetch_gef_projects_csv
)
from transformer import (
    process_projects_excel,  # Need to use this instead of process_projects_data
    process_api_call_json,
    process_gef_projects_csv
)
from loader import load_dataframe

# Setup logging using our centralized configuration
logging.basicConfig(
    level=LOG_CONFIG['level'],
    format=LOG_CONFIG['format']
)
logger = logging.getLogger(__name__)

def run_pipeline(engine):
    """
    Executes the complete data pipeline:
    1. Fetches data from all World Bank APIs
    2. Processes and transforms the data
    3. Loads it into PostgreSQL
    
    The pipeline handles multiple datasets:
    - World Bank Projects (Excel file with multiple sheets)
    - Credit Statements
    - Contract Awards
    """
    try:
        # Fetch data from all sources
        logger.info("Fetching data from World Bank APIs...")
        
        # Download and process the projects Excel file
        logger.info("Fetching WBG project excel data APIs...")
        projects_file = fetch_projects_excel(API_CONFIG['projects_url'])
        if not projects_file:
            raise ValueError("Failed to download projects Excel file")
        
        #Pull Gef data
        logger.info("Fetching GEF CSV data...")
        gef_file = fetch_gef_projects_csv(API_CONFIG['gef_projects_url'])
            
        # Fetch other data sources
        logger.info("Fetching Json Data APIs...")
        api_json_data = {}
        api_dataframes = {}
        for table_name in API_CONFIG['endpoints']:
            api_json_data[table_name] = fetch_wb_endppoints(table_name)
            if not api_json_data:
                raise ValueError(f"Failed to fetch data for {table_name}")
            if not all([
                api_json_data[table_name] and api_json_data[table_name].get('data'),
            ]):
                raise ValueError("Failed to fetch data from one or more sources")

        # Process each dataset
        logger.info("Processing WBG project excel data...")
        project_dataframes = process_projects_excel(projects_file)

        # Process Gef data
        logger.info("Processing GEF CSV data...")
        project_dataframes['gef_projects'] = process_gef_projects_csv(gef_file)

        logger.info("Processing WBG API data...")
        for table_name, data in api_json_data.items():
            if data and data.get('data'):
                api_dataframes[table_name] = process_api_call_json(data['data'], table_name)
            else:
                logger.warning(f"No data found for {table_name}")
                
        # Load project-related datasets to their respective tables
        logger.info("Loading project datasets to PostgreSQL...")
        for table_key, df in project_dataframes.items():
            if table_key in TABLES:
                logger.info(f"Loading {table_key} data...")
                load_dataframe(df, TABLES[table_key], engine, create_backup=False)
            else:
                logger.warning(f"No table mapping found for {table_key}")

        # Load other datasets
        logger.info("Loading additional datasets to PostgreSQL...")
        for table_key, df in api_dataframes.items():
            if table_key in TABLES:
                logger.info(f"Loading {table_key} data...")
                load_dataframe(df, TABLES[table_key], engine, create_backup=False)
            else:
                logger.warning(f"No table mapping found for {table_key}")


        # Clean up the temporary Excel file
        try:
            os.remove(projects_file)
            logger.info("Cleaned up temporary Excel file")
        except Exception as e:
            logger.warning(f"Could not remove temporary file {projects_file}: {str(e)}")

        logger.info("Pipeline run completed successfully")
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