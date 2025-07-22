SELECT 
    project_id,
    supplier_country,
    NULLIF(TO_CHAR(SUM(supplier_contract_amount_usd), '999,999,999,999.99'), '') as supplier_country_total,
    NULLIF(TO_CHAR(SUM(SUM(supplier_contract_amount_usd)) OVER (PARTITION BY project_id), '999,999,999,999.99'), '') as project_total,
    TO_CHAR(
        (SUM(supplier_contract_amount_usd) * 100.0 / 
        NULLIF(SUM(SUM(supplier_contract_amount_usd)) OVER (PARTITION BY project_id), 0))::NUMERIC,
        '999.99'
    ) || '%' as percentage_of_project
FROM wb_contract_awards
WHERE 
    borrower_country = 'Madagascar'
GROUP BY 
    project_id, 
    supplier_country
ORDER BY
    project_id DESC,
    supplier_country DESC