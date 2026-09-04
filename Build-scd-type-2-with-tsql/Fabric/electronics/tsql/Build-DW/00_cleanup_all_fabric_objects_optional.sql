/* ============================================================
   FABRIC DW CLEANUP SCRIPT (SAFE DROP WITH IF EXISTS)
   Purpose:
     - Remove all ETL stored procedures, logging tables,
       Silver tables, Bronze tables, and schemas
     - Drops objects in correct dependency order
     - Uses DROP IF EXISTS for safe, repeatable execution
   Notes:
     - Designed for full environment reset or rebuild
     - Order matters: procedures → tables → schemas
   ============================================================ */


/* ============================
   1. DROP STORED PROCEDURES
   ============================ */
DROP PROCEDURE IF EXISTS etl.usp_load_bronze_into_silver_dim_customer;
DROP PROCEDURE IF EXISTS etl.usp_load_bronze_into_silver_dim_date;
DROP PROCEDURE IF EXISTS etl.usp_load_bronze_into_silver_dim_product;
DROP PROCEDURE IF EXISTS etl.usp_load_bronze_into_silver_fact_sales;
DROP PROCEDURE IF EXISTS etl.usp_load_electronics_csv_file_into_bronze_tables;
DROP PROCEDURE IF EXISTS etl.sp_log_process_error;
DROP PROCEDURE IF EXISTS etl.sp_log_process_success;
DROP PROCEDURE IF EXISTS etl.usp_get_az_strg_file_endpoint
DROP PROCEDURE IF EXISTS etl.usp_load_bronze_into_silver_dim_reviews
/* ============================
   2. DROP LOGGING TABLES
   ============================ */
DROP TABLE IF EXISTS etl.ETL_ProcessLog;
DROP TABLE IF EXISTS etl.ETL_ErrorLog;
DROP TABLE IF EXISTS etl.config_variables;


/* ============================
   3. DROP SILVER TABLES
   ============================ */

-- Remove PK constraints (if they exist)
ALTER TABLE silver.dim_customer DROP CONSTRAINT IF EXISTS PK_silver_dim_customer;
ALTER TABLE silver.dim_product DROP CONSTRAINT IF EXISTS PK_silver_dim_product;
ALTER TABLE silver.dim_date DROP CONSTRAINT IF EXISTS PK_silver_dim_date;
ALTER TABLE silver.dim_reviews DROP CONSTRAINT IF EXISTS PK_silver_dim_reviews;


-- Drop tables
DROP TABLE IF EXISTS silver.fact_sales;
DROP TABLE IF EXISTS silver.dim_customer;
DROP TABLE IF EXISTS silver.dim_product;
DROP TABLE IF EXISTS silver.dim_date;
DROP TABLE IF EXISTS silver.dim_reviews;


/* ============================
   4. DROP BRONZE TABLES
   ============================ */
DROP TABLE IF EXISTS bronze.fact_sales;
DROP TABLE IF EXISTS bronze.dim_customer;
DROP TABLE IF EXISTS bronze.dim_product;
DROP TABLE IF EXISTS bronze.dim_date;
DROP TABLE IF EXISTS bronze.dim_reviews;

/* ============================
   5. DROP SCHEMAS
   ============================ */
DROP SCHEMA IF EXISTS silver;
DROP SCHEMA IF EXISTS bronze;
DROP SCHEMA IF EXISTS etl;