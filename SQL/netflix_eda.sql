-- Data cleaning & Feature Engineering

SELECT DISTINCT content_type, COUNT(*) AS Count 
FROM netflix 
GROUP BY content_type;

-- Check for Missing values in each column
SELECT 'show_id' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE show_id = '' 
UNION 
SELECT 'content_type' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE content_type = '' 
UNION 
SELECT 'title' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE title = '' 
UNION 
SELECT 'director' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE director = '' 
UNION 
SELECT 'cast' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE cast = '' 
UNION 
SELECT 'country' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE country = '' 
UNION 
SELECT 'date_added' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE date_added = '' 
UNION 
SELECT 'release_year' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE release_year = '' 
UNION 
SELECT 'rating' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE rating = '' 
UNION 
SELECT 'duration' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE duration = '' 
UNION 
SELECT 'listed_in' AS ColumnName, COUNT(*) AS Count 
FROM netflix 
WHERE listed_in = '';

SELECT * 
FROM netflix 
WHERE duration = '';

-- Replace duration blank spaces with values that got shifted to rating
UPDATE netflix
SET duration = '74 min' 
WHERE show_id = 's5542';

UPDATE netflix
SET duration = '84 min' 
WHERE show_id = 's5795';

UPDATE netflix
SET duration = '66 min' 
WHERE show_id = 's5814';

-- Replace rating's blank spaces with the value - unknown
UPDATE netflix
SET rating = 'Unknown' 
WHERE rating IN ('74 min', '84 min', '66 min', '');

-- Delete rows where date_added has an empty string
DELETE FROM netflix 
WHERE date_added = '';

UPDATE netflix
SET cast = 'Unknown' 
WHERE cast = '';

UPDATE netflix
SET country = 'Unknown' 
WHERE country = '';

UPDATE netflix
SET director = 'Unknown' 
WHERE director = '';

-- Modify Datatype of date_added
UPDATE netflix
SET date_added = STR_TO_DATE(date_added, '%M %d, %Y');

-- Create a new column month_added from date_added
ALTER TABLE netflix
ADD month_added VARCHAR(15);

UPDATE netflix
SET month_added = MONTHNAME(date_added);

-- Create a new column year_added from date_added
ALTER TABLE netflix
ADD year_added INT;

UPDATE netflix
SET year_added = YEAR(date_added);

-- Delete records where release_year > year_added
DELETE FROM netflix 
WHERE release_year > year_added;

-- Clean up country values with extra commas
UPDATE netflix
SET country = TRIM(BOTH ',' FROM country) 
WHERE LEFT(country, 1) = ',' OR RIGHT(country, 1) = ',';

SELECT DISTINCT release_year 
FROM netflix 
ORDER BY release_year;

SELECT DISTINCT rating 
FROM netflix 
ORDER BY rating;

SELECT DISTINCT duration 
FROM netflix;

-- Create a column that contains only the numeric part of the duration column
ALTER TABLE netflix
ADD total_duration INT;

UPDATE netflix
SET total_duration = REGEXP_SUBSTR(duration, "[0-9]+");

-- Create a column that contains only the unit part of the duration column
ALTER TABLE netflix
ADD units VARCHAR(50);

UPDATE netflix
SET units = REGEXP_SUBSTR(duration, "[a-zA-Z]+");

-- Exploratory Data Analysis

-- 1. Find the minimum and maximum year_added
SELECT MIN(year_added) AS Min_Year FROM netflix;
SELECT MAX(year_added) AS Max_Year FROM netflix;

-- 2. Which month had the most content released on Netflix each year?
WITH cte1 AS (
    SELECT DISTINCT year_added, month_added, COUNT(*) AS Total 
    FROM netflix 
    GROUP BY year_added, month_added
), 
cte2 AS (
    SELECT year_added, month_added, total, ROW_NUMBER() OVER (PARTITION BY year_added ORDER BY total DESC) AS rn 
    FROM cte1
)
SELECT * 
FROM cte2 
WHERE rn = 1 
ORDER BY year_added;

-- 3. Content distribution on Netflix
CREATE VIEW distribution AS 
SELECT release_year, content_type, COUNT(content_type) AS count 
FROM netflix 
GROUP BY release_year, content_type;

-- 4. Top 5 years for movie releases on Netflix
SELECT * 
FROM distribution 
WHERE content_type = 'Movie' 
ORDER BY count DESC 
LIMIT 5;

-- 5. Top 5 years for TV Show releases on Netflix
SELECT * 
FROM distribution 
WHERE content_type = 'TV Show' 
ORDER BY count DESC 
LIMIT 5;
-- 6. Movie to TV Show ratio by year
WITH cte1 AS (
    SELECT release_year, COUNT(*) AS movie 
    FROM netflix 
    WHERE content_type = 'Movie' 
    GROUP BY release_year
), 
cte2 AS (
    SELECT release_year, COUNT(*) AS tv_show 
    FROM netflix 
    WHERE content_type = 'TV Show' 
    GROUP BY release_year
)
SELECT cte1.release_year, cte1.movie, cte2.tv_show, 
    (cte1.movie / (cte1.movie + cte2.tv_show)) * 100 AS movie_percent, 
    (cte2.tv_show / (cte1.movie + cte2.tv_show)) * 100 AS tv_percent 
FROM cte1 
JOIN cte2 ON cte1.release_year = cte2.release_year 
ORDER BY cte1.release_year;

-- 7. Which country has released the most content on Netflix?
SELECT country, COUNT(*) AS total_content 
FROM netflix 
GROUP BY country 
ORDER BY total_content DESC;

-- 8. Explore content distribution by country
WITH cte1 AS (
    SELECT country, COUNT(*) AS movie 
    FROM netflix 
    WHERE content_type = 'Movie' 
    GROUP BY country
), 
cte2 AS (
    SELECT country, COUNT(*) AS tv_show 
    FROM netflix 
    WHERE content_type = 'TV Show' 
    GROUP BY country
)
SELECT cte1.country, cte1.movie, cte2.tv_show, 
    (cte1.movie / (cte1.movie + cte2.tv_show)) * 100 AS movie_percent, 
    (cte2.tv_show / (cte1.movie + cte2.tv_show)) * 100 AS tv_percent 
FROM cte1 
JOIN cte2 ON cte1.country = cte2.country 
ORDER BY movie_percent DESC;

-- 9. Countries where more TV Shows were released than Movies
WITH cte1 AS (
    SELECT country, COUNT(*) AS movie 
    FROM netflix 
    WHERE content_type = 'Movie' 
    GROUP BY country
), 
cte2 AS (
    SELECT country, COUNT(*) AS tv_show 
    FROM netflix 
    WHERE content_type = 'TV Show' 
    GROUP BY country
)
SELECT cte1.country, cte1.movie, cte2.tv_show 
FROM cte1 
JOIN cte2 ON cte1.country = cte2.country 
WHERE cte1.movie < cte2.tv_show 
ORDER BY tv_show DESC;

-- 10. How many different types of ratings are in this data?
SELECT DISTINCT rating 
FROM netflix;

SELECT COUNT(DISTINCT rating) 
FROM netflix;

-- 11. Explore content distribution by rating
SELECT rating, COUNT(*) AS content 
FROM netflix 
GROUP BY rating 
ORDER BY content DESC 
LIMIT 5;

SELECT rating, COUNT(*) AS content 
FROM netflix 
GROUP BY rating 
ORDER BY content ASC 
LIMIT 5;

-- 12. Explore country vs. rating
SELECT country, rating, COUNT(rating) AS count 
FROM netflix 
GROUP BY country, rating 
ORDER BY country, count DESC;

-- 13. India's content distribution by rating
SELECT country, rating, COUNT(rating) AS count 
FROM netflix 
WHERE country = 'India' 
GROUP BY rating 
ORDER BY count DESC;

-- 14. Most released content rating by year
WITH c1 AS (
    SELECT year_added, rating, COUNT(rating) AS total 
    FROM netflix 
    GROUP BY year_added, rating
), 
c2 AS (
    SELECT *, RANK() OVER (PARTITION BY year_added ORDER BY total DESC) AS rn 
    FROM c1
)
SELECT year_added, rating, total 
FROM c2 
WHERE rn = 1;

-- 15. Least produced content rating by year
WITH c1 AS (
    SELECT year_added, rating, COUNT(rating) AS total 
    FROM netflix 
    GROUP BY year_added, rating
), 
c2 AS (
    SELECT *, RANK() OVER (PARTITION BY year_added ORDER BY total ASC) AS rn 
    FROM c1
)
SELECT year_added, rating, total 
FROM c2 
WHERE rn = 1;

-- 16. Find the longest and shortest movies
-- Longest movie
SELECT title, content_type, total_duration 
FROM netflix 
WHERE content_type = 'Movie' 
ORDER BY total_duration DESC 
LIMIT 1;

-- Shortest movie
SELECT title, content_type, total_duration 
FROM netflix 
WHERE content_type = 'Movie' 
ORDER BY total_duration 
LIMIT 1;

-- Movie duration distribution
SELECT total_duration, COUNT(*) AS no_of_movies 
FROM netflix 
WHERE content_type = 'Movie' 
GROUP BY total_duration 
ORDER BY no_of_movies DESC 
LIMIT 10;

-- Longest TV Show
SELECT title, content_type, total_duration 
FROM netflix 
WHERE content_type = 'TV Show' 
ORDER BY total_duration DESC 
LIMIT 1;

-- Most common number of seasons for TV Shows
SELECT total_duration, COUNT(*) AS no_of_tv_shows 
FROM netflix 
WHERE content_type = 'TV Show' 
GROUP BY total_duration 
ORDER BY no_of_tv_shows DESC 
LIMIT 10;

-- 17. Top 5 directors with the most content on Netflix
-- Movies
SELECT director, COUNT(*) AS total_movies 
FROM netflix 
WHERE content_type = 'Movie' AND director <> 'Unknown' 
GROUP BY director 
ORDER BY total_movies DESC 
LIMIT 5;

-- TV Shows
SELECT director, COUNT(*) AS total_shows 
FROM netflix 
WHERE content_type = 'TV Show' AND director <> 'Unknown' 
GROUP BY director 
ORDER BY total_shows DESC 
LIMIT 5;
