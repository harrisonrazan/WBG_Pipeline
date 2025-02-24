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
        'trust_fund_commitments': {
            'dataset_id': 'DS00271',
            'resource_id': 'RS00236'
        },
        'corporate_procurement_contract_awards': {
            'dataset_id': 'DS00028',
            'resource_id': 'RS00025'
        },
        'loan_statements': {
            'dataset_id': 'DS00047',
            'resource_id': 'RS00049'
        },
        'procurement_notices': {
            'dataset_id': 'DS00979',
            'resource_id': 'RS00909'
        },
        'financial_intermediary_funds_contributions': {
            'dataset_id': 'DS00977',
            'resource_id': 'RS00907'
        },
        'contract_awards': {
            'dataset_id': 'DS00005',
            'resource_id': 'RS00005'
        }
    },
    'max_retries': 3,
    'retry_delay': 5,
    'timeout': 30,
    'records_per_page': 1000,
    'num_workers': 10
}

# Database tables configuration
TABLES = {
    # excel file
    'world_bank_projects': 'wb_projects',
    'themes': 'wb_project_themes',
    'sectors': 'wb_project_sectors',
    'geo_locations': 'wb_project_geo_locations',
    'financers': 'wb_project_financers',
    # api data
    'credit_statements': 'wb_credit_statements',
    'contract_awards': 'wb_contract_awards',
    'trust_fund_commitments': 'wb_trust_fund_commitments',
    'corporate_procurement_contract_awards': 'wb_corporate_procurement_contract_awards',
    'loan_statements': 'wb_loan_statements',
    'procurement_notices': 'wb_procurement_notices',
    'financial_intermediary_funds_contributions': 'wb_financial_intermediary_funds_contributions',
}


# Fetch interval in seconds (default 1 hour)
FETCH_INTERVAL = 604800

# Logging configuration
LOG_CONFIG = {
    'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    'level': 'INFO'
}