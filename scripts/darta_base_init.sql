/*
===============================================================================
Database Initialization Script
===============================================================================
Project:
    Lahore Air Quality Data Warehouse

Purpose:
    This script initializes the SQL Server database and creates the schemas
    required for implementing the Medallion Architecture.

Database:
    LahoreAirQuality_DW

Schemas:
    - Bronze : Stores raw data ingested directly from source files.
    - Silver : Stores cleaned, validated, and standardized data.
    - Gold   : Stores business-ready analytical views, dimensions, and facts.

Architecture:
    Source Data
        ↓
    Bronze (Raw)
        ↓
    Silver (Cleaned & Validated)
        ↓
    Gold (Business-Ready)

Usage:
    Run this script before executing any Bronze, Silver, or Gold layer scripts.

Warning:
    This script creates a new database. Ensure that a database with the same
    name does not already exist before execution.
===============================================================================
*/


-- =============================================================================
-- Create Database
-- =============================================================================

CREATE DATABASE LahoreAirQuality_DW;
GO

USE LahoreAirQuality_DW;
GO


-- =============================================================================
-- Create Medallion Architecture Schemas
-- =============================================================================

-- Bronze Layer: Raw source data
CREATE SCHEMA Bronze;
GO

-- Silver Layer: Cleaned, standardized, and validated data
CREATE SCHEMA Silver;
GO

-- Gold Layer: Business-ready analytical model
CREATE SCHEMA Gold;
GO
