/*
===============================================================================
Stored Procedure: Silver.load_silver
===============================================================================
Purpose:
    This stored procedure loads cleaned and validated data from the Bronze
    layer into the Silver layer of the data warehouse.

    The Silver layer applies data quality rules and removes invalid records
    before the data is used for analytical modeling in the Gold layer.

Data Flow:
    Bronze.aqi_raw
        --> Silver.aqi_cleaned

    Bronze.weather_raw
        --> Silver.weather_cleaned

Transformations:
    AQI Data:
      - Removes records with NULL dates.
      - Removes records with NULL PM2.5 values.
      - Keeps PM2.5 values greater than 0.
      - Filters unrealistic PM2.5 values above 1000.

    Weather Data:
      - Removes records with NULL dates.
      - Keeps temperature values between -5°C and 55°C.
      - Keeps relative humidity between 0% and 100%.
      - Removes negative precipitation values.
      - Removes negative wind speed values.
      - Keeps wind direction between 0° and 360°.
      - Keeps cloud cover between 0% and 100%.

Load Strategy:
    Full Load / Truncate and Reload

Usage:
    EXEC Silver.load_silver;

Notes:
    - Existing Silver tables are truncated before loading.
    - Data is selected from Bronze tables and filtered using validation rules.
    - Individual table load duration and total batch duration are recorded.
    - TRY...CATCH is used for error handling.
===============================================================================
*/

CREATE OR ALTER PROCEDURE Silver.load_silver
AS
BEGIN

    -- Variables used to track individual table load times
    -- and total Silver layer batch execution time.
    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        -- Start tracking the complete Silver layer load duration.
        SET @batch_start_time = GETDATE();

        PRINT '=============================';
        PRINT 'Loading the Silver Layer';
        PRINT '=============================';


        -- =====================================================================
        -- Load AQI Cleaned Data
        -- =====================================================================

        PRINT '=============================';
        PRINT 'Loading Data Into Silver.aqi_cleaned';
        PRINT '=============================';

        SET @start_time = GETDATE();

        -- Remove previously loaded Silver data.
        PRINT '>> Truncating Table: Silver.aqi_cleaned';

        TRUNCATE TABLE Silver.aqi_cleaned;


        -- Insert validated AQI records from the Bronze layer.
        PRINT '>> Inserting Data Into: Silver.aqi_cleaned';

        INSERT INTO Silver.aqi_cleaned (
            [date],
            pm25
        )
        SELECT
            [date],
            pm25
        FROM Bronze.aqi_raw
        WHERE [date] IS NOT NULL
          AND pm25 IS NOT NULL
          AND pm25 > 0
          AND pm25 <= 1000;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @start_time,
                    @end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '-----------------------------';


        -- =====================================================================
        -- Load Weather Cleaned Data
        -- =====================================================================

        PRINT '=============================';
        PRINT 'Loading Data Into Silver.weather_cleaned';
        PRINT '=============================';

        SET @start_time = GETDATE();


        -- Remove previously loaded Silver weather data.
        PRINT '>> Truncating Table: Silver.weather_cleaned';

        TRUNCATE TABLE Silver.weather_cleaned;


        -- Insert validated weather records from the Bronze layer.
        PRINT '>> Inserting Data Into: Silver.weather_cleaned';

        INSERT INTO Silver.weather_cleaned (
            [time],
            [temperature_2m_mean (C)],
            [relative_humidity_2m_mean (%)],
            [precipitation_sum (mm)],
            [wind_speed_10m_max (km/h)],
            [wind_direction_10m_dominant (.)],
            [cloud_cover_mean (%)]
        )
        SELECT
            [time],
            [temperature_2m_mean (C)],
            [relative_humidity_2m_mean (%)],
            [precipitation_sum (mm)],
            [wind_speed_10m_max (km/h)],
            [wind_direction_10m_dominant (.)],
            [cloud_cover_mean (%)]
        FROM Bronze.weather_raw
        WHERE [time] IS NOT NULL

          -- Validate temperature range.
          AND [temperature_2m_mean (C)] BETWEEN -5 AND 55

          -- Relative humidity must stay between 0% and 100%.
          AND [relative_humidity_2m_mean (%)] BETWEEN 0 AND 100

          -- Precipitation cannot be negative.
          AND [precipitation_sum (mm)] >= 0

          -- Wind speed cannot be negative.
          AND [wind_speed_10m_max (km/h)] >= 0

          -- Wind direction must stay within a valid degree range.
          AND [wind_direction_10m_dominant (.)] BETWEEN 0 AND 360

          -- Cloud cover percentage must stay between 0% and 100%.
          AND [cloud_cover_mean (%)] BETWEEN 0 AND 100;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @start_time,
                    @end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '-----------------------------';


        -- =====================================================================
        -- Complete Silver Layer Batch
        -- =====================================================================

        SET @batch_end_time = GETDATE();

        PRINT '=============================';
        PRINT 'Silver Layer Load Completed';

        PRINT '>> Total Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @batch_start_time,
                    @batch_end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '=============================';

    END TRY

    BEGIN CATCH

        -- Display error details if any step of the Silver load fails.
        PRINT '=============================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER DATA LOADING';
        PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '=============================';

    END CATCH

END;
