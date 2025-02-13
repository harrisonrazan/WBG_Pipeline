SELECT
	project_id,
	supplier_country,
	NULLIF(TO_CHAR(supplier_contract_amount_usd, '999,999,999,999.99'), '') as contract_amount,
	project_name,
	wb_contract_number,
	-- TO_CHAR(as_of_date, 'YYYY-MM-DD') AS as_of_date,
	fiscal_year,
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
	contract_age_days,
	fiscal_quarter
FROM wb_contract_awards
WHERE
	borrower_country = 'Madagascar'
ORDER BY
	project_id DESC,
	supplier_country DESC,
	supplier_contract_amount_usd,
	contract_signing_date
	