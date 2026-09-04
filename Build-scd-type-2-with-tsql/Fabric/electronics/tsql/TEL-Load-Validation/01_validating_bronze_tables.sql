/* ============================================================
   BRONZE INGESTION TEST SCRIPT (VALIDATION + LOGGING CHECKS)
   Purpose:
     - Verify required schemas exist before ingestion
     - Validate Bronze table row counts after Full loads
     - Confirm ETL logging tables capture process + error entries
     - Ensure Bronze ingestion pipeline is functioning correctly
   ============================================================ */

PRINT '--- TEST STARTED ---';


/* ============================================================
   1. VERIFY SCHEMAS EXIST
   ============================================================ */

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
    THROW 50000, 'Schema bronze does not exist. Run 01_create script first.', 1;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    THROW 50000, 'Schema silver does not exist. Run 01_create script first.', 1;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl')
    THROW 50000, 'Schema etl does not exist. Run 01_create script first.', 1;

PRINT 'Schemas verified.';


/* ============================================================
   4. VALIDATE BRONZE ROW COUNTS
   ============================================================ */

PRINT 'Validating Bronze row counts...';

SELECT 'bronze.dim_customer' AS TableName, COUNT(*) AS [RowCount]
FROM bronze.dim_customer;

SELECT 'bronze.dim_product' AS TableName, COUNT(*) AS [RowCount]
FROM bronze.dim_product;

SELECT 'bronze.dim_date' AS TableName, COUNT(*) AS [RowCount]
FROM bronze.dim_date;

SELECT 'bronze.dim_reviews' AS TableName, COUNT(*) AS [RowCount]
FROM bronze.dim_reviews;

SELECT 'bronze.fact_sales' AS TableName, COUNT(*) AS [RowCount]
FROM bronze.fact_sales;


/* ============================================================
   5. VALIDATE LOGGING TABLES
   ============================================================ */

PRINT 'Checking ETL logs...';

SELECT TOP 10 *
FROM etl.ETL_ProcessLog
ORDER BY EndTime DESC;

SELECT TOP 10 *
FROM etl.ETL_ErrorLog
ORDER BY ErrorTime DESC;


/* ============================================================
   6. TEST COMPLETE
   ============================================================ */

PRINT '--- TEST COMPLETED SUCCESSFULLY ---';
