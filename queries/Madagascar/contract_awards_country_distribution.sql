SELECT
	TO_CHAR(CAST(contract_signing_date AS TIMESTAMP), 'YYYY-MM-DD') AS contract_signing_date,
	project_id,
	borrower_country,
	supplier_country,
	supplier,
	borrower_contract_reference_number,
	wb_contract_number,
	NULLIF(TO_CHAR(supplier_contract_amount_usd, '999,999,999,999.99'), '') as contract_amount,
	NULLIF(TO_CHAR(SUM(supplier_contract_amount_usd) OVER (PARTITION BY project_id), '999,999,999,999.99'), '') as project_total,
	NULLIF(TO_CHAR(SUM(supplier_contract_amount_usd) OVER (PARTITION BY project_id, supplier_country), '999,999,999,999.99'), '') as project_country_total,
	TO_CHAR(
        (SUM(CAST(supplier_contract_amount_usd AS NUMERIC)) OVER (PARTITION BY project_id, supplier_country) * 100.0 / 
        NULLIF(SUM(CAST(supplier_contract_amount_usd AS NUMERIC)) OVER (PARTITION BY project_id), 0))::NUMERIC,
        '999.99'
    ) || '%' as country_percentage,
	contract_description,
	project_name,
	-- region,
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
	borrower_country = 'Madagascar'
	-- project_id = 'P153370'
	-- and (
	-- 	contract_description ILIKE '%surveillance%'
	-- )
ORDER BY
	-- supplier
	project_id DESC,
	supplier_country DESC,
	CAST(supplier_contract_amount_usd AS NUMERIC) DESC,
	contract_signing_date
	