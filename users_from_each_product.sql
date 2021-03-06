set search_path TO 'central_insights_sandbox';

-- Date table to make it easier to switch dates

DROP TABLE IF EXISTS vb_dates;
CREATE TABLE vb_dates (
    max_date date,
    min_date date
);
INSERT INTO vb_dates values ('2021-06-17', '2021-06-11');

--- Users going to iPlayer and visiting euros content
DROP TABLE IF EXISTS vb_euros_iplayer;
CREATE TABLE vb_euros_iplayer as
SELECT DISTINCT audience_id,
                CASE
                    WHEN age_range IN ('0-5', '6-10', '11-15') THEN 'Under 16'
                    WHEN age_range IN ('16-19', '20-24', '25-29', '30-34') THEN '16 to 34'
                    WHEN age_range IN ('35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '65-70', '>70')
                        THEN 'Over 35'
                    ELSE NULL END                         AS age_group,
                CASE WHEN programme_title!= episode_title THEN programme_title || ' - ' || episode_title  ELSE programme_title END as programme_title
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_IPLAYER'
  AND date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates)
  AND LENGTH(audience_id) = 43
  AND pips_genre_level_1_names ILIKE 'Sport%'
  AND (programme_title ILIKE '%Euro 2020%' OR programme_title = 'Cristiano Ronaldo: Impossible to Ignore' OR
       programme_title = 'Roberto Martinez: Whistle to Whistle')
;
SELECT count(distinct audience_id) FROM vb_euros_iplayer;--5,261,821
SELECT programme_title, count(*)
FROM vb_euros_iplayer GROUP BY 1 ORDER BY  2 DESC;

--- Users going to Sounds and visiting euros content
DROP TABLE IF EXISTS vb_euros_sounds;
CREATE TABLE vb_euros_sounds as
SELECT DISTINCT audience_id,
       CASE
           WHEN age_range IN ('0-5', '6-10', '11-15') THEN 'Under 16'
           WHEN age_range IN ('16-19', '20-24', '25-29', '30-34') THEN '16 to 34'
           WHEN age_range IN ('35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '65-70', '>70')
               THEN 'Over 35'
           ELSE NULL END AS age_group,
                programme_title
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_SOUNDS'
  AND date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates)
  AND LENGTH(audience_id) = 43
  and (episode_title ILIKE '%euro%' OR series_title ILIKE '%euro%' OR brand_title ILIKE '%euro%' OR
       programme_title ILIKE '%euro%')
  AND programme_title NOT ILIKE '%Euro Leagues%'
  AND programme_title NOT ILIKE '%Europa League%'
  AND programme_title NOT ILIKE '%European%'
  AND episode_title NOT ILIKE '%European%'
  AND programme_title NOT ILIKE '%Women???s Euro 2022%'
  AND pips_genre_level_1_names ILIKE '%Sport%'
;
SELECT count(distinct audience_id) FROM vb_euros_sounds;-- 519,482



--- Sport users
DROP TABLE IF EXISTS vb_euros_sport;
CREATE TABLE vb_euros_sport as
SELECT DISTINCT audience_id,
                CASE
                    WHEN age_range IN ('0-5', '6-10', '11-15') THEN 'Under 16'
                    WHEN age_range IN ('16-19', '20-24', '25-29', '30-34') THEN '16 to 34'
                    WHEN age_range IN ('35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '65-70', '>70')
                        THEN 'Over 35'
                    ELSE NULL END AS age_group,
                CASE WHEN programme_title!= episode_title and episode_title IS NOT NULL and episode_title!='null'  THEN programme_title || ' - ' || episode_title  ELSE programme_title END as programme_title,
                REGEXP_REPLACE(REGEXP_REPLACE(a.page_name,'-',' '),'other::homepage::sport.app.page','other::homepage::sport.page') AS page_name,
                b.page_title
FROM audience.audience_activity_daily_summary_enriched a
LEFT JOIN vb_dist_page_names b on a.page_name = b.page_name
WHERE destination = 'PS_SPORT'
  AND date_of_event BETWEEN (SELECT min_date FROM central_insights_sandbox.vb_dates) AND (SELECT max_date FROM central_insights_sandbox.vb_dates)
  AND LENGTH(audience_id) = 43
  AND (((episode_title ILIKE '%euro%' OR series_title ILIKE '%euro%' OR brand_title ILIKE '%euro%' OR
         programme_title ILIKE '%euro%')
    AND programme_title NOT ILIKE '%Euro Leagues%'
    AND programme_title NOT ILIKE '%Europa League%'
    AND programme_title NOT ILIKE '%European%'
    AND episode_title NOT ILIKE '%European%'
    AND pips_genre_level_1_names ILIKE '%Sport%')
    OR
       a.page_name ILIKE '%football.european_championship%'
    OR a.page_name ILIKE 'sport.football.page')
;

ALTER TABLE vb_euros_sport ADD COLUMN title varchar(4000);
ALTER TABLE vb_euros_sport ADD COLUMN content_type varchar(4000);

UPDATE vb_euros_sport SET content_type = CASE WHEN programme_title IS NOT NULL THEN 'AV' ELSE 'page' END;
UPDATE vb_euros_sport SET title = CASE WHEN programme_title IS NOT NULL THEN programme_title ELSE page_title END;

ALTER TABLE vb_euros_sport DROP COLUMN programme_title;
ALTER TABLE vb_euros_sport DROP COLUMN page_name;
ALTER TABLE vb_euros_sport DROP COLUMN page_title;


SELECT * FROM vb_euros_sport WHERE title ISNULL ORDER BY random() LIMIT 100;
SELECT count(*) FROM vb_euros_sport WHERE title ISNULL ORDER BY random() LIMIT 100;

SELECT count(distinct audience_id) FROM vb_euros_sport;--5,516,102
SELECT count(*) FROM vb_euros_sport;--47,128,585


-- Get all users seen to join all the others onto
DROP TABLE IF EXISTS vb_euros_all_users;
CREATE TABLE vb_euros_all_users AS
SELECT distinct audience_id,
                CASE
                    WHEN age_range IN ('0-5', '6-10', '11-15') THEN 'Under 16'
                    WHEN age_range IN ('16-19', '20-24', '25-29', '30-34') THEN '16 to 34'
                    WHEN age_range IN
                         ('35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '65-70', '>70')
                        THEN 'Over 35'
                    ELSE NULL END AS age_group,
                programme_title
FROM audience.audience_activity_daily_summary_enriched
WHERE date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates);

SELECT count(distinct audience_id) FROM vb_euros_all_users;--21,024,659

--- Who is in which group?
DROP TABLE IF EXISTS vb_euros_crossover;
CREATE TABLE vb_euros_crossover AS
with all_hids as (SELECT distinct audience_id, age_group FROM vb_euros_all_users),
     iplayer as (SELECT distinct audience_id, cast(1 as boolean) as iplayer FROM vb_euros_iplayer),
     sounds as (SELECT distinct audience_id, cast(1 as boolean) as sounds FROM vb_euros_sounds),
     sport as (SELECT distinct audience_id, cast(1 as boolean) as sport FROM vb_euros_sport)
SELECT
       a.audience_id,
       a.age_group,
       isnull(iplayer,FALSE) as iplayer,
       isnull(sounds,FALSE) as sounds,
       isnull(sport,FALSE) as sport
FROM all_hids a
         LEFT JOIN iplayer b ON a.audience_id = b.audience_id
         LEFT JOIN sounds c on a.audience_id = c.audience_id
         LEFT JOIN sport d on a.audience_id = d.audience_id
ORDER BY a.audience_id
;
--Categorise users based on the products they use
ALTER TABLE  vb_euros_crossover
    add products_used varchar(40);
UPDATE vb_euros_crossover
set products_used = CASE
                        WHEN sport = TRUE AND iplayer = TRUE AND sounds = TRUE THEN '1_all'
                        WHEN sport = TRUE AND iplayer = TRUE AND sounds = FALSE THEN '2_sport_iplayer'
                        WHEN sport = TRUE AND iplayer = FALSE AND sounds = TRUE THEN '3_sport_sounds'
                        WHEN sport = FALSE AND iplayer = TRUE AND sounds = TRUE THEN '4_iplayer_sounds'
                        WHEN sport = TRUE AND iplayer = FALSE AND sounds = FALSE THEN '5_sport_only'
                        WHEN sport = FALSE AND iplayer = TRUE AND sounds = FALSE THEN '6_iplayer_only'
                        WHEN sport = FALSE AND iplayer = FALSE AND sounds = TRUE THEN '7_sounds_only'
                        ELSE '8'
    END;
-- Check product split
SELECT products_used, count(distinct audience_id) FROM vb_euros_crossover GROUP BY 1 ORDER BY 1;
--Remove people who went to no product
DELETE FROM vb_euros_crossover WHERE products_used = '8';

SELECT *  FROM vb_euros_crossover ORDER BY audience_id limit 10;

SELECT count(distinct audience_id) FROM vb_euros_crossover;--9,356,653

-- See what combination of products are used for people who consumed Euros on at least one platform
SELECT products_used,
       sport,
       iplayer,
       sounds,
       count(distinct audience_id) as users,
       round(100 * users::double precision / (SELECT count(*)
                                              FROM vb_euros_crossover
                                              WHERE (iplayer = TRUE OR sounds = TRUE or sport = TRUE) )::double precision,
             1)                    as perc
FROM vb_euros_crossover
WHERE (iplayer = TRUE
   OR sounds = TRUE
   or sport = TRUE)
--AND age_group = '16 to 34'
GROUP BY 1, 2, 3, 4
ORDER BY products_used
;

-- Check what the split is for all users, not just those to the euros content
DROP TABLE IF EXISTS vb_euros_crossover_test;
CREATE TABLE vb_euros_crossover_test AS
with all_hids as (SELECT distinct audience_id, age_group FROM vb_euros_all_users),
     iplayer as (SELECT distinct audience_id, cast(1 as boolean) as iplayer FROM audience.audience_activity_daily_summary_enriched WHERE date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates) and destination = 'PS_IPLAYER'),
     sounds as (SELECT distinct audience_id, cast(1 as boolean) as sounds FROM audience.audience_activity_daily_summary_enriched WHERE date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates) and destination = 'PS_SOUNDS'),
     sport as (SELECT distinct audience_id, cast(1 as boolean) as sport FROM audience.audience_activity_daily_summary_enriched WHERE date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates) and destination = 'PS_SPORT')
SELECT a.audience_id,
       a.age_group,
       isnull(iplayer,FALSE) as iplayer,
       isnull(sounds,FALSE) as sounds,
       isnull(sport,FALSE) as sport
FROM all_hids a
         LEFT JOIN iplayer b ON a.audience_id = b.audience_id
         LEFT JOIN sounds c on a.audience_id = c.audience_id
         LEFT JOIN sport d on a.audience_id = d.audience_id
ORDER BY a.audience_id
;
--Categorise users based on the products they use
ALTER TABLE  vb_euros_crossover_test
    add products_used varchar(40);
UPDATE vb_euros_crossover_test
set products_used = CASE
                        WHEN sport = TRUE AND iplayer = TRUE AND sounds = TRUE THEN '1_all'
                        WHEN sport = TRUE AND iplayer = TRUE AND sounds = FALSE THEN '2_sport_iplayer'
                        WHEN sport = TRUE AND iplayer = FALSE AND sounds = TRUE THEN '3_sport_sounds'
                        WHEN sport = FALSE AND iplayer = TRUE AND sounds = TRUE THEN '4_iplayer_sounds'
                        WHEN sport = TRUE AND iplayer = FALSE AND sounds = FALSE THEN '5_sport_only'
                        WHEN sport = FALSE AND iplayer = TRUE AND sounds = FALSE THEN '6_iplayer_only'
                        WHEN sport = FALSE AND iplayer = FALSE AND sounds = TRUE THEN '7_sounds_only'
                        ELSE '8'
    END;
-- Check product split
SELECT products_used, count(distinct audience_id) FROM vb_euros_crossover_test GROUP BY 1 ORDER BY 1;
--Remove people who went to no product
DELETE FROM vb_euros_crossover_test WHERE products_used = '8';

SELECT products_used,
       sport,
       iplayer,
       sounds,
       count(distinct audience_id) as users,
       round(100 * users::double precision / (SELECT count(*)
                                              FROM vb_euros_crossover_test
                                              WHERE (iplayer = TRUE OR sounds = TRUE or sport = TRUE) AND age_group = '16 to 34')::double precision,
             1)                    as perc
FROM vb_euros_crossover_test
WHERE (iplayer = TRUE
   OR sounds = TRUE
   or sport = TRUE)
AND age_group = '16 to 34'
GROUP BY 1, 2, 3, 4
ORDER BY products_used
;

--top_level_editorial_object
SELECT distinct date_of_event FROM audience.audience_activity_daily_summary_enriched
WHERE date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates);

--- Find the top items for users in each group

SELECT a.products_used,b.programme_title as iplayer_title, count(distinct a.audience_id) as users
FROM vb_euros_crossover a
         LEFT JOIN vb_euros_iplayer b on a.audience_id = b.audience_id
WHERE products_used = '2_sport_iplayer'
GROUP BY 1,2
ORDER BY users DESC;


SELECT count(*) FROM vb_euros_crossover;


-- Get all the titles
--- iplayer
SELECT CASE
           WHEN programme_title != episode_title THEN programme_title || ' - ' || episode_title
           ELSE programme_title END as programme_title,
       brand_title,
       series_title,
       episode_title,
       count(distinct audience_id)
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_IPLAYER'
  AND date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates)
  AND LENGTH(audience_id) = 43
  AND pips_genre_level_1_names ILIKE 'Sport%'
  AND (programme_title ILIKE '%Euro 2020%' OR programme_title = 'Cristiano Ronaldo: Impossible to Ignore' OR
       programme_title = 'Roberto Martinez: Whistle to Whistle')
GROUP BY 1,2,3,4
ORDER BY 1
;
--Sounds
SELECT programme_title,
       brand_title,
       series_title,
       episode_title,
       count(distinct audience_id)
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_SOUNDS'
  AND date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates)
  AND LENGTH(audience_id) = 43
  and (episode_title ILIKE '%euro%' OR series_title ILIKE '%euro%' OR brand_title ILIKE '%euro%' OR
       programme_title ILIKE '%euro%')
  AND programme_title NOT ILIKE '%Euro Leagues%'
  AND programme_title NOT ILIKE '%Europa League%'
  AND programme_title NOT ILIKE '%European%'
  AND episode_title NOT ILIKE '%European%'
  AND programme_title NOT ILIKE '%Women???s Euro 2022%'
  AND pips_genre_level_1_names ILIKE '%Sport%'
GROUP BY 1,2,3,4
ORDER BY 1
;


--Sport AV content
SELECT programme_title,
       brand_title,
       series_title,
       episode_title,
       count(distinct audience_id)
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_SPORT'
  AND date_of_event BETWEEN (SELECT min_date FROM central_insights_sandbox.vb_dates) AND (SELECT max_date FROM central_insights_sandbox.vb_dates)
  AND LENGTH(audience_id) = 43
  AND (((episode_title ILIKE '%euro%' OR series_title ILIKE '%euro%' OR brand_title ILIKE '%euro%' OR
         programme_title ILIKE '%euro%')
    AND programme_title NOT ILIKE '%Euro Leagues%'
    AND programme_title NOT ILIKE '%Europa League%'
    AND programme_title NOT ILIKE '%European%'
    AND episode_title NOT ILIKE '%European%'
    AND pips_genre_level_1_names ILIKE '%Sport%')
    OR
       page_name ILIKE '%football.european_championship%'
      OR page_name ILIKE 'sport.football.page')
GROUP BY 1,2,3,4
ORDER BY 1
;

-- Sport pages
SELECT a.cps_id, a.page_title, a.page_section, count(distinct audience_id) as users
FROM vb_nice_page_names a
         LEFT JOIN audience.audience_activity_daily_summary_enriched b on a.page_name = b.page_name
WHERE b.destination = 'PS_SPORT'
  AND b.date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates)
  AND LENGTH(b.audience_id) = 43
  AND (a.page_name ILIKE '%football.european_championship%'
    OR a.page_name ILIKE 'sport.football.page')
GROUP BY 1, 2, 3
ORDER BY 4 desc;

--The whole sport file is large to take into R. Need to only select the items likely to come out top
DROP TABLE vb;
CREATE temp table vb as
with top_content as (
    SELECT content_type, title, count(distinct audience_id) as users
    FROM central_insights_sandbox.vb_euros_sport
    GROUP BY 1, 2
    HAVING users > 10000
    ORDER BY 3 DESC)
SELECT a.*
FROM central_insights_sandbox.vb_euros_sport a
         INNER JOIN top_content b on a.title = b.title
;
SELECT count(*) from vb;--46,959,916

--LIMIT 10;--47,128,585

---- Pre group the data so it's easier to go into R
DROP TABLE IF EXISTS vb_euros_sport_grouped;
CREATE TABLE vb_euros_sport_grouped AS
with data_joined as (
    SELECT a.audience_id, a.age_group, a.products_used, b.content_type || ' - ' || b.title as title
    FROM vb_euros_crossover a
             INNER JOIN vb_euros_sport b on a.audience_id = b.audience_id and a.age_group = b.age_group
)
SELECT products_used, title, count(audience_id) as users
FROM data_joined
GROUP BY 1,2
ORDER BY users DESC
;

-- FA Cup 2021 - We want to include the date range 10th May - 16th May