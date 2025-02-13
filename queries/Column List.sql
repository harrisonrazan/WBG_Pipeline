SELECT column_name
FROM information_schema.columns
WHERE table_name = 'wb_projects'
-- WHERE table_name = 'wb_project_themes'
-- WHERE table_name = 'wb_project_sectors'
-- WHERE table_name = 'wb_project_geo_locations'
-- WHERE table_name = 'wb_project_financers'
-- WHERE table_name = 'wb_contract_awards'
-- WHERE table_name = 'wb_credit_statements'
ORDER BY ordinal_position;