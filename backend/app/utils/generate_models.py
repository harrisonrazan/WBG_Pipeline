# backend/app/utils/generate_models.py
import os
from sqlalchemy import create_engine, MetaData, inspect
from pathlib import Path
import logging
from typing import List, Dict, Any
import re

logger = logging.getLogger(__name__)

def get_column_type_string(column_type: Any) -> str:
    """
    Determines the appropriate SQLAlchemy column type based on the database column type.
    Handles various SQL types and maps them to their SQLAlchemy equivalents.
    """
    type_name = str(column_type).upper()
    
    if 'INTEGER' in type_name:
        return 'Integer'
    elif 'TIMESTAMP' in type_name or 'DATETIME' in type_name:
        return 'DateTime'
    elif 'FLOAT' in type_name or 'NUMERIC' in type_name or 'DECIMAL' in type_name:
        return 'Float'
    elif 'BOOLEAN' in type_name:
        return 'Boolean'
    elif 'TEXT' in type_name or 'VARCHAR' in type_name or 'CHAR' in type_name:
        return 'String'
    else:
        return 'String'  # Default to String for unknown types

def sanitize_column_name(name: str) -> str:
    """
    Converts a database column name into a valid Python identifier.
    For example:
    'Project ID' becomes 'project_id'
    'Amount (USD)' becomes 'amount_usd'
    """
    # Remove parentheses and their contents
    name = re.sub(r'\([^)]*\)', '', name)
    
    # Replace spaces and special characters with underscores
    name = re.sub(r'[^a-zA-Z0-9]', '_', name)
    
    # Remove consecutive underscores
    name = re.sub(r'_+', '_', name)
    
    # Remove leading/trailing underscores
    name = name.strip('_')
    
    # Convert to lowercase for Python naming conventions
    name = name.lower()
    
    return name

def generate_model_class(table_name: str, columns: List[Dict]) -> str:
    """
    Generates a SQLAlchemy model class with proper primary keys based on project relationships.
    Most tables use 'Project ID' as their primary key, while the financers table uses 'Project' and 'Financer ID'.
    """
    class_name = ''.join(word.title() for word in table_name.split('_'))
    
    model_str = f"""class {class_name}(Base):
    \"\"\"SQLAlchemy model for the {table_name} table.\"\"\" 
    __tablename__ = '{table_name}'

"""

    # Define primary keys conditionally
    if table_name == 'wb_project_financers':
        primary_keys = ['Project', 'Financer ID']  # Composite primary key
    elif table_name == 'wb_credit_statements':
        primary_keys = ['credit_number']
    elif table_name == 'wb_contract_awards':
        primary_keys = ['wb_contract_number', 'project_id']
    else:
        primary_keys = ['Project ID']  # Default primary key for other tables

    # Add each column with appropriate configuration
    primary_key_fields = []
    for col in columns:
        original_name = col['name']
        python_name = sanitize_column_name(original_name)

        # Build column attributes
        attributes = []
        
        # Add the column type
        col_type = get_column_type_string(col['type'])
        attributes.append(col_type)

        # Set primary key
        if original_name in primary_keys:
            attributes.append('primary_key=True')
            primary_key_fields.append(python_name)

        # Add nullable attribute if specified
        if not col.get('nullable', True):
            attributes.append('nullable=False')

        # Create the complete column definition
        attr_str = ', '.join(attributes)
        model_str += f"    {python_name} = Column('{original_name}', {attr_str})\n"

    # Handle relationships to main projects table
    if table_name != 'wb_projects':
        key_column = 'project' if 'Project' in primary_keys else 'project_id'
        relationship_str = f"""
    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='{table_name.replace('wb_', '').replace('_', '')}_collection',
                               foreign_keys=[{key_column}])
"""
        model_str += relationship_str

    # Add string representation method
    model_str += "\n    def __repr__(self):\n"
    model_str += f"        return f\"<{class_name}(" + ", ".join(f"{{self.{pk}}}" for pk in primary_key_fields) + ")>\"\n\n"

    return model_str


def generate_models():
    """
    Generates SQLAlchemy models by inspecting the database schema.
    Includes error handling and detailed logging for troubleshooting.
    """
    try:
        database_url = os.getenv("DATABASE_URL")
        if not database_url:
            raise ValueError("DATABASE_URL environment variable not set")

        engine = create_engine(database_url)
        inspector = inspect(engine)
        
        # Get all table names and log them
        table_names = inspector.get_table_names()
        logger.info(f"Found tables: {table_names}")
        
        # Start with imports
        content = '''"""Auto-generated models. Do not edit manually."""

from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from .base import Base

'''
        
        # Generate models with detailed logging
        for table_name in table_names:
            try:
                columns = inspector.get_columns(table_name)
                logger.debug(f"Table {table_name} columns: {columns}")
                
                model_class = generate_model_class(table_name, columns)
                content += model_class
                logger.info(f"Generated model for table: {table_name}")
                
            except Exception as table_error:
                logger.error(f"Error generating model for table {table_name}: {str(table_error)}")
                raise
        
        # Write to file with path verification
        models_dir = Path('/app/app/models')
        models_dir.mkdir(exist_ok=True)
        generated_file = models_dir / 'generated.py'
        
        with open(generated_file, 'w') as f:
            f.write(content)
            
        logger.info(f"Successfully wrote models to {generated_file}")
        
    except Exception as e:
        logger.error(f"Error generating models: {str(e)}")
        raise