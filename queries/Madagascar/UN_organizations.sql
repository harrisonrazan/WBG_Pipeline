SELECT
	TO_CHAR(CAST(contract_signing_date AS TIMESTAMP), 'YYYY-MM-DD') AS contract_signing_date,
	project_id,
	supplier_country,
	supplier,
	borrower_contract_reference_number,
	NULLIF(TO_CHAR(supplier_contract_amount_usd, '999,999,999,999.99'), '') as contract_amount,
	-- NULLIF(TO_CHAR(SUM(supplier_contract_amount_usd) OVER (PARTITION BY project_id), '999,999,999,999.99'), '') as project_total,
	-- NULLIF(TO_CHAR(SUM(supplier_contract_amount_usd) OVER (PARTITION BY project_id, supplier_country), '999,999,999,999.99'), '') as project_country_total,
	-- TO_CHAR(
	--        (SUM(CAST(supplier_contract_amount_usd AS NUMERIC)) OVER (PARTITION BY project_id, supplier_country) * 100.0 / 
	--        NULLIF(SUM(CAST(supplier_contract_amount_usd AS NUMERIC)) OVER (PARTITION BY project_id), 0))::NUMERIC,
	--        '999.99'
	--    ) || '%' as country_percentage,
	contract_description,
	project_name,
	wb_contract_number,
	-- TO_CHAR(as_of_date, 'YYYY-MM-DD') AS as_of_date,
	-- region,
	-- borrower_country,
	-- borrower_country_code,
	-- project_global_practice,
	procurement_category,
	procurement_method,
	-- supplier_country_code,
	-- review_type,
	-- is_domestic_supplier,
	supplier_id,
	-- fiscal_quarter,
	fiscal_year,
	TO_CHAR(CAST(as_of_date AS TIMESTAMP), 'YYYY-MM-DD') AS as_of_date
	-- contract_age_days
FROM wb_contract_awards
WHERE
	borrower_country = 'Madagascar' AND
	(
        supplier ~* '\y(UNICEF|UNCTAD|UNDP|UNEP|UNFPA|UNRWA|UNU|WFP|PAM|UNHCR|HABITAT|OCHA|ITC|UNOPS|CTBTO|IAEA|IOM|OPCW|WTOILO|FAO|UNESCO|ICAO|WHO|WB|IMF|UPU|ITU|WMO|IMO|WIPO|IFAD|UNIDO|WTO|UN TOURISM)\y'
    )
ORDER BY
	project_id DESC,
	supplier_country DESC,
	supplier_contract_amount_usd,
	contract_signing_date
	