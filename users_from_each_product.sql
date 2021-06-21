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
                    ELSE NULL END AS age_group
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_IPLAYER'
  AND date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates)
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
  AND date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates)
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
SELECT count(*) FROM vb_euros_sounds;-- 519,482



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
  AND date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates)
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
                    ELSE NULL END AS age_group
FROM audience.audience_activity_daily_summary_enriched
WHERE date_of_event BETWEEN (SELECT min_date FROM vb_dates) AND (SELECT max_date FROM vb_dates);

SELECT count(*) FROM vb_euros_all_users;

--- Who is in which group?
DROP TABLE IF EXISTS vb_euros_crossover;
CREATE TABLE vb_euros_crossover AS
with all_hids as (SELECT * FROM vb_euros_all_users),
     iplayer as (SELECT *, cast(1 as boolean) as iplayer FROM vb_euros_iplayer),
     sounds as (SELECT *, cast(1 as boolean) as sounds FROM vb_euros_sounds),
     sport as (SELECT *, cast(1 as boolean) as sport FROM vb_euros_sport)
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
SELECT distinct age_group FROM vb_euros_crossover;
-- See what combination of products are used for people who consumed Euros on at least one platform
SELECT CASE
           WHEN sport = TRUE AND iplayer = TRUE AND sounds = TRUE THEN '1_all'
           WHEN sport = TRUE AND iplayer = TRUE AND sounds = FALSE THEN '2_sport_iplayer'
           WHEN sport = TRUE AND iplayer = FALSE AND sounds = TRUE THEN '3_sport_sounds'
           WHEN sport = FALSE AND iplayer = TRUE AND sounds = TRUE THEN '4_iplayer_sounds'
           WHEN sport = TRUE AND iplayer = FALSE AND sounds = FALSE THEN '5_sport_only'
           WHEN sport = FALSE AND iplayer = TRUE AND sounds = FALSE THEN '6_iplayer_only'
           WHEN sport = FALSE AND iplayer = FALSE AND sounds = TRUE THEN '7_sounds_only'
           ELSE '8'
           END                     as product_order,
       sport,
       iplayer,
       sounds,
       count(distinct audience_id) as users,
       round(100 * users::double precision / (SELECT count(*)
                                              FROM vb_euros_crossover
                                              WHERE (iplayer = TRUE OR sounds = TRUE or sport = TRUE) AND age_group = '16 to 34')::double precision,
             1)                    as perc
FROM vb_euros_crossover
WHERE (iplayer = TRUE
   OR sounds = TRUE
   or sport = TRUE)
AND age_group = '16 to 34'
GROUP BY 1, 2, 3, 4
ORDER BY product_order
;

-- Check what the split is for all users, not just those to the euros content
DROP TABLE IF EXISTS vb_euros_crossover_test;
CREATE TABLE vb_euros_crossover_test AS
with all_hids as (SELECT * FROM vb_euros_all_users),
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
SELECT CASE
           WHEN sport = TRUE AND iplayer = TRUE AND sounds = TRUE THEN '1_all'
           WHEN sport = TRUE AND iplayer = TRUE AND sounds = FALSE THEN '2_sport_iplayer'
           WHEN sport = TRUE AND iplayer = FALSE AND sounds = TRUE THEN '3_sport_sounds'
           WHEN sport = FALSE AND iplayer = TRUE AND sounds = TRUE THEN '4_iplayer_sounds'
           WHEN sport = TRUE AND iplayer = FALSE AND sounds = FALSE THEN '5_sport_only'
           WHEN sport = FALSE AND iplayer = TRUE AND sounds = FALSE THEN '6_iplayer_only'
           WHEN sport = FALSE AND iplayer = FALSE AND sounds = TRUE THEN '7_sounds_only'
           ELSE '8'
           END                     as product_order,
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
ORDER BY product_order
;