/*****************************************************************************************************************
NAME:    My Script Name
PURPOSE: Solve an increased complexity question using SQL

MODIFICATION LOG:
Ver      Date        Author        Description
-----   ----------   -----------   -------------------------------------------------------------------------------
1.0     05/23/2022   LURRUTIA       1. Built this script for EC IT 143


RUNTIME: 
Xm Xs

NOTES: 
Adventure works: Create Answers - Example 1
 
******************************************************************************************************************/
-- Here is the increased complexity question...


--Business User Questions—Marginal Complexity:

--Q1: What are the top five most expensive products in terms of list price?

-- Step 1: Select the 5 most expensive products by ListPrice
SELECT TOP 5
    ProductID,
    Name AS ProductName,
    ListPrice
FROM 
    Production.Product
WHERE 
    ListPrice > 0 -- Filter only products with a valid ListPrice
ORDER BY 
    ListPrice DESC;

--Q2: Which three employees have the highest total sales revenue?
-- Step 1: Calculate total revenue per employee
WITH EmployeeSales AS (
    SELECT 
        SOH.SalesPersonID,
        P.FirstName,
        P.LastName,
        SUM(SOH.TotalDue) AS TotalRevenue
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        HumanResources.Employee E ON SOH.SalesPersonID = E.BusinessEntityID
    JOIN 
        Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
    GROUP BY 
        SOH.SalesPersonID, P.FirstName, P.LastName
)
-- Step 2: Select the 3 highest-earning employees
SELECT TOP 3
    FirstName,
    LastName,
    TotalRevenue
FROM 
    EmployeeSales
ORDER BY 
    TotalRevenue DESC;

 --Business User question—Moderate complexity:

--Q3 Which three customers spent the most money on online orders last year?

-- Step 1: Check for online orders from last year
SELECT 
    COUNT(*) AS TotalOnlineOrdersLastYear
FROM 
    Sales.SalesOrderHeader SOH
WHERE 
    SOH.OnlineOrderFlag = 1 -- Filter only online orders
    AND SOH.OrderDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1) -- Since the beginning of last year
    AND SOH.OrderDate < DATEFROMPARTS(YEAR(GETDATE()), 1, 1); -- Until the end of last year

-- Step 2: Calculate the total spending per customer on online orders for the year 2012
WITH CustomerSpending AS (
    SELECT 
        SOH.CustomerID,
        P.FirstName,
        P.LastName,
        SUM(SOH.TotalDue) AS TotalSpent
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        Person.Person P ON SOH.CustomerID = P.BusinessEntityID
    WHERE 
        SOH.OnlineOrderFlag = 1 -- Filter only online orders
        AND SOH.OrderDate >= '2012-01-01' -- Since the beginning of 2012
        AND SOH.OrderDate < '2013-01-01' -- Until the end of 2012
    GROUP BY 
        SOH.CustomerID, P.FirstName, P.LastName
)
-- Step 3: Select the 3 customers who spent the most
SELECT TOP 3
    FirstName,
    LastName,
    TotalSpent
FROM 
    CustomerSpending
ORDER BY 
    TotalSpent DESC;

--Q4 Which salesperson made the most sales in the last three months of the year? Show their name and total sales.

-- Step 1: Calculate the total sales for each salesperson in the last three months of 2012
WITH SalesLastThreeMonths AS (
    SELECT 
        SOH.SalesPersonID,
        P.FirstName,
        P.LastName,
        SUM(SOH.TotalDue) AS TotalSales
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        Person.Person P ON SOH.SalesPersonID = P.BusinessEntityID
    WHERE 
        SOH.OrderDate >= '2012-10-01' -- Since October 2012
        AND SOH.OrderDate < '2013-01-01' -- Until December 2012
    GROUP BY 
        SOH.SalesPersonID, P.FirstName, P.LastName
)
-- Step 2: Select the seller with the highest sales
SELECT TOP 1
    FirstName,
    LastName,
    TotalSales
FROM 
    SalesLastThreeMonths
ORDER BY 
    TotalSales DESC;

--Business User Questions—Increased Complexity:

--Q5: I need to analyze the performance of our sales team during the first quarter of 2013. Specifically, I want to know which salesperson had the highest total sales revenue,
--their total sales amount, and the number of orders they processed. Additionally, can you provide a breakdown of their sales by product category?

-- Step 1: Calculate the total revenue and number of orders per seller in Q1 2013
WITH SalesPerformance AS (
    SELECT 
        SOH.SalesPersonID,
        P.FirstName,
        P.LastName,
        SUM(SOH.TotalDue) AS TotalRevenue,
        COUNT(SOH.SalesOrderID) AS TotalOrders
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        Person.Person P ON SOH.SalesPersonID = P.BusinessEntityID
    WHERE 
        SOH.OrderDate >= '2013-01-01' 
        AND SOH.OrderDate <= '2013-03-31'
        AND SOH.SalesPersonID IS NOT NULL -- Make sure the seller is assigned
    GROUP BY 
        SOH.SalesPersonID, P.FirstName, P.LastName
)
-- Step 2: Select the seller with the highest income
SELECT TOP 1
    FirstName,
    LastName,
    TotalRevenue,
    TotalOrders
FROM 
    SalesPerformance
ORDER BY 
    TotalRevenue DESC;


	-- Step 1: Identify the seller with the highest revenue in Q1 2013
WITH TopSalesPerson AS (
    SELECT 
        SOH.SalesPersonID,
        SUM(SOH.TotalDue) AS TotalRevenue
    FROM 
        Sales.SalesOrderHeader SOH
    WHERE 
        SOH.OrderDate >= '2013-01-01' 
        AND SOH.OrderDate <= '2013-03-31'
        AND SOH.SalesPersonID IS NOT NULL -- Make sure the seller is assigned
    GROUP BY 
        SOH.SalesPersonID
    ORDER BY 
        TotalRevenue DESC
    OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
)
-- Step 2: Break down the seller's sales by product category
SELECT 
    PC.Name AS ProductCategory,
    SUM(SOD.LineTotal) AS CategoryRevenue
FROM 
    Sales.SalesOrderHeader SOH
JOIN 
    Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN 
    Production.Product P ON SOD.ProductID = P.ProductID
JOIN 
    Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
JOIN 
    Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE 
    SOH.SalesPersonID = (SELECT SalesPersonID FROM TopSalesPerson)
GROUP BY 
    PC.Name
ORDER BY 
    CategoryRevenue DESC;


--Q6 I need a 2013 sales report for stakeholders and investors. What were the top three products sold per quarter with names, quantities,
--and total revenue by month using Production.Product, Sales.SalesOrderDetail. and Sales.SalesOrderHeader?

-- Step 1: Create a temporary table to store the results by quarter
CREATE TABLE #SalesReport (
    Quarter INT,
    ProductName NVARCHAR(50),
    Month INT,
    Quantity INT,
    TotalRevenue MONEY
);

-- Step 2: Calculate sales by quarter, month, and product
WITH SalesData AS (
    SELECT 
        DATEPART(QUARTER, SOH.OrderDate) AS Quarter,
        DATEPART(MONTH, SOH.OrderDate) AS Month,
        P.Name AS ProductName,
        SUM(SOD.OrderQty) AS Quantity,
        SUM(SOD.LineTotal) AS TotalRevenue
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    JOIN 
        Production.Product P ON SOD.ProductID = P.ProductID
    WHERE 
        YEAR(SOH.OrderDate) = 2013
    GROUP BY 
        DATEPART(QUARTER, SOH.OrderDate),
        DATEPART(MONTH, SOH.OrderDate),
        P.Name
)
-- Step 3: Insert the data into the temporary table
INSERT INTO #SalesReport (Quarter, ProductName, Month, Quantity, TotalRevenue)
SELECT 
    Quarter,
    ProductName,
    Month,
    Quantity,
    TotalRevenue
FROM 
    SalesData;

-- Step 4: Select the three best-selling products per quarter and month
SELECT 
    Quarter,
    ProductName,
    Month,
    Quantity,
    TotalRevenue
FROM (
    SELECT 
        Quarter,
        ProductName,
        Month,
        Quantity,
        TotalRevenue,
        ROW_NUMBER() OVER (PARTITION BY Quarter, Month ORDER BY TotalRevenue DESC) AS Rank
    FROM 
        #SalesReport
) AS RankedSales
WHERE 
    Rank <= 3
ORDER BY 
    Quarter, Month, Rank;

-- Step 5: Drop the temporary table
DROP TABLE #SalesReport;

--Metadata Questions

--Q7: Which tables in AdventureWorks contain a column named "ModifiedDate"?

-- Step 1: Find all tables that have a column named "ModifiedDate"
SELECT 
    TABLE_SCHEMA AS SchemaName,
    TABLE_NAME AS TableName
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    COLUMN_NAME = 'ModifiedDate';

--Q8: Can you list all the views in AdventureWorks that reference the "SalesOrderHeader" table?

-- Paso 1: Encontrar todas las vistas que hacen referencia a la tabla "SalesOrderHeader"
SELECT 
    V.name AS ViewName,
    OBJECT_DEFINITION(V.object_id) AS ViewDefinition
FROM 
    sys.views V
JOIN 
    sys.sql_expression_dependencies D ON V.object_id = D.referencing_id
JOIN 
    sys.tables T ON D.referenced_id = T.object_id
WHERE 
    T.name = 'SalesOrderHeader';
