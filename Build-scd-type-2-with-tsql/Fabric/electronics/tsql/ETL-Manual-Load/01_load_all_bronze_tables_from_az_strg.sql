/* ============================================================
   LOAD ALL BRONZE TABLES (FULL LOAD INGESTION)
   Purpose:
     - Reload all Bronze tables from Azure Storage
     - Uses @load_type = 'FullLoad' to pull complete datasets
     - Overwrites existing Bronze data via TRUNCATE + COPY INTO
     - Ensures a clean baseline before Delta loads or SCD2 processing
   ============================================================ */

--SELECT * FROM [etl].[ETL_ErrorLog]  

--SELECT * FROM [etl].[ETL_ProcessLog]

PRINT '--- START LOADING BRONZE TABLES (FULL LOAD) ---';


/* ============================================================
   1. LOAD BRONZE.DIM_CUSTOMER
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.dim_customer',
      @FirstRow    = 2,
      @ProcessId   = 202,
      @load_type   = 'FullLoad',
      @AppName     = 'Electronics';

PRINT 'Loaded bronze.dim_customer';


/* ============================================================
   2. LOAD BRONZE.DIM_PRODUCT
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.dim_product',
      @FirstRow    = 2,
      @ProcessId   = 202,
      @load_type   = 'FullLoad',
      @AppName     = 'Electronics';

PRINT 'Loaded bronze.dim_product';


/* ============================================================
   3. LOAD BRONZE.DIM_DATE
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.dim_date',
      @FirstRow    = 2,
      @ProcessId   = 202,
      @load_type   = 'FullLoad',
      @AppName     = 'Electronics';

PRINT 'Loaded bronze.dim_date';



/* ============================================================
   3. LOAD BRONZE.DIM_DATE
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.dim_reviews',
      @FirstRow    = 2,
      @ProcessId   = 202,
      @load_type   = 'FullLoad',
      @AppName     = 'Electronics';

PRINT 'Loaded bronze.dim_reviews';



/* ============================================================
   4. LOAD BRONZE.FACT_SALES
   ============================================================ */
EXEC etl.usp_load_electronics_csv_file_into_bronze_tables
      @TargetTable = 'bronze.fact_sales',
      @FirstRow    = 2,
      @ProcessId   = 202,
      @load_type   = 'FullLoad',
      @AppName     = 'Electronics';

PRINT 'Loaded bronze.fact_sales';


/* ============================================================
   DONE
   ============================================================ */

PRINT '--- ALL BRONZE TABLES LOADED SUCCESSFULLY (FULL LOAD) ---';
