### Data source description
 - Copy and paste below text into **Data source description**

**DW01 - HelpDesk Sales & Reviews Warehouse.** A Microsoft Fabric Warehouse where the **`silver` schema** is the curated, analytics-ready layer and the only one to query. It holds retail data across Electronics, Furniture, Stationery, Sports, Home, and Accessories in five tables: **`silver.fact_sales`** (transactions), **`silver.dim_customer`** (SCD2), **`silver.dim_product`**, **`silver.dim_date`**, and **`silver.dim_reviews`** (SCD2, with Sentiment and Rating 1 to 5). Use it for revenue, units, AOV, ARPU, trends (MoM/QoQ/YoY), top performers, regional analysis, customer 360, and voice-of-customer sentiment. Do not use for bronze, ETL, or non-sales topics.

### Data source instructions
 - Copy and paste below text into **Data source instructions**

# DW01 query mechanics

## Schema map

| Table | Grain | Key columns |
|---|---|---|
| `silver.fact_sales` | 1 row per transaction | `TransactionID`, `DateID`, `CustomerID`, `ProductID`, `Quantity`, `UnitPrice`, `TotalAmount` |
| `silver.dim_customer` (SCD2) | 1 row per customer version | `CustomerID`, `FirstName`, `LastName`, `Region`, `SignupDate`, `IsCurrent`, `EffectiveStartDate`, `EffectiveEndDate` |
| `silver.dim_product` | 1 row per product | `ProductID`, `ProductName`, `Category`, `UnitPrice` |
| `silver.dim_date` | 1 row per date | `DateID`, `FullDate`, `Year`, `Quarter`, `Month`, `Day` |
| `silver.dim_reviews` (SCD2) | 1 row per review version | `ReviewID`, `ProductID`, `CustomerID`, `ReviewDate`, `Sentiment`, `Rating`, `ReviewText`, `IsCurrent` |

**Allowed values**
- `Sentiment` ∈ { `Positive`, `Negative`, `Neutral`, `Mixed` }
- `Region` ∈ { `East`, `West`, `North`, `South` }
- `Rating` ∈ integers 1 to 5
- `Category` ∈ { `Electronics`, `Furniture`, `Stationery`, `Sports`, `Home`, `Accessories` }

## Canonical joins (use these every time)

```sql
fs.DateID     = dd.DateID
fs.CustomerID = dc.CustomerID  AND dc.IsCurrent = 1
fs.ProductID  = dp.ProductID
dr.ProductID  = dp.ProductID
dr.CustomerID = dc.CustomerID  AND dc.IsCurrent = 1
-- and always: dr.IsCurrent = 1