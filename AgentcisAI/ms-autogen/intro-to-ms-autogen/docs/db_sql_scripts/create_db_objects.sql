-- Create the 'AgenticAI' database only if it doesn't already exist
USE master
GO

IF DB_ID('AgenticAI') IS NULL
    CREATE DATABASE [AgenticAI]
GO

USE [AgenticAI]
GO

-- Create a new schema named 'sales' to organize related database objects
CREATE SCHEMA [sales]
GO

-- Enable ANSI_NULLS setting for consistent null comparison behavior
SET ANSI_NULLS ON
GO

-- Enable quoted identifiers to allow use of reserved keywords in object names
SET QUOTED_IDENTIFIER ON
GO

-- Create a table to store bicycle sales data with product and transaction details
CREATE TABLE [sales].[BicycleSales](
    [ProductId] [tinyint] NOT NULL,               -- Unique product identifier
    [ProductName]  NOT NULL,        -- Name of the product
    [ProductType]  NOT NULL,        -- Type/category of product
    [Color]  NOT NULL,              -- Product color
    [OrderQuantity] [tinyint] NOT NULL,           -- Quantity ordered
    [Size]  NOT NULL,               -- Product size
    [Category]  NOT NULL,           -- Sales category
    [Country]  NOT NULL,            -- Country of sale
    [Date] [date] NOT NULL,                       -- Date of transaction
    [PurchasePrice] [decimal](18, 2) NOT NULL,    -- Cost to acquire product
    [SellingPrice] [decimal](18, 2) NOT NULL      -- Price sold to customer
) ON [PRIMARY]
GO

-- Re-enable settings for stored procedure creation
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create a stored procedure to summarize sales by product and country
CREATE PROC [sales].[usp_get_sales_summary_by_country]
AS
BEGIN
    SELECT 
        [ProductName],
        [Country],
        MAX([OrderQuantity]) AS MaxOrderQuantity,         -- Highest quantity ordered
        SUM([PurchasePrice]) AS TotalPurchasePrice,       -- Total cost of products
        SUM([SellingPrice]) AS TotalSellingPrice          -- Total revenue from sales
    FROM [sales].[BicycleSales]
    GROUP BY [ProductName], [Country]
END
GO

