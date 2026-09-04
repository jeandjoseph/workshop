/* ============================================================
   LOAD ALL BRONZE TABLES (INCREMENTAL / DELTA INGESTION)
   Executes COPY INTO for each bronze table using @loda_type = 'Delta'
   Purpose:
     - Load only new or changed rows from Azure Storage
     - Preserve existing Bronze data while appending incremental updates
     - Log each ingestion event for audit and traceability
   ============================================================ */

PRINT '--- START LOADING BRONZE TABLES (DELTA MODE) ---';


/* ============================================================
   1. LOAD BRONZE.DIM_CUSTOMER
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.dim_customer',
      @FirstRow    = 2,
      @ProcessId   = 203,
      @load_type   = 'Delta',
      @AppName     = 'Electronics';
GO 

PRINT 'Loaded bronze.dim_customer';


/* ============================================================
   2. LOAD BRONZE.DIM_PRODUCT
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.dim_product',
      @FirstRow    = 2,
      @ProcessId   = 203,
      @load_type   = 'Delta',
      @AppName     = 'Electronics';
GO

PRINT 'Loaded bronze.dim_product';


/* ============================================================
   3. LOAD BRONZE.DIM_DATE
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.dim_date',
      @FirstRow    = 2,
      @ProcessId   = 203,
      @load_type   = 'Delta',
      @AppName     = 'Electronics';
GO 

PRINT 'Loaded bronze.dim_date';
[bronze].[dim_reviews]

/* ============================================================
   3. LOAD BRONZE.dim_reviews
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.dim_reviews',
      @FirstRow    = 2,
      @ProcessId   = 203,
      @load_type   = 'Delta',
      @AppName     = 'Electronics';
GO 

PRINT 'Loaded bronze.dim_date';

/* ============================================================
   4. LOAD BRONZE.FACT_SALES
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.fact_sales',
      @FirstRow    = 2,
      @ProcessId   = 203,
      @load_type   = 'Delta',
      @AppName     = 'Electronics';
GO

PRINT 'Loaded bronze.fact_sales';


/* ============================================================
   DONE
   ============================================================ */

PRINT '--- ALL BRONZE TABLES LOADED SUCCESSFULLY (DELTA MODE) ---';
