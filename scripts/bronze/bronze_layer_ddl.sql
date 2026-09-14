/*
===============================================================================
DDL Script: Create Bronze Layer Tables
===============================================================================
Purpose:
    This script creates the tables in the Bronze layer of the data warehouse.

    The Bronze layer stores raw data ingested from the source datasets before
    any cleaning, standardization, transformation, or validation is performed.

    Tables:
      - Bronze.aqi_cleaned
      - Bronze.weather_cleaned

    Note:
      Existing tables are dropped and recreated when this script is executed.
===============================================================================
*/

-- =============================================================================
-- Create AQI Table
-- =============================================================================

IF OBJECT_ID('Bronze.aqi_cleaned', 'U') IS NOT NULL
    DROP TABLE Bronze.aqi_cleaned;

CREATE TABLE Bronze.aqi_cleaned (
    [date] DATE,
    pm25 INT
);


-- =============================================================================
-- Create Weather Table
-- =============================================================================

IF OBJECT_ID('Bronze.weather_cleaned', 'U') IS NOT NULL
    DROP TABLE Bronze.weather_cleaned;

CREATE TABLE Bronze.weather_cleaned (
    [time] DATE,
    [temperature_2m_mean (C)] FLOAT,
    [relative_humidity_2m_mean (%)] FLOAT,
    [precipitation_sum (mm)] FLOAT,
    [wind_speed_10m_max (km/h)] FLOAT,
    [wind_direction_10m_dominant (.)] FLOAT,
    [cloud_cover_mean (%)] FLOAT
);
