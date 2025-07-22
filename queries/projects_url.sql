SELECT 
	project_id, 
	project_id_url,
	associated_project
FROM public.wb_projects
-- WHERE
-- 	project_id_url is NULL
-- 	associated_project = 'N'
ORDER BY
project_id DESC
	