SELECT
	project_id,
	project_id_url,
	associated_project,
	region,
	country,
	project_status,
	-- last_stage_reached_name,
	project_name,
	-- project_development_objective ,
	implementing_agency,
	TO_CHAR(public_disclosure_date, 'YYYY-MM-DD') AS public_disclosure_date,
	TO_CHAR(board_approval_date, 'YYYY-MM-DD') AS board_approval_date,
	TO_CHAR(loan_effective_date, 'YYYY-MM-DD') AS loan_effective_date,
	TO_CHAR(project_closing_date, 'YYYY-MM-DD') AS project_closing_date,
	NULLIF(TO_CHAR(current_project_cost, '999,999,999,999.99'), '') AS current_project_cost,
	NULLIF(TO_CHAR(ibrd_commitment, '999,999,999,999.99'), '') AS ibrd_commitment,
	NULLIF(TO_CHAR(ida_commitment, '999,999,999,999.99'), '') AS ida_commitment,
	NULLIF(TO_CHAR(grant_amount, '999,999,999,999.99'), '') AS grant_amount,
	NULLIF(TO_CHAR(total_ibrd_ida_and_grant_commitment, '999,999,999,999.99'), '') AS total_ibrd_ida_and_grant_commitment,
	borrower,
	lending_instrument,
	environmental_assessment_category,
	environmental_and_social_risk,
	consultant_services_required,
	financing_type
FROM wb_projects
-- WHERE
-- 	country = 'Madagascar'
-- 	or borrower ILIKE '%Madagascar%'
	-- project_id = 'P181398'
ORDER BY
	-- project_ID
	implementing_agency
