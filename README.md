# 🌫️ Lahore Air Quality Data Warehouse

## 📌 Project Overview

The **Lahore Air Quality Data Warehouse** is an end-to-end SQL Server data engineering project built using the **Medallion Architecture (Bronze → Silver → Gold)**.

The project integrates historical **PM2.5 air-quality data** and **weather data for Lahore**, transforms raw source files into clean and validated datasets, and builds a business-ready dimensional model for analytics and Power BI reporting.

The project demonstrates practical concepts including:

- Data ingestion
- Data cleaning and validation
- Medallion Architecture
- ETL/ELT pipelines
- Data quality checks
- Stored procedures
- Dimensional modeling
- Star schema design
- Fact and dimension views
- Referential integrity validation
- Time-series analysis

---

## 🎯 Project Objective

The objective of this project is to build a structured analytical data warehouse that can support analysis of:

- Historical PM2.5 pollution levels in Lahore
- AQI health categories
- Unhealthy and hazardous air-quality days
- Seasonal smog patterns
- Temperature and humidity
- Rainfall and precipitation
- Wind speed and direction
- Cloud cover
- Relationships between weather conditions and air pollution

The final Gold layer is designed to support **Power BI dashboards and analytical reporting**.

---

# 🏗️ Data Architecture

The project follows the **Medallion Architecture**, where data becomes progressively cleaner and more business-ready as it moves through the warehouse.

```text
                    Source CSV Files
                           │
                           ▼
                 ┌──────────────────┐
                 │   Bronze Layer   │
                 │     Raw Data     │
                 └──────────────────┘
                           │
                           ▼
                 ┌──────────────────┐
                 │   Silver Layer   │
                 │ Clean & Validate │
                 └──────────────────┘
                           │
                           ▼
                 ┌──────────────────┐
                 │    Gold Layer    │
                 │ Analytical Model │
                 └──────────────────┘
                           │
                           ▼
                    Power BI / BI
```

### 🥉 Bronze Layer

Stores raw source data loaded from CSV files.

### 🥈 Silver Layer

Cleans, validates, and standardizes the raw Bronze data.

### 🥇 Gold Layer

Transforms Silver data into business-ready **dimensions and facts** for analytics and reporting.

---

# 🗄️ Database Initialization

The project uses a SQL Server database named:

```text
LahoreAirQuality_DW
```

The initialization script creates the database and the three schemas required for the Medallion Architecture.

```sql
CREATE DATABASE LahoreAirQuality_DW;
USE LahoreAirQuality_DW;
GO

CREATE SCHEMA Bronze;
CREATE SCHEMA Silver;
CREATE SCHEMA Gold;
```

The initialization script should be executed before all other project scripts.

```text
scripts/init_database.sql
```

---

# 🥉 Bronze Layer

The **Bronze Layer** stores data in its raw form after ingestion from the source CSV files.

## Bronze Tables

```text
Bronze.aqi_raw
Bronze.weather_raw
```

### `Bronze.aqi_raw`

Contains historical daily PM2.5 readings for Lahore.

### `Bronze.weather_raw`

Contains historical daily weather observations including:

- Temperature
- Relative humidity
- Precipitation
- Wind speed
- Wind direction
- Cloud cover

---

## 📥 Bronze Data Loading

The stored procedure:

```sql
Bronze.load_bronze
```

loads the source CSV files into the Bronze tables using SQL Server `BULK INSERT`.

The procedure performs the following steps:

1. Truncates existing Bronze data.
2. Loads AQI data from the source CSV.
3. Loads weather data from the source CSV.
4. Tracks individual table load duration.
5. Tracks total batch execution time.
6. Handles errors using `TRY...CATCH`.

Example:

```sql
EXEC Bronze.load_bronze;
```

The loading strategy is:

```text
Full Load
    ↓
TRUNCATE
    ↓
BULK INSERT
```

---

# 🔍 Bronze Data Quality Checks

The Bronze quality-check script profiles the raw source data before transformation.

Checks include:

### AQI Data

- Date range
- Total row count
- NULL dates
- NULL PM2.5 readings
- Zero or negative PM2.5 values
- Extremely high PM2.5 values
- Duplicate dates
- Missing dates in the daily time series

### Weather Data

- Date range
- Total row count
- NULL values
- Humidity outside `0–100%`
- Cloud cover outside `0–100%`
- Wind direction outside `0–360°`
- Negative precipitation
- Negative wind speed
- Duplicate dates
- Unrealistic temperatures

These checks help identify problems before data is moved into the Silver layer.

---

# 🥈 Silver Layer

The **Silver Layer** contains cleaned, validated, and standardized data derived from the Bronze layer.

## Silver Tables

```text
Silver.aqi_cleaned
Silver.weather_cleaned
```

The data flow is:

```text
Bronze.aqi_raw
        │
        ▼
Silver.aqi_cleaned


Bronze.weather_raw
        │
        ▼
Silver.weather_cleaned
```

---

## 🧹 AQI Cleaning Rules

The following validation rules are applied before AQI records enter the Silver layer:

- Date cannot be `NULL`
- PM2.5 cannot be `NULL`
- PM2.5 must be greater than `0`
- PM2.5 must not exceed `1000`

Example transformation:

```sql
INSERT INTO Silver.aqi_cleaned ([date], pm25)
SELECT
    [date],
    pm25
FROM Bronze.aqi_raw
WHERE [date] IS NOT NULL
  AND pm25 IS NOT NULL
  AND pm25 > 0
  AND pm25 <= 1000;
```

---

## 🌦️ Weather Cleaning Rules

Weather records are validated using the following rules:

| Variable | Validation Rule |
|---|---|
| Date | Cannot be NULL |
| Temperature | -5°C to 55°C |
| Relative Humidity | 0% to 100% |
| Precipitation | ≥ 0 mm |
| Wind Speed | ≥ 0 km/h |
| Wind Direction | 0° to 360° |
| Cloud Cover | 0% to 100% |

Records failing these validation rules are excluded from the cleaned Silver dataset.

---

# ⚙️ Silver Data Loading

The stored procedure:

```sql
Silver.load_silver
```

moves validated data from Bronze into Silver.

The process follows:

```text
Bronze Raw Data
       │
       ▼
Data Validation
       │
       ▼
Invalid Records Removed
       │
       ▼
Silver Clean Data
```

The Silver layer also uses a **truncate-and-reload** strategy.

Execute it using:

```sql
EXEC Silver.load_silver;
```

---

# 🥇 Gold Layer

The **Gold Layer** is the final business-facing layer of the data warehouse.

It transforms cleaned Silver data into an analytical model designed for:

- Power BI
- Dashboarding
- Reporting
- KPI analysis
- Time-series analysis
- Air-quality trend analysis

The Gold layer follows a **Star Schema style dimensional model**.

Gold objects are implemented as **SQL views rather than physical tables**.

This means changes in Silver are automatically reflected in Gold without requiring a separate Gold loading procedure.

---

# ⭐ Gold Star Schema

The Gold layer contains **6 dimensions** and **3 fact views**.

## Dimension Views

| Dimension | Description |
|---|---|
| `Gold.dim_city` | City reference information |
| `Gold.dim_station` | Air-quality monitoring station |
| `Gold.dim_pollutant` | Pollutant reference information |
| `Gold.dim_aqi_category` | AQI health categories |
| `Gold.dim_date` | Continuous calendar dimension |
| `Gold.dim_weather_condition` | Weather classifications |

## Fact Views

| Fact | Grain |
|---|---|
| `Gold.fact_air_quality_reading` | One PM2.5 reading per date/station/pollutant |
| `Gold.fact_weather_observation` | One weather observation per date/city |
| `Gold.fact_aqi_alert_daily` | One AQI alert record per date/station |

---

# 🔗 Gold Data Model

```text
                     ┌────────────────────┐
                     │      dim_date      │
                     └─────────┬──────────┘
                               │
                               │
     ┌─────────────────────────┼──────────────────────────┐
     │                         │                          │
     ▼                         ▼                          ▼

dim_station ───────┐   dim_city ───────────┐      dim_station
                   │                       │           │
dim_pollutant ─────┤                       │           │
                   ▼                       ▼           ▼
          fact_air_quality         fact_weather    fact_aqi_alert
             _reading              _observation       _daily
                   ▲                       ▲           ▲
                   │                       │           │
dim_aqi_category ──┘      dim_weather_condition       │
                                                   dim_aqi_category
```

---

# 🌫️ AQI Classification

PM2.5 readings are categorized into health-related groups in the Gold layer.

| AQI Category | PM2.5 Range |
|---|---:|
| Good | 0–12 |
| Moderate | >12–35 |
| Unhealthy for Sensitive Groups | >35–55 |
| Unhealthy | >55–150 |
| Very Unhealthy | >150–250 |
| Hazardous | >250 |

The classification is generated using a SQL `CASE` expression.

Example:

```sql
CASE
    WHEN pm25 <= 12  THEN 'GOOD'
    WHEN pm25 <= 35  THEN 'MODERATE'
    WHEN pm25 <= 55  THEN 'USG'
    WHEN pm25 <= 150 THEN 'UNHEALTHY'
    WHEN pm25 <= 250 THEN 'VERY_UNHEALTHY'
    ELSE 'HAZARDOUS'
END
```

---

# 🚨 AQI Alert Days

The Gold layer contains:

```text
Gold.fact_aqi_alert_daily
```

This view identifies days when Lahore experienced unhealthy air quality.

The following categories are considered alert days:

```text
UNHEALTHY
VERY_UNHEALTHY
HAZARDOUS
```

These days receive:

```text
is_alert_day = 1
```

Other AQI categories receive:

```text
is_alert_day = 0
```

This makes it easy to calculate metrics such as:

```text
Number of Unhealthy Days
Percentage of Alert Days
Seasonal Alert Frequency
Year-over-Year Pollution Trends
```

---

# 🌦️ Weather Classification

Weather observations are categorized into four conditions:

| Key | Condition |
|---|---|
| `CLEAR` | Clear |
| `PARTLY` | Partly Cloudy |
| `CLOUDY` | Cloudy |
| `RAINY` | Rainy |

Classification logic:

```sql
CASE
    WHEN precipitation > 0 THEN 'RAINY'
    WHEN cloud_cover <= 20 THEN 'CLEAR'
    WHEN cloud_cover <= 60 THEN 'PARTLY'
    ELSE 'CLOUDY'
END
```

Rain is evaluated first, meaning a day with precipitation is classified as `RAINY` regardless of cloud cover.

---

# 📅 Date Dimension

The Gold layer contains a generated calendar dimension:

```text
Gold.dim_date
```

It covers the complete analytical date range:

```text
2019-05-09 → 2025-02-18
```

The dimension includes:

- `date_key`
- `year`
- `month`
- `month_name`
- `quarter`
- `weekday`
- `is_smog_season`

---

## 🌁 Smog Season

The months:

```text
October
November
December
January
February
```

are flagged as Lahore's smog season.

```sql
CASE
    WHEN MONTH(date_key) >= 10
      OR MONTH(date_key) <= 2
    THEN 1
    ELSE 0
END
```

This enables comparisons between:

```text
Smog Season
     vs
Non-Smog Season
```

---

# 📊 Data Coverage

The cleaned datasets currently cover:

| Dataset | Date Range | Clean Rows |
|---|---|---:|
| AQI | 2019-05-09 → 2025-02-18 | 1,845 |
| Weather | 2019-05-09 → 2025-02-18 | 2,113 |

The Date dimension contains every calendar date in the complete period, including days where AQI observations may be missing.

This makes missing observations visible in time-series reporting instead of silently skipping those dates.

---

# ✅ Gold Layer Quality Checks

The Gold verification script validates the final analytical model before it is used for reporting.

Checks include:

### Dimension Validation

- City dimension
- Station dimension
- Pollutant dimension
- AQI category dimension
- Weather condition dimension
- Date dimension

### Fact Validation

- AQI fact row count
- Weather fact row count
- Alert fact row count
- AQI category distribution
- Weather condition distribution

### Referential Integrity

Fact keys are checked against their corresponding dimensions.

For example:

```text
fact_air_quality_reading
        │
        ├── date_key ──────────> dim_date
        ├── station_key ───────> dim_station
        ├── pollutant_key ─────> dim_pollutant
        └── aqi_category_key ──> dim_aqi_category
```

Expected result:

```text
OrphanedRows = 0
```

The same validation is performed for weather and AQI alert facts.

---

# 🔄 Cross-Layer Validation

Silver and Gold row counts are compared to ensure that Gold views do not unexpectedly lose records.

Example:

```text
Silver.aqi_cleaned
        ↓
Gold.fact_air_quality_reading

Expected Difference = 0
```

and:

```text
Silver.weather_cleaned
        ↓
Gold.fact_weather_observation

Expected Difference = 0
```

---

# 🔎 Duplicate Grain Checks

The Gold layer also verifies that fact views respect their intended grain.

### Air Quality Fact

Expected grain:

```text
date + station + pollutant
```

### Weather Fact

Expected grain:

```text
date + city
```

### AQI Alert Fact

Expected grain:

```text
date + station
```

Duplicate-grain queries should return:

```text
No Results
```

---

# 📂 Repository Structure

```text
LahoreAirQuality_DW/
│
├── datasets/
│   ├── aqi_lahore-us-embassy_2019-2025.csv
│   └── weather_lahore_2019-2025_clean.csv
│
├── scripts/
│   │
│   ├── init_database.sql
│   │
│   ├── bronze/
│   │   ├── ddl_bronze.sql
│   │   ├── proc_load_bronze.sql
│   │   └── quality_checks_bronze.sql
│   │
│   ├── silver/
│   │   ├── ddl_silver.sql
│   │   ├── proc_load_silver.sql
│   │   └── quality_checks_silver.sql
│   │
│   └── gold/
│       ├── ddl_gold.sql
│       └── quality_checks_gold.sql
│
├── docs/
│   └── architecture diagrams
│
└── README.md
```

---

# 🔄 End-to-End Data Pipeline

```text
                   DATABASE INITIALIZATION
                            │
                            ▼
                      SOURCE DATA
                     /           \
                    /             \
             AQI CSV             Weather CSV
                │                    │
                ▼                    ▼
        Bronze.aqi_raw       Bronze.weather_raw
                │                    │
                ▼                    ▼
          Data Quality          Data Quality
             Checks                Checks
                │                    │
                ▼                    ▼
      Silver.aqi_cleaned   Silver.weather_cleaned
                │                    │
                ▼                    ▼
       Gold Air Quality      Gold Weather Fact
             Facts                  │
                │                    │
                └─────────┬──────────┘
                          │
                          ▼
                    Gold Dimensions
                          │
                          ▼
                  Quality Validation
                          │
                          ▼
                    Power BI / BI
```

---

# 🚀 How to Run the Project

## 1. Initialize the Database

Run:

```text
scripts/init_database.sql
```

This creates:

```text
LahoreAirQuality_DW
├── Bronze
├── Silver
└── Gold
```

---

## 2. Create Bronze Tables

Run:

```text
scripts/bronze/ddl_bronze.sql
```

---

## 3. Load Bronze Data

Before execution, update the local CSV paths inside the Bronze loading procedure if required.

Then execute:

```sql
EXEC Bronze.load_bronze;
```

---

## 4. Run Bronze Quality Checks

Run:

```text
scripts/bronze/quality_checks_bronze.sql
```

Review:

- NULL values
- Duplicate dates
- Missing dates
- Invalid PM2.5 values
- Invalid weather measurements

---

## 5. Create Silver Tables

Run:

```text
scripts/silver/ddl_silver.sql
```

---

## 6. Load Silver Data

Execute:

```sql
EXEC Silver.load_silver;
```

---

## 7. Run Silver Quality Checks

Run:

```text
scripts/silver/quality_checks_silver.sql
```

---

## 8. Create Gold Views

Run:

```text
scripts/gold/ddl_gold.sql
```

A separate Gold loading procedure is **not required** because the Gold layer consists of SQL views over the cleaned Silver data.

---

## 9. Verify the Gold Layer

Run:

```text
scripts/gold/quality_checks_gold.sql
```

Confirm that:

- Dimension values are correct
- Fact row counts match expectations
- Silver-to-Gold row counts match
- Duplicate-grain checks return no unexpected records
- Referential-integrity checks return `0` orphaned rows

---

# 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| SQL Server | Data warehouse platform |
| T-SQL | Data transformation and modeling |
| Medallion Architecture | Data-layer organization |
| Star Schema | Analytical data modeling |
| Stored Procedures | Pipeline automation |
| BULK INSERT | CSV ingestion |
| SQL Views | Gold analytical layer |
| Power BI | Intended reporting and visualization layer |

---

# 💡 SQL Concepts Demonstrated

This project demonstrates practical use of:

- Database creation
- Schema creation
- DDL
- Stored procedures
- `BULK INSERT`
- `TRUNCATE TABLE`
- `INSERT INTO ... SELECT`
- Data validation
- CTEs
- Recursive CTEs
- `CASE`
- `UNION ALL`
- `ROW_NUMBER()`
- Date functions
- Aggregate functions
- `GROUP BY`
- `LEFT JOIN`
- Fact and dimension modeling
- Star schema design
- Referential-integrity testing
- `TRY...CATCH`
- Execution-time tracking
- SQL views
- Data quality checks

---

# 📈 Potential Analytics

The warehouse can support questions such as:

- How has Lahore's PM2.5 changed over time?
- Which months have the worst air quality?
- How many unhealthy air-quality days occur each year?
- Is PM2.5 higher during Lahore's smog season?
- How does rainfall affect PM2.5?
- Does higher wind speed correspond with lower pollution?
- What percentage of recorded days were unhealthy or hazardous?
- How do weather conditions relate to daily air quality?

---

# 🔮 Future Improvements

Possible future extensions include:

- Power BI dashboard development
- Automated pipeline scheduling
- Incremental loading instead of full refreshes
- Additional Lahore monitoring stations
- Additional pollutants such as NO₂, SO₂, CO, and O₃
- ETL logging and audit tables
- Data-quality exception tables
- Dynamic date-dimension generation
- Cloud deployment
- Automated data ingestion from APIs

---

# 👤 Author

**Muhammad Jamal**  
Data Science Graduate

**GitHub:**  
https://github.com/muhammadjamal1155

**LinkedIn:**  
https://www.linkedin.com/in/muhammad-jamal-a08241240

---

## ⭐ About This Project

This project was developed as a practical **Data Engineering and Analytics portfolio project** demonstrating how raw environmental datasets can be transformed into a structured, validated, and analytics-ready data warehouse using **SQL Server, Medallion Architecture, and dimensional modeling**.

The final warehouse provides a clean foundation for analyzing Lahore's air pollution, seasonal smog patterns, and the relationship between weather conditions and PM2.5 levels.
