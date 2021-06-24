
--This takes the sport page name and gets a nice title
set search_path TO 'central_insights_sandbox';
-- get a table with all the page names and the cleaned up titles
-- the row number can be used to select only the most popular name if needed
DROP TABLE IF EXISTS vb_nice_page_names;
CREATE  TABLE vb_nice_page_names
(
  page_name     VARCHAR(200),
  cps_id               VARCHAR(200) DISTKEY,
  page_title    VARCHAR(200),
  content_type         VARCHAR(100),
  page_section         VARCHAR(100),
  page_subsection      VARCHAR(100),
  page_subsubsection   VARCHAR(100),
  count_id             INT4,
  row_num INT
);
INSERT INTO vb_nice_page_names
with regex as (
    (SELECT
            REGEXP_REPLACE(REGEXP_REPLACE(page_name,'-',' '),'other::homepage::sport.app.page','other::homepage::sport.page') AS page_name,
             COALESCE(NULLIF(REGEXP_SUBSTR(page_name, '\\d{8}'),''), page_name)::VARCHAR(100) AS cps_id_all_fixtures,
             CASE WHEN cps_id_all_fixtures ~ '^.*fixtures.\\d+.*' THEN REGEXP_REPLACE(cps_id_all_fixtures, 'fixtures.\\d+.*', 'fixtures.page')
                  WHEN cps_id_all_fixtures = 'other::homepage::sport.app.page' THEN REGEXP_REPLACE(cps_id_all_fixtures, 'other::homepage::sport.app.page', 'other::homepage::sport.page')
                  ELSE cps_id_all_fixtures
              END AS cps_id,
             -- Replace underscores in titles with spaces and remove ' - BBC Sport' suffix:
             REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(page_title,'_',' '),' - BBC Sport',''),'&','$') AS page_title,
             REGEXP_REPLACE(REGEXP_REPLACE(content_type,'oppm','article'),'index-section','index-home') AS content_type,
             REGEXP_REPLACE(page_section,'-','_') AS page_section,
             REGEXP_REPLACE(page_subsection,'-','_') AS page_subsection,
             REGEXP_REPLACE(page_subsubsection,'-','_') AS page_subsubsection,
             COUNT(DISTINCT unique_visitor_cookie_id) AS count_id,
             -- Number the rows for each page_name, with row_num = 1
             -- corresponding to the most common page_title:
             ROW_NUMBER() OVER (PARTITION BY cps_id ORDER BY count_id DESC) AS row_num
      FROM s3_audience.audience_activity
      WHERE (destination = 'PS_SPORT') --OR (destination = 'PS_NEWS' AND page_name LIKE '%sport.%' AND page_name NOT LIKE '%.sport.%'))
      AND   LOWER(geo_country_site_visited) = 'united kingdom'
      AND   dt BETWEEN (SELECT replace(min_date,'-','') FROM vb_dates) AND (SELECT replace(max_date,'-','') FROM vb_dates)
      GROUP BY page_name,
               page_title,
               content_type,
               page_section,
               page_subsection,
               page_subsubsection
      ORDER BY page_name)
)
SELECT page_name::VARCHAR(200) AS page_name,
       cps_id::VARCHAR(100),
       page_title::VARCHAR(100) AS page_title,
       content_type::VARCHAR(100),
       page_section::VARCHAR(100),
       page_subsection::VARCHAR(100),
       page_subsubsection::VARCHAR(100),
       count_id,
       row_num
FROM regex
--WHERE count_id >=1000 --remove any weird titles that look like mistakes
--WHERE row_num = 1
;

SELECT * FROM vb_nice_page_names  LIMIT 500;

DROP TABLE If EXISTS vb_dist_page_names;
CREATE TABLE vb_dist_page_names AS
with dup_check AS (
    SELECT distinct page_name,
                    page_title,
                    count_id,
                    row_number() over (partition by page_name order by count_id DESC) as row_count
    FROM vb_nice_page_names)
SELECT page_name, page_title
FROM dup_check
WHERE row_count = 1;






