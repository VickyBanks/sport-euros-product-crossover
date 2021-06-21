set search_path TO 'central_insights_sandbox';

--- Users going to iPlayer and visiting euros content
DROP TABLE IF EXISTS vb_euros_iplayer;
CREATE TABLE vb_euros_iplayer as
SELECT DISTINCT audience_id,
                CASE
                    WHEN age_range IN ('0-5', '6-10', '11-15') THEN 'Under 16'
                    WHEN age_range IN ('16-19', '20-24', '25-29', '30-34') THEN '16 to 34'
                    WHEN age_range IN ('35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '65-70', '>70')
                        THEN 'Over 35'
                    ELSE NULL END AS age_group
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_IPLAYER'
  AND date_of_event BETWEEN '2021-06-11' AND '2021-06-17'
  AND LENGTH(audience_id) = 43
  AND pips_genre_level_1_names ILIKE 'Sport%'
  AND programme_title ILIKE '%Euro 2020%'
;
SELECT count(*) FROM vb_euros_iplayer;--5,261,821

--- Users going to iPlayer and visiting euros content
DROP TABLE IF EXISTS vb_euros_sounds;
CREATE TABLE vb_euros_sounds as
SELECT DISTINCT audience_id,
       CASE
           WHEN age_range IN ('0-5', '6-10', '11-15') THEN 'Under 16'
           WHEN age_range IN ('16-19', '20-24', '25-29', '30-34') THEN '16 to 34'
           WHEN age_range IN ('35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '65-70', '>70')
               THEN 'Over 35'
           ELSE NULL END AS age_group
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_SOUNDS'
  AND date_of_event BETWEEN '2021-06-11' AND '2021-06-17'
  AND LENGTH(audience_id) = 43
  and (episode_title ILIKE '%euro%' OR series_title ILIKE '%euro%' OR brand_title ILIKE '%euro%' OR
       programme_title ILIKE '%euro%')
  AND programme_title NOT ILIKE '%Euro Leagues%'
  AND programme_title NOT ILIKE '%Europa League%'
  AND programme_title NOT ILIKE '%European%'
  AND episode_title NOT ILIKE '%European%'
  AND programme_title NOT ILIKE '%Women’s Euro 2022%'
  AND pips_genre_level_1_names ILIKE '%Sport%'
;
SELECT count(*) FROM vb_euros_sounds;--2,074,023



--- Sport users
DROP TABLE IF EXISTS vb_euros_sport;
CREATE TABLE vb_euros_sport as
SELECT DISTINCT audience_id,
                CASE
                    WHEN age_range IN ('0-5', '6-10', '11-15') THEN 'Under 16'
                    WHEN age_range IN ('16-19', '20-24', '25-29', '30-34') THEN '16 to 34'
                    WHEN age_range IN ('35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '65-70', '>70')
                        THEN 'Over 35'
                    ELSE NULL END AS age_group
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_SPORT'
  AND date_of_event BETWEEN '2021-06-11' AND '2021-06-17'
  AND LENGTH(audience_id) = 43
  and (episode_title ILIKE '%euro%' OR series_title ILIKE '%euro%' OR brand_title ILIKE '%euro%' OR
       programme_title ILIKE '%euro%')
  AND programme_title NOT ILIKE '%Euro Leagues%'
  AND programme_title NOT ILIKE '%Europa League%'
  AND programme_title NOT ILIKE '%European%'
  AND episode_title NOT ILIKE '%European%'
  AND pips_genre_level_1_names ILIKE '%Sport%'
;
SELECT count(*) FROM vb_euros_sport;--2,942,245


--- Who is in which group?
CREATE TABLE vb_euros_crossover AS
with iplayer as (SELECT *, cast(1 as boolean) as iplayer FROM vb_euros_iplayer),
     sounds as (SELECT *, cast(1 as boolean) as sounds FROM vb_euros_iplayer),
     sport as (SELECT *, cast(1 as boolean) as sport FROM vb_euros_sport)
SELECT CASE
           WHEN a.audience_id IS NOT NULL THEN a.audience_id
           WHEN b.audience_id IS NOT NULL THEN b.audience_id
           WHEN c.audience_id IS NOT NULL THEN c.audience_id
           ELSE NULL END as audience_id,
       CASE
           WHEN a.age_group IS NOT NULL THEN a.age_group
           WHEN b.age_group IS NOT NULL THEN b.age_group
           WHEN c.age_group IS NOT NULL THEN c.age_group
           ELSE NULL END as age_group,
       iplayer,
       sounds,
       sport
FROM iplayer a
         FULL OUTER JOIN sounds b on a.audience_id = b.audience_id
         FULL OUTER JOIN sport c on a.audience_id = c.audience_id;


SELECT count(*), --7,203,504
       count(distinct audience_id) --7,203,322
FROM vb_euros_crossover;