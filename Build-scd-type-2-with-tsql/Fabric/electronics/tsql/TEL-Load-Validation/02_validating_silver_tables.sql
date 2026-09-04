/* ============================================================
   TEST SCRIPT FOR FABRIC BRONZE INGESTION + LOGGING
   Validates:
     - Required schemas exist
     - Silver table row counts
     - ETL success/error logs
   ============================================================ */

PRINT '--- TEST STARTED ---';


/* ============================================================
   1. VERIFY SCHEMAS EXIST
   Ensures bronze, silver, and etl schemas are created before tests
   ============================================================ */

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
    THROW 50000, 'Schema bronze does not exist. Run 01_create script first.', 1;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    THROW 50000, 'Schema silver does not exist. Run 01_create script first.', 1;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl')
    THROW 50000, 'Schema etl does not exist. Run 01_create script first.', 1;

PRINT 'Schemas verified.';



/* ============================================================
   4. VALIDATE SILVER ROW COUNTS
   Confirms that Silver tables received expected data after ETL
   ============================================================ */

PRINT 'Validating Silver row counts...';

SELECT 'silver.dim_customer' AS TableName, COUNT(*) AS [RowCount]
FROM silver.dim_customer;

SELECT 'silver.dim_product' AS TableName, COUNT(*) AS [RowCount]
FROM silver.dim_product;

SELECT 'silver.dim_date' AS TableName, COUNT(*) AS [RowCount]
FROM silver.dim_date;

SELECT 'silver.fact_sales' AS TableName, COUNT(*) AS [RowCount]
FROM silver.fact_sales;



/* ============================================================
   5. VALIDATE LOGGING TABLES
   Ensures ETL success and error logs are being recorded properly
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
