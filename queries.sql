-- Advance SQL Queries

-- 1. Write a query to find top 3 most frequently ordered dishes by customer called 'Daniel Brown' in last 1 year
WITH RankedDishes AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        o.order_item AS dish,
        COUNT(*) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.customer_id ORDER BY COUNT(*) DESC) AS rank
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
      AND c.customer_name = 'Daniel Brown'
    GROUP BY c.customer_id, c.customer_name, o.order_item
)
SELECT 
    customer_id, 
    customer_name, 
    dish AS dishes, 
    order_count
FROM RankedDishes
WHERE rank <= 3
ORDER BY order_count DESC;



-- 2. Popular Time Slots
-- Question: Identify the time slots during which the most orders are placed. based on 2-hour interval

-- Approch 1: 
-- HINT: GET_HOUR(SELECT 00:59:59) - 0
-- 	  	 GET_HOUR(SELECT 01:59:59) - 1
SELECT 
    CASE 
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
    END AS time_slot,
    COUNT(*) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY order_count DESC;


-- Approch 2: 
WITH TimeSlots AS (
    SELECT
        FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 AS start_hour,
        FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 + 2 AS end_hour,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY start_hour, end_hour
)
SELECT
    CONCAT(start_hour, ' - ', end_hour) AS time_slot,
    order_count
FROM TimeSlots
ORDER BY order_count DESC;


-- 3 Order value analysis
-- Find the average order value per customer who has placed at least 7 orders
-- return customer_name, and aov(average order value)

-- NOTE: I changed few records in 'order' table in column 'customer_id to 7' to get more desired output

select c.customer_name, count(*) as total_orders, avg(total_amount) as aov
from orders o
join customers c on o.customer_id = c.customer_id
group by 1
having count(*) >= 7
order by 1

-- 4. High-Value Customers
-- List the customer who have spent more than 300 in total on food orders
-- return customer_name, customer_id

select o.customer_id, c.customer_name, sum(total_amount) as total_spent
from orders o
join customers c on o.customer_id = c.customer_id
group by 1, 2
having sum(total_amount) > 300


-- 5. Orders without delivery
-- Write a query to find orders that were placed but not delivered
-- return restaurant_name, city and order_id
SELECT COUNT(*) AS total_orders FROM orders; -- 110
SELECT COUNT(*) AS total_deliveries FROM deliveries; -- 100

SELECT r.restaurant_name, r.city, o.order_id
FROM orders o
LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
LEFT JOIN deliveries d ON o.order_id = d.order_id
WHERE d.delivery_id IS NULL


-- 6. Restaurant Revenue Ranking
-- Rank restaurants by their total revenue from last 2 year.
-- return restaurant_name, total_revenue, city, rank

SELECT 
    r.city, 
    r.restaurant_name, 
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rk
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY r.city, r.restaurant_name


-- 7. Most popular dish by city based on number of orders


select r.city, o.order_item as dish, count(order_id) as total_orders,
	rank() over(partition by r.city order by count(order_id) desc) as rk
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
group by 1, 2


-- 8. Customer Churn
-- Find customers who havent placed an order in 2024 but did in 2023

SELECT DISTINCT c.customer_id, c.customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
  AND o.customer_id NOT IN (
      SELECT DISTINCT customer_id 
      FROM orders 
      WHERE EXTRACT(YEAR FROM order_date) = 2024);

-- 9. Cancellation Rate Comparision
-- Calculate and compare the order cancellation rate for each restaurant between current year and previous year

WITH CancellationRates AS (
    SELECT 
        o.restaurant_id,
        EXTRACT(YEAR FROM o.order_date) AS year,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    GROUP BY o.restaurant_id, EXTRACT(YEAR FROM o.order_date)
),

-- 2024
CurrentYear AS (
    SELECT
        restaurant_id,
        total_orders AS current_year_orders,
        not_delivered AS current_year_not_delivered,
        (not_delivered * 100.0 / total_orders) AS current_year_cancellation_rate
    FROM CancellationRates
    WHERE year = EXTRACT(YEAR FROM CURRENT_DATE)
),

-- 2023
PreviousYear AS (
    SELECT
        restaurant_id,
        total_orders AS previous_year_orders,
        not_delivered AS previous_year_not_delivered,
        (not_delivered * 100.0 / total_orders) AS previous_year_cancellation_rate
    FROM CancellationRates
    WHERE year = EXTRACT(YEAR FROM CURRENT_DATE) - 1
)

SELECT
    cy.restaurant_id,
    cy.current_year_orders,
    cy.current_year_not_delivered,
    cy.current_year_cancellation_rate,
    py.previous_year_orders,
    py.previous_year_not_delivered,
    py.previous_year_cancellation_rate
FROM CurrentYear cy
LEFT JOIN PreviousYear py ON cy.restaurant_id = py.restaurant_id
ORDER BY cy.restaurant_id;


-- 10. Riders Average Delivery Time
-- Find each riders average delivery time

SELECT 
    r.rider_id, 
    r.rider_name,
    ROUND(AVG(EXTRACT(EPOCH FROM (
        d.delivery_time - o.order_time 
        + CASE 
            WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
            ELSE INTERVAL '0 day'
          END
    )) / 60), 2) AS avg_delivery_time_minutes
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
JOIN riders r ON d.rider_id = r.rider_id
WHERE o.order_status = 'Delivered'
GROUP BY r.rider_id, r.rider_name
ORDER BY avg_delivery_time_minutes;


-- END
