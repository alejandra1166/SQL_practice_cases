/*Pizza Runner

From https://8weeksqlchallenge.com/case-study-2/

CLEANING DATA: runner_orders
Changing datatypes */

--pickup_time

UPDATE runner_orders 
SET pickup_time = NULL 
WHERE pickup_time = 'null' 

ALTER TABLE runner_orders 
ALTER COLUMN pickup_time DATETIME

--distance 

UPDATE runner_orders
SET distance = SUBSTRING(distance, 1, LEN(distance)-2)
WHERE distance like'%km'


UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null'


ALTER TABLE runner_orders 
ALTER COLUMN distance DECIMAL(5,2)

--duration and nulls

UPDATE runner_orders
SET duration = SUBSTRING(duration, 1, 2)
WHERE duration like'%min%'

UPDATE runner_orders
SET cancellation = NULL 
where cancellation = 'null'

UPDATE runner_orders
SET cancellation = ISNULL(cancellation,'')



-- exclusions and extras

UPDATE [dbo].[customer_orders]
SET exclusions = NULL
WHERE exclusions = 'null'

UPDATE [dbo].[customer_orders]
SET extras = NULL
WHERE extras = 'null'

--ANSWERING QUESTIONS
--PIZZA METRICS

--1. How many pizzas were ordered?

SELECT SUM(pizza_id) AS Total_Pizzas
FROM customer_orders

-- Total_Pizzas = 18


-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT(order_id)) AS unique_orders
FROM customer_orders

--unique_orders = 10



-- 3. How many successful orders were delivered by each runner?


SELECT COUNT(cancellation) AS successful_orders, runner_id
FROM runner_orders
WHERE cancellation = ''
GROUP BY runner_id

/*
Successful_orders: 4,3,1
Runner_id: 1,2,3
*/

--4. How many of each type of pizza was delivered?

SELECT c_o.pizza_id, COUNT(c_o.pizza_id) AS Total_by_Type
  FROM runner_orders AS r_o
  INNER JOIN customer_orders AS c_o
  ON r_o.order_id = c_o.order_id
  WHERE NOT r_o.cancellation IN ('Restaurant Cancellation', 'Customer Cancellation')
  GROUP BY c_o.pizza_id

/*
Pizza_id = 1, 2
Total_by_Type = 9, 3
*/

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

WITH cte_1
AS(
SELECT pizza_id, customer_id, COUNT(pizza_id) AS Total_Pizzas_Ordered
FROM customer_orders
GROUP BY pizza_id, customer_id
)

SELECT cte_1.customer_id, cte_1.Total_Pizzas_Ordered, pizza_names.pizza_name
FROM cte_1
INNER JOIN pizza_names
ON pizza_names.pizza_id = cte_1.pizza_id
ORDER BY cte_1.customer_id

/*
customer_id	Total_Pizzas_Ordered	pizza_name
101	2	Meatlovers
101	1	Vegetarian
102	2	Meatlovers
102	1	Vegetarian
103	3	Meatlovers
103	1	Vegetarian
104	3	Meatlovers
105	1	Vegetarian
*/



