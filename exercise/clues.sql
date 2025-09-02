-- "\connect world" will allow us to connect to the database
-- "\x" this will format the information being printed in the console to make it easier.. try it without if you want!
-- !!We're counting on you, gumshoe. Find out where she's headed, send us the info, and we'll be sure to meet her at the gates with bells on!!
\connect world  
\x              

-- START FINDING CARMEN! --
-- Clue #1: We recently got word that someone fitting Carmen Sandiego's description has been traveling through Southern Europe. She's most likely traveling someplace where she won't be noticed, so find the least populated country in Southern Europe, and we'll start looking for her there.
-- Write SQL query here
-- Clue 1: Least populated country in Southern Europe
WITH clue1 AS (
  SELECT c.code, c.name, c.population
  FROM countries c
  WHERE c.region = 'Southern Europe'
  ORDER BY c.population ASC NULLS LAST
  LIMIT 1
),

-- Clue #2: Now that we're here, we have insight that Carmen was seen attending language classes in this country's officially recognized language. Check our databases and find out what language is spoken in this country, so we can call in a translator to work with you.
-- Write SQL query here
-- Clue 2: Official language of that country (pick 1 deterministically)
clue2 AS (
  SELECT cl.country_code, cl.language
  FROM country_languages cl
  JOIN clue1 c1 ON c1.code = cl.country_code
  WHERE cl.is_official = TRUE
  ORDER BY cl.language
  LIMIT 1
),

-- Helper: count official languages per country
official_counts AS (
  SELECT country_code,
         COUNT(*) FILTER (WHERE is_official) AS official_count
  FROM country_languages
  GROUP BY country_code
),

-- Clue #3: We have new news on the classes Carmen attended – our gumshoes tell us she's moved on to a different country, a country where people speak only the language she was learning. Find out which nearby country speaks nothing but that language.
-- Write SQL query here
-- Clue 3: Another Southern Europe country that speaks ONLY that language
clue3 AS (
  SELECT c.code, c.name
  FROM countries c
  JOIN country_languages cl ON cl.country_code = c.code
  JOIN official_counts oc ON oc.country_code = c.code
  JOIN clue2 ON clue2.language = cl.language
  WHERE c.region = 'Southern Europe'
    AND cl.is_official = TRUE
    AND oc.official_count = 1
    AND c.code <> (SELECT code FROM clue1)
  GROUP BY c.code, c.name
  ORDER BY c.name
  LIMIT 1
),

-- Helper: find which candidate from clue3 (if any) has exactly two cities
two_city_country AS (
  SELECT c3.code, c3.name
  FROM clue3 c3
  JOIN (
    SELECT country_code, COUNT(*) AS city_count
    FROM cities
    GROUP BY country_code
  ) cnt ON cnt.country_code = c3.code
  WHERE cnt.city_count = 2
  LIMIT 1
),

-- Exclude the original country from Clue #1 if it also matches the constraint
clue3 AS (
  SELECT o.code, o.name
  FROM only_that_language o
  WHERE o.code <> (SELECT code FROM clue1)
  ORDER BY o.name
  LIMIT 1
),

-- Clue #4: We're booking the first flight out – maybe we've actually got a chance to catch her this time. There are only two cities she could be flying to in the country. One is named the same as the country – that would be too obvious. We're following our gut on this one; find out what other city in that country she might be flying to.
-- Write SQL query here
country_city_counts AS (
  SELECT ci.country_code, COUNT(*) AS city_count
  FROM cities ci
  GROUP BY ci.country_code
),
two_city_country AS (
  SELECT c.code, c.name
  FROM clue3 c
  JOIN country_city_counts cnt ON cnt.country_code = c.code
  WHERE cnt.city_count = 2
),
clue4 AS (
  SELECT ci.name AS city_name
  FROM cities ci
  JOIN two_city_country tc ON tc.code = ci.country_code
  WHERE ci.name <> tc.name      -- the other city, not the one named same as the country
  ORDER BY ci.name
  LIMIT 1
),

-- Clue #5: Oh no, she pulled a switch – there are two cities with very similar names, but in totally different parts of the globe! She's headed to South America as we speak; go find a city whose name is like the one we were headed to, but doesn't end the same. Find out the city, and do another search for what country it's in. Hurry!
-- Write SQL query here
clue5 AS (
  SELECT sa_ci.name AS city_name, sa_c.name AS country_name, sa_c.code AS country_code
  FROM cities sa_ci
  JOIN countries sa_c ON sa_c.code = sa_ci.country_code
  CROSS JOIN clue4 prev
  WHERE sa_c.region = 'South America'
    AND sa_ci.name <> prev.city_name
    AND sa_ci.name ILIKE CONCAT(LEFT(prev.city_name, GREATEST(length(prev.city_name) - 2, 1)), '%')
  ORDER BY sa_ci.name
  LIMIT 1
),


-- Clue #6: We're close! Our South American agent says she just got a taxi at the airport, and is headed towards
-- the capital! Look up the country's capital, and get there pronto! Send us the name of where you're headed and we'll
-- follow right behind you!
-- Write SQL query here
capital_from_flag_on_city AS (
  SELECT ci.name AS capital_name
  FROM cities ci
  JOIN clue5 f ON f.country_code = ci.country_code
  WHERE ci.is_capital = TRUE
  LIMIT 1
),
capital_from_fk AS (
  SELECT ci.name AS capital_name
  FROM countries c
  JOIN clue5 f ON f.country_code = c.code
  JOIN cities ci ON ci.id = c.capital_city_id
  LIMIT 1
),
clue6 AS (
  -- Prefer explicit capital flag; fall back to FK if needed
  SELECT COALESCE(
    (SELECT capital_name FROM capital_from_flag_on_city),
    (SELECT capital_name FROM capital_from_fk)
  ) AS capital_name
),


-- Clue #7: She knows we're on to her – her taxi dropped her off at the international airport, and she beat us to the boarding gates. We have one chance to catch her, we just have to know where she's heading and beat her to the landing dock. Lucky for us, she's getting cocky. She left us a note (below), and I'm sure she thinks she's very clever, but if we can crack it, we can finally put her where she belongs – behind bars.
--               Our playdate of late has been unusually fun –
--               As an agent, I'll say, you've been a joy to outrun.
--               And while the food here is great, and the people – so nice!
--               I need a little more sunshine with my slice of life.
--               So I'm off to add one to the population I find
--               In a city of ninety-one thousand and now, eighty five.
-- Write SQL query here:
clue7 AS (
  SELECT ci.name AS city_name, ci.population, c.name AS country_name
  FROM cities ci
  JOIN countries c ON c.code = ci.country_code
  WHERE ci.population = 91085
  ORDER BY ci.name
)

-- ===========================
-- Results per clue
-- ===========================
-- Clue #1 result:
SELECT 'Clue #1 - Least populated country in Southern Europe' AS note, name, population
FROM clue1
UNION ALL
-- Clue #2 result:
SELECT 'Clue #2 - Official language (picked)' AS note, (SELECT language FROM picked_language), NULL
UNION ALL
-- Clue #3 result:
SELECT 'Clue #3 - Country speaking only that language' AS note, name, NULL
FROM clue3
UNION ALL
-- Clue #4 result:
SELECT 'Clue #4 - The other city (not same as country)' AS note, (SELECT city_name FROM clue4), NULL
UNION ALL
-- Clue #5 result:
SELECT 'Clue #5 - Similar-named South American city and its country' AS note,
       (SELECT city_name FROM clue5) || ' (in ' || (SELECT country_name FROM clue5) || ')', NULL
UNION ALL
-- Clue #6 result:
SELECT 'Clue #6 - Capital of that country' AS note, (SELECT capital_name FROM clue6), NULL
UNION ALL
-- Clue #7 result:
SELECT 'Clue #7 - City with population 91,085' AS note,
       (SELECT city_name FROM clue7 LIMIT 1) || ' (in ' || (SELECT country_name FROM clue7 LIMIT 1) || ')',
       91085;

\disconnect world