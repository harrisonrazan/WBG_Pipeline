SELECT 
    MAX(CASE WHEN table_name = 'wb_projects' THEN column_name END) AS wb_projects,
    MAX(CASE WHEN table_name = 'wb_project_themes' THEN column_name END) AS wb_project_themes,
    MAX(CASE WHEN table_name = 'wb_project_sectors' THEN column_name END) AS wb_project_sectors,
    MAX(CASE WHEN table_name = 'wb_project_geo_locations' THEN column_name END) AS wb_project_geo_locations,
    MAX(CASE WHEN table_name = 'wb_project_financers' THEN column_name END) AS wb_project_financers,
    MAX(CASE WHEN table_name = 'wb_credit_statements' THEN column_name END) AS wb_credit_statements,
    MAX(CASE WHEN table_name = 'wb_contract_awards' THEN column_name END) AS wb_contract_awards,
    MAX(CASE WHEN table_name = 'wb_trust_fund_commitments' THEN column_name END) AS wb_trust_fund_commitments,
    MAX(CASE WHEN table_name = 'wb_corporate_procurement_contract_awards' THEN column_name END) AS wb_corporate_procurement_contract_awards,
    MAX(CASE WHEN table_name = 'wb_loan_statements' THEN column_name END) AS wb_loan_statements,
    MAX(CASE WHEN table_name = 'wb_procurement_notices' THEN column_name END) AS wb_procurement_notices,
    MAX(CASE WHEN table_name = 'wb_financial_intermediary_funds_contributions' THEN column_name END) AS wb_financial_intermediary_funds_contributions,
    MAX(CASE WHEN table_name = 'gef_projects' THEN column_name END) AS gef_projects
FROM (
    SELECT table_name, column_name, ROW_NUMBER() OVER (PARTITION BY table_name ORDER BY ordinal_position) AS rn
    FROM information_schema.columns
    WHERE table_name IN (
        'wb_projects',
        'wb_project_themes',
        'wb_project_sectors',
        'wb_project_geo_locations',
        'wb_project_financers',
        'wb_credit_statements',
        'wb_contract_awards',
        'wb_trust_fund_commitments',
        'wb_corporate_procurement_contract_awards',
        'wb_loan_statements',
        'wb_procurement_notices',
        'wb_financial_intermediary_funds_contributions',
		'gef_projects'
    )
) AS subquery
GROUP BY rn
ORDER BY rn;
