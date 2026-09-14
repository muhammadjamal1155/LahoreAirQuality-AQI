# Lahore Air Quality Data Warehouse

A SQL Server data warehouse project built using the **Medallion
Architecture (Bronze → Silver → Gold)** to analyze Lahore's historical
air quality and weather data.

The project combines daily **PM2.5 air-quality readings** with **weather
observations**, applies data-quality rules, and transforms the cleaned
data into a business-ready analytical model for reporting and Power BI.

## Project Objective

The goal of this project is to build an end-to-end data warehouse that
supports analysis of:

-   Lahore's historical PM2.5 levels
-   AQI health categories
-   Unhealthy and hazardous air-quality days
-   Seasonal smog patterns
-   Temperature, humidity, precipitation, wind, and cloud cover
-   Relationships between weather conditions and air quality

## Architecture

``` text
Source CSV Files
       |
       v
+------------------+
|   Bronze Layer   |
|     Raw Data     |
+------------------+
       |
       v
+------------------+
|   Silver Layer   |
| Clean & Validate |
+------------------+
       |
       v
+------------------+
|    Gold Layer    |
| Analytical Model |
+------------------+
       |
       v
   Power BI / BI
```

The project uses three SQL Server schemas:

-   **Bronze** --- raw source data
-   **Silver** --- cleaned, standardized, and validated data
-   **Gold** --- business-ready dimensions, facts, and analytical views

## Database Initialization

The project begins by creating the `LahoreAirQuality_DW` database and
the three schemas required for the Medallion Architecture.

``` sql
CREATE DATABASE LahoreAirQuality_DW;
USE LahoreAirQuality_DW;
GO

CREATE SCHEMA Bronze;
CREATE SCHEMA Silver;
CREATE SCHEMA Gold;
```

This setup is stored in:

``` text
scripts/init_database.sql
```

Run it before executing any Bronze, Silver, or Gold scripts.

## Bronze Layer

The Bronze layer stores source data with minimal transformation.

### Tables

-   `Bronze.aqi_raw`
-   `Bronze.weather_raw`

### Loading Process

1.  Existing Bronze data is truncated.
2.  AQI and weather CSV files are loaded using `BULK INSERT`.
3.  Individual table load durations are recorded.
4.  Total batch execution time is recorded.
5.  `TRY...CATCH` handles loading errors.

The Bronze quality checks identify NULL values, duplicate dates, missing
dates, invalid PM2.5 readings, unrealistic weather measurements, and
other source-data issues.

## Silver Layer

The Silver layer contains cleaned and validated data derived from
Bronze.

### Tables

-   `Silver.aqi_cleaned`
-   `Silver.weather_cleaned`

### AQI Validation Rules

-   Date cannot be NULL.
-   PM2.5 cannot be NULL.
-   PM2.5 must be greater than `0`.
-   PM2.5 must not exceed `1000`.

### Weather Validation Rules

-   Date cannot be NULL.
-   Temperature must be between `-5°C` and `55°C`.
-   Relative humidity must be between `0%` and `100%`.
-   Precipitation cannot be negative.
-   Wind speed cannot be negative.
-   Wind direction must be between `0°` and `360°`.
-   Cloud cover must be between `0%` and `100%`.

The Silver layer uses a **truncate-and-reload** strategy.

## Gold Layer

The Gold layer is the business-facing analytical layer. Gold objects are
implemented as SQL views, allowing them to remain synchronized with the
cleaned Silver data without requiring a separate Gold loading procedure.

The analytical model follows a **star-schema-style design**.

### Dimension Views

  View                           Description
  ------------------------------ --------------------------------------------
  `Gold.dim_city`                City reference information for Lahore
  `Gold.dim_station`             Air-quality monitoring station information
  `Gold.dim_pollutant`           Pollutant reference information for PM2.5
  `Gold.dim_aqi_category`        AQI health-category reference data
  `Gold.dim_date`                Continuous calendar dimension
  `Gold.dim_weather_condition`   Weather-condition classifications

### Fact Views

  -----------------------------------------------------------------------
  View                                Grain / Purpose
  ----------------------------------- -----------------------------------
  `Gold.fact_air_quality_reading`     One PM2.5 reading per
                                      date/station/pollutant

  `Gold.fact_weather_observation`     One weather observation per
                                      date/city

  `Gold.fact_aqi_alert_daily`         Daily AQI alert indicator
  -----------------------------------------------------------------------

## Gold Data Model

``` text
dim_station --------\
dim_pollutant -------\
dim_aqi_category -----> fact_air_quality_reading
dim_date ------------/

dim_city -------------------\
dim_date --------------------> fact_weather_observation
dim_weather_condition ------/

dim_date ------------\
dim_station ----------> fact_aqi_alert_daily
dim_aqi_category ----/
```

## AQI Classification

PM2.5 readings are mapped to health categories in the Gold layer.

  Category                           PM2.5 Range
  -------------------------------- -------------
  Good                                     0--12
  Moderate                              \>12--35
  Unhealthy for Sensitive Groups        \>35--55
  Unhealthy                            \>55--150
  Very Unhealthy                      \>150--250
  Hazardous                                \>250

Days classified as **Unhealthy**, **Very Unhealthy**, or **Hazardous**
are flagged as AQI alert days.

## Weather Classification

Weather observations are categorized as:

-   `RAINY` --- precipitation is greater than 0
-   `CLEAR` --- cloud cover is 20% or less
-   `PARTLY` --- cloud cover is greater than 20% and up to 60%
-   `CLOUDY` --- cloud cover is greater than 60%

Rain is evaluated first, so a day with precipitation is classified as
`RAINY` regardless of cloud-cover percentage.

## Date Dimension

`Gold.dim_date` provides a continuous calendar from **2019-05-09 to
2025-02-18**.

It contains:

-   Date
-   Year
-   Month
-   Month name
-   Quarter
-   Weekday
-   Smog-season indicator

October through February is flagged as the smog season.

The continuous calendar ensures that dates without AQI or weather
readings can remain visible as gaps in time-series reporting.

## Data Quality & Validation

Quality checks are included throughout the warehouse.

### Bronze Checks

-   Date range and row counts
-   NULL detection
-   Invalid PM2.5 readings
-   Extreme PM2.5 readings
-   Duplicate dates
-   Missing dates
-   Invalid humidity
-   Invalid cloud cover
-   Invalid wind direction
-   Negative precipitation
-   Negative wind speed
-   Unrealistic temperatures

### Gold Checks

The Gold verification script validates:

-   Dimension contents
-   Date-dimension coverage
-   Fact row counts
-   AQI category distribution
-   Weather-condition distribution
-   AQI alert statistics
-   Referential integrity
-   Orphaned dimension keys
-   Silver-to-Gold row-count consistency
-   Duplicate fact grains

Referential-integrity checks are expected to return **0 orphaned rows**.

## Expected Data Coverage

  Dataset   Date Range                  Expected Clean Rows
  --------- ------------------------- ---------------------
  AQI       2019-05-09 → 2025-02-18                   1,845
  Weather   2019-05-09 → 2025-02-18                   2,113

## Repository Structure

``` text
LahoreAirQuality_DW/
|
├── datasets/
|   ├── aqi_lahore-us-embassy_2019-2025.csv
|   └── weather_lahore_2019-2025_clean.csv
|
├── scripts/
|   ├── init_database.sql
|   |
|   ├── bronze/
|   |   ├── ddl_bronze.sql
|   |   ├── proc_load_bronze.sql
|   |   └── quality_checks_bronze.sql
|   |
|   ├── silver/
|   |   ├── ddl_silver.sql
|   |   ├── proc_load_silver.sql
|   |   └── quality_checks_silver.sql
|   |
|   └── gold/
|       ├── ddl_gold.sql
|       └── quality_checks_gold.sql
|
├── docs/
|   └── architecture diagrams
|
└── README.md
```

> Adjust the repository tree if your actual folder or file names differ.

## Data Pipeline

``` text
AQI CSV
   |
   v
Bronze.aqi_raw
   |
   | Clean & Validate
   v
Silver.aqi_cleaned
   |
   v
Gold.fact_air_quality_reading
   |
   v
Gold.fact_aqi_alert_daily


Weather CSV
   |
   v
Bronze.weather_raw
   |
   | Clean & Validate
   v
Silver.weather_cleaned
   |
   v
Gold.fact_weather_observation
```

## How to Run the Project

### 1. Initialize the Database

Run:

``` text
scripts/init_database.sql
```

This creates:

``` text
LahoreAirQuality_DW
├── Bronze
├── Silver
└── Gold
```

### 2. Create Bronze Tables

Run:

``` text
scripts/bronze/ddl_bronze.sql
```

### 3. Load Bronze Data

Update the local CSV paths inside `Bronze.load_bronze` if necessary,
then execute:

``` sql
EXEC Bronze.load_bronze;
```

### 4. Run Bronze Quality Checks

Run:

``` text
scripts/bronze/quality_checks_bronze.sql
```

Review NULLs, duplicates, missing dates, and invalid measurements before
continuing.

### 5. Create Silver Tables

Run:

``` text
scripts/silver/ddl_silver.sql
```

### 6. Load Silver Data

Execute:

``` sql
EXEC Silver.load_silver;
```

### 7. Run Silver Quality Checks

Run:

``` text
scripts/silver/quality_checks_silver.sql
```

### 8. Create the Gold Model

Run:

``` text
scripts/gold/ddl_gold.sql
```

A separate Gold loading procedure is not required because the Gold layer
consists of views over cleaned Silver data.

### 9. Verify the Gold Layer

Run:

``` text
scripts/gold/quality_checks_gold.sql
```

Confirm that:

-   Expected fact row counts are returned.
-   Dimension values are correct.
-   Duplicate-grain checks return no unexpected duplicates.
-   Referential-integrity checks return `0` orphaned rows.

## Technologies Used

-   **SQL Server**
-   **T-SQL**
-   **Medallion Architecture**
-   **Star Schema**
-   **ETL / ELT**
-   **SQL Views**
-   **Stored Procedures**
-   **BULK INSERT**
-   **Data Quality Validation**
-   **Power BI-ready analytical modeling**

## Key SQL Concepts Demonstrated

-   Database and schema creation
-   DDL
-   Stored procedures
-   `BULK INSERT`
-   `TRUNCATE TABLE`
-   `INSERT ... SELECT`
-   Data validation
-   CTEs
-   `CASE`
-   `UNION ALL`
-   Date functions
-   Aggregate functions
-   Dimension and fact modeling
-   Referential-integrity testing
-   `TRY...CATCH`
-   Execution-time tracking
-   SQL views

## End-to-End Workflow

``` text
Database Initialization
        ↓
Source CSV Files
        ↓
Bronze Layer
        ↓
Data Profiling & Quality Checks
        ↓
Silver Cleaning & Validation
        ↓
Silver Quality Checks
        ↓
Gold Dimensional Model
        ↓
Gold Verification
        ↓
Power BI / Analytics
```

## Author

**Muhammad Jamal**\
Data Science Graduate

GitHub: https://github.com/muhammadjamal1155\
LinkedIn: https://www.linkedin.com/in/muhammad-jamal-a08241240

------------------------------------------------------------------------

This project demonstrates an end-to-end SQL Server data-engineering
workflow, transforming raw environmental datasets into a structured,
validated, and analytics-ready warehouse using the Medallion
Architecture.
