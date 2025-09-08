-- 🔍 Clue #1: Reports say Carmen was spotted in Southern Europe. 
-- She’d likely choose the least populated country there. Let’s check.
SELECT name, population 
FROM countries 
WHERE region = 'Southern Europe' 
ORDER BY population;

-- 🔍 Clue #2: While in that country, she attended language lessons. 
-- Find its official language so we can grab a translator.
SELECT language 
FROM countrylanguages 
WHERE countrycode = 'VAT' AND isofficial = 't';

-- 🔍 Clue #3: Now she’s moved to a place where *only* that language is spoken. 
-- Identify which country fits, then confirm its name.
SELECT countrycode 
FROM countrylanguages 
WHERE language = 'Italian' AND percentage = 100;

SELECT name 
FROM countries 
WHERE code = 'SMR';

-- 🔍 Clue #4: In that country, there are just two cities. 
-- One is the same as the country’s name—too obvious. Find the *other* one.
SELECT name 
FROM cities 
WHERE countrycode = 'SMR' AND name <> 'San Marino';

-- 🔍 Clue #5: Plot twist! There’s a similarly named city in South America. 
-- Locate that city and figure out which country it belongs to.
SELECT name, countrycode 
FROM cities 
WHERE name LIKE 'Serra%';

SELECT name 
FROM countries 
WHERE code = 'BRA';

-- 🔍 Clue #6: She landed in that country—head straight to its capital.
SELECT capital 
FROM countries 
WHERE name = 'Brazil';

-- 🔍 Clue #7: She slipped away again, but left us a riddle. 
-- Look for the city with a population of 91,084—soon to be 91,085.
SELECT name, population + 1 AS new_population 
FROM cities 
WHERE population = 91084;

\disconnect world