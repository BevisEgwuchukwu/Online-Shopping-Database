CREATE DATABASE OnlineShoppingDB;
GO
USE OnlineShoppingDB;
GO

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(50),
    country VARCHAR(50)
);

BULK INSERT Customers
FROM 'C:\Users\HP PAVILON 15\Desktop\Customers.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

SELECT * FROM Customers;

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

BULK INSERT Products
FROM 'C:\Users\HP PAVILON 15\Desktop\Products.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

SELECT * FROM Products;

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

BULK INSERT Orders
FROM 'C:\Users\HP PAVILON 15\Desktop\Orders.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

SELECT * FROM Orders;

CREATE TABLE Order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price_each DECIMAL(10,2),
    Total_price DECIMAL(10,2), 
    Totalamount DECIMAL(10,2), 
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

BULK INSERT Order_items
FROM 'C:\Users\HP PAVILON 15\Desktop\Order_items.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

SELECT * FROM Order_items;

CREATE TABLE Payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
	payment_date DATE,
	 payment_method VARCHAR(50),
    Amount_paid DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

BULK INSERT Payments
FROM 'C:\Users\HP PAVILON 15\Desktop\Payments.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

SELECT * FROM Payments;

-- Task 2
SELECT DISTINCT c.name, c.country
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Order_items oi ON o.order_id = oi.order_id
GROUP BY c.name, c.country, o.order_id
HAVING SUM(CONVERT(DECIMAL(10, 2), oi.Totalamount)) BETWEEN 500 AND 1000;

--Task 3
SELECT c.name, SUM(CAST(p.Amount_paid AS DECIMAL(10, 2))) AS total_paid
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Order_items oi ON o.order_id = oi.order_id
JOIN Payments p ON o.order_id = p.order_id
WHERE c.country = 'UK'
GROUP BY c.name, o.order_id
HAVING SUM(CAST(oi.quantity AS INT)) > 3;

--Task 4 
SELECT TOP 2 
    ROUND(CAST(p.amount_paid AS DECIMAL(10, 2)) * 1.122, 0) AS vat_adjusted_amount
FROM Payments p
JOIN Orders o ON p.order_id = o.order_id
JOIN Customers c ON o.customer_id = c.customer_id
WHERE c.country IN ('UK', 'Australia')
ORDER BY vat_adjusted_amount DESC;

--Task 5 
SELECT p.product_name, SUM(CAST(oi.quantity AS INT)) AS total_quantity
FROM Order_items oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC;

GO

--Task 6
CREATE PROCEDURE ApplyDiscountss
AS
BEGIN
    UPDATE p
    SET p.Amount_paid = CAST(p.Amount_paid AS DECIMAL(10, 2)) * 0.95
    FROM Payments p
    JOIN Orders o ON p.order_id = o.order_id
    JOIN Order_items oi ON o.order_id = oi.order_id
    JOIN Products pr ON oi.product_id = pr.product_id
    WHERE pr.product_name IN ('Laptop', 'Smartphone') AND CAST(p.Amount_paid AS DECIMAL(10, 2)) >= 17000;
END;
GO

EXEC ApplyDiscountss; 

-- Test the discount
SELECT 
    p.payment_id, 
    p.order_id, 
    p.Amount_paid
FROM Payments p
JOIN Orders o ON p.order_id = o.order_id
JOIN Order_items oi ON o.order_id = oi.order_id
JOIN Products pr ON oi.product_id = pr.product_id
WHERE pr.product_name IN ('Laptop', 'Smartphone') 
    AND CAST(p.Amount_paid AS DECIMAL(10, 2)) >= 17000;

--Task 7: Custom Queries

--Query 1 - Customers purchasin electronics 
SELECT c.name, c.email
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    JOIN Order_items oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_id = p.product_id
    WHERE o.customer_id = c.customer_id
      AND p.category = 'Electronics'
);

--Query 2 - orders value by country
SELECT 
  c.country, 
  COUNT(o.order_id) AS OrderCount, 
  SUM(p.Amount_paid) AS TotalRevenue
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Payments p ON o.order_id = p.order_id
GROUP BY c.country
HAVING SUM(p.Amount_paid) > 10000
ORDER BY TotalRevenue DESC;

--Query 3 - Monthly order analysis 
SELECT YEAR(o.order_date) AS OrderYear, MONTH(o.order_date) AS OrderMonth,
    DATENAME(MONTH, o.order_date) AS MonthName,
    COUNT(o.order_id) AS OrderCount,
    SUM(p.Amount_paid) AS MonthlyRevenue,
    AVG(p.Amount_paid) AS AverageOrderValue
FROM Orders o
JOIN Payments p ON o.order_id = p.order_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date), DATENAME(MONTH, o.order_date)
ORDER BY OrderYear, OrderMonth;

--Query 4 - Products that have been purchased by more than 3 customers
SELECT 
    p.product_id, 
    p.product_name
FROM Products p
WHERE p.product_id IN (
    SELECT oi.product_id
    FROM Order_items oi
    JOIN Orders o ON oi.order_id = o.order_id
    GROUP BY oi.product_id
    HAVING COUNT(DISTINCT o.customer_id) > 20
);

--Query 5 - Top 10 customer ranking by spending 
WITH CustomerSpending AS (
    SELECT c.name, c.country, SUM(p.Amount_paid) AS TotalSpent
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN Payments p ON o.order_id = p.order_id
    GROUP BY c.name, c.country
)
SELECT TOP 10 name, country, TotalSpent
FROM CustomerSpending
ORDER BY TotalSpent DESC;

-- Data Protection: 
-- BackUp Database AirportTicketSystem
-- Regular Full Backup
BACKUP DATABASE OnlineShoppingDB
TO DISK = 'C:\Backup\OnlineShoppingDB_Full_20250418.bak'
WITH INIT, NAME = 'Full Database Backup';

-- Transaction Log Backup
BACKUP LOG OnlineShoppingDB
TO DISK = 'C:\Backup\OnlineShoppingDB_Log_20250418.trn'

-- Differential Backup
BACKUP DATABASE OnlineShoppingDB
TO DISK = 'C:\Backup\OnlineShoppingDB_Diff_20250418.bak'
WITH DIFFERENTIAL; 

-- TEST BACKUP INTEGRITY
RESTORE VERIFYONLY 
FROM DISK = 'C:\Backup\OnlineShoppingDB_Full_20250418.bak'

-- DISASTER RECOVERY 
RESTORE DATABASE OnlineShoppingDB
FROM DISK = 'C:\Backup\OnlineShoppingDB_Full_20250418.bak'
WITH NORECOVERY; 

RESTORE DATABASE OnlineShoppingDB
FROM DISK = 'C:\Backup\OnlineShoppingDB_Log_20250418.trn'
WITH RECOVERY, STOPAT = '2025-04-20T16:30:00'; 
