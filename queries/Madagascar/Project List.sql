SELECT
	-- TO_CHAR(supplier_contract_amount_usd, '999,999,999,999.99') as supplier_contract_amount_formatted,
	"Project ID",
	"Associated Project",
	-- "Region",
	-- "Country",
	"Project Status",
	"Last Stage Reached Name",
	"Project Name",
	"Project Development Objective ",
	"Implementing Agency",
	TO_CHAR("Public Disclosure Date", 'YYYY-MM-DD') AS "Public Disclosure Date",
	TO_CHAR("Board Approval Date", 'YYYY-MM-DD') AS "Board Approval Date",
	TO_CHAR("Loan Effective Date", 'YYYY-MM-DD') AS "Loan Effective Date",
	TO_CHAR("Project Closing Date", 'YYYY-MM-DD') AS "Project Closing Date",
	NULLIF(TO_CHAR("Current Project Cost", '999,999,999,999.99'), '') AS "Current Project Cost",
	NULLIF(TO_CHAR("IBRD Commitment", '999,999,999,999.99'), '') AS "IBRD Commitment",
	NULLIF(TO_CHAR("IDA Commitment", '999,999,999,999.99'), '') AS "IDA Commitment",
	NULLIF(TO_CHAR("Grant Amount", '999,999,999,999.99'), '') AS "Grant Amount",
	NULLIF(TO_CHAR("Total IBRD, IDA and Grant Commitment", '999,999,999,999.99'), '') AS "Total IBRD, IDA and Grant Commitment",
	"Borrower",
	"Lending Instrument",
	"Environmental Assessment Category",
	"Environmental and Social Risk",
	"Consultant Services Required",
	"Financing Type"
FROM wb_projects
WHERE
	"Country" = 'Madagascar'
ORDER BY
	-- "Project ID"
	"Borrower"