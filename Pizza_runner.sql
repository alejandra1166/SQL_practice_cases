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




