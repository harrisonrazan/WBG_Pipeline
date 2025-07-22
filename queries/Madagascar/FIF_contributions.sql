SELECT 
    as_of_date,
    fund_name,
    donor_name,
    donor_country_code,
    receipt_type,
    receipt_quarter,
    calendar_year,
    receipt_currency,
    receipt_amount,
    contribution_type,
    sub_account,
    amount_in_usd,
    sectortheme
FROM wb_financial_intermediary_funds_contributions
-- WHERE
-- 	fund_name ILIKE '%Global Environment Facility%'
-- ORDER BY
-- 	as_of_date
	