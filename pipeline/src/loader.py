# pipeline/src/loader.py
"""
Functions for loading processed data into PostgreSQL database.
This module handles the final stage of our ETL pipeline, safely loading
transformed data into our database while providing detailed feedback about the process.
"""

import pandas as pd
import logging
from typing import Optional, Any, Dict
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine.base import Engine
from datetime import datetime

# Setup logging for this module
logger = logging.getLogger(__name__)

def verify_table_structure(engine: Engine, table_name: str, df: pd.DataFrame) -> bool:
    """
    Verifies if the DataFrame structure matches the existing table structure.
    Also checks column types compatibility.
    """
    try:
        inspector = inspect(engine)
        if not inspector.has_table(table_name):
            logger.info(f"Table {table_name} does not exist - will be created")
            return True
            
        existing_columns = {col['name']: col['type'] 
                          for col in inspector.get_columns(table_name)}
        df_columns = set(df.columns)
        
        # Check for missing columns
        if not df_columns.issubset(existing_columns.keys()):
            new_columns = df_columns - set(existing_columns.keys())
            logger.warning(f"New columns found in DataFrame: {new_columns}")
            return False
            
        # Check column type compatibility
        for col in df_columns:
            df_type = df[col].dtype
            db_type = existing_columns[col]
            
            # Check basic type compatibility
            if ('int' in str(df_type).lower() and 'INTEGER' not in str(db_type).upper()) or \
               ('float' in str(df_type).lower() and 'NUMERIC' not in str(db_type).upper()) or \
               ('datetime' in str(df_type).lower() and 'TIMESTAMP' not in str(db_type).upper()):
                logger.warning(f"Column {col} type mismatch: DataFrame={df_type}, DB={db_type}")
                return False
            
        return True
        
    except Exception as e:
        logger.error(f"Error verifying table structure: {str(e)}")
        return False

def create_backup_table(engine: Engine, table_name: str) -> bool:
    """
    Creates a backup of the existing table before loading new data.
    This provides a safety net in case we need to rollback changes.
    
    Args:
        engine: SQLAlchemy engine connected to the database
        table_name: Name of the table to backup
        
    Returns:
        bool: True if backup was successful, False otherwise
    """
    try:
        backup_table = f"{table_name}_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        with engine.connect() as conn:
            conn.execute(text(f"CREATE TABLE {backup_table} AS SELECT * FROM {table_name}"))
            logger.info(f"Created backup table: {backup_table}")
        return True
    except Exception as e:
        logger.error(f"Error creating backup table: {str(e)}")
        return False

def migrate_table_schema(engine: Engine, table_name: str, df: pd.DataFrame) -> bool:
    """
    Handles schema changes by creating a new table with the updated schema,
    copying the data, and swapping the tables.
    """
    try:
        temp_table = f"{table_name}_new"
        
        # Create new table with updated schema
        df.head(0).to_sql(temp_table, engine, if_exists='replace', index=False)
        
        # Copy existing data that matches the new schema
        with engine.connect() as conn:
            common_columns = ", ".join(col for col in df.columns 
                                     if col in [c['name'] for c in inspect(engine).get_columns(table_name)])
            conn.execute(text(
                f"INSERT INTO {temp_table} ({common_columns}) "
                f"SELECT {common_columns} FROM {table_name}"
            ))
            
            # Swap tables
            conn.execute(text(f"ALTER TABLE {table_name} RENAME TO {table_name}_old"))
            conn.execute(text(f"ALTER TABLE {temp_table} RENAME TO {table_name}"))
            conn.execute(text(f"DROP TABLE {table_name}_old"))
            
        return True
        
    except Exception as e:
        logger.error(f"Error migrating table schema: {str(e)}")
        return False

def load_dataframe(
    df: pd.DataFrame,
    table_name: str,
    engine: Any,
    if_exists: str = 'replace',
    create_backup: bool = True
) -> bool:
    """
    Loads a DataFrame into PostgreSQL with enhanced schema handling.
    """
    try:
        logger.info(f"Attempting to load {len(df)} rows into table: {table_name}")
        
        inspector = inspect(engine)
        table_exists = inspector.has_table(table_name)
        
        # Handle schema verification and migration
        if table_exists and if_exists == 'append':
            if not verify_table_structure(engine, table_name, df):
                logger.info("Schema mismatch detected, attempting migration...")
                if not migrate_table_schema(engine, table_name, df):
                    return False
        
        # Create backup if requested and table exists
        if create_backup and table_exists:
            if not create_backup_table(engine, table_name):
                logger.error("Failed to create backup table")
                return False
        
        # Load the data with retry logic
        max_retries = 3
        for attempt in range(max_retries):
            try:
                df.to_sql(
                    table_name,
                    engine,
                    if_exists=if_exists,
                    index=False,
                    method='multi',
                    chunksize=10000
                )
                break
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                logger.warning(f"Load attempt {attempt + 1} failed, retrying: {str(e)}")
                time.sleep(5)
        
        # Verify row count
        with engine.connect() as conn:
            result = conn.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
            db_count = result.scalar()
            logger.info(f"Verified row count in database: {db_count}")
            
            if db_count != len(df):
                logger.warning(f"Row count mismatch: DataFrame={len(df)}, Database={db_count}")
        
        return True
        
    except Exception as e:
        logger.error(f"Error loading data to {table_name}: {str(e)}")
        return False