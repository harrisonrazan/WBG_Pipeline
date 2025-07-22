DO $$
DECLARE
    pivot_columns text;
    pivot_query text;
BEGIN
    -- Create temporary table to store results
    DROP TABLE IF EXISTS temp_pivot_results;
    
    -- Generate the column list dynamically
    SELECT string_agg(
        format(
            'MAX(CASE WHEN supplier_country = %L THEN percentage END) as %I',
            supplier_country,
            supplier_country
        ),
        ', '
    )
    INTO pivot_columns
    FROM (
        SELECT DISTINCT supplier_country 
        FROM wb_contract_awards 
        WHERE borrower_country = 'Madagascar'
        ORDER BY supplier_country DESC
    ) sc;

    -- Construct the full pivot query with CREATE TABLE
    pivot_query := format(
        'CREATE TEMP TABLE temp_pivot_results AS
        WITH base_totals AS (
            SELECT 
                project_id,
                supplier_country,
                SUM(supplier_contract_amount_usd) as country_amount
            FROM wb_contract_awards
            WHERE borrower_country = ''Madagascar''
            GROUP BY project_id, supplier_country
        ),
        with_percentages AS (
            SELECT 
                project_id,
                supplier_country,
                TO_CHAR(
                    (country_amount * 100.0 / 
                    NULLIF(SUM(country_amount) OVER (PARTITION BY project_id), 0))::NUMERIC,
                    ''999.99''
                ) || ''%%'' as percentage
            FROM base_totals
        )
        SELECT 
            project_id,
            %s
        FROM with_percentages
        GROUP BY project_id
        ORDER BY project_id DESC',
        pivot_columns
    );

    -- Execute the CREATE TABLE query
    EXECUTE pivot_query;
END $$;

-- Query the results
SELECT * FROM temp_pivot_results;