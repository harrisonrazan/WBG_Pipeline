# pipeline/src/transformer.py
"""Functions for transforming and processing World Bank data into structured formats"""

import pandas as pd
from typing import Dict, Any, List
from datetime import datetime
import re
import logging

logger = logging.getLogger(__name__)

def process_credit_statements(data: List[Dict[str, Any]]) -> pd.DataFrame:
    """
    Processes World Bank credit statements data into a structured DataFrame.
    
    This function handles detailed IDA credit information including:
    - Credit identification and status
    - Important dates (signing, approval, effectiveness, etc.)
    - Financial amounts (disbursements, repayments, cancellations)
    - Borrower and project information
    
    Args:
        data: List of credit statement records from the API
        
    Returns:
        DataFrame with standardized credit statement information
    """
    try:
        # Create DataFrame from raw data
        df = pd.DataFrame(data)
        
        # Define date columns that need conversion
        date_columns = [
            'agreement_signing_date',
            'board_approval_date',
            'closed_date_most_recent',
            'effective_date_most_recent',
            'first_repayment_date',
            'last_disbursement_date',
            'last_repayment_date',
            'end_of_period'
        ]
        
        # Convert date columns to datetime, handling the specific date format
        for col in date_columns:
            if col in df.columns:
                # Handle the 'DD-Mon-YYYY' format (e.g., '12-May-1961')
                df[col] = pd.to_datetime(df[col], format='%d-%b-%Y', errors='coerce')
        
        # Define amount columns that need numeric conversion
        # Note: columns ending with 'us_' represent USD amounts
        amount_columns = [
            'borrowers_obligation_us_',
            'cancelled_amount_us_',
            'credits_held_us_',
            'disbursed_amount_us_',
            'due_3rd_party_us_',
            'due_to_ida_us_',
            'exchange_adjustment_us_',
            'original_principal_amount_us_',
            'repaid_3rd_party_us_',
            'repaid_to_ida_us_',
            'sold_3rd_party_us_',
            'undisbursed_amount_us_'
        ]
        
        # Convert amount columns to numeric, handling any formatting
        for col in amount_columns:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors='coerce')
        
        # Convert service charge rate to numeric (it's a percentage)
        if 'service_charge_rate' in df.columns:
            df['service_charge_rate'] = pd.to_numeric(df['service_charge_rate'], errors='coerce')
        
        # Clean up string columns (remove extra whitespace, ensure consistent capitalization)
        string_columns = [
            'borrower', 'country', 'country_code', 'credit_number',
            'credit_status', 'currency_of_commitment', 'project_id',
            'project_name', 'region'
        ]
        
        for col in string_columns:
            if col in df.columns:
                df[col] = df[col].str.strip()
                
        # Region names are in uppercase, convert to title case for consistency
        if 'region' in df.columns:
            df['region'] = df['region'].str.title()
            
        # Add calculated fields that might be useful for analysis
        df['total_repayment'] = df['repaid_to_ida_us_'] + df['repaid_3rd_party_us_']
        df['repayment_rate'] = (df['total_repayment'] / 
                               df['disbursed_amount_us_'].where(df['disbursed_amount_us_'] != 0))
        
        # Add processing timestamp
        df['processed_at'] = datetime.now()
        
        return df
        
    except Exception as e:
        logger.error(f"Error processing credit statements: {str(e)}")
        raise

def process_contract_awards(data: List[Dict[str, Any]]) -> pd.DataFrame:
    """
    Processes World Bank contract awards data into a structured DataFrame.
    
    This function handles detailed procurement information including:
    - Contract identification and timing
    - Project and borrower details
    - Supplier information
    - Procurement classifications
    - Financial amounts
    
    The data represents individual contracts awarded under World Bank-funded projects,
    capturing both the financial and operational aspects of project implementation.
    
    Args:
        data: List of contract award records from the API
        
    Returns:
        DataFrame with standardized contract award information
    """
    try:
        # Create DataFrame from raw data
        df = pd.DataFrame(data)
        
        # Process date columns - they use the format 'DD-Mon-YYYY'
        date_columns = ['as_of_date', 'contract_signing_date']
        for col in date_columns:
            if col in df.columns:
                df[col] = pd.to_datetime(df[col], format='%d-%b-%Y', errors='coerce')
        
        # Convert fiscal year to integer while handling potential invalid values
        if 'fiscal_year' in df.columns:
            df['fiscal_year'] = pd.to_numeric(df['fiscal_year'], errors='coerce').astype('Int64')
        
        # Convert monetary amount to numeric, preserving decimal places
        if 'supplier_contract_amount_usd' in df.columns:
            df['supplier_contract_amount_usd'] = pd.to_numeric(
                df['supplier_contract_amount_usd'],
                errors='coerce'
            )
        
        # Handle semicolon-separated values in project_global_practice
        # Store as list to maintain all values while ensuring consistent format
        if 'project_global_practice' in df.columns:
            df['project_global_practice'] = df['project_global_practice'].str.split(';')
        
        # Clean up string columns to ensure consistent formatting
        string_columns = [
            'region',
            'borrower_country',
            'borrower_country_code',
            'project_id',
            'project_name',
            'procurement_category',
            'procurement_method',
            'wb_contract_number',
            'contract_description',
            'borrower_contract_reference_number',
            'supplier_id',
            'supplier',
            'supplier_country',
            'supplier_country_code',
            'review_type'
        ]
        
        for col in string_columns:
            if col in df.columns:
                # Strip whitespace and handle nulls consistently
                df[col] = df[col].str.strip() if df[col].dtype == 'object' else df[col]
        
        # Add derived fields useful for analysis
        
        # Flag for domestic contracts (supplier country matches borrower country)
        df['is_domestic_supplier'] = (
            df['supplier_country_code'] == df['borrower_country_code']
        )
        
        # Calculate contract processing time if both dates are available
        if all(col in df.columns for col in ['as_of_date', 'contract_signing_date']):
            df['contract_age_days'] = (
                df['as_of_date'] - df['contract_signing_date']
            ).dt.days
        
        # Add processing metadata
        df['processed_at'] = datetime.now()
        
        # Calculate fiscal quarter from contract_signing_date
        if 'contract_signing_date' in df.columns:
            df['fiscal_quarter'] = df['contract_signing_date'].dt.quarter
        
        return df
        
    except Exception as e:
        logger.error(f"Error processing contract awards: {str(e)}")
        raise

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
            dataframes[sheet_key] = df
            
            logging.info(f"Processed sheet '{sheet}' with {len(df)} rows")
            logging.debug(f"Standardized columns for '{sheet}': {list(df.columns)}")
        
        return dataframes
        
    except Exception as e:
        logging.error(f"Error processing projects Excel file: {str(e)}")
        raise