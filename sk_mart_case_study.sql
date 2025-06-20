
-- 1. What are the top 5 best-selling products by quantity and revenue? 

SELECT
	P.NAME,
	SUM(OI.QUANTITY) AS TOTAL_QTY,
	SUM(OI.PRICE*OI.QUANTITY) AS REVENUE
FROM PRODUCTS AS P
LEFT JOIN ORDER_ITEMS AS OI
ON P.ID = OI.PRODUCT_ID
GROUP BY 1
ORDER BY TOTAL_QTY desc, REVENUE DESC
LIMIT 5;

-- 2.Which customers placed the most orders? 

SELECT
	C.FULL_NAME,
	COUNT(O.ID) AS TOTAL_ORDERS,
	RANK() OVER( ORDER BY COUNT(O.ID) DESC) AS RANK_ORDERS
FROM CUSTOMERS AS C
LEFT JOIN ORDERS AS O
ON C.ID = O.CUSTOMER_ID
GROUP BY 1
LIMIT 2;

-- 3. Who are the top customers based on total spending? 

SELECT
	C.FULL_NAME,
	SUM(TOTAL_AMOUNT) AS TOTAL_SPEND
FROM CUSTOMERS AS C
LEFT JOIN ORDERS AS O
ON C.ID = O.CUSTOMER_ID
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- 4. Compare online vs. offline sales for each store. 

-- SELECT
-- S.ID AS STORE_ID,
-- S.STORE_NAME,
-- O.ORDER_TYPE,
-- COUNT(O.ID) AS TOTAL_ORDERS,
-- SUM(O.TOTAL_AMOUNT) AS TOTAL_SALES
-- FROM STORES AS S
-- LEFT JOIN ORDERS AS O
-- ON S.ID = O.STORE_ID
-- GROUP BY 1,2,3
-- ORDER BY SUM(O.TOTAL_AMOUNT) DESC;

-- 4. Compare online vs. offline sales for each store. 

SELECT 
    s.id AS store_id,
    s.store_name,
    SUM(CASE WHEN o.order_type = 'online' THEN o.total_amount ELSE 0 END) AS online_sales,
    SUM(CASE WHEN o.order_type = 'offline' THEN o.total_amount ELSE 0 END) AS offline_sales
FROM stores s
JOIN orders o 
ON s.id = o.store_id
GROUP BY s.id, s.store_name
ORDER BY S.ID

-- 5. Which product categories generate the highest and lowest revenue? 

SELECT
	C.CATEGORY_NAME ,
	SUM(OI.PRICE * OI.QUANTITY) AS REVENUE
FROM CATEGORIES AS C
LEFT JOIN PRODUCTS AS P
ON C.ID = P.CATEGORY_ID
LEFT JOIN ORDER_ITEMS AS OI
ON P.ID = OI.PRODUCT_ID
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


SELECT
	C.CATEGORY_NAME ,
	SUM(OI.PRICE * OI.QUANTITY) AS REVENUE
FROM CATEGORIES AS C
LEFT JOIN PRODUCTS AS P
ON C.ID = P.CATEGORY_ID
LEFT JOIN ORDER_ITEMS AS OI
ON P.ID = OI.PRODUCT_ID
GROUP BY 1
ORDER BY 2 ASC
LIMIT 1;

-- 6. Which marketing campaign brought in the most orders? 

SELECT
	MC.campaign_name,
	COUNT(*) AS TOTAL_ORDERS
FROM marketing_campaigns AS MC
LEFT JOIN ORDERS AS O
ON MC.ID = O.MARKETING_ID
GROUP BY 1
ORDER BY 2 DESC;
-- LIMIT 1;

-- 7. What is the revenue trend over days or months? 

SELECT
DATE_FORMAT(ORDER_DATE, '%m-%d') AS time,
SUM(TOTAL_AMOUNT) AS REVENUE
FROM ORDERS
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- 8. Which payment method is used most frequently? 

SELECT
payment_method,
COUNT(ID) AS TOTAL_ORDERS
FROM ORDERS
GROUP BY 1
ORDER BY 2 DESC;

-- 9. What are the current inventory levels per store and product? 

SELECT
	S.ID, S.STORE_NAME,
	P.ID,P.NAME,
	I.QUANTITY AS CURRENT_QTY
FROM INVENTORY AS I
JOIN STORES AS S
ON S.ID = I.STORE_ID
JOIN PRODUCTS AS P
ON P.ID = I.PRODUCT_ID
ORDER BY S.STORE_NAME, P.NAME, CURRENT_QTY DESC;

-- SELECT
--     S.ID AS STORE_ID,
--     S.STORE_NAME,
--     P.ID AS PRODUCT_ID,
--     P.NAME AS PRODUCT_NAME,
--     SUM(I.QUANTITY) AS TOTAL_QTY
-- FROM INVENTORY AS I
-- JOIN STORES AS S ON S.ID = I.STORE_ID
-- JOIN PRODUCTS AS P ON P.ID = I.PRODUCT_ID
-- GROUP BY  S.STORE_NAME, P.ID, P.NAME
-- ORDER BY S.STORE_NAME, P.NAME;

-- 10. Add a column last_order_date to the customers table.

ALTER TABLE CUSTOMERS
ADD COLUMN LAST_ORDER_DATE DATETIME;

-- 11. Update each customer’s last_order_date based on their latest order. 

UPDATE CUSTOMERS C
SET LAST_ORDER_DATE = (
	SELECT
    MAX(O.ORDER_DATE) 
    FROM ORDERS O
    WHERE C.ID = O.CUSTOMER_ID);

SELECT * FROM CUSTOMERS;

-- 12. Insert a new promotional campaign and assign it to new orders. 

INSERT INTO marketing_campaigns (
	ID, campaign_name, platform, budget, start_date, end_date, notes, created_at
)
VALUES (
	21,'Eid Mega Offer','facebook', 50000.00, '2025-06-01', '2025-06-30', 'Special Eid campaign with 15% discount on selected items.', NOW()
);

INSERT INTO orders (
    id, customer_id, store_id, marketing_id, order_type, order_date, total_amount, payment_method, created_at
)
VALUES (
    301, 5,  2,  21, 'online', NOW(), 1250.00, 'credit_card', NOW()
);

-- 13. Delete products that haven’t been sold in the last 6 months. 

SELECT * FROM PRODUCTS
WHERE ID NOT IN (
	SELECT DISTINCT OI.product_id
    FROM ORDER_ITEMS AS OI
    JOIN ORDERS AS O
    ON O.ID = OI.ORDER_ID
    WHERE O.ORDER_DATE >= CURDATE() - INTERVAL 6 MONTH);

DELETE FROM products
WHERE id NOT IN (
    SELECT DISTINCT oi.product_id
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    WHERE o.order_date >= CURDATE() - INTERVAL 6 MONTH
);

-- 14. Rank customers by total amount spent. 

SELECT
C.ID AS CUSTOMER_ID,
C.FULL_NAME,
SUM(O.TOTAL_AMOUNT) AS AMOUNT_SPENT,
RANK() OVER(ORDER BY SUM(O.TOTAL_AMOUNT) DESC) AS RNK
FROM CUSTOMERS AS C
LEFT JOIN ORDERS AS O
ON C.ID = O.CUSTOMER_ID
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10;

-- 15. Show the top 3 best-selling products per store. 

WITH CTE AS(
SELECT 
        s.id AS store_id,
        s.store_name,
        p.id AS product_id,
        p.name AS product_name,
        SUM(oi.quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY SUM(oi.quantity) DESC) AS RNK
    FROM order_items oi
    JOIN orders o 
    ON oi.order_id = o.id
    JOIN stores s 
    ON o.store_id = s.id
    JOIN products p 
    ON oi.product_id = p.id
    GROUP BY s.id, s.store_name, p.id, p.name
)

SELECT STORE_ID, STORE_NAME, PRODUCT_NAME,
total_quantity_sold, RNK
FROM CTE
WHERE RNK <= 3;

-- 16. Calculate a running total of daily revenue. 

SELECT
    DATE(order_date) AS order_day,
    SUM(total_amount) AS daily_revenue,
    SUM(SUM(total_amount)) OVER (ORDER BY DATE(order_date)) AS running_total_revenue
FROM orders
GROUP BY DATE(order_date)
ORDER BY order_day;

-- 17. Compute a 7-day rolling average of total order amounts. 

SELECT
    DATE(order_date) AS order_day,
    SUM(total_amount) AS daily_revenue,
    AVG(SUM(total_amount)) OVER (ORDER BY DATE(order_date) 
				ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) 
    AS ROLLING_AVG_7_DAY
FROM orders
GROUP BY DATE(order_date)
ORDER BY order_day;

-- 18. Show the time difference between each customer's consecutive orders. 

SELECT
    customer_id,
    id AS order_id,
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
    TIMESTAMPDIFF(DAY, 
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date), 
        order_date
    ) AS days_between_orders
FROM orders
ORDER BY customer_id, order_date;

-- 19. Identify customers who placed two orders on back-to-back days. 

WITH CTE AS(
SELECT
	C.ID AS CUSTOMER_ID,
    C.FULL_NAME AS FULL_NAME,
    O.ID AS order_id,
    O.order_date,
    LAG(O.order_date) OVER (PARTITION BY O.customer_id ORDER BY O.order_date) AS previous_order_date,
    DATEDIFF( O.ORDER_DATE, LAG(O.order_date) OVER (PARTITION BY O.customer_id ORDER BY O.order_date)) AS DIFF
FROM ORDERS AS O
JOIN CUSTOMERS AS C
ON C.ID = O.CUSTOMER_ID
)
SELECT DISTINCT CUSTOMER_ID, FULL_NAME, DIFF
 FROM CTE
WHERE DIFF = 1;

-- 20. Classify orders as ‘High’, ‘Medium’, or ‘Low’ value based on amount. 

SELECT
    id AS order_id,
    customer_id,
    total_amount,
    CASE
        WHEN total_amount >= 1000 THEN 'High'
        WHEN total_amount >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS order_value_category
FROM orders
ORDER BY total_amount DESC;

-- 21. Show whether each day’s sales were higher or lower than the previous day. 

WITH daily_sales AS (
    SELECT 
        DATE(order_date) AS order_day,
        SUM(total_amount) AS daily_revenue
    FROM 
        orders
    GROUP BY 
        DATE(order_date)
)

SELECT
    order_day,
    daily_revenue,
    LAG(daily_revenue) OVER (ORDER BY order_day) AS previous_day_revenue,
    CASE
        WHEN daily_revenue > LAG(daily_revenue) OVER (ORDER BY order_day) THEN 'Higher'
        WHEN daily_revenue < LAG(daily_revenue) OVER (ORDER BY order_day) THEN 'Lower'
        WHEN daily_revenue = LAG(daily_revenue) OVER (ORDER BY order_day) THEN 'Same'
        ELSE 'N/A'
    END AS sales_trend
FROM daily_sales
ORDER BY order_day;

-- 22. Find customers who placed only one order ever. 

SELECT 
    C.ID AS CUSTOMER_ID,
    C.FULL_NAME,
    COUNT(O.ID) AS ORDER_COUNT
FROM CUSTOMERS AS C
JOIN ORDERS AS O 
ON C.ID = O.CUSTOMER_ID
GROUP BY C.ID, C.FULL_NAME
HAVING 
    COUNT(O.ID) = 1
ORDER BY C.ID;

-- 24. Find the most popular product among buyers of 'Soybean Oil'. 

WITH soybean_buyers AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE p.name = 'Soybean Oil'
),
other_products AS (
    SELECT 
        p.id AS product_id,
        p.name AS product_name,
        COUNT(*) AS times_ordered
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.customer_id IN (SELECT customer_id FROM soybean_buyers)
      AND p.name != 'Soybean Oil'
    GROUP BY p.id, p.name
)
SELECT *
FROM other_products
ORDER BY times_ordered DESC
LIMIT 1;

-- 25. Create a trigger to update last_order_date after a new order. 

DELIMITER $$

CREATE TRIGGER update_last_order_date
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    UPDATE customers
    SET last_order_date = NEW.order_date
    WHERE id = NEW.customer_id;
END $$

DELIMITER ;

-- 26. Schedule an update to refresh all last_order_date fields once daily. 

CREATE EVENT IF NOT EXISTS update_last_order_dates_daily
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
  UPDATE customers c
  SET last_order_date = (
      SELECT MAX(o.order_date)
      FROM orders o
      WHERE o.customer_id = c.id
  );
  
  SHOW EVENTS;
  CALL update_last_order_dates_daily;
  
  

