SELECT 
	execution_type,
	fiscal_year,
	fund_classification,
	TO_CHAR(new_commitments_us, '999,999,999,999.99') AS new_commitments_usd,
	program_group,
	trust_fund,
	trust_fund_name,
	trust_fund_status,
	trustee,
	trustee_name,
	trustee_status,
	as_of_date
FROM wb_trust_fund_commitments
WHERE
	trust_fund_name ILIKE '%Global Environment Facility%'
ORDER BY
	new_commitments_us
