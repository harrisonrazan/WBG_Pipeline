import pandas as pd
from typing import Callable, Dict, Any
from sqlalchemy import create_engine
import os
import time
import logging
from functools import partial

# Configuration
def create_db_engine(database_url: str):
    """Creates and returns a database engine."""
    return create_engine(database_url)

def fetch_data(url: str) -> pd.DataFrame:
    """Pure function to fetch data from a URL."""
    return pd.read_csv(url)

def process_data(df: pd.DataFrame) -> pd.DataFrame:
    """Pure function to process the DataFrame.
    Add your specific transformations here."""
    # Example transformation
    processed = df.copy()
    return processed

def save_to_db(engine, df: pd.DataFrame, table_name: str) -> None:
    """Handles database persistence."""
    df.to_sql(table_name, engine, if_exists='replace', index=False)

def compose(*functions: Callable) -> Callable:
    """Function composition utility."""
    return reduce(lambda f, g: lambda x: f(g(x)), functions[::-1])

def create_pipeline(config: Dict[str, Any]) -> Callable:
    """Creates a pipeline function with injected dependencies."""
    engine = create_db_engine(config['database_url'])
    
    def pipeline_step():
        try:
            # Compose our data processing functions
            process_and_save = compose(
                lambda df: save_to_db(engine, df, 'processed_data'),
                process_data,
                fetch_data
            )
            
            # Execute pipeline
            process_and_save(config['data_url'])
            logging.info("Pipeline run completed successfully")
            
        except Exception as e:
            logging.error(f"Pipeline error: {str(e)}")
    
    return pipeline_step

def run_pipeline(pipeline_fn: Callable, interval: int):
    """Runs the pipeline at specified intervals."""
    while True:
        pipeline_fn()
        time.sleep(interval)