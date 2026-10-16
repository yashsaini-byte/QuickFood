-- Q.1
-- Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 1 year.
--

-- join cx and orders
-- filter for last 4 year 
-- FILTER 'arjun mehta'
-- group by cx id, dishes, cnt

SELECT 
	c.customer_name,
	o.order_item AS dishes,
	COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON o.customer_id=c.customer_id
WHERE c.customer_name= 'Arjun Mehta'
AND o.order_date >= CURRENT_DATE - INTERVAL '4 year'
GROUP BY c.customer_name,o.order_item
ORDER BY total_orders DESC LIMIT 5;




-- 2. Popular Time Slots
-- Question: Identify the time slots during which the most orders are placed. based on 2-hour intervals.


SELECT
CASE 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00-02:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00-04:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00-06:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00-08:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00-10:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00-12:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00-14:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00-16:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00-18:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00-20:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00-22:00' 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00-00:00' 
END AS time_slot,
count(order_id) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY order_count DESC;




-- 3. Order Value Analysis
-- Question: Find the average order value per customer who has placed more than 750 orders.
-- Return customer_name, and aov(average order value)

SELECT 
c.customer_name,
AVG(o.total_amount) AS average_order_value
FROM orders AS o
JOIN customers AS c ON c.customer_id=o.customer_id
GROUP BY customer_name
HAVING COUNT(order_id)>750;




-- 5. Orders Without Delivery
-- Question: Write a query to find orders that were placed but not delivered. 
-- Return each restuarant name, city and number of not delivered orders 

SELECT
    r.restaurant_name,
    r.city,
    COUNT(o.order_id) AS undelivered_orders
FROM restaurants r
JOIN orders o ON r.restaurant_id = o.restaurant_id
WHERE o.order_status = 'Not Fulfilled'
GROUP BY r.restaurant_name, r.city, o.order_status
ORDER BY undelivered_orders DESC;



-- Q. 6
-- Restaurant Revenue Ranking: 
-- Rank restaurants by their total revenue from the last 5 year, including their name, 
-- total revenue, and filtering rank per city.

SELECT 
r.restaurant_name,
r.city,
o.total_amount 
FROM restaurants as r
JOIN orders as o ON r.restaurant_id=o.restaurant_id
WHERE r.city='Delhi' AND o.order_date> CURRENT_DATE - interval '3 Year'
GROUP BY r.restaurant_name,r.city, o.total_amount
ORDER BY o.total_amount DESC;


-- Q. 7
-- Most Popular Dish by City: 
-- Identify the most popular dish in each city based on the number of orders.

WITH dish_counts AS (
    SELECT
        r.city AS city,
        o.order_item AS dish,
        COUNT(o.order_id) AS total_orders,
        RANK() OVER (
            PARTITION BY r.city
            ORDER BY COUNT(o.order_id) DESC
        ) AS city_rank
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    GROUP BY r.city, o.order_item
)
SELECT city, dish, total_orders
FROM dish_counts
WHERE city_rank = 1
ORDER BY city;



-- Q.8 Customer Churn: 
-- Find customers who haven’t placed an order in 2024 but did in 2023.

-- find cx who has done orders in 2023
-- find cx who has not done orders in 2024
-- compare 1 and 2


SELECT DISTINCT customer_id FROM orders
WHERE 
EXTRACT(YEAR FROM order_date)= 2023
AND 
customer_id NOT IN 
(SELECT DISTINCT customer_id FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024);




-- Q.9 Customer Segmentation: 
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV, 
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue

-- cx total spend
-- aov
-- gold
-- silver
-- each category and total orders and total rev


WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(o.total_amount) AS revenue,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    revenue,
    total_orders,
    CASE
        WHEN revenue > (SELECT AVG(revenue) FROM customer_spend)
            THEN 'Gold'
        ELSE 'Silver'
    END AS customer_category
FROM customer_spend
ORDER BY revenue DESC
LIMIT 5;



-- Q.10 Customer Lifetime Value (CLV): 
-- Calculate the total revenue generated by each customer over all their orders.

SELECT 
o.customer_id,
	c.customer_name,
	SUM(o.total_amount) as CLV
FROM orders as o
JOIN customers as c
ON o.customer_id = c.customer_id
GROUP BY 1, 2;



