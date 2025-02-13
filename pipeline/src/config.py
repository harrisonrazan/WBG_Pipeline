# pipeline/src/config.py
"""Configuration settings for our data pipeline"""

# World Bank API configurations
API_CONFIG = {
    'projects_url': 'https://search.worldbank.org/api/v3/projects/all.xlsx',
    'base_url': 'https://datacatalogapi.worldbank.org/dexapps/fone/api/apiservice',
    'endpoints': {
        'credit_statements': {
            'dataset_id': 'DS00001',
            'resource_id': 'RS00001'
        },
        'contract_awards': {
            'dataset_id': 'DS00005',
            'resource_id': 'RS00005'
        }
    },
    'max_retries': 3,
    'retry_delay': 5,
    'timeout': 30,
    'records_per_page': 1000
}

# Database tables configuration
TABLES = {
    'world_bank_projects': 'wb_projects',  # Main projects data
    'themes': 'wb_project_themes',
    'sectors': 'wb_project_sectors',
    'geo_locations': 'wb_project_geo_locations',
    'financers': 'wb_project_financers',
    'credit_statements': 'wb_credit_statements',
    'contract_awards': 'wb_contract_awards',
    # 'combined_metrics': 'wb_combined_metrics'
}


# Fetch interval in seconds (default 1 hour)
FETCH_INTERVAL = 604800

# Logging configuration
LOG_CONFIG = {
    'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    'level': 'INFO'
}