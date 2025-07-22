SELECT
	project_id,
	supplier_country,
	NULLIF(TO_CHAR(supplier_contract_amount_usd, '999,999,999,999.99'), '') as contract_amount,
	NULLIF(TO_CHAR(SUM(supplier_contract_amount_usd) OVER (PARTITION BY project_id), '999,999,999,999.99'), '') as project_total,
	NULLIF(TO_CHAR(SUM(supplier_contract_amount_usd) OVER (PARTITION BY project_id, supplier_country), '999,999,999,999.99'), '') as project_country_total,
	TO_CHAR(
        (SUM(CAST(supplier_contract_amount_usd AS NUMERIC)) OVER (PARTITION BY project_id, supplier_country) * 100.0 / 
        NULLIF(SUM(CAST(supplier_contract_amount_usd AS NUMERIC)) OVER (PARTITION BY project_id), 0))::NUMERIC,
        '999.99'
    ) || '%' as country_percentage,
	project_name,
	wb_contract_number,
	-- TO_CHAR(as_of_date, 'YYYY-MM-DD') AS as_of_date,
	-- region,
	-- borrower_country,
	-- borrower_country_code,
	project_global_practice,
	procurement_category,
	procurement_method,
	contract_description,
	borrower_contract_reference_number,
	TO_CHAR(contract_signing_date, 'YYYY-MM-DD') AS contract_signing_date,
	supplier_id,
	supplier,
	supplier_country_code,
	review_type,
	TO_CHAR(processed_at, 'YYYY-MM-DD') AS processed_at,
	is_domestic_supplier,
	fiscal_quarter,
	fiscal_year,
	contract_age_days
FROM wb_contract_awards
WHERE
	borrower_country = 'Madagascar' AND
	(
		project_id = 'P151469' OR
		project_id = 'P166133'
	)
ORDER BY
	project_id DESC,
	supplier_country DESC,
	supplier_contract_amount_usd,
	contract_signing_date
	