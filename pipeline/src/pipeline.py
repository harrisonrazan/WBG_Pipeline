# pipeline/src/pipeline.py
"""Main script for the World Bank data pipeline"""
import logging
from datetime import datetime
import time
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

# Import our configuration and fetching functions
from config import TABLES, FETCH_INTERVAL, LOG_CONFIG, API_CONFIG
from fetcher import (
    fetch_projects_excel,  # Changed from fetch_projects
    fetch_credit_statements,
    fetch_contract_awards
)
from transformer import (
    process_projects_excel,  # Need to use this instead of process_projects_data
    process_credit_statements,
    process_contract_awards,
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
        projects_file = fetch_projects_excel(API_CONFIG['projects_url'])
        if not projects_file:
            raise ValueError("Failed to download projects Excel file")
            
        # Fetch other data sources
        credit_data = fetch_credit_statements()
        contract_data = fetch_contract_awards()

        # Verify we have all required data
        if not all([
            credit_data and credit_data.get('data'),
            contract_data and contract_data.get('data')
        ]):
            raise ValueError("Failed to fetch data from one or more sources")

        # Process each dataset
        logger.info("Processing fetched data...")
        
        # Process the Excel file - it contains multiple sheets of project data
        project_dataframes = process_projects_excel(projects_file)
        
        # Process other datasets
        credit_df = process_credit_statements(credit_data['data'])
        contract_df = process_contract_awards(contract_data['data'])

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
        load_dataframe(credit_df, TABLES['credit_statements'], engine, create_backup=False)
        load_dataframe(contract_df, TABLES['contract_awards'], engine, create_backup=False)

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