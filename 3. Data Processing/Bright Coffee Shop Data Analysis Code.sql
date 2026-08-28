-- Databricks notebook source
--============================================================
--  Data Transformation: Creating a Temporary Analytics Table
--=============================================================

CREATE OR REPLACE TABLE bright_coffee.analysis.sales_analytics AS

SELECT
    transaction_id,
    transaction_date,
    transaction_time,
    transaction_qty,
    store_id,
    store_location,
    product_id,
    product_category,
    product_type,
    product_detail,
    unit_price,

    -- Revenue
    ROUND(unit_price * transaction_qty, 2) AS total_amount,

    -- Date fields
    YEAR(transaction_date) AS transaction_year,
    MONTH(transaction_date) AS transaction_month,
    DATE_FORMAT(transaction_date, 'MMMM') AS month_name,

    DAYOFWEEK(transaction_date) AS day_number,
    DATE_FORMAT(transaction_date, 'EEEE') AS day_name,

    -- Time fields
    HOUR(transaction_time) AS transaction_hour,

      CASE
        WHEN DAYOFWEEK(transaction_date) = 1 THEN 'Sunday'
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
    END AS day_of_week,

    -- 3-hour time bucket
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
            THEN '18:00 - 20:59 | Evening'

        ELSE 'Other'
    END AS transaction_time_bucket

FROM bright_coffee.analysis.sales;

-- Preview of new table bright_coffee.analysis.sales_analytics
SELECT *
FROM bright_coffee.analysis.sales_analytics;

SELECT COUNT(*) AS total_rows
FROM bright_coffee.analysis.sales_analytics;

--===========================================================
-- Business Analysis
--===========================================================

-- Building KPIs

SELECT 
    COUNT(DISTINCT transaction_id) AS total_transaction,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS average_transaction_value
FROM bright_coffee.analysis.sales_analytics;

------------------------------
-- Analysis by Product Field
------------------------------

-- Revenue & Units sold by Product Category - Which product_category generated most revenue

SELECT 
    product_category,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee.analysis.sales_analytics
GROUP BY product_category
ORDER BY total_revenue DESC;

-- Revenue & Units sold by Product Type - Which specific products are influenicing the category results

SELECT 
    product_type,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee.analysis.sales_analytics
GROUP BY product_type
ORDER BY total_revenue DESC;

-- Revenue & Units sold by Product Details

SELECT 
    product_detail,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee.analysis.sales_analytics
GROUP BY product_detail
ORDER BY total_revenue DESC;


------------------------------
-- Analysis by Time Field
------------------------------

-- Revenue & Units sold by 3-hour time bucket - Finding when the Bright Coffee performs best

SELECT
    transaction_time_bucket,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee.analysis.sales_analytics
GROUP BY transaction_time_bucket
ORDER BY total_revenue DESC; 

-- Product Perfomance by 3-hour Time Bucket - Which products are influencing sales during each time period

SELECT 
    product_type,
    transaction_time_bucket,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee.analysis.sales_analytics
GROUP BY 
    product_type, 
    transaction_time_bucket
ORDER BY total_units_sold DESC, total_revenue DESC;


--  Creating temporary output for : Top Product Type by Revenue Within Each Time Bucket

WITH product_time_sales AS (
    SELECT
        transaction_time_bucket,
        product_type,
        SUM(transaction_qty) AS total_units_sold,
        ROUND(SUM(total_amount), 2) AS total_revenue

    FROM bright_coffee.analysis.sales_analytics

    GROUP BY
        transaction_time_bucket,
        product_type
),

ranked_products AS (
    SELECT
        transaction_time_bucket,
        product_type,
        total_units_sold,
        total_revenue,

        ROW_NUMBER() OVER (
            PARTITION BY transaction_time_bucket
            ORDER BY total_revenue DESC
        ) AS revenue_rank

    FROM product_time_sales
)

SELECT
    transaction_time_bucket,
    product_type,
    total_units_sold,
    total_revenue
FROM ranked_products
WHERE revenue_rank = 1
ORDER BY transaction_time_bucket;
------------------------------
-- Anaysis by Store Location
-----------------------------

--Revenue and Units sold by Store Location

SELECT 
    store_location,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee.analysis.sales_analytics
GROUP BY store_location
ORDER BY total_revenue DESC;


-- Revenue per Unit by Store Location

SELECT
    store_location,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(SUM(total_amount) / SUM(transaction_qty),2) AS revenue_per_unit
FROM bright_coffee.analysis.sales_analytics
GROUP BY store_location
ORDER BY revenue_per_unit DESC;

------------------------------
-- Analysis by Day of Week
------------------------------

--Revenue and Units sold by Day of Week

SELECT 
    day_name,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee.analysis.sales_analytics
GROUP BY day_name
ORDER BY total_revenue DESC;


------------------------------------
-- Analsis by Month
------------------------------------

-- Monthly sales trend

SELECT
    transaction_year,
    transaction_month,
    month_name,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee.analysis.sales_analytics
GROUP BY
    transaction_year,
    transaction_month,
    month_name
ORDER BY
    transaction_year,
    transaction_month;


-- ------------------------------------------
--  Analysis by Month-over-Month 
-- ------------------------------------------

-- Month-over-month revenue growth %

WITH monthly_sales AS (

    SELECT
        transaction_year,
        transaction_month,
        month_name,
        ROUND(SUM(total_amount), 2) AS total_revenue
    FROM bright_coffee.analysis.sales_analytics
    GROUP BY
        transaction_year,
        transaction_month,
        month_name
)

SELECT
    transaction_year,
    transaction_month,
    month_name,
    total_revenue,
    LAG(total_revenue) OVER (
        ORDER BY transaction_year, transaction_month
    ) AS previous_month_revenue,
    ROUND(
        ( total_revenue - LAG(total_revenue) OVER (
                ORDER BY transaction_year, transaction_month
            )
        ) / LAG(total_revenue) OVER (
            ORDER BY transaction_year, transaction_month
        ) * 100, 2) AS revenue_growth_pct
FROM monthly_sales
ORDER BY
    transaction_year,
    transaction_month;










