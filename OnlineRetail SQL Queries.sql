SELECT*
FROM OnlineRetail
-- Cleaning + prepping the data
-- Viewing null customer ID entries
SELECT*
FROM OnlineRetail
WHERE CustomerID IS NULL

-- Creating new table without null customer ID entries
SELECT*
FROM OnlineRetail
WHERE CustomerID IS NOT NULL

SELECT *
INTO CleanRetail
FROM OnlineRetail
WHERE CustomerID IS NOT NULL

SELECT*
FROM CleanRetail

-- Handling duplicates
-- Viewing if we have duplicates
SELECT 
    InvoiceNo, StockCode, Description, Quantity, InvoiceDate, CustomerID, UnitPrice, Country,
    COUNT(*) AS duplicate_count
FROM CleanRetail
GROUP BY 
    InvoiceNo, StockCode, Description, Quantity, InvoiceDate, CustomerID, UnitPrice, Country
HAVING COUNT(*) > 1

-- Removing duplicates
WITH Deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, CustomerID, UnitPrice, Country
            ORDER BY InvoiceDate
        ) AS row_num
    FROM CleanRetail
)

SELECT *
INTO CleanRetail_NoDuplicates
FROM Deduped
WHERE row_num = 1

SELECT*
FROM CleanRetail_NoDuplicates

-- Total Price
SELECT *,
       Quantity * UnitPrice AS TotalPrice
INTO CleanRetail_WithPrice
FROM CleanRetail_NoDuplicates

SELECT*
FROM CleanRetail_WithPrice

-- Analysis
-- Top 10 customers by spend
SELECT TOP 10 CustomerID,
       Country,
       SUM(TotalPrice) AS TotalSpent
FROM CleanRetail_WithPrice
GROUP BY CustomerID, Country
ORDER BY TotalSpent DESC
-- If I wanted to create a table for Top_10Customers
SELECT TOP 10 CustomerID,
       SUM(TotalPrice) AS TotalSpent
INTO Top10_Customers
FROM CleanRetail_WithPrice
GROUP BY CustomerID
ORDER BY TotalSpent DESC

SELECT*
FROM Top10_Customers

-- Best selling products by revenue and quantity
-- By revenue(TotalPrice)
SELECT Description,
       SUM(Quantity) AS TotalQuantitySold,
       SUM(TotalPrice) AS TotalRevenue
FROM CleanRetail_WithPrice
GROUP BY Description
ORDER BY TotalRevenue DESC

-- By quantity
SELECT Description,
       SUM(Quantity) AS TotalQuantitySold
FROM CleanRetail_WithPrice
GROUP BY Description
ORDER BY TotalQuantitySold DESC

-- Months with highest and lowest sales
SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS SalesMonth,
    SUM(TotalPrice) AS MonthlyRevenue
FROM CleanRetail_WithPrice
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY MonthlyRevenue DESC
 
 -- Highest, Nov. Lowest, Dec
 -- To see lowest first, remove DESC, SQL always orders in ASC by default
SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS SalesMonth,
    SUM(TotalPrice) AS MonthlyRevenue
FROM CleanRetail_WithPrice
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY MonthlyRevenue

-- See which countries generate the most revenue
SELECT Country, 
       ROUND(SUM(TotalPrice), 2) AS TotalRevenue
FROM CleanRetail_WithPrice
GROUP BY Country
ORDER BY TotalRevenue DESC
-- Flagging suspicious orders
SELECT *, 
       CASE 
           WHEN Quantity < 0 THEN 'Suspicious'
           ELSE 'Normal'
       END AS OrderStatus
FROM CleanRetail_WithPrice

-- Creating a table of suspicious orders
SELECT *
INTO SuspiciousOrders
FROM CleanRetail_WithPrice
WHERE Quantity < 0

SELECT*
FROM SuspiciousOrders

-- Tracking returning v/s one-time customers
SELECT CustomerID,
       COUNT(DISTINCT InvoiceNo) AS OrderCount,
       CASE 
           WHEN COUNT(DISTINCT InvoiceNo) = 1 THEN 'One-time'
           ELSE 'Returning'
       END AS CustomerType
FROM CleanRetail_WithPrice
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY OrderCount DESC

-- How many are returning v/s one time
SELECT CustomerType, COUNT(*) AS NumCustomers
FROM (
    SELECT CustomerID,
           COUNT(DISTINCT InvoiceNo) AS OrderCount,
           CASE 
               WHEN COUNT(DISTINCT InvoiceNo) = 1 THEN 'One-time'
               ELSE 'Returning'
           END AS CustomerType
    FROM CleanRetail_WithPrice
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
) AS CustomerSummary
GROUP BY CustomerType

-- Customer lifetime value estimate/most valuable customers
SELECT CustomerID,
       ROUND(SUM(TotalPrice), 2) AS CustomerLifetimeValue,
       COUNT(DISTINCT InvoiceNo) AS TotalOrders,
       COUNT(*) AS TotalItemsBought,
       ROUND(AVG(TotalPrice), 2) AS AvgOrderValue
FROM CleanRetail_WithPrice
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY CustomerLifetimeValue DESC

-- Saving it as a table
SELECT CustomerID,
       ROUND(SUM(TotalPrice), 2) AS CustomerLifetimeValue,
       COUNT(DISTINCT InvoiceNo) AS TotalOrders,
       COUNT(*) AS TotalItemsBought,
       ROUND(AVG(TotalPrice), 2) AS AvgOrderValue
INTO Customer_LTV
FROM CleanRetail_WithPrice
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID

SELECT*
FROM Customer_LTV







