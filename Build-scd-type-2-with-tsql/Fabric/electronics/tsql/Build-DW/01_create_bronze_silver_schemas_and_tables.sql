/* ============================================================
   0. CREATE SCHEMAS IF NOT EXISTS
   ============================================================ */

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA bronze');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl')
    EXEC('CREATE SCHEMA etl');

/* ============================================================
   1. DROP TABLES IF THEY ALREADY EXIST (SAFE ORDER)
   ============================================================ */

-- SILVER TABLES (drop constraints first)
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'PK_silver_dim_customer')
    ALTER TABLE silver.dim_customer DROP CONSTRAINT PK_silver_dim_customer;

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'PK_silver_dim_product')
    ALTER TABLE silver.dim_product DROP CONSTRAINT PK_silver_dim_product;

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'PK_silver_dim_date')
    ALTER TABLE silver.dim_date DROP CONSTRAINT PK_silver_dim_date;


-- BRONZE TABLES
DROP TABLE IF EXISTS bronze.fact_sales;
DROP TABLE IF EXISTS bronze.dim_customer;
DROP TABLE IF EXISTS bronze.dim_product;
DROP TABLE IF EXISTS bronze.dim_date;
DROP TABLE IF EXISTS bronze.dim_reviews;


-- SILVER TABLES
DROP TABLE IF EXISTS silver.fact_sales;
DROP TABLE IF EXISTS silver.dim_customer;
DROP TABLE IF EXISTS silver.dim_product;
DROP TABLE IF EXISTS silver.dim_date;
DROP TABLE IF EXISTS bronze.dim_reviews;


/* ============================================================
   2. RECREATE BRONZE TABLES
   ============================================================ */

CREATE TABLE bronze.dim_customer (
    CustomerID      INT,
    FirstName       VARCHAR(100),
    LastName        VARCHAR(100),
    Region          VARCHAR(50),
    SignupDate      DATE,
    LoadDate        DATETIME2(3)
);

CREATE TABLE bronze.dim_product (
    ProductID       INT,
    ProductName     VARCHAR(200),
    Category        VARCHAR(100),
    UnitPrice       DECIMAL(10,2),
    LoadDate        DATETIME2(3)
);

CREATE TABLE bronze.dim_date (
    DateID          INT,
    FullDate        DATE,
    Year            INT,
    Month           INT,
    Day             INT,
    Quarter         VARCHAR(10),
    LoadDate        DATETIME2(3)
);

CREATE TABLE bronze.fact_sales (
    TransactionID   INT,
    DateID          INT,
    CustomerID      INT,
    ProductID       INT,
    Quantity        INT,
    UnitPrice       DECIMAL(10,2),
    TotalAmount     DECIMAL(10,2),
    LoadDate        DATETIME2(3)
);



CREATE TABLE bronze.dim_reviews (
    ReviewID     INT             NOT NULL,
    ProductID    INT             NOT NULL,
    CustomerID   INT             NOT NULL,
    ReviewDate   DATE            NOT NULL,
    ReviewText   VARCHAR(512)           NOT NULL
    --CONSTRAINT CK_dim_reviews_Sentiment
    --    CHECK (Sentiment IN ('Positive', 'Negative', 'Neutral', 'Mixed')),
    --CONSTRAINT CK_dim_reviews_Rating
    --    CHECK (Rating BETWEEN 1 AND 5)
);
GO


/* ============================================================
   3. RECREATE SILVER TABLES (SCD2 DIMENSIONS)
   ============================================================ */

CREATE TABLE silver.dim_customer (
    SurrogateKey        BIGINT IDENTITY NOT NULL,
    CustomerID          INT NOT NULL,
    FirstName           VARCHAR(100) NOT NULL,
    LastName            VARCHAR(100) NOT NULL,
    Region              VARCHAR(50) NOT NULL,
    SignupDate          DATE NOT NULL,

    HashDiff            VARBINARY(128),
    EffectiveStartDate  DATETIME2(0) NOT NULL,
    EffectiveEndDate    DATETIME2(0) NULL,
    IsCurrent           BIT NOT NULL,
    LoadDate            DATETIME2(0) NOT NULL
);

ALTER TABLE silver.dim_customer
ADD CONSTRAINT PK_silver_dim_customer
PRIMARY KEY NONCLUSTERED (SurrogateKey, CustomerID) NOT ENFORCED;


CREATE TABLE silver.dim_product (
    SurrogateKey        BIGINT IDENTITY NOT NULL,
    ProductID           INT NOT NULL,
    ProductName         VARCHAR(200) NOT NULL,
    Category            VARCHAR(100) NOT NULL,
    UnitPrice           DECIMAL(10,2) NOT NULL,

    HashDiff            VARBINARY(128),
    EffectiveStartDate  DATETIME2(0) NOT NULL,
    EffectiveEndDate    DATETIME2(0) NULL,
    IsCurrent           BIT NOT NULL,
    LoadDate            DATETIME2(0) NOT NULL
);

ALTER TABLE silver.dim_product
ADD CONSTRAINT PK_silver_dim_product
PRIMARY KEY NONCLUSTERED (SurrogateKey, ProductID) NOT ENFORCED;


CREATE TABLE silver.dim_date (
    SurrogateKey        BIGINT IDENTITY NOT NULL,
    DateID              INT NOT NULL,
    FullDate            DATE NOT NULL,
    Year                INT NOT NULL,
    Month               INT NOT NULL,
    Day                 INT NOT NULL,
    Quarter             VARCHAR(10) NOT NULL,

    HashDiff            VARBINARY(128),
    EffectiveStartDate  DATETIME2(0) NOT NULL,
    EffectiveEndDate    DATETIME2(0) NULL,
    IsCurrent           BIT NOT NULL,
    LoadDate            DATETIME2(0) NOT NULL
);

ALTER TABLE silver.dim_date
ADD CONSTRAINT PK_silver_dim_date
PRIMARY KEY NONCLUSTERED (SurrogateKey, DateID) NOT ENFORCED;


CREATE TABLE silver.dim_reviews (
    SurrogateKey BIGINT IDENTITY        NOT NULL,
    ReviewID     INT                    NOT NULL,
    ProductID    INT                    NOT NULL,
    CustomerID   INT                    NOT NULL,
    ReviewDate   DATE                   NOT NULL,
    ReviewText   VARCHAR(512)           NOT NULL,
    SentimentLabel    VARCHAR(10)       NOT NULL,
    Rating       INT                    NOT NULL,
    ExtractedEntities   VARCHAR(512)    NOT NULL,

    HashDiff            VARBINARY(128),
    EffectiveStartDate  DATETIME2(0)    NOT NULL,
    EffectiveEndDate    DATETIME2(0)    NULL,
    IsCurrent           BIT             NOT NULL,
    LoadDate            DATETIME2(0)    NOT NULL
);
GO


ALTER TABLE silver.dim_reviews
ADD CONSTRAINT PK_silver_dim_reviews
PRIMARY KEY NONCLUSTERED (SurrogateKey, ReviewID,ProductID,CustomerID) NOT ENFORCED;


-- silver.fact_sales
-- ⭐ SILVER FACT TABLE (No SCD2, but includes LoadDate)
-- Fact tables are not SCD2 — they are append‑only.
CREATE TABLE silver.fact_sales (
    TransactionID   INT NOT NULL,
    DateID          INT NOT NULL,
    CustomerID      INT NOT NULL,
    ProductID       INT NOT NULL,
    Quantity        INT NOT NULL,
    UnitPrice       DECIMAL(10,2) NOT NULL,
    TotalAmount     DECIMAL(10,2) NOT NULL,
    LoadDate        DATETIME2(0) NOT NULL  
);