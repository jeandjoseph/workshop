/* ============================================================
   LOAD ALL SILVER TABLES FROM BRONZE (SCD2 + INCREMENTAL FACTS)
   Purpose:
     - Apply SCD Type 2 processing for all dimension tables
     - Insert only new or changed rows into Silver dimensions
     - Load incremental transactional rows into fact_sales
     - Maintain historical tracking + referential integrity
     - Execute all Silver‑layer ETL stored procedures in order
   Notes:
     - Bronze layer must already be refreshed (Full or Delta)
     - ProcessId should uniquely identify each ETL run
   ============================================================ */

PRINT '--- START LOADING BRONZE TABLES (DELTA MODE) ---';

EXEC etl.usp_load_bronze_into_silver_dim_product
      @TargetTable       = 'silver.dim_product',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.dim_product',
      @ProcessId         = 203;
GO

EXEC etl.usp_load_bronze_into_silver_dim_customer
      @TargetTable       = 'silver.dim_customer',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.dim_customer',
      @ProcessId         = 203;
GO


EXEC etl.usp_load_bronze_into_silver_dim_date
      @TargetTable       = 'silver.dim_date',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.dim_date',
      @ProcessId         = 203;
GO


EXEC etl.usp_load_bronze_into_silver_dim_reviews
      @TargetTable       = 'silver.dim_reviews',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.dim_reviews',
      @ProcessId         = 203;
GO


EXEC etl.usp_load_bronze_into_silver_fact_sales
      @TargetTable       = 'silver.fact_sales',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.fact_sales',
      @ProcessId         = 203;
GO