/* ============================================================
   SILVER DIM_PRODUCT SCD TYPE 2 LOAD (FROM BRONZE)
   Purpose:
     - Detect attribute changes using SHA2_256 HashDiff
     - Expire old versions (set EffectiveEndDate, IsCurrent = 0)
     - Insert new SCD2 rows for changed or new Product records
     - Maintain full historical tracking of dimension changes
     - Log success/error details for full audit traceability
   Notes:
     - This procedure processes incremental changes only
     - Bronze is assumed to contain the latest incoming data
   ============================================================ */

CREATE OR ALTER PROC etl.usp_load_bronze_into_silver_dim_product
(
    @TargetTable       NVARCHAR(200),
    @AppName           VARCHAR(100) = 'Electronics',
    @SourceSystem      NVARCHAR(256),
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
    -- get workspace ID
    ---------------------------------------------------------------------
    SELECT TOP(1) @Fb_ws = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = 'workspace_id';

    BEGIN TRY
        BEGIN TRANSACTION;

        /* ============================================================
           1️ EXPIRE OLD ROWS WHERE HASHDIFF HAS CHANGED
           ============================================================ */
        UPDATE tgt
        SET 
            tgt.EffectiveEndDate = SYSDATETIME(),
            tgt.IsCurrent        = 0
        FROM silver.dim_product tgt
        INNER JOIN bronze.dim_product stg
            ON tgt.ProductID = stg.ProductID
        WHERE tgt.IsCurrent = 1
          AND tgt.HashDiff <> CONVERT(VARBINARY(128),
                HASHBYTES(
                    'SHA2_256',
                    CONCAT(
                        stg.ProductID, '|', stg.ProductName, '|',
                        stg.Category, '|', stg.UnitPrice
                    )
                )
          );

        /* ============================================================
           2 INSERT NEW SCD2 ROWS
           ============================================================ */
        INSERT INTO silver.dim_product
        (
            ProductID, ProductName, Category, UnitPrice,
            HashDiff, EffectiveStartDate, EffectiveEndDate,
            IsCurrent, LoadDate
        )
        SELECT
            stg.ProductID,
            stg.ProductName,
            stg.Category,
            stg.UnitPrice,
            CONVERT(VARBINARY(128),
                HASHBYTES(
                    'SHA2_256',
                    CONCAT(
                        stg.ProductID, '|', stg.ProductName, '|',
                        stg.Category, '|', stg.UnitPrice
                    )
                )
            ) AS HashDiff,
            SYSDATETIME() AS EffectiveStartDate,
            NULL          AS EffectiveEndDate,
            1             AS IsCurrent,
            SYSDATETIME() AS LoadDate
        FROM bronze.dim_product stg
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM silver.dim_product tgt
            WHERE tgt.ProductID = stg.ProductID
            AND tgt.HashDiff = CONVERT(VARBINARY(128),
                    HASHBYTES(
                        'SHA2_256',
                        CONCAT(
                            stg.ProductID, '|', stg.ProductName, '|',
                            stg.Category, '|', stg.UnitPrice
                        )
            ))
            AND tgt.IsCurrent = 1
        );

        SET @RowsInserted = @@ROWCOUNT;

        /* ============================================================
           3 LOG SUCCESS
           ============================================================ */
        SET @EndTime = SYSDATETIME();

        EXEC etl.sp_log_process_success
            @ProcessName        = 'Load silver.dim_product from bronze',
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
            @ProcessName        = 'Load silver.dim_product from bronze',
            @WorkspaceID        = @Fb_ws,
            @DestinationSystem  = @TargetTable,
            @SourceSystem       = @SourceSystem,
            @ErrorMessage       = @ErrorMessage,
            @ProcessId          = @ProcessId;            

        THROW;
    END CATCH;
END;
GO
