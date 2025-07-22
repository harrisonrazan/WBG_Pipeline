SELECT
	region,
	country,
	-- country_code,
	TO_CHAR(CAST(agreement_signing_date AS TIMESTAMP), 'YYYY-MM-DD') AS agreement_signing_date,
	project_id,
	credit_number,
	project_name,
	borrower,
	NULLIF(TO_CHAR(original_principal_amount_us, '999,999,999,999.99'), '') AS original_principal_amount_usd,
	NULLIF(TO_CHAR(disbursed_amount_us, '999,999,999,999.99'), '') AS disbursed_amount_usd,
	NULLIF(TO_CHAR(undisbursed_amount_us, '999,999,999,999.99'), '') AS undisbursed_amount_usd,
	NULLIF(TO_CHAR(cancelled_amount_us, '999,999,999,999.99'), '') AS cancelled_amount_usd,
	NULLIF(TO_CHAR(borrowers_obligation_us, '999,999,999,999.99'), '') AS borrowers_obligation_usd,
	NULLIF(TO_CHAR(credits_held_us, '999,999,999,999.99'), '') AS credits_held_usd,
	-- NULLIF(TO_CHAR(total_repayment, '999,999,999,999.99'), '') AS total_repayment,
	NULLIF(TO_CHAR(exchange_adjustment_us, '999,999,999,999.99'), '') AS exchange_adjustment_usd,
	NULLIF(TO_CHAR(due_to_ida_us, '999,999,999,999.99'), '') AS due_to_ida_usd,
	NULLIF(TO_CHAR(repaid_to_ida_us, '999,999,999,999.99'), '') AS repaid_to_ida_usd,
	NULLIF(TO_CHAR(due_3rd_party_us, '999,999,999,999.99'), '') AS due_3rd_party_usd,
	NULLIF(TO_CHAR(repaid_3rd_party_us, '999,999,999,999.99'), '') AS repaid_3rd_party_usd,
	NULLIF(TO_CHAR(sold_3rd_party_us, '999,999,999,999.99'), '') AS sold_3rd_party_usd,
	TO_CHAR(CAST(board_approval_date AS TIMESTAMP), 'YYYY-MM-DD') AS board_approval_date,
	TO_CHAR(CAST(last_disbursement_date AS TIMESTAMP), 'YYYY-MM-DD') AS last_disbursement_date,
	TO_CHAR(CAST(first_repayment_date AS TIMESTAMP), 'YYYY-MM-DD') AS first_repayment_date,
	TO_CHAR(CAST(last_repayment_date AS TIMESTAMP), 'YYYY-MM-DD') AS last_repayment_date,
	TO_CHAR(CAST(closed_date_most_recent AS TIMESTAMP), 'YYYY-MM-DD') AS closed_date_most_recent,
	TO_CHAR(CAST(effective_date_most_recent AS TIMESTAMP), 'YYYY-MM-DD') AS effective_date_most_recent,
	TO_CHAR(CAST(end_of_period AS TIMESTAMP), 'YYYY-MM-DD') AS end_of_period,
	service_charge_rate,
	-- repayment_rate,
	credit_status,
	currency_of_commitment,
	TO_CHAR(as_of_date, 'YYYY-MM-DD') AS as_of_date
FROM wb_credit_statements
WHERE
	credit_number ILIKE 'IDAB%'
	OR credit_number ILIKE 'IDAG%'
ORDER BY
	-- project_id,
	agreement_signing_date Desc