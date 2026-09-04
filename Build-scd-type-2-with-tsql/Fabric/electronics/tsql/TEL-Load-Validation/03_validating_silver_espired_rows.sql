/* ============================================================
   SCD TYPE 2 + INCREMENTAL CHANGE VALIDATION — ALL TABLES
   Purpose:
     - Identify expired SCD2 rows (EffectiveEndDate IS NOT NULL)
     - Identify new incoming rows from bronze
     - Identify updated rows (for fact tables without SCD2 columns)
   Tables Covered:
     - silver.dim_product
     - silver.dim_customer
     - silver.dim_date
     - silver.fact_sales (incremental change detection only)
   ============================================================ */


/* ============================================================
   1. PRODUCT (SCD TYPE 2)
   ============================================================ */

-- Expired rows (EffectiveEndDate IS NOT NULL)
SELECT *
FROM silver.dim_product
WHERE ProductID IN (
    SELECT ProductID
    FROM silver.dim_product
    WHERE EffectiveEndDate IS NOT NULL
)
ORDER BY ProductID;

-- New rows (exist in bronze but not expired in silver)
SELECT DW.*
FROM silver.dim_product DW
INNER JOIN bronze.dim_product STG
    ON DW.ProductID = STG.ProductID
WHERE STG.ProductID NOT IN (
    SELECT ProductID
    FROM silver.dim_product
    WHERE EffectiveEndDate IS NOT NULL
)
ORDER BY ProductID;



/* ============================================================
   2. CUSTOMER (SCD TYPE 2)
   ============================================================ */

-- Expired rows
SELECT *
FROM silver.dim_customer
WHERE CustomerID IN (
    SELECT CustomerID
    FROM silver.dim_customer
    WHERE EffectiveEndDate IS NOT NULL
)
ORDER BY CustomerID;

-- New rows
SELECT DW.*
FROM silver.dim_customer DW
INNER JOIN bronze.dim_customer STG
    ON DW.CustomerID = STG.CustomerID
WHERE STG.CustomerID NOT IN (
    SELECT CustomerID
    FROM silver.dim_customer
    WHERE EffectiveEndDate IS NOT NULL
)
ORDER BY CustomerID;



/* ============================================================
   3. DATE (SCD TYPE 2)
   ============================================================ */

-- Expired rows
SELECT *
FROM silver.dim_date
WHERE DateID IN (
    SELECT DateID
    FROM silver.dim_date
    WHERE EffectiveEndDate IS NOT NULL
)
ORDER BY DateID;

-- New rows
SELECT DW.*
FROM silver.dim_date DW
INNER JOIN bronze.dim_date STG
    ON DW.DateID = STG.DateID
WHERE STG.DateID NOT IN (
    SELECT DateID
    FROM silver.dim_date
    WHERE EffectiveEndDate IS NOT NULL
)
ORDER BY DateID;



/* ============================================================
   3. dim_reviews (SCD TYPE 2)
   ============================================================ */

-- Expired rows
SELECT *
FROM [silver].[dim_reviews]
WHERE [ReviewID] IN (
    SELECT [ReviewID]
    FROM [silver].[dim_reviews]
    WHERE EffectiveEndDate IS NOT NULL
)
ORDER BY [ReviewID];

-- New rows
SELECT DW.*
FROM [silver].[dim_reviews] DW
INNER JOIN [silver].[dim_reviews] STG
    ON DW.[ReviewID] = STG.[ReviewID]
WHERE STG.[ReviewID] NOT IN (
    SELECT [ReviewID]
    FROM [silver].[dim_reviews]
    WHERE EffectiveEndDate IS NOT NULL
)
ORDER BY [ReviewID];


/* ============================================================
   4. FACT SALES (NOT SCD2 — INCREMENTAL CHANGE DETECTION)
   ============================================================ */

-- UPDATED rows (same TransactionID, different attributes)
SELECT STG.*
FROM bronze.fact_sales STG
INNER JOIN silver.fact_sales DW
    ON DW.TransactionID = STG.TransactionID
WHERE 
       DW.DateID      <> STG.DateID
    OR DW.CustomerID  <> STG.CustomerID
    OR DW.ProductID   <> STG.ProductID
    OR DW.Quantity    <> STG.Quantity
    OR DW.UnitPrice   <> STG.UnitPrice
    OR DW.TotalAmount <> STG.TotalAmount
ORDER BY STG.TransactionID;

-- NEW rows in bronze that are not yet in silver
SELECT STG.*
FROM bronze.fact_sales STG
LEFT JOIN silver.fact_sales DW
    ON DW.TransactionID = STG.TransactionID
WHERE DW.TransactionID IS NULL
ORDER BY STG.TransactionID;
