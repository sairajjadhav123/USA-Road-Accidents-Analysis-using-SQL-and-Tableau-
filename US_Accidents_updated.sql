USE [US Traffic Accident]


SELECT 
	*
FROM
	accidents;


-- Total number of accidents
SELECT
	COUNT(ID) AS total_accidents
FROM 
	accidents
;


-- Total accidents per state, city and county
SELECT
	state,
	city,
	county,
	COUNT(ID) AS qtty_accidents
FROM	
	accidents
GROUP BY state, city, county
ORDER BY 2 DESC;


-- Quantity and ratio of severity. 
-- On the website it says that it may vary from 1 to 4.From 1 to no effect on traffic up to 4 which means significant impact.
SELECT 
	severity,
	COUNT(severity) AS qtty_severity,
	ROUND(COUNT(*) * 100./ SUM(COUNT(*)) OVER (),2) as pct_accidents
from
	accidents
GROUP BY severity
ORDER BY 3 DESC;


-- Higher qtty of accidents first per hours then per day. I needed to separate date from hours using try_convert.
SELECT	
	TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1)) AS Highest_hours_accident,	
	COUNT (*) AS _qtty_acc
FROM 
	accidents
GROUP BY TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1))
ORDER BY 2 DESC;


SELECT	
	TRY_CONVERT(DATE, start_time) AS date_accident,
	COUNT (*) AS _qtty_acc
FROM 
	accidents
GROUP BY TRY_CONVERT(DATE, start_time) 
ORDER BY 2 DESC;


-- Verify if most accidents happens during the night or day, and in what hours.
SELECT
	sunrise_sunset,
	COUNT (*) AS _qtty_acc
FROM 
	accidents
WHERE sunrise_sunset <> ' '
GROUP BY sunrise_sunset
ORDER BY 2 DESC;


SELECT	
	TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1)) AS hours_accident,	
	sunrise_sunset,
	COUNT (*) AS _qtty_acc
FROM 
	accidents
WHERE sunrise_sunset <> ' '
GROUP BY TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1)), sunrise_sunset
ORDER BY 1,3 DESC;


-- % of accidents per hours
SELECT
	TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1)) AS hours_accident,	
	COUNT (*) AS _qtty_acc,
	ROUND(COUNT(*) * 100./ SUM(COUNT(*)) OVER (),2) as pct_accidents
FROM
	accidents
GROUP BY TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1)),	
		 sunrise_sunset
ORDER BY 3 DESC;

-- Cumulative sum in an hour basis

SELECT 
	TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1)) AS hours_accident,	
	SUM(COUNT(*)) OVER (ORDER BY TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1))) AS cumulative_sum
FROM
	accidents
GROUP BY 
	TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1))
	

-- Cumulative % using a temp table

DROP TABLE IF EXISTS #percent_accidents_hour
CREATE TABLE #percent_accidents_hour
(
	hours_acc TIME,
	cumulative_accident NUMERIC
)

INSERT INTO #percent_accidents_hour
SELECT 
	TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1)),	
	SUM(COUNT(*)) OVER (ORDER BY TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1)))
FROM
	accidents
GROUP BY 
	TRY_CONVERT(TIME, PARSENAME(REPLACE(dateadd(hour, datediff(hour, 0, start_time), 0),' ',' '),1));


SELECT
	*,
	(SUM(cumulative_accident) OVER (ORDER BY hours_acc) / SUM(cumulative_accident) OVER ())*100 AS pctrolling
FROM
	#percent_accidents_hour
GROUP BY hours_acc, cumulative_accident
