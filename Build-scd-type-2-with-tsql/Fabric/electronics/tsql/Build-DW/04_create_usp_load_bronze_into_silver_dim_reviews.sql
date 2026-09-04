/* ============================================================
   SILVER DIM_REVIEWS SCD TYPE 2 LOAD (FROM BRONZE)
   Purpose:
     - Detect attribute changes using SHA2_256 HashDiff
     - Expire old versions (set EffectiveEndDate, IsCurrent = 0)
     - Insert new SCD2 rows for new or changed Review records
     - Maintain full historical tracking of review attributes
       (Rating, Sentiment, ReviewText, ReviewDate, etc.)
     - Log success/error details for audit and lineage

   Natural Key : ReviewID
   Tracked Cols: ProductID, CustomerID, ReviewDate,
                 Sentiment, Rating, ReviewText
   Notes:
     - Processes incremental changes only (Delta-style)
     - Bronze layer is assumed to contain latest incoming data
   ============================================================ */
CREATE OR ALTER PROC etl.usp_load_bronze_into_silver_dim_reviews
(
    @TargetTable     NVARCHAR(200),
    @AppName         VARCHAR(100) = 'Electronics',
    @SourceSystem    NVARCHAR(256),
    @ProcessId       BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime    DATETIME2(3) = SYSDATETIME();
    DECLARE @EndTime      DATETIME2(3);
    DECLARE @RowsExpired  BIGINT       = 0;
    DECLARE @RowsInserted BIGINT       = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    DECLARE @Fb_ws        NVARCHAR(200);

    ---------------------------------------------------------------------
    -- Resolve workspace ID from config
    ---------------------------------------------------------------------
    SELECT TOP (1) @Fb_ws = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = 'workspace_id';

    BEGIN TRY
        BEGIN TRANSACTION;

        /* ============================================================
           1. EXPIRE CURRENT ROWS WHEN HASHDIFF HAS CHANGED
           ============================================================ */
        UPDATE tgt
        SET
            tgt.EffectiveEndDate = SYSDATETIME(),
            tgt.IsCurrent        = 0
        FROM silver.dim_reviews tgt
        INNER JOIN bronze.dim_reviews stg
            ON tgt.ReviewID = stg.ReviewID
        WHERE tgt.IsCurrent = 1
          AND tgt.HashDiff <> CONVERT(VARBINARY(32),
                HASHBYTES(
                    'SHA2_256',
                    CONCAT(
                        ISNULL(CONVERT(NVARCHAR(20), stg.ReviewID),   ''), '|',
                        ISNULL(CONVERT(NVARCHAR(20), stg.ProductID),  ''), '|',
                        ISNULL(CONVERT(NVARCHAR(20), stg.CustomerID), ''), '|',
                        ISNULL(CONVERT(NVARCHAR(10), stg.ReviewDate, 23), ''), '|',
                        ISNULL(stg.ReviewText, '')
                    )
                )
          );

        SET @RowsExpired = @@ROWCOUNT;

        /* ============================================================
           2. INSERT NEW SCD2 ROWS
           ============================================================ */
        INSERT INTO silver.dim_reviews
        (
            ReviewID,
            ProductID,
            CustomerID,
            ReviewDate,
            ReviewText,
            SentimentLabel,
            Rating,
            ExtractedEntities,
            HashDiff,
            EffectiveStartDate,
            EffectiveEndDate,
            IsCurrent,
            LoadDate
        )
        SELECT top (4)
            stg.ReviewID,
            stg.ProductID,
            stg.CustomerID,
            stg.ReviewDate,
            stg.ReviewText,

            ai_analyze_sentiment(stg.ReviewText) AS SentimentLabel,

            CASE ai_analyze_sentiment(stg.ReviewText)
                WHEN 'negative' THEN 1
                WHEN 'mixed'   THEN 2
                WHEN 'neutral' THEN 3
                WHEN 'positive' THEN 5
                ELSE 3
            END AS Rating,

            ai_extract(
                stg.ReviewText,
                'sentiment',
                'problem',
                'time_reported',
                'topic',
                'category',
                'product'
            ) AS ExtractedEntities,

            CONVERT(VARBINARY(32),
                HASHBYTES(
                    'SHA2_256',
                    CONCAT(
                        ISNULL(CONVERT(NVARCHAR(20), stg.ReviewID),   ''), '|',
                        ISNULL(CONVERT(NVARCHAR(20), stg.ProductID),  ''), '|',
                        ISNULL(CONVERT(NVARCHAR(20), stg.CustomerID), ''), '|',
                        ISNULL(CONVERT(NVARCHAR(10), stg.ReviewDate, 23), ''), '|',
                        ISNULL(stg.ReviewText, '')
                    )
                )
            ) AS HashDiff,

            SYSDATETIME() AS EffectiveStartDate,
            NULL          AS EffectiveEndDate,
            1             AS IsCurrent,
            SYSDATETIME() AS LoadDate

        FROM bronze.dim_reviews stg
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM silver.dim_reviews tgt
            WHERE tgt.ReviewID  = stg.ReviewID
              AND tgt.IsCurrent = 1
              AND tgt.HashDiff  = CONVERT(VARBINARY(32),
                    HASHBYTES(
                        'SHA2_256',
                        CONCAT(
                            ISNULL(CONVERT(NVARCHAR(20), stg.ReviewID),   ''), '|',
                            ISNULL(CONVERT(NVARCHAR(20), stg.ProductID),  ''), '|',
                            ISNULL(CONVERT(NVARCHAR(20), stg.CustomerID), ''), '|',
                            ISNULL(CONVERT(NVARCHAR(10), stg.ReviewDate, 23), ''), '|',
                            ISNULL(stg.ReviewText, '')
                        )
                    ))
        );

        SET @RowsInserted = @@ROWCOUNT;

        /* ============================================================
           3. LOG SUCCESS
           ============================================================ */
        SET @EndTime = SYSDATETIME();

        EXEC etl.sp_log_process_success
            @ProcessName       = 'Load silver.dim_reviews from bronze',
            @WorkspaceID       = @Fb_ws,
            @DestinationSystem = @TargetTable,
            @SourceSystem      = @SourceSystem,
            @RowsInserted      = @RowsInserted,
            @StartTime         = @StartTime,
            @EndTime           = @EndTime,
            @ProcessId         = @ProcessId;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();

        EXEC etl.sp_log_process_error
            @ProcessName       = 'Load silver.dim_reviews from bronze',
            @WorkspaceID       = @Fb_ws,
            @DestinationSystem = @TargetTable,
            @SourceSystem      = @SourceSystem,
            @ErrorMessage      = @ErrorMessage,
            @ProcessId         = @ProcessId;

        THROW;
    END CATCH;
END;
GO
