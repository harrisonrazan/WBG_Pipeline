# List of required tables
REQUIRED_TABLES = {
    'wb_projects': ['project_id'],
    'wb_project_themes': ['project_id', 'level_1', 'level_2', 'level_3'],
    'wb_project_sectors': ['project_id', 'major_sector', 'sector'],
    'wb_project_geo_locations': ['project_id', 'geo_loc_id', 'place_id'],
    'wb_project_financers': ['project', 'financer_id'],
    'wb_credit_statements': ['credit_number'],
    'wb_contract_awards': ['wb_contract_number', 'project_id'],
    'wb_trust_fund_commitments': [],
    'wb_corporate_procurement_contract_awards': [],
    'wb_loan_statements': [],
    'wb_procurement_notices': [],
    'wb_financial_intermediary_funds_contributions': []
}