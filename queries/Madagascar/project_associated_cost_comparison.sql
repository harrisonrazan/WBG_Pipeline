WITH contract_totals AS (
    SELECT 
        project_id,
        SUM(supplier_contract_amount_usd) as project_total
    FROM wb_contract_awards
    WHERE borrower_country = 'Madagascar'
    GROUP BY project_id
),
project_list AS (
    SELECT 
        project_id,
        associated_project,
        current_project_cost,
        ibrd_commitment,
        ida_commitment,
        grant_amount,
        total_ibrd_ida_and_grant_commitment
    FROM wb_projects
    WHERE country = 'Madagascar'
)
SELECT
    TO_CHAR(CAST(agreement_signing_date AS TIMESTAMP), 'YYYY-MM-DD') AS agreement_signing_date,
    cs.project_id,
    credit_number,
    pl.associated_project,
    cs.project_name,
    cs.borrower,
    -- NULLIF(TO_CHAR(pl.ibrd_commitment, '999,999,999,999.99'), '') AS pl_ibrd_commitment,
    NULLIF(TO_CHAR(pl.ida_commitment, '999,999,999,999.99'), '') AS pl_ida_commitment,
    NULLIF(TO_CHAR(pl.grant_amount, '999,999,999,999.99'), '') AS pl_grant_amount,
    NULLIF(TO_CHAR(pl.current_project_cost, '999,999,999,999.99'), '') AS pl_current_project_cost,
    NULLIF(TO_CHAR(pl.total_ibrd_ida_and_grant_commitment, '999,999,999,999.99'), '') AS pl_total_ibrd_ida_and_grant_commitment,
    NULLIF(TO_CHAR(ct.project_total, '999,999,999,999.99'), '') AS ct_contract_awards_total,
    NULLIF(TO_CHAR(disbursed_amount_us_, '999,999,999,999.99'), '') AS disbursed_amount_usd,
    NULLIF(TO_CHAR(undisbursed_amount_us_, '999,999,999,999.99'), '') AS undisbursed_amount_usd,
    NULLIF(TO_CHAR(cancelled_amount_us_, '999,999,999,999.99'), '') AS cancelled_amount_usd,
    NULLIF(TO_CHAR(original_principal_amount_us_, '999,999,999,999.99'), '') AS original_principal_amount_usd,
    NULLIF(TO_CHAR(borrowers_obligation_us_, '999,999,999,999.99'), '') AS borrowers_obligation_usd,
    NULLIF(TO_CHAR(credits_held_us_, '999,999,999,999.99'), '') AS credits_held_usd,
    -- NULLIF(TO_CHAR(total_repayment, '999,999,999,999.99'), '') AS total_repayment,
    -- NULLIF(TO_CHAR(exchange_adjustment_us_, '999,999,999,999.99'), '') AS exchange_adjustment_usd,
    -- NULLIF(TO_CHAR(due_to_ida_us_, '999,999,999,999.99'), '') AS due_to_ida_usd,
    -- NULLIF(TO_CHAR(repaid_to_ida_us_, '999,999,999,999.99'), '') AS repaid_to_ida_usd,
    -- NULLIF(TO_CHAR(due_3rd_party_us_, '999,999,999,999.99'), '') AS due_3rd_party_usd,
    -- NULLIF(TO_CHAR(repaid_3rd_party_us_, '999,999,999,999.99'), '') AS repaid_3rd_party_usd,
    -- NULLIF(TO_CHAR(sold_3rd_party_us_, '999,999,999,999.99'), '') AS sold_3rd_party_usd,
    -- TO_CHAR(board_approval_date, 'YYYY-MM-DD') AS board_approval_date,
    -- TO_CHAR(last_disbursement_date, 'YYYY-MM-DD') AS last_disbursement_date,
    -- TO_CHAR(first_repayment_date, 'YYYY-MM-DD') AS first_repayment_date,
    -- TO_CHAR(last_repayment_date, 'YYYY-MM-DD') AS last_repayment_date,
    -- TO_CHAR(closed_date_most_recent, 'YYYY-MM-DD') AS closed_date_most_recent,
    -- TO_CHAR(effective_date_most_recent, 'YYYY-MM-DD') AS effective_date_most_recent,
    -- TO_CHAR(end_of_period, 'YYYY-MM-DD') AS end_of_period,
    service_charge_rate,
    -- repayment_rate,
    credit_status,
    -- currency_of_commitment,
    TO_CHAR(as_of_date, 'YYYY-MM-DD') AS processed_at
FROM wb_credit_statements cs
LEFT JOIN contract_totals ct ON cs.project_id = ct.project_id
LEFT JOIN project_list pl ON cs.project_id = pl.project_id
WHERE country = 'Madagascar'
ORDER BY agreement_signing_date DESC;