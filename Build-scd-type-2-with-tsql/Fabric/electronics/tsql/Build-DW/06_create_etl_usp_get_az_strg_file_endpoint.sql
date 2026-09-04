
--[etl].[usp_get_az_strg_file_endpoint] @SchemaName='bronze',@LoadType ='FullLoad'
--[etl].[usp_get_az_strg_file_endpoint] @SchemaName='silver',@LoadType ='Delta'
CREATE OR ALTER     PROC [etl].[usp_get_az_strg_file_endpoint]
@SchemaName VARCHAR(10)='bronze',
@LoadType VARCHAR(30)='FullLoad'
AS

IF (@SchemaName = 'bronze')
BEGIN
    ;WITH cfg AS
    (
        SELECT
            LTRIM(RTRIM(AppName)) AS AppName,
            LTRIM(RTRIM(VariableName)) AS VariableName,
            LTRIM(RTRIM(VariableValue)) AS VariableValue
        FROM etl.config_variables
        WHERE LTRIM(RTRIM(AppName)) = 'Electronics'
    ),
    base AS
    (
        SELECT
            MAX(CASE WHEN VariableName = 'az_strg_endpoint'  THEN VariableValue END) AS endpoint,
            MAX(CASE WHEN VariableName = 'az_strg_container' THEN VariableValue END) AS container,
            MAX(CASE WHEN VariableName = 'az_strg_file_dir'  THEN VariableValue END) AS file_dir
        FROM cfg
    )
    SELECT DISTINCT
        --c.AppName,
        --c.VariableName,
        @SchemaName AS SchemaName,
        @LoadType AS LoadType,
        REPLACE(c.VariableValue,'.csv','') AS SystemName,
        c.VariableValue AS FileName,    
        ISNULL(b.endpoint, '')
        + ISNULL(b.container, '')
        + REPLACE(
            REPLACE(ISNULL(b.file_dir, ''), '<<load_type>>', @LoadType),
            '<<file_category>>',
            REPLACE(REPLACE(c.VariableName, 'csv_', ''), '_file', '')
          )
        + ISNULL(c.VariableValue, '') AS FullPath
    FROM cfg c
    CROSS JOIN base b
    WHERE c.VariableName LIKE 'csv[_]%[_]file'
    ORDER BY SystemName;
END
ELSE IF (@SchemaName = 'silver')
BEGIN
    SELECT 1 AS LoadOrder, 'silver.dim_product' AS TargetTable, 'bronze.dim_product' AS SourceSystem, 
            'EXEC etl.usp_load_bronze_into_silver_dim_product' AS tsql_proc UNION

    SELECT 1,'silver.dim_customer' AS TargetTable, 'bronze.dim_customer' AS SourceSystem, 
            'EXEC etl.usp_load_bronze_into_silver_dim_customer' AS tsql_proc UNION

    SELECT 1,'silver.dim_date' AS TargetTable, 'bronze.dim_date' AS SourceSystem, 
            'EXEC etl.usp_load_bronze_into_silver_dim_date' AS tsql_proc UNION

    SELECT 1,'silver.dim_date' AS TargetTable, 'bronze.dim_reviews' AS SourceSystem, 
            'EXEC etl.usp_load_bronze_into_silver_dim_reviews' AS tsql_proc UNION

    SELECT 2,'silver.fact_sales' AS TargetTable, 'bronze.fact_sales' AS SourceSystem, 
            'EXEC etl.usp_load_bronze_into_silver_fact_sales' AS tsql_proc 
    ORDER BY LoadOrder
END