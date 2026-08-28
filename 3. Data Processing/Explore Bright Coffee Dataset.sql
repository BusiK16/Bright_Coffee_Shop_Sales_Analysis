-- Databricks notebook source
--============================================================
-- Bright Coffee Shop Sales Anlysis: 01. DATA INSPECTION
--============================================================

--------------------------------------------------------------
-- 1.1 Data Exploration
--------------------------------------------------------------
-- Previewing sales table
SELECT *
FROM bright_coffee.analysis.sales
LIMIT 10; -- 11 columns

-- Inspecting structure of table - data types
DESCRIBE bright_coffee.analysis.sales;

-- Checking total rows in table 
SELECT COUNT(*) AS total_rows
FROM bright_coffee.analysis.sales; -- 149116

------------------------------------------------------------
-- 1.2 Checking transaction fields
------------------------------------------------------------

-- Checking transaction date range - earliest and latest transaction dates
SELECT
    MIN(transaction_date) AS earliest_date,
    MAX(transaction_date) AS latest_date
FROM bright_coffee.analysis.sales; -- 2023-01-01 - 2023-06-30

-- Checking transaction time range - earliest and latest trasaction times
SELECT
    MIN(transaction_time) AS earliest_time,
    MAX(transaction_time) AS latest_time
FROM bright_coffee.analysis.sales; -- default date is 2026-08-21, min_time 06:00:00, max_time 20:59:32

----------------------------------------------------------------------------------
-- 1.3 Product Fields Inspection
----------------------------------------------------------------------------------
-- product_category Check
SELECT DISTINCT product_category
FROM bright_coffee.analysis.sales
ORDER BY product_category ASC; -- 9 categories

-- product_type Check
SELECT DISTINCT product_type
FROM bright_coffee.analysis.sales
ORDER BY product_type ASC; -- 29 product types

-- Product_detail Check
SELECT DISTINCT product_detail
FROM bright_coffee.analysis.sales
ORDER BY product_detail ASC; --80 product details

--------------------------------------------------------------
-- 1.4 Store Location Inspection
--------------------------------------------------------------
-- Store_location Check
SELECT DISTINCT store_location
FROM bright_coffee.analysis.sales
ORDER BY store_location; -- 3 locations

-- Product fields checked
-- 9 product categories, 29 product types 80 product details and 3 store locations



--=============================================================
-- 02. DATA QUALITY CHECKS
--=============================================================

---------------------------------------------------------------
-- 2.1 Checking for NULL values
---------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS null_transaction_date,
    SUM(CASE WHEN transaction_time IS NULL THEN 1 ELSE 0 END) AS null_transaction_time,
    SUM(CASE WHEN transaction_qty IS NULL THEN 1 ELSE 0 END) AS null_transaction_qty,
    SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS null_store_id,
    SUM(CASE WHEN store_location IS NULL THEN 1 ELSE 0 END) AS null_store_location,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN product_category IS NULL THEN 1 ELSE 0 END) AS null_product_category,
    SUM(CASE WHEN product_type IS NULL THEN 1 ELSE 0 END) AS null_product_type,
    SUM(CASE WHEN product_detail IS NULL THEN 1 ELSE 0 END) AS null_product_detail

FROM bright_coffee.analysis.sales;


---------------------------------------------------------------
-- 2.2 Checking for duplicate transaction IDs
---------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT transaction_id) AS unique_transactions
FROM bright_coffee.analysis.sales;


-- Identify transaction_ids appearing more than once
SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM bright_coffee.analysis.sales
GROUP BY transaction_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC; -- No rows returned = No transaction_id duplicates


---------------------------------------------------------------
-- 2.3 Checking transaction quantities
---------------------------------------------------------------

SELECT
    MIN(transaction_qty) AS min_qty,
    MAX(transaction_qty) AS max_qty,
    COUNT(
        CASE
            WHEN transaction_qty < 0 OR transaction_qty = 0  THEN 1
        END
    ) AS non_positive_qty
FROM bright_coffee.analysis.sales; -- min (1), max(8), non_pos (0), valid qtys


---------------------------------------------------------------
-- 2.4 Checking unit prices
---------------------------------------------------------------

-- Confirm how unit_price is stored
SELECT DISTINCT unit_price
FROM bright_coffee.analysis.sales
ORDER BY unit_price;-- unit_price is in DOUBLE format 1.2 and not string 1,2

-- Case if unit_price was in string format and not double, then:
SELECT DISTINCT unit_price,
CAST(REPLACE(unit_price, ',', '.') AS DOUBLE) AS cast_unit_price
FROM bright_coffee.analysis.sales
ORDER BY cast_unit_price;

-- Check price range (cheapest & most expensive) and invalid prices (based on actual values)
SELECT
    MIN(unit_price) AS min_price,
    MAX(unit_price) AS max_price,
    COUNT(
        CASE
            WHEN unit_price < 0 OR unit_price = 0 THEN 1
        END
    ) AS non_positive_price
FROM bright_coffee.analysis.sales; -- min(0.8), max(45), invalid price (0)= no price is < or > than the range


---------------------------------------------------------------
-- 2.5 Checking product fields for NULL or blank values
---------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN TRIM(product_category) = '' THEN 1 ELSE 0 END) AS blank_product_category,
    SUM(CASE WHEN TRIM(product_type) = '' THEN 1 ELSE 0 END) AS blank_product_type,
    SUM(CASE WHEN TRIM(product_detail) = '' THEN 1 ELSE 0 END) AS blank_product_detail,
    SUM(CASE WHEN TRIM(store_location) = '' THEN 1 ELSE 0 END) AS blank_store_location
FROM bright_coffee.analysis.sales; -- all product field rows do not have a blank value(s)


---------------------------------------------------------------
-- 2.6 Checking transaction dates
---------------------------------------------------------------


-- Check for missing transaction dates
SELECT
    COUNT(*) AS total_rows,
    COUNT(
        CASE
            WHEN transaction_date IS NULL THEN 1
        END
    ) AS missing_dates
FROM bright_coffee.analysis.sales; -- all rows have no missing dates


-- Check for dates outside the expected period
SELECT
    COUNT(*) AS unexpected_dates
FROM bright_coffee.analysis.sales
WHERE transaction_date < '2023-01-01'
   OR transaction_date > '2023-06-30'; -- all rows have dates falling within the date range, no outliers.


---------------------------------------------------------------
-- 2.7 Checking transaction times
---------------------------------------------------------------

-- Checking if date portion is the same for every record
SELECT DISTINCT DATE(transaction_time) AS time_date
FROM bright_coffee.analysis.sales
ORDER BY time_date;

SELECT
    MIN(transaction_time) AS earliest_time,
    MAX(transaction_time) AS latest_time
FROM bright_coffee.analysis.sales; -- default date is 2026-08-21, min_time 06:00:00, max_time 20:59:32


-- Check for missing transaction times
SELECT
    COUNT(*) AS total_rows,
    COUNT(
        CASE
            WHEN transaction_time IS NULL THEN 1
        END
    ) AS missing_times
FROM bright_coffee.analysis.sales; -- no missing transaction_times, time valid

--============================================================
-- END OF DATA INSPECTION & DATA QUALITY CHECKS
-- Product fields checked
-- 9 product categories, 29 product types 80 product details and 3 store locations
-- No NULL or empty values found
-- Product fields require no transformation
-- Unit price field requires no transformation or CAST, values are in DOUBLE and not String
--============================================================


--=============================================================
-- 03. DATA CLEANING & TRANSFORMATION
--=============================================================
-- This section will create:
--  total_amount
--   month_name
--   day_name
--   transaction_hour
--   transaction_time_bucket

-- ============================================================

---------------------------------------------------------------
-- 3.1 Creating total_amount 
---------------------------------------------------------------

SELECT 
    transaction_id,
    transaction_qty,
    unit_price,
    ROUND(unit_price * transaction_qty, 2) AS total_amount
FROM bright_coffee.analysis.sales
ORDER BY total_amount DESC;

-- ------------------------------------------------------------
-- 3.2 Creating date fields
-- ------------------------------------------------------------

SELECT
    transaction_date,
    YEAR(transaction_date) AS transaction_year,
    MONTH(transaction_date) AS transaction_month,
    DATE_FORMAT(transaction_date, 'MMMM') AS month_name
FROM bright_coffee.analysis.sales
ORDER BY transaction_date ASC;


-- ------------------------------------------------------------
-- 3.3 Creating day-of-week fields
-- ------------------------------------------------------------

SELECT
    transaction_date,
    DAYOFWEEK(transaction_date) AS day_number,
    DATE_FORMAT(transaction_date, 'EEEE') AS day_name
FROM bright_coffee.analysis.sales
ORDER BY transaction_date ASC;


-- ------------------------------------------------------------
-- 3.4 Creating transaction hour/ time field
-- ------------------------------------------------------------

SELECT
    transaction_time,
    HOUR(transaction_time) AS transaction_hour
FROM bright_coffee.analysis.sales
ORDER BY transaction_time ASC;


-- ------------------------------------------------------------
-- 3.5 Creating 3-hour transaction time buckets
-- ------------------------------------------------------------

SELECT
    transaction_time,
    HOUR(transaction_time) AS transaction_hour,

    CASE
        WHEN HOUR(transaction_time) BETWEEN 6 AND 8
            THEN '06:00 - 08:59 | Early Morning'

        WHEN HOUR(transaction_time) BETWEEN 9 AND 11
            THEN '09:00 - 11:59 | Late Morning'

        WHEN HOUR(transaction_time) BETWEEN 12 AND 14
            THEN '12:00 - 14:59 | Early Afternoon'

        WHEN HOUR(transaction_time) BETWEEN 15 AND 17
            THEN '15:00 - 17:59 | Late Afternoon'

        WHEN HOUR(transaction_time) BETWEEN 18 AND 20
            THEN '18:00 - 20:59 | Evenining'

        ELSE 'Other'
    END AS transaction_time_bucket

FROM bright_coffee.analysis.sales
ORDER BY transaction_time;


