/*
===============================================================================
Data Quality Checks: Bronze Layer
===============================================================================
Purpose:
    This script performs data quality validation on the raw AQI and weather
    datasets loaded into the Bronze layer.

    These checks help identify:
      - Missing values
      - Invalid or unrealistic measurements
      - Duplicate dates
      - Gaps in the daily time series
      - Out-of-range weather values

Tables Checked:
    - Bronze.aqi_raw
    - Bronze.weather_raw

Notes:
    - These queries are intended for data profiling and validation.
    - No data is modified by this script.
    - Issues identified here can be handled during the Silver layer
      transformation and cleaning process.
===============================================================================
*/


-- =============================================================================
-- AQI DATA QUALITY CHECKS
-- =============================================================================


-- 1. Check overall date range and total number of rows
SELECT 
    MIN([date]) AS MinDate,
    MAX([date]) AS MaxDate,
    COUNT(*) AS TotalRows
FROM Bronze.aqi_raw;


-- 2. Check for NULL values in date or PM2.5
SELECT *
FROM Bronze.aqi_raw
WHERE [date] IS NULL
   OR pm25 IS NULL;


-- 3. Check for zero or negative PM2.5 values
-- These values are considered invalid or suspicious.
SELECT *
FROM Bronze.aqi_raw
WHERE pm25 <= 0;


-- 4. Check for unrealistically high PM2.5 values
-- Values greater than 1000 are treated as potential sensor/data errors.
SELECT *
FROM Bronze.aqi_raw
WHERE pm25 > 1000;


-- 5. Check for duplicate dates
-- Each date is expected to appear only once in the daily dataset.
SELECT 
    [date],
    COUNT(*) AS Occurrences
FROM Bronze.aqi_raw
GROUP BY [date]
HAVING COUNT(*) > 1;


-- 6. Check for missing dates in the daily AQI time series
-- Generates every date between the minimum and maximum available dates
-- and compares them against the actual AQI records.

;WITH Bounds AS (
    SELECT
        CAST(MIN([date]) AS DATE) AS MinDate,
        CAST(MAX([date]) AS DATE) AS MaxDate
    FROM Bronze.aqi_raw
),

DateRange AS (
    -- Start from the earliest AQI date.
    SELECT MinDate AS d
    FROM Bounds

    UNION ALL

    -- Generate one date at a time until the maximum date is reached.
    SELECT DATEADD(DAY, 1, d)
    FROM DateRange
    CROSS JOIN Bounds
    WHERE d < MaxDate
)

SELECT
    d AS MissingDate
FROM DateRange dr
WHERE NOT EXISTS (
    SELECT 1
    FROM Bronze.aqi_raw a
    WHERE CAST(a.[date] AS DATE) = dr.d
)
OPTION (MAXRECURSION 0);



-- =============================================================================
-- WEATHER DATA QUALITY CHECKS
-- =============================================================================


-- 1. Check overall date range and total number of rows
SELECT
    MIN([time]) AS MinDate,
    MAX([time]) AS MaxDate,
    COUNT(*) AS TotalRows
FROM Bronze.weather_raw;


-- 2. Check for NULL values in any weather column
SELECT *
FROM Bronze.weather_raw
WHERE [time] IS NULL
   OR [temperature_2m_mean (C)] IS NULL
   OR [relative_humidity_2m_mean (%)] IS NULL
   OR [precipitation_sum (mm)] IS NULL
   OR [wind_speed_10m_max (km/h)] IS NULL
   OR [wind_direction_10m_dominant (.)] IS NULL
   OR [cloud_cover_mean (%)] IS NULL;


-- 3. Check humidity values outside the valid 0-100% range
SELECT *
FROM Bronze.weather_raw
WHERE [relative_humidity_2m_mean (%)] < 0
   OR [relative_humidity_2m_mean (%)] > 100;


-- 4. Check cloud cover values outside the valid 0-100% range
SELECT *
FROM Bronze.weather_raw
WHERE [cloud_cover_mean (%)] < 0
   OR [cloud_cover_mean (%)] > 100;


-- 5. Check wind direction outside the valid 0-360 degree range
SELECT *
FROM Bronze.weather_raw
WHERE [wind_direction_10m_dominant (.)] < 0
   OR [wind_direction_10m_dominant (.)] > 360;


-- 6. Check for negative precipitation or wind speed
-- Negative values are physically invalid.
SELECT *
FROM Bronze.weather_raw
WHERE [precipitation_sum (mm)] < 0
   OR [wind_speed_10m_max (km/h)] < 0;


-- 7. Check for duplicate weather dates
SELECT
    [time],
    COUNT(*) AS Occurrences
FROM Bronze.weather_raw
GROUP BY [time]
HAVING COUNT(*) > 1;


-- 8. Check for extreme or unrealistic temperature values
-- Lahore sanity range used here: approximately -5°C to 55°C.
SELECT *
FROM Bronze.weather_raw
WHERE [temperature_2m_mean (C)] < -5
   OR [temperature_2m_mean (C)] > 55;
