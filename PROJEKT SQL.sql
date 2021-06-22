-- potřebné tabulky v db

SELECT * FROM countries c 	
SELECT * FROM covid19_basic_differences
ORDER BY date ASC
SELECT * FROM economies
WHERE country = 'Afghanistan'
WHERE country IN ('Albania', 'Afganistan', 'Algeria') AND year IN (2020,2019)
SELECT * FROM life_expectancy
SELECT * FROM religions
WHERE year = 2020
SELECT * FROM covid19_testing
SELECT * FROM weather
SELECT * FROM lookup_table

-- ze základního vhledu je jasné, že jako zakladní stavební tabulku pro finalní plachtu 
-- použijeme covid19_basic_differences jelikož obsahuje oba dva klíče: countries a date


-- 1) časové proměnné - TIME VARIABLES


WITH Time_variables AS (

SELECT 
	date,
	country,
	YEAR(date) AS rok,
	CASE 
		WHEN WEEKDAY(cbd.date) IN (5, 6) THEN 1 ELSE 0 END AS weekend,
	(CASE 
		WHEN MONTH(date) IN (12, 1, 2) THEN 0
		WHEN MONTH(date) IN (3, 4, 5) THEN 1
		WHEN MONTH(date) IN  (6, 7, 8) THEN 2
		WHEN MONTH(date) IN  (9, 10, 11) THEN 3
 END) AS season

FROM covid19_basic_differences cbd),

Life_exp_diff AS (

SELECT a.country, a.life_exp_1965 , b.life_exp_2015,
    round( b.life_exp_2015 / a.life_exp_1965, 2 ) as life_exp_ratio,
    ABS(a.life_exp_1965 - b.life_exp_2015) AS life_exp_difference
	FROM (
SELECT le.country , le.life_expectancy as life_exp_1965
	FROM life_expectancy le 
    WHERE year = 1965
    ) a JOIN (
 SELECT le.country , le.life_expectancy as life_exp_2015
    FROM life_expectancy le 
    WHERE year = 2015
    ) b
    ON a.country = b.country),
    
 Religion_ratio AS (
 
 SELECT 
 	r.country,
 	MAX(CASE religion WHEN 'Islam' THEN ROUND(r.population / e.population * 100,2) END) Islam_rel,
 	MAX(CASE religion WHEN 'Christianity' THEN ROUND(r.population / e.population * 100,2) END) Christianity_rel,
 	MAX(CASE religion WHEN 'Unaffiliated Religions' THEN ROUND(r.population / e.population * 100,2) END) Unaffiliated_rel,
 	MAX(CASE religion WHEN 'Hinduism' THEN ROUND(r.population / e.population * 100,2) END) Hinduism_rel,
 	MAX(CASE religion WHEN 'Buddhism' THEN ROUND(r.population / e.population * 100,2) END) Buddhism_rel,
 	MAX(CASE religion WHEN 'Folk Religions' THEN ROUND(r.population / e.population * 100,2) END) Folk_rel,
 	MAX(CASE religion WHEN 'Other Religions' THEN ROUND(r.population / e.population * 100,2) END) Other_rel,
 	MAX(CASE religion WHEN 'Judaism' THEN ROUND(r.population / e.population * 100,2) END) Judaism_rel
 	
 	FROM religions r 
 	INNER JOIN economies e 
 	ON e.country = r.country 
	AND CAST(e.year-1 AS INT) = CAST(r.year AS INT)
	-- WHERE 1=1
	-- AND e.GDP IS NOT NULL 
	-- AND e.gini IS NOT NULL 
	-- AND e.population IS NOT NULL
	GROUP BY r.country
	
 	),
 	
 	weather_1 AS (

SELECT 
	date,
    city,
	AVG(CAST((REPLACE(temp,'°c','')) AS INT)) AS Avg_temp
FROM weather 
	WHERE time BETWEEN '08:00' AND  '20:00'
	GROUP BY date,city
	ORDER BY date DESC ),

weather_2 AS (

SELECT 
	city,
	date,
	COUNT(time) * 3 AS Hour_count,
	ROUND(CAST((REPLACE(rain,'mm','')) AS FLOAT),1) AS rain_int
FROM weather 
	WHERE ROUND(CAST((REPLACE(rain,'mm','')) AS FLOAT),1) > 0
	GROUP BY date,city
	ORDER BY date DESC ),

weather_3 AS (

SELECT 
	city,
	date,
	CAST((REPLACE(gust,'km/h','')) AS INT) AS Max_wind
FROM weather 
GROUP BY date,city
ORDER BY date DESC)
 

SELECT 
	tv.*,
	c.median_age_2018,
	c.population_density,
	e.GDP / e.population AS GDP_per_capita,
	e.gini,
	e.mortaliy_under5,
	led.life_exp_difference,
	led.life_exp_ratio,
	rr.Islam_rel,
	rr.Christianity_rel,
	rr.Unaffiliated_rel,
	rr.Hinduism_rel,
	rr.Buddhism_rel,
	rr.Folk_rel,
	rr.Other_rel,
	rr.Judaism_rel,
	w1.Avg_temp,
	w2.Hour_count,
	w3.Max_wind
	
	
	
	
FROM time_variables AS tv
LEFT JOIN countries AS c 
ON tv.country = c.country 
LEFT JOIN Life_exp_diff AS led
ON led.country = tv.country
LEFT JOIN economies AS e
ON tv.country = e.country 
AND tv.rok = e.year 
LEFT JOIN religion_ratio AS rr 
ON tv.country = rr.country
LEFT JOIN weather_1 AS w1
ON w1.city = c.capital_city 
LEFT JOIN weather_2 AS w2
ON w2.city = c.capital_city 
LEFT JOIN weather_3 AS w3
ON w3.city = c.capital_city 




-- 2) Proměnné specifické pro daný stát 

WHERE 1=1
	AND e.GDP IS NOT NULL 
	AND e.gini IS NOT NULL 
	AND e.population IS NOT NULL


-- hustota zalidnění  / population_density z tabulky countries
-- GDP z tabulky economies : extrahovat rok? 
-- GINI  z tabulky economies : extrahovat rok? 
-- dětská úmrtnost mortaliy_under5 : extrahovat rok ?
-- median_age_2018 z countries



--- rozdíl mezi očekávanou dobou dožití v roce 1965 a v roce 2015 - státy,
---  ve kterých proběhl rychlý rozvoj mohou reagovat jinak než země, které jsou vyspělé už delší dobu

SELECT a.country, a.life_exp_1965 , b.life_exp_2015,
    round( b.life_exp_2015 / a.life_exp_1965, 2 ) as life_exp_ratio,
    ABS(a.life_exp_1965 - b.life_exp_2015) AS life_exp_difference
FROM (
    SELECT le.country , le.life_expectancy as life_exp_1965
    FROM life_expectancy le 
    WHERE year = 1965
    ) a JOIN (
    SELECT le.country , le.life_expectancy as life_exp_2015
    FROM life_expectancy le 
    WHERE year = 2015
    ) b
    ON a.country = b.country
  
 

    

--- podíly jednotlivých náboženství - použijeme jako proxy proměnnou pro kulturní specifika.

-- správně 
	SELECT 
 	r.country,
 	MAX(CASE religion WHEN 'Islam' THEN ROUND(r.population / e.population * 100,2) END) Islam_rel,
 	MAX(CASE religion WHEN 'Christianity' THEN ROUND(r.population / e.population * 100,2) END) Christianity_rel,
 	MAX(CASE religion WHEN 'Unaffiliated Religions' THEN ROUND(r.population / e.population * 100,2) END) Unaffiliated_rel,
 	MAX(CASE religion WHEN 'Hinduism' THEN ROUND(r.population / e.population * 100,2) END) Hinduism_rel,
 	MAX(CASE religion WHEN 'Buddhism' THEN ROUND(r.population / e.population * 100,2) END) Buddhism_rel,
 	MAX(CASE religion WHEN 'Folk Religions' THEN ROUND(r.population / e.population * 100,2) END) Folk_rel,
 	MAX(CASE religion WHEN 'Other Religions' THEN ROUND(r.population / e.population * 100,2) END) Other_rel,
 	MAX(CASE religion WHEN 'Judaism' THEN ROUND(r.population / e.population * 100,2) END) Judaism_rel
 	
 	FROM religions r 
 	INNER JOIN economies e 
 	ON e.country = r.country 
AND CAST(e.year-1 AS INT) = CAST(r.year AS INT)
 	GROUP BY country

---- Pro každé náboženství v daném státě bych chtěl procentní podíl jeho příslušníků na celkovém obyvatelstvu

SELECT r.country , r.religion , 
    round( r.population / r2.total_population_2020 * 100, 2 ) as religion_share_2020
FROM religions r 
JOIN (
        SELECT r.country , r.year,  sum(r.population) as total_population_2020
        FROM religions r 
        WHERE r.year = 2020 and r.country != 'All Countries'
        GROUP BY r.country
    ) r2
    ON r.country = r2.country
    AND r.year = r2.year
    AND r.population > 0
    
 -- 1)   
 
 SELECT 
 	r.country,
 	r.religion, 
 	r.population, 
 	c.population AS total_population,
 	ROUND((r.population / c.population) * 100,2) AS religion_ratio
 	
 FROM religions r 
 JOIN countries c 
 ON r.country = c.country 
 WHERE r.year = 2020
 

 -- 2)
 
  SELECT 
 	r.country,
 	r.religion, 
 	r.population, 
 	e.population AS total_population,
 	ROUND((r.population / e.population) * 100,2) AS religion_ratio
 	
 FROM religions r 
 LEFT JOIN economies e 
 ON r.country = e.country 
 WHERE r.year = 2020
 
 
 -- 3)
 
 SELECT 
 	country,
 	religion,
 	SUM(population),
 	population
 	
 FROM religions r 
 WHERE year = 2020
 GROUP BY country, religion
 
 
 -- 
 
 -- jestli je to propojení s year správně
 -- jestli muže byt religion takto
 
 
 WITH religion_pivot AS (SELECT 
 	country,
 	MAX(CASE religion WHEN 'Islam' THEN population END) Islam_rel,
 	MAX(CASE religion WHEN 'Christianity' THEN population END) Christianity_rel,
 	MAX(CASE religion WHEN 'Unaffiliated Religions' THEN population END) Unaffiliated_rel,
 	MAX(CASE religion WHEN 'Hinduism' THEN population END) Hinduism_rel,
 	MAX(CASE religion WHEN 'Buddhism' THEN population END) Buddhism_rel,
 	MAX(CASE religion WHEN 'Folk Religions' THEN population END) Folk_rel,
 	MAX(CASE religion WHEN 'Other Religions' THEN population END) Other_rel,
 	MAX(CASE religion WHEN 'Judaism' THEN population END) Judaism_rel

 	FROM religions r 
 	WHERE year = 2020
 	GROUP BY country
 	
-- správně 
 	
 	SELECT 
 	r.country,
 	MAX(CASE religion WHEN 'Islam' THEN ROUND(r.population / e.population * 100,2) END) Islam_rel,
 	MAX(CASE religion WHEN 'Christianity' THEN ROUND(r.population / e.population * 100,2) END) Christianity_rel,
 	MAX(CASE religion WHEN 'Unaffiliated Religions' THEN ROUND(r.population / e.population * 100,2) END) Unaffiliated_rel,
 	MAX(CASE religion WHEN 'Hinduism' THEN ROUND(r.population / e.population * 100,2) END) Hinduism_rel,
 	MAX(CASE religion WHEN 'Buddhism' THEN ROUND(r.population / e.population * 100,2) END) Buddhism_rel,
 	MAX(CASE religion WHEN 'Folk Religions' THEN ROUND(r.population / e.population * 100,2) END) Folk_rel,
 	MAX(CASE religion WHEN 'Other Religions' THEN ROUND(r.population / e.population * 100,2) END) Other_rel,
 	MAX(CASE religion WHEN 'Judaism' THEN ROUND(r.population / e.population * 100,2) END) Judaism_rel
 	
 	FROM religions r 
 	INNER JOIN economies e 
 	ON e.country = r.country 
AND CAST(e.year-1 AS INT) = CAST(r.year AS INT)
 	GROUP BY country
 	
 	
 	
 	

 	
 	
 	WITH total AS (
				SELECT 
						SUM(population) AS total
				FROM religions r 
				WHERE year = '2020'
					)
SELECT 
		country,
		year,
		region,
		CAST(population AS INT) AS believers,
		CAST(total.total AS INT) AS sum_believers,
		ROUND((population / total.total)*100,2) AS ratio
FROM religions r2,
		total
WHERE YEAR = '2020'


SELECT *
		FROM economies e 
INNER JOIN religions r 
ON e.country = r.country 
AND CAST(e.year-1 AS INT) = CAST(r.year AS INT)


-- 3) weather 

SELECT 
	c.country,
	AVG(w.temp)
	
FROM weather w
LEFT JOIN countries c
ON w.city = c.capital_city 



weather_1 AS (

SELECT 
	date,
    city,
	AVG(CAST((REPLACE(temp,'°c','')) AS INT)) AS Avg_temp
FROM weather 
WHERE time BETWEEN '08:00' AND  '20:00'
GROUP BY date,city
ORDER BY date DESC ),

weather_2 AS (

SELECT 
city,
date,
COUNT(time) * 3 AS Hour_count,
ROUND(CAST((REPLACE(rain,'mm','')) AS FLOAT),1) AS rain_int
FROM weather 
WHERE ROUND(CAST((REPLACE(rain,'mm','')) AS FLOAT),1) > 0
GROUP BY date,city
ORDER BY date DESC)

weather_3 AS (

SELECT 
	city,
	date,
	CAST((REPLACE(gust,'km/h','')) AS INT) AS Max_wind
FROM weather 
GROUP BY date,city
ORDER BY date DESC)


SELECT SUBSTRING(wind,1,3)
FROM weather 

select SUBSTRING(wind, PATINDEX('%[0-9]%'), wind)
FROM weather 


SELECT * FROM weather
WHERE date = '2021-04-30 00:00:00'

SELECT 

	temp,
	rain,
	wind,
	CAST(temp AS INT),
	ROUND(CAST(rain AS FLOAT),1),
	CAST(wind AS INT)
	
	
FROM weather 

-- jednotky ( třeba smazat? )
-- jak spojit 3 selecty
-- gust za wind
-- spojit tabulky pres left join
-- použít funkci replace misto cast

-- rozdíl mezi:


CAST((REPLACE(temp,'°c','')) AS INT),
ROUND(CAST((REPLACE(rain,'mm','')) AS FLOAT),1),
CAST((REPLACE(gust,'km/h','')) AS INT)

-- a 

CAST(temp AS INT),
	ROUND(CAST(rain AS FLOAT),1),
	CAST(wind AS INT)

	



