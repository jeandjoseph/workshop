/****** Object:  StoredProcedure [etl].[usp_load_electronics_csv_file_into_bronze_tables]    Script Date: 6/7/2026 11:59:48 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* ============================================================
   BRONZE INGESTION STORED PROCEDURE (FULL + INCREMENTAL LOADS)
   Purpose:
     - Load CSV files from Azure Storage into bronze.<table>
     - Supports both FullLoad and Delta (incremental) ingestion
     - Dynamically resolves file paths based on load type + table
     - Executes COPY INTO for high‑performance ingestion
     - Logs success/error details for full audit traceability
   Parameters:
     @TargetTable  → bronze table to load
     @FirstRow     → header row handling for CSV
     @ProcessId    → ETL run identifier for logging
     @loda_type    → 'FullLoad' or 'Delta' (incremental)
     @AppName      → application namespace for config lookup
   ============================================================ */

CREATE OR ALTER  PROCEDURE [etl].[usp_load_electronics_csv_file_into_bronze_tables]
(
    @TargetTable NVARCHAR(200),
    @FirstRow    INT,
    @ProcessId   BIGINT,
    @load_type   VARCHAR(50),  -- 'FullLoad' | 'Delta'
    @AppName     VARCHAR(100) = 'Electronics',
    @Full_File_Path VARCHAR(128)=NULL --NULL allows you to run without automation
)
AS
BEGIN
    DECLARE @StartTime      DATETIME2(3) = SYSDATETIME();
    DECLARE @EndTime        DATETIME2(3);
    DECLARE @RowsInserted   BIGINT       = 0;
    DECLARE @sql            NVARCHAR(MAX);
    DECLARE @CountSQL       NVARCHAR(MAX);
    DECLARE @ErrorMessage   NVARCHAR(MAX);
    DECLARE @ProcessName    VARCHAR(100);

    ---------------------------------------------------------------------
    -- NEW VARIABLE SET
    ---------------------------------------------------------------------
    DECLARE @az_strg_ednpoint  VARCHAR(128),
            @az_strg_container VARCHAR(50),
            @az_strg_file_dir  VARCHAR(128),
            @file_name         VARCHAR(50),
            @csv_file_name     VARCHAR(100),
            @file_category     VARCHAR(50);

    ---------------------------------------------------------------------
    -- Load workspace ID
    ---------------------------------------------------------------------
    DECLARE @Fb_ws NVARCHAR(200);

    SELECT TOP(1) @Fb_ws = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = 'workspace_id';

    ---------------------------------------------------------------------
    -- Set process name
    ---------------------------------------------------------------------
    SET @ProcessName = CONCAT('Load ', @TargetTable,' from csv file(s)');

    ---------------------------------------------------------------------
    -- Extract table name (schema.table → table)
    ---------------------------------------------------------------------
    SELECT @file_category =
        (SELECT value
         FROM STRING_SPLIT(@TargetTable, '.', 1)
         WHERE ordinal = 2);

    ---------------------------------------------------------------------
    -- Build config variable name: csv_<table>_file
    ---------------------------------------------------------------------
    SELECT @file_name = CONCAT_WS('_', 'csv', @file_category, 'file');

    ---------------------------------------------------------------------
    -- Load config values
    ---------------------------------------------------------------------
    SELECT @az_strg_ednpoint = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = 'az_strg_endpoint';

    SELECT @az_strg_container = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = 'az_strg_container';

    SELECT @az_strg_file_dir = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = 'az_strg_file_dir';

    ---------------------------------------------------------------------
    -- Load CSV file name from config
    ---------------------------------------------------------------------
    SELECT @csv_file_name = VariableValue
    FROM etl.config_variables
    WHERE AppName = @AppName
      AND VariableName = @file_name;

    ---------------------------------------------------------------------
    -- Build final Azure Blob path
    ---------------------------------------------------------------------
    IF (@Full_File_Path IS NULL)
    BEGIN
        SET @Full_File_Path =
            CONCAT(
                @az_strg_ednpoint,
                @az_strg_container,
                REPLACE(REPLACE(@az_strg_file_dir, '<<load_type>>', @load_type), '<<file_category>>', @file_category),
                @csv_file_name
            );

            PRINT(@Full_File_Path)
    END

    BEGIN TRY
        -----------------------------------------------------------------
        -- TRUNCATE TABLE (must be executed separately)
        -----------------------------------------------------------------
        SET @sql = N'TRUNCATE TABLE ' + @TargetTable + N';';
        PRINT @sql;
        EXEC sp_executesql @sql;

        -----------------------------------------------------------------
        -- COPY INTO using Azure Blob Storage
        -----------------------------------------------------------------
        SET @sql = N'
            COPY INTO ' + @TargetTable + N'
            FROM ''' + @Full_File_Path + N'''
            WITH (
                FILE_TYPE = ''CSV'',
                FIELDTERMINATOR = '','',
                FIRSTROW = ' + CAST(@FirstRow AS NVARCHAR(10)) + N'
            );
        ';

        PRINT @sql;
        EXEC sp_executesql @sql;

        -----------------------------------------------------------------
        -- Count rows inserted
        -----------------------------------------------------------------
        SET @CountSQL = N'SELECT @cnt = COUNT(*) FROM ' + @TargetTable;

        EXEC sp_executesql
            @CountSQL,
            N'@cnt BIGINT OUTPUT',
            @cnt = @RowsInserted OUTPUT;

        -----------------------------------------------------------------
        -- Log success
        -----------------------------------------------------------------
        SET @EndTime = SYSDATETIME();

        EXEC etl.sp_log_process_success
            @ProcessName        = @ProcessName,
            @WorkspaceID        = @Fb_ws,
            @DestinationSystem  = @TargetTable,
            @SourceSystem       = @Full_File_Path,
            @RowsInserted       = @RowsInserted,
            @StartTime          = @StartTime,
            @EndTime            = @EndTime,
            @ProcessId          = @ProcessId;
    END TRY


    BEGIN CATCH
        -----------------------------------------------------------------
        -- Log error
        -----------------------------------------------------------------
        SET @ErrorMessage = ERROR_MESSAGE();

        EXEC etl.sp_log_process_error
            @ProcessName        = @ProcessName,
            @WorkspaceID        = @Fb_ws,
            @DestinationSystem  = @TargetTable,
            @SourceSystem       = @Full_File_Path,
            @ErrorMessage       = @ErrorMessage,
            @ProcessId          = @ProcessId;

        THROW;
    END CATCH
END;
GO