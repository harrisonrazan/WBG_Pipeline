SELECT 
	countries,
	title,
	id,
	focal_areas,
	type,
	agencies,
	gef_grant,
	cofinancing,
	status,
	approval_fy,
	funding_source_indexed_field,
	non_grant_instrument_indexed_field,
	capacity_building_initiative_for_transparency,
	gef_period,
	as_of_date
FROM gef_projects
WHERE
-- 	id = '9457'
	countries ILIKE '%Madagascar%'
	-- AND agencies ILIKE '%world bank%'
ORDER BY
	-- id desc
	-- title,
	-- CAST(REPLACE(cofinancing, ',', '') AS NUMERIC) DESC,
	CAST(REPLACE(gef_grant, ',', '') AS NUMERIC)
	-- approval_fy desc,
	-- gef_period desc
	
