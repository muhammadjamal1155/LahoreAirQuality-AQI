/*
===============================================================================
Stored Procedure: Bronze.load_bronze
===============================================================================
Purpose:
    This stored procedure loads raw source data into the Bronze layer of the
    data warehouse.

    It performs a full refresh of the Bronze tables by:
      1. Truncating the existing Bronze tables.
      2. Loading AQI data from the source CSV file.
      3. Loading weather data from the source CSV file.
      4. Tracking the load duration for each table.
      5. Tracking the total batch execution time.
      6. Handling and displaying errors using TRY...CATCH.

Source Files:
    - aqi_lahore-us-embassy_2019-2025.csv
    - weather_lahore_2019-2025_clean.csv

Target Tables:
    - Bronze.aqi_raw
    - Bronze.weather_raw

Load Strategy:
    Full Load / Truncate and Reload

Usage:
    EXEC Bronze.load_bronze;

Notes:
    - FIRSTROW = 2 skips the CSV header row.
    - FIELDTERMINATOR = ',' specifies comma-separated values.
    - ROWTERMINATOR = '0x0a' defines the end of each row.
    - TABLOCK improves bulk insert performance by acquiring a table-level lock.
===============================================================================
*/

CREATE OR ALTER PROCEDURE Bronze.load_bronze
AS
BEGIN

    -- Variables used to track individual table load time
    -- and total batch execution time.
    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        -- Start tracking total Bronze layer load time.
        SET @batch_start_time = GETDATE();

        PRINT '=============================';
        PRINT 'Loading the Bronze Layer';
        PRINT '=============================';


        -- =====================================================================
        -- Load AQI Data
        -- =====================================================================

        PRINT '=============================';
        PRINT 'Loading Data Into Bronze.aqi_raw';
        PRINT '=============================';

        SET @start_time = GETDATE();

        -- Remove existing records before performing a full reload.
        PRINT '>> Truncating Table: Bronze.aqi_raw';
        TRUNCATE TABLE Bronze.aqi_raw;

        -- Load raw AQI data from the CSV source file.
        PRINT '>> Inserting Data Into: Bronze.aqi_raw';

        BULK INSERT Bronze.aqi_raw
        FROM 'D:\SQL\aqi_lahore-us-embassy_2019-2025.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-----------------------------';


        -- =====================================================================
        -- Load Weather Data
        -- =====================================================================

        PRINT '=============================';
        PRINT 'Loading Data Into Bronze.weather_raw';
        PRINT '=============================';

        SET @start_time = GETDATE();

        -- Remove existing records before performing a full reload.
        PRINT '>> Truncating Table: Bronze.weather_raw';
        TRUNCATE TABLE Bronze.weather_raw;

        -- Load raw weather data from the CSV source file.
        PRINT '>> Inserting Data Into: Bronze.weather_raw';

        BULK INSERT Bronze.weather_raw
        FROM 'D:\SQL\weather_lahore_2019-2025_clean.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-----------------------------';


        -- =====================================================================
        -- Complete Batch
        -- =====================================================================

        SET @batch_end_time = GETDATE();

        PRINT '=============================';
        PRINT 'Bronze Layer Load Completed';

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

        -- Display error information if any part of the load fails.
        PRINT '=============================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER DATA LOADING';
        PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '=============================';

    END CATCH

END;
