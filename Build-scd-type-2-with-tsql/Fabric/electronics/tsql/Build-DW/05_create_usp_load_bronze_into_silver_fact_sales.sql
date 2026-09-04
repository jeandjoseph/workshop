/* ============================================================
   SILVER FACT_SALES INCREMENTAL LOAD (FROM BRONZE)
   Purpose:
     - Load new transactional sales records into silver.fact_sales
     - Enforce referential integrity via Date, Customer, Product lookups
     - Insert only new TransactionID values (deduped incremental load)
     - Maintain clean, append‑only fact table structure
     - Log success/error details for audit and lineage tracking
   Notes:
     - Fact tables are NOT SCD2; only new rows are inserted
     - Bronze layer is assumed to contain latest incremental data
   ============================================================ */

CREATE OR ALTER PROC etl.usp_load_bronze_into_silver_fact_sales
(
    @TargetTable       NVARCHAR(200),
    @AppName           VARCHAR(100) = 'Electronics',
    @SourceSystem      NVARCHAR(256),
   -- @DestinationSystem NVARCHAR(256),
    @ProcessId         BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime     DATETIME2(3) = SYSDATETIME();
    DECLARE @EndTime       DATETIME2(3);
    DECLARE @RowsInserted  BIGINT       = 0;
    DECLARE @ErrorMessage  NVARCHAR(MAX);
    DECLARE @Fb_ws         NVARCHAR(200);

    ---------------------------------------------------------------------
    -- Load workspace ID
    ---------------------------------------------------------------------
    SELECT TOP(1) @Fb_ws = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = 'workspace_id';

    BEGIN TRY
        BEGIN TRANSACTION;

        /* ============================================================
           1️⃣ INSERT FACT ROWS (DEDUPED + DIM LOOKUPS)
           ============================================================ */
        INSERT INTO silver.fact_sales
        (
            TransactionID, DateID, CustomerID, ProductID,
            Quantity, UnitPrice, TotalAmount, LoadDate
        )
        SELECT
            f.TransactionID,
            f.DateID,
            f.CustomerID,
            f.ProductID,
            f.Quantity,
            f.UnitPrice,
            f.TotalAmount,
            SYSDATETIME()
        FROM bronze.fact_sales f
        INNER JOIN bronze.dim_date d
            ON f.DateID = d.DateID
        INNER JOIN bronze.dim_customer c
            ON f.CustomerID = c.CustomerID
        INNER JOIN bronze.dim_product p
            ON f.ProductID = p.ProductID
        WHERE NOT EXISTS (
            SELECT 1
            FROM silver.fact_sales s
            WHERE s.TransactionID = f.TransactionID
        );

        SET @RowsInserted = @@ROWCOUNT;

        /* ============================================================
           2️⃣ LOG SUCCESS
           ============================================================ */
        SET @EndTime = SYSDATETIME();

        EXEC etl.sp_log_process_success
            @ProcessName        = 'Load silver.fact_sales from bronze',
            @WorkspaceID        = @Fb_ws,
            @DestinationSystem  = @TargetTable,
            @SourceSystem       = @SourceSystem,
            @RowsInserted       = @RowsInserted,
            @StartTime          = @StartTime,
            @EndTime            = @EndTime,
            @ProcessId          = @ProcessId;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();

        EXEC etl.sp_log_process_error
            @ProcessName        = 'Load silver.fact_sales from bronze',
            @WorkspaceID        = @Fb_ws,
            @DestinationSystem  = @TargetTable,
            @SourceSystem       = @SourceSystem,
            @ErrorMessage       = @ErrorMessage,
            @ProcessId          = @ProcessId;

        THROW;
    END CATCH;
END;
GO
