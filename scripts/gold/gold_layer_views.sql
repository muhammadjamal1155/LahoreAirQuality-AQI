/*
===============================================================================
DDL Script: Create Gold Layer Views
===============================================================================
Project:
    Lahore Air Quality Data Warehouse

Purpose:
    This script creates the business-ready Gold layer of the data warehouse.

    The Gold layer transforms cleaned Silver data into analytical Dimension
    and Fact views designed for reporting, dashboarding, and Power BI analysis.

Architecture:
    Bronze (Raw Data)
        ↓
    Silver (Cleaned & Validated Data)
        ↓
    Gold (Business-Ready Analytical Model)

Model:
    Star Schema

Gold Objects:
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

Design Decisions:
    - Gold objects are implemented as views rather than physical tables.
    - Fact views retrieve cleaned and validated data from the Silver layer.
    - Static reference dimensions are created using SELECT and UNION ALL.
    - Business-friendly column names are introduced in the Gold layer.
    - The Date dimension provides a continuous calendar for time-series analysis.
    - AQI readings are categorized into health-related AQI groups.
    - Weather observations are categorized into readable weather conditions.
    - Alert-day indicators support air-quality monitoring and reporting.

Usage:
    Run this script after the Bronze and Silver layers have been created
    and populated successfully.

Notes:
    - No separate Gold load procedure is required because Gold objects are views.
    - Views automatically reflect changes made to the underlying Silver data.
===============================================================================
*/
