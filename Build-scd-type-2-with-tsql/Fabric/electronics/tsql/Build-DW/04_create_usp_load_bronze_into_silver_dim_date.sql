/* ============================================================
   SILVER DIM_DATE SCD TYPE 2 LOAD (FROM BRONZE)
   Purpose:
     - Detect attribute changes using SHA2_256 HashDiff
     - Expire old versions (set EffectiveEndDate, IsCurrent = 0)
     - Insert new SCD2 rows for new or changed Date records
     - Maintain full historical tracking for date attributes
     - Log success/error details for audit and lineage
   Notes:
     - Processes incremental changes only (Delta-style)
     - Bronze layer is assumed to contain latest incoming data
   ============================================================ */

CREATE OR ALTER PROC etl.usp_load_bronze_into_silver_dim_date
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
    -- get workspace ID
    ---------------------------------------------------------------------
    SELECT TOP(1) @Fb_ws = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = 'workspace_id';

    BEGIN TRY
        BEGIN TRANSACTION;

        /* ============================================================
           1️⃣ EXPIRE OLD ROWS WHERE HASHDIFF HAS CHANGED
           ============================================================ */
        UPDATE tgt
        SET 
            tgt.EffectiveEndDate = SYSDATETIME(),
            tgt.IsCurrent        = 0
        FROM silver.dim_date tgt
        INNER JOIN bronze.dim_date stg
            ON tgt.DateID = stg.DateID
        WHERE tgt.IsCurrent = 1
          AND tgt.HashDiff <> CONVERT(VARBINARY(128),
                HASHBYTES(
                    'SHA2_256',
                    CONCAT(
                        stg.DateID, '|', stg.FullDate, '|',
                        stg.Year, '|', stg.Month, '|',
                        stg.Day, '|', stg.Quarter
                    )
                )
          );

        /* ============================================================
           2️⃣ INSERT NEW SCD2 ROWS (ONLY NEW OR CHANGED)
           ============================================================ */
        INSERT INTO silver.dim_date
        (
            DateID, FullDate, Year, Month, Day, Quarter,
            HashDiff, EffectiveStartDate, EffectiveEndDate,
            IsCurrent, LoadDate
        )
        SELECT
            stg.DateID,
            stg.FullDate,
            stg.Year,
            stg.Month,
            stg.Day,
            stg.Quarter,
            CONVERT(VARBINARY(128),
                HASHBYTES(
                    'SHA2_256',
                    CONCAT(
                        stg.DateID, '|', stg.FullDate, '|',
                        stg.Year, '|', stg.Month, '|',
                        stg.Day, '|', stg.Quarter
                    )
                )
            ) AS HashDiff,
            SYSDATETIME() AS EffectiveStartDate,
            NULL          AS EffectiveEndDate,
            1             AS IsCurrent,
            SYSDATETIME() AS LoadDate
        FROM bronze.dim_date stg
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM silver.dim_date tgt
            WHERE tgt.DateID = stg.DateID
              AND tgt.HashDiff = CONVERT(VARBINARY(128),
                    HASHBYTES(
                        'SHA2_256',
                        CONCAT(
                            stg.DateID, '|', stg.FullDate, '|',
                            stg.Year, '|', stg.Month, '|',
                            stg.Day, '|', stg.Quarter
                        )
              ))
              AND tgt.IsCurrent = 1
        );

        SET @RowsInserted = @@ROWCOUNT;

        /* ============================================================
           3️⃣ LOG SUCCESS
           ============================================================ */
        SET @EndTime = SYSDATETIME();

        EXEC etl.sp_log_process_success
            @ProcessName        = 'Load silver.dim_date from bronze',
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
            @ProcessName        = 'Load silver.dim_date from bronze',
            @WorkspaceID        = @Fb_ws,
            @DestinationSystem  = @TargetTable,
            @SourceSystem       = @SourceSystem,
            @ErrorMessage       = @ErrorMessage,
            @ProcessId          = @ProcessId;

        THROW;
    END CATCH;
END;
GO
