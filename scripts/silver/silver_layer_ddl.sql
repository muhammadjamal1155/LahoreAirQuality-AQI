/*
===============================================================================
DDL Script: Create Silver Layer Tables
===============================================================================
Purpose:
    This script creates the tables in the Silver layer of the data warehouse.

    The Silver layer stores cleaned, standardized, and validated data that has
    been transformed from the raw Bronze layer.

    Data in this layer is prepared for further analytical modeling and for
    building Gold layer dimension and fact tables.

Tables:
    - Silver.aqi_cleaned
    - Silver.weather_cleaned

Data Flow:
    Bronze.aqi_raw     --> Silver.aqi_cleaned
    Bronze.weather_raw --> Silver.weather_cleaned

Notes:
    - Existing Silver tables are dropped before being recreated.
    - Data cleaning and transformation logic is handled separately during
      the Silver layer loading process.
===============================================================================
*/


-- =============================================================================
-- Create AQI Cleaned Table
-- =============================================================================

IF OBJECT_ID('Silver.aqi_cleaned', 'U') IS NOT NULL
    DROP TABLE Silver.aqi_cleaned;

CREATE TABLE Silver.aqi_cleaned (
    [date] DATE,
    pm25 INT
);


-- =============================================================================
-- Create Weather Cleaned Table
-- =============================================================================

IF OBJECT_ID('Silver.weather_cleaned', 'U') IS NOT NULL
    DROP TABLE Silver.weather_cleaned;

CREATE TABLE Silver.weather_cleaned (
    [time] DATE,
    [temperature_2m_mean (C)] FLOAT,
    [relative_humidity_2m_mean (%)] FLOAT,
    [precipitation_sum (mm)] FLOAT,
    [wind_speed_10m_max (km/h)] FLOAT,
    [wind_direction_10m_dominant (.)] FLOAT,
    [cloud_cover_mean (%)] FLOAT
);
