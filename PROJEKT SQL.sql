-- potřebné tabulky v db

SELECT * FROM countries c 	
SELECT * FROM covid19_basic_differences
ORDER BY date ASC
SELECT * FROM economies
SELECT * FROM life_expectancy
SELECT * FROM religions
SELECT * FROM covid19_testing
SELECT * FROM weather
SELECT * FROM lookup_table

-- ze základního vhledu je jasné, že jako zakladní stavební tabulku pro finalní plachtu použijeme 
-- covid19_basic_differences jelikož obsahuje oba dva klíče: countries a date
-- rozhodl jsem se jednotlivé úkoly řešit pomocí WITH a dočasných tabulek, které později pospojuji do jedné velké plachty

-- 1) časové proměnné - TIME VARIABLES

-- v první tabulce time_variables jsem si vytáhl dva základní klíče. countries a date, dále jsem si pomocí YEAR funkce vytvořil
-- atribut rok, který pozdějí použiji ke spojení s tabulkou economies, kde nestačí tabulku spojit přes country ale i rok. 
-- k rozdělení jednotlivých dnů jsem použil funkci WEEKDAY 
-- k přiřazení ročních období ke dnům jsem použil funkci MONTH 

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

-- 2) míra dožití. Tuto úlohu jsem přes vnořený SELECT, kde jsem nejprve vybral zemi a life-exp z roku 1965 a přes JOIN ji spojil
-- s life exp. 2015, to mi ve nvořeném SELECTU udělalo tabulku se sloupečky country, life_exp1965 a life_exp2015 u kterých jsem později jednoduše
-- odečetl a agregoval 

Life_exp_diff AS (
	
	SELECT 
		lf1.country, 
		lf1.life_exp_1965, 
		lf2.life_exp_2015,
    	round( lf2.life_exp_2015 / lf1.life_exp_1965, 2 ) as life_exp_ratio,
    	ABS(lf1.life_exp_1965 - lf2.life_exp_2015) AS life_exp_difference
	
	FROM (
		SELECT le.country , le.life_expectancy as life_exp_1965
		FROM life_expectancy le 
		WHERE year = 1965 
		) lf1 
	JOIN (
		SELECT le.country , le.life_expectancy as life_exp_2015
		FROM life_expectancy le 
		WHERE year = 2015
    		) lf2
    	ON lf1.country = lf2.country),
   
-- 3) Religion 
-- tabulku bylo třeba nejdříve pivotovat a vytvořit sloupečky pro jednotlivé náboženstí, aby bylo později možné 
-- provádět matematické operace
-- tabulku jsem spojil s economies, abychom mohl kalkulovat s populací jednotlivých států
-- jelikož tabulka religion je dělaná po 10 letech, rozhodl jsem se je spojit pomocí roku kdy rok o jeden menší v economies
-- je stejný jako rok v religion
    
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
 -- 4)
 -- u tabulek weather  bylo třeba převést jednotlivé sloupečky na INT a odebrat od nich jednotky 
 -- později bylo třeba tabulku spojit nejdříve přes capital_city z countries a později až na zemi, jelikož weather neobsahuje země
 
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
 
-- vybráné sloupečky, keré se mají zobrazit na plachtě

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
	
	
-- Jednotlivé spojovaní tabulek 	
	
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
-- na ukázku, jak pracovat tabulkou a vyselektovat různé typy dat
WHERE tv.country ='Albania'
AND tv.rok = 2020
-- AND tv.counry ='Denmark'
AND weekend = 1


-- na první pohled některé sloupečky jsou nulové. je to z důvodu že pro daný rok chybí v tabulce economies data




  
 

    




