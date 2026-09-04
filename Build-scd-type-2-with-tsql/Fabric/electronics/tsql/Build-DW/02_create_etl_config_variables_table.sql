/* ============================================================
   ETL LOGGING + CONFIGURATION OBJECTS (FABRIC DW)
   Purpose:
     - Create process‑level success and error logging tables
     - Provide reusable logging procedures for all ETL pipelines
     - Store environment‑specific configuration values
       (storage paths, workspace IDs, file names, etc.)
     - Enable full auditability, traceability, and repeatable loads
   Notes:
     - Tables support all Bronze → Silver → Gold ETL flows
     - Logging procedures are called by every ETL stored procedure
   ============================================================ */


-- TABLE: ETL_ProcessLog
CREATE TABLE etl.ETL_ProcessLog
(
    LogID              BIGINT IDENTITY,    
    ProcessName        VARCHAR(200) NOT NULL,
    ProcessId          BIGINT NOT NULL,
    WorkspaceID        VARCHAR(200) NOT NULL,
    DestinationSystem  VARCHAR(512) NOT NULL,
    SourceSystem       VARCHAR(2000) NOT NULL,
    RowsInserted       BIGINT NOT NULL,
    StartTime          DATETIME2(3) NOT NULL,
    EndTime            DATETIME2(3) NOT NULL,
    Duration           VARCHAR(10) NOT NULL,
    Status             VARCHAR(50) NOT NULL
);



-- TABLE: ETL_ErrorLog
CREATE TABLE etl.ETL_ErrorLog
(
    ErrorLogID         BIGINT IDENTITY,    
    ProcessName        VARCHAR(200) NOT NULL,
    ProcessId          BIGINT NOT NULL,
    WorkspaceID        VARCHAR(200) NOT NULL,
    DestinationSystem  VARCHAR(200) NOT NULL,
    SourceSystem       VARCHAR(2000) NOT NULL,
    ErrorMessage       VARCHAR(MAX) NOT NULL,
    ErrorTime          DATETIME2(3) NOT NULL
);
GO


/* ============================================================
   STORED PROCEDURE: LOG SUCCESS
   ============================================================ */
CREATE OR ALTER PROCEDURE etl.sp_log_process_success
(
    @ProcessName       NVARCHAR(200),
    @WorkspaceID       NVARCHAR(200),
    @DestinationSystem NVARCHAR(200),
    @SourceSystem      NVARCHAR(2000),
    @RowsInserted      BIGINT,
    @StartTime         DATETIME2(3),
    @EndTime           DATETIME2(3),
    @ProcessId         BIGINT
)
AS
BEGIN
    ---------------------------------------------------------------------
    -- Compute duration
    ---------------------------------------------------------------------
    DECLARE @DurationSeconds INT;
    DECLARE @DurationFormatted VARCHAR(8);

    SET @DurationSeconds = DATEDIFF(SECOND, @StartTime, @EndTime);

    SET @DurationFormatted =
        CONVERT(VARCHAR(8), DATEADD(SECOND, @DurationSeconds, 0), 108);

    ---------------------------------------------------------------------
    -- Insert log record
    ---------------------------------------------------------------------
    INSERT INTO etl.ETL_ProcessLog
    (
        ProcessName,
        ProcessId,
        WorkspaceID,
        DestinationSystem,
        SourceSystem,
        RowsInserted,
        StartTime,
        EndTime,
        Duration,
        Status
    )
    VALUES
    (
        @ProcessName,
        @ProcessId,
        @WorkspaceID,
        @DestinationSystem,
        @SourceSystem,
        @RowsInserted,
        @StartTime,
        @EndTime,
        @DurationFormatted,
        'SUCCESS'
    );
END;
GO


/* ============================================================
   STORED PROCEDURE: LOG ERROR
   ============================================================ */
CREATE OR ALTER PROCEDURE etl.sp_log_process_error
(
    @ProcessName       NVARCHAR(200),
    @WorkspaceID       NVARCHAR(200),
    @DestinationSystem NVARCHAR(200),
    @SourceSystem      NVARCHAR(2000),
    @ErrorMessage      NVARCHAR(MAX),
    @ProcessId         BIGINT
)
AS
BEGIN
    INSERT INTO etl.ETL_ErrorLog
    (
        ProcessName,
        ProcessId,
        WorkspaceID,
        DestinationSystem,
        SourceSystem,
        ErrorMessage,
        ErrorTime
    )
    VALUES
    (
        @ProcessName,
        @ProcessId,
        @WorkspaceID,
        @DestinationSystem,
        @SourceSystem,
        @ErrorMessage,
        SYSDATETIME()
    );
END;
GO


/* ============================================================
   CONFIGURATION TABLE + DEFAULT VALUES
   ============================================================ */

CREATE TABLE etl.config_variables (
    AppName        VARCHAR(100),
    VariableName   VARCHAR(200),
    VariableValue  VARCHAR(500),
    Comments       VARCHAR(500),
    CreatedDate    DATETIME2(0)
);


INSERT INTO etl.config_variables (AppName, VariableName, VariableValue, Comments, CreatedDate)
SELECT v.AppName, v.VariableName, v.VariableValue, v.Comments, v.CreatedDate
FROM (
    VALUES
        ('Electronics','az_strg_endpoint','https://<<az-account-storage-name>>.blob.core.windows.net','',SYSDATETIME()),
        ('Electronics','az_strg_container','/demo/','',SYSDATETIME()),
        ('Electronics','az_strg_file_dir','electronics/<<load_type>>/<<file_category>>/','',SYSDATETIME()),
        ('Electronics','csv_dim_reviews_file','dim_reviews.csv','',SYSDATETIME()),
        ('Electronics','csv_dim_customer_file','dim_customer.csv','',SYSDATETIME()),
        ('Electronics','csv_dim_date_file','dim_date.csv','',SYSDATETIME()),        
        ('Electronics','csv_dim_product_file','dim_product.csv','',SYSDATETIME()),
        ('Electronics','csv_fact_sales_file','fact_sales.csv','',SYSDATETIME()),
        ('Electronics','workspace_id','<<your fabric workspace id>>','',SYSDATETIME()),
        ('Electronics','dw_id','<<your fabric data warehouse id>>','',SYSDATETIME())        
) AS v(AppName, VariableName, VariableValue, Comments, CreatedDate)
WHERE NOT EXISTS (
    SELECT 1 
    FROM etl.config_variables t
    WHERE t.AppName = v.AppName
      AND t.VariableName = v.VariableName
      AND t.VariableValue = v.VariableValue
);


SELECT TOP (4) * FROM etl.config_variables;
