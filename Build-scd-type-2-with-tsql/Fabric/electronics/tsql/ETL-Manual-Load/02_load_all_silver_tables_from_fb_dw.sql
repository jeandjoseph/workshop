/* ============================================================
   RUN BRONZE → SILVER LOADS FOR ALL DIMENSIONS & FACT TABLES
   Each procedure:
     - Reads from bronze.<table>
     - Applies SCD logic (if dimension)
     - Loads into silver.<table>
     - Logs process execution using @ProcessId
   ============================================================ */

EXEC etl.usp_load_bronze_into_silver_dim_product
      @TargetTable       = 'silver.dim_product',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.dim_product',
      @ProcessId         = 202;
GO

EXEC etl.usp_load_bronze_into_silver_dim_customer
      @TargetTable       = 'silver.dim_customer',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.dim_customer',
      @ProcessId         = 202;
GO

EXEC etl.usp_load_bronze_into_silver_dim_date
      @TargetTable       = 'silver.dim_date',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.dim_date',
      @ProcessId         = 202;
GO

EXEC etl.usp_load_bronze_into_silver_dim_reviews
      @TargetTable       = 'silver.dim_reviews',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.dim_reviews',
      @ProcessId         = 202;
GO


EXEC etl.usp_load_bronze_into_silver_fact_sales
      @TargetTable       = 'silver.fact_sales',
      @AppName           = 'Electronics',
      @SourceSystem      = 'bronze.fact_sales',
      @ProcessId         = 202;
GO