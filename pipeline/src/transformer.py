# pipeline/src/transformer.py
"""Functions for transforming and processing World Bank data into structured formats"""

import pandas as pd
from typing import Dict, Any, List
from datetime import datetime
import re
import logging
from config import TABLES
import csv
import io

logger = logging.getLogger(__name__)

def process_api_call_json(data: List[Dict[str, Any]], api_endpoint: str) -> pd.DataFrame:
    try:
        logger.info(f"Processing {api_endpoint} data...")
        df = pd.DataFrame(data)
        df.columns = [standardize_column_name(col) for col in df.columns]
        if 'processed_at' not in df.columns and 'as_of_date' not in df.columns:
            df['as_of_date'] = datetime.now()
        return df
    except Exception as e:
        logger.error(f"Error processing {api_endpoint}:{str(e)}")


def standardize_column_name(column: str) -> str:
    """
    Standardizes column names to lowercase with underscores.
    
    Args:
        column: Original column name from Excel
        
    Returns:
        Standardized column name in lowercase with underscores
    """
    # Convert to lowercase
    name = str(column).lower()
    
    # Replace special characters and spaces with underscore
    import re
    # Replace any non-alphanumeric character (except underscores) with underscore
    name = re.sub(r'[^a-z0-9_]', '_', name)
    
    # Replace multiple consecutive underscores with a single underscore
    name = re.sub(r'_+', '_', name)
    
    # Remove leading/trailing underscores
    name = name.strip('_')
    
    return name

def process_projects_excel(file_path: str) -> Dict[str, pd.DataFrame]:
    """
    Processes the World Bank projects Excel file into multiple DataFrames.
    
    This function reads each sheet of the Excel file and processes it into
    a clean DataFrame. Each sheet contains different aspects of project data.
    The function handles special cases:
    - Skips the first row in all sheets (download timestamp)
    - For 'World Bank Projects' sheet, skips first and third rows
      (timestamp and duplicate header)
    - Standardizes all column names to lowercase with underscores
    
    Args:
        file_path: Path to the downloaded Excel file
        
    Returns:
        Dictionary of DataFrames, one for each sheet
    """
    try:
        # Read all sheets from Excel file
        sheet_names = ['World Bank Projects', 'Themes', 'Sectors', 
                      'GEO Locations', 'Financers']
        
        dataframes = {}
        
        for sheet in sheet_names:
            # For World Bank Projects sheet, skip rows 0 and 2 (indices)
            # For all other sheets, skip only row 0
            skiprows = [0, 2] if sheet == 'World Bank Projects' else [0]
            
            # Read the Excel sheet, skipping specified rows
            df = pd.read_excel(
                file_path,
                sheet_name=sheet,
                skiprows=skiprows
            )
            
            # Standardize column names
            df.columns = [standardize_column_name(col) for col in df.columns]
            
            # Convert date columns if present (using standardized column names)
            date_columns = [col for col in df.columns 
                          if any(date_term in col 
                                for date_term in ['date', 'as_of'])]
            for col in date_columns:
                df[col] = pd.to_datetime(df[col], errors='coerce')
            
            # Convert numeric columns (using standardized column names)
            numeric_columns = [col for col in df.columns 
                             if any(amount_term in col 
                                   for amount_term in ['amount', 'cost', 'commitment'])]
            for col in numeric_columns:
                df[col] = pd.to_numeric(df[col], errors='coerce')
            
            # Store the DataFrame using the sheet name as key
            # Convert sheet name to lowercase and replace spaces with underscores
            sheet_key = standardize_column_name(sheet)
            if 'processed_at' not in df.columns and 'as_of_date' not in df.columns:
                df['as_of_date'] = datetime.now()

            dataframes[sheet_key] = df
            
            logging.info(f"Processed sheet '{sheet}' with {len(df)} rows")
            logging.debug(f"Standardized columns for '{sheet}': {list(df.columns)}")
        
        return dataframes
        
    except Exception as e:
        logging.error(f"Error processing projects Excel file: {str(e)}")
        raise

def process_gef_projects_csv(file_path: str) -> pd.DataFrame:
    try:
        # Read the CSV file, handling potential issues
        df = pd.read_csv(
            file_path,
            # engine='python',           # Use more flexible parser
            # encoding='utf-8-sig',      # Handle BOM if present
            quoting=csv.QUOTE_MINIMAL, # Only quote when needed
            # escapechar='\\',           # Define escape character
            # skipinitialspace=True      # Skip spaces after delimiter
        )
        
        logger.info("Successfully parsed GEF projects CSV file")
        
        # Standardize column names
        df.columns = [standardize_column_name(col) for col in df.columns]
        
        if 'processed_at' not in df.columns and 'as_of_date' not in df.columns:
            df['as_of_date'] = datetime.now()
        
        return df
    except Exception as e:
        logger.error(f"Error processing GEF projects CSV file: {str(e)}")
        raise