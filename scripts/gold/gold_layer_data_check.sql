/*
===============================================================================
Data Quality Checks: Gold Layer
===============================================================================
Project:
    Lahore Air Quality Data Warehouse

Purpose:
    This script validates the integrity, completeness, and consistency of the
    Gold layer after the Bronze and Silver pipelines have been executed.

    The checks verify:
      - Dimension data and expected row counts
      - Fact view row counts
      - Date dimension coverage
      - AQI category distribution
      - Weather condition distribution
      - AQI alert-day statistics
      - Referential integrity between facts and dimensions
      - Orphaned foreign keys

Gold Objects Checked:

    Dimensions:
      - Gold.dim_city
      - Gold.dim_station
      - Gold.dim_pollutant
      - Gold.dim_aqi_category
      - Gold.dim_date
      - Gold.dim_weather_condition

    Facts:
      - Gold.fact_air_quality_reading
      - Gold.fact_weather_observation
      - Gold.fact_aqi_alert_daily

Expected Data Coverage:
    AQI:
      2019-05-09 to 2025-02-18
      Expected rows: 1,845

    Weather:
      2019-05-09 to 2025-02-18
      Expected rows: 2,113

Expected Results:
    - Fact row counts should match their corresponding Silver datasets.
    - Dimension values should match the expected reference data.
    - All fact keys should match their corresponding dimension keys.
    - Referential integrity checks should return 0 orphaned rows.
    - AQI and weather categories should contain only defined classifications.

Usage:
    Run this script after creating the Gold views and after each pipeline
    refresh to confirm that the analytical model is ready for reporting.

Notes:
    - This script performs validation only and does not modify data.
    - A non-zero OrphanedRows result indicates a broken relationship between
      a fact view and one or more dimension views.
===============================================================================
*/


-- =============================================================================
-- 1. DIMENSION CHECKS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1.1 DimCity
-- Expected: 1 row for Lahore
-- -----------------------------------------------------------------------------
SELECT *
FROM Gold.dim_city;


-- -----------------------------------------------------------------------------
-- 1.2 DimStation
-- Expected: 1 row for Lahore US Embassy
-- -----------------------------------------------------------------------------
SELECT *
FROM Gold.dim_station;


-- -----------------------------------------------------------------------------
-- 1.3 DimPollutant
-- Expected: 1 row for PM2.5
-- -----------------------------------------------------------------------------
SELECT *
FROM Gold.dim_pollutant;


-- -----------------------------------------------------------------------------
-- 1.4 DimAQICategory
-- Expected: 6 AQI categories
-- -----------------------------------------------------------------------------
SELECT *
FROM Gold.dim_aqi_category;


-- -----------------------------------------------------------------------------
-- 1.5 DimWeatherCondition
-- Expected: 4 weather conditions
-- CLEAR, PARTLY, CLOUDY, RAINY
-- -----------------------------------------------------------------------------
SELECT *
FROM Gold.dim_weather_condition;


-- -----------------------------------------------------------------------------
-- 1.6 DimDate - Row Count
-- Expected:
-- One row for every calendar day between 2019-05-09 and 2025-02-18.
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS DateRowCount
FROM Gold.dim_date;


-- -----------------------------------------------------------------------------
-- 1.7 DimDate - Date Range
-- Expected:
-- MinDate = 2019-05-09
-- MaxDate = 2025-02-18
-- -----------------------------------------------------------------------------
SELECT
    MIN(date_key) AS MinDate,
    MAX(date_key) AS MaxDate
FROM Gold.dim_date;


-- -----------------------------------------------------------------------------
-- 1.8 DimDate - Spot Check
-- Verify that dates increase correctly and calendar attributes are valid.
-- -----------------------------------------------------------------------------
SELECT TOP 5 *
FROM Gold.dim_date
ORDER BY date_key;



-- =============================================================================
-- 2. FACT AIR QUALITY CHECKS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 2.1 FactAirQualityReading - Row Count
-- Expected: 1,845 rows
-- Must match Silver.aqi_cleaned.
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS AirQualityRowCount
FROM Gold.fact_air_quality_reading;


-- -----------------------------------------------------------------------------
-- 2.2 AQI Category Distribution
-- Expected:
-- Up to 6 categories, with total DayCount = 1,845.
-- -----------------------------------------------------------------------------
SELECT
    aqi_category_key,
    COUNT(*) AS DayCount
FROM Gold.fact_air_quality_reading
GROUP BY aqi_category_key
ORDER BY MIN(reading_value);



-- =============================================================================
-- 3. FACT WEATHER CHECKS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 3.1 FactWeatherObservation - Row Count
-- Expected: 2,113 rows
-- Must match Silver.weather_cleaned.
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS WeatherRowCount
FROM Gold.fact_weather_observation;


-- -----------------------------------------------------------------------------
-- 3.2 Weather Condition Distribution
-- Expected:
-- Up to 4 categories:
-- CLEAR, PARTLY, CLOUDY, RAINY
-- Total DayCount should equal 2,113.
-- -----------------------------------------------------------------------------
SELECT
    weather_condition_key,
    COUNT(*) AS DayCount
FROM Gold.fact_weather_observation
GROUP BY weather_condition_key;



-- =============================================================================
-- 4. AQI ALERT CHECKS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 4.1 FactAQIAlertDaily - Row Count
-- Expected: 1,845 rows
-- Must match Gold.fact_air_quality_reading.
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS AlertFactRowCount
FROM Gold.fact_aqi_alert_daily;


-- -----------------------------------------------------------------------------
-- 4.2 Overall Alert-Day Statistics
-- Alert day = AQI category is UNHEALTHY or worse.
-- -----------------------------------------------------------------------------
SELECT
    SUM(is_alert_day) AS AlertDays,
    COUNT(*) AS TotalDays,
    CAST(
        SUM(is_alert_day) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS PctAlertDays
FROM Gold.fact_aqi_alert_daily;



-- =============================================================================
-- 5. REFERENTIAL INTEGRITY CHECKS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 5.1 FactAirQualityReading Referential Integrity
--
-- Checks:
--   date_key         -> Gold.dim_date
--   station_key      -> Gold.dim_station
--   pollutant_key    -> Gold.dim_pollutant
--   aqi_category_key -> Gold.dim_aqi_category
--
-- Expected: OrphanedRows = 0
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS OrphanedRows
FROM Gold.fact_air_quality_reading AS f

LEFT JOIN Gold.dim_date AS d
    ON f.date_key = d.date_key

LEFT JOIN Gold.dim_station AS s
    ON f.station_key = s.station_key

LEFT JOIN Gold.dim_pollutant AS p
    ON f.pollutant_key = p.pollutant_key

LEFT JOIN Gold.dim_aqi_category AS c
    ON f.aqi_category_key = c.aqi_category_key

WHERE d.date_key IS NULL
   OR s.station_key IS NULL
   OR p.pollutant_key IS NULL
   OR c.aqi_category_key IS NULL;


-- -----------------------------------------------------------------------------
-- 5.2 FactWeatherObservation Referential Integrity
--
-- Checks:
--   date_key              -> Gold.dim_date
--   city_key              -> Gold.dim_city
--   weather_condition_key -> Gold.dim_weather_condition
--
-- Expected: OrphanedRows = 0
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS OrphanedRows
FROM Gold.fact_weather_observation AS f

LEFT JOIN Gold.dim_date AS d
    ON f.date_key = d.date_key

LEFT JOIN Gold.dim_city AS c
    ON f.city_key = c.city_key

LEFT JOIN Gold.dim_weather_condition AS wc
    ON f.weather_condition_key = wc.weather_condition_key

WHERE d.date_key IS NULL
   OR c.city_key IS NULL
   OR wc.weather_condition_key IS NULL;


-- -----------------------------------------------------------------------------
-- 5.3 FactAQIAlertDaily Referential Integrity
--
-- Checks:
--   date_key         -> Gold.dim_date
--   station_key      -> Gold.dim_station
--   aqi_category_key -> Gold.dim_aqi_category
--
-- Expected: OrphanedRows = 0
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS OrphanedRows
FROM Gold.fact_aqi_alert_daily AS f

LEFT JOIN Gold.dim_date AS d
    ON f.date_key = d.date_key

LEFT JOIN Gold.dim_station AS s
    ON f.station_key = s.station_key

LEFT JOIN Gold.dim_aqi_category AS c
    ON f.aqi_category_key = c.aqi_category_key

WHERE d.date_key IS NULL
   OR s.station_key IS NULL
   OR c.aqi_category_key IS NULL;



-- =============================================================================
-- 6. CROSS-LAYER ROW COUNT VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 6.1 AQI Silver vs Gold
-- Expected: Difference = 0
-- -----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM Silver.aqi_cleaned) AS SilverRows,
    (SELECT COUNT(*) FROM Gold.fact_air_quality_reading) AS GoldRows,
    (SELECT COUNT(*) FROM Silver.aqi_cleaned)
        - (SELECT COUNT(*) FROM Gold.fact_air_quality_reading) AS Difference;


-- -----------------------------------------------------------------------------
-- 6.2 Weather Silver vs Gold
-- Expected: Difference = 0
-- -----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM Silver.weather_cleaned) AS SilverRows,
    (SELECT COUNT(*) FROM Gold.fact_weather_observation) AS GoldRows,
    (SELECT COUNT(*) FROM Silver.weather_cleaned)
        - (SELECT COUNT(*) FROM Gold.fact_weather_observation) AS Difference;



-- =============================================================================
-- 7. DUPLICATE GRAIN CHECKS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 7.1 Duplicate AQI fact dates
-- Expected: No Results
-- -----------------------------------------------------------------------------
SELECT
    date_key,
    station_key,
    pollutant_key,
    COUNT(*) AS Occurrences
FROM Gold.fact_air_quality_reading
GROUP BY
    date_key,
    station_key,
    pollutant_key
HAVING COUNT(*) > 1;


-- -----------------------------------------------------------------------------
-- 7.2 Duplicate Weather fact dates
-- Expected: No Results
-- -----------------------------------------------------------------------------
SELECT
    date_key,
    city_key,
    COUNT(*) AS Occurrences
FROM Gold.fact_weather_observation
GROUP BY
    date_key,
    city_key
HAVING COUNT(*) > 1;


-- -----------------------------------------------------------------------------
-- 7.3 Duplicate Alert fact dates
-- Expected: No Results
-- -----------------------------------------------------------------------------
SELECT
    date_key,
    station_key,
    COUNT(*) AS Occurrences
FROM Gold.fact_aqi_alert_daily
GROUP BY
    date_key,
    station_key
HAVING COUNT(*) > 1;



-- =============================================================================
-- END OF GOLD LAYER QUALITY CHECKS
-- =============================================================================
