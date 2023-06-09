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

ALTER TABLE runner_orders 
ALTER COLUMN duration DECIMAL(5,2)

--cancellation

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
--1. PIZZA METRICS

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
-- 6. What was the maximum number of pizzas delivered in a single order?
 
SELECT customer_id, COUNT(customer_id) AS Pizzas_in_a_single_order
FROM customer_orders AS co
INNER JOIN runner_orders AS ru
ON co.order_id = ru.order_id
WHERE NOT ru.cancellation IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY  customer_id, order_time
ORDER BY  Pizzas_in_a_single_order DESC
 
/*
customer_id	Pizzas_in_a_single_order
103	3
104	2
102	2
102	1
101	1
101	1
105	1
104	1
*/

--7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT customer_id, 
       COUNT(CASE WHEN NOT COALESCE(extras, '') = '' 
                    OR NOT COALESCE(exclusions, '') = '' THEN 1 END) AS num_with_changes,
       COUNT(CASE WHEN COALESCE(extras, '') = ''
                   AND COALESCE(exclusions, '') = '' THEN 1 END) AS num_with_no_changes
FROM customer_orders co
WHERE NOT EXISTS(SELECT 1 
                 FROM runner_orders ro 
                 WHERE co.order_id = ro.order_id 
                   AND NOT COALESCE(cancellation, '') = '')
GROUP BY customer_id

/*
customer_id	num_with_changes	num_with_no_changes
101	0	2
102	0	3
103	3	0
104	2	1
105	1	0

*/



--8. How many pizzas were delivered that had both exclusions and extras?


WITH cte_1
AS(
SELECT co.customer_id, 
       COUNT(CASE WHEN NOT exclusions = '' THEN 0 END) AS with_exclusions
	   ,COUNT(CASE WHEN NOT extras = '' THEN 0 END) AS  with_extras
FROM customer_orders AS co
WHERE NOT EXISTS(SELECT 1 
                 FROM runner_orders ro 
                 WHERE co.order_id = ro.order_id 
                   AND NOT COALESCE(cancellation, '') = '')
group by customer_id
)
Select customer_id
		,COUNT(CASE WHEN with_exclusions != 0 AND with_extras != 0 THEN 0 END) AS with_exclusions_and_extras
From cte_1
group by customer_id
ORDER BY with_exclusions_and_extras DESC

/*
customer_id	with_exclusions_and_extras
104	1
105	0
101	0
102	0
103	0
*/


--9. What was the total volume of pizzas ordered for each hour of the day?


WITH cte_1
AS(
SELECT COUNT(pizza_id) AS pizzas_ordered, DATEPART(HOUR,order_time) AS date_of_the_order
FROM customer_orders
GROUP BY DATEPART(HOUR,order_time)
)
SELECT avg(cast(pizzas_ordered AS DECIMAL(5,2))) /24 AS avg_by_hour
FROM cte_1


-- Avg_by_day : 0.097222


-- 10. What was the volume of orders for each day of the week?

WITH cte_1
AS(
SELECT  DATEPART(day,order_time) AS day_ordered, order_id
FROM customer_orders
)
SELECT COUNT(order_id) AS number_of_orders, day_ordered
FROM cte_1
GROUP BY day_ordered

/*
number_of_orders	day_ordered
2	1
2	2
3	4
3	8
1	9
1	10
2	11
*/

--B. Runner and Customer Experience

--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

WITH cte_1
AS(
SELECT DATEPART(WEEK, registration_date) AS weeks, runner_id
FROM runners
)

SELECT weeks, COUNT(runner_id) AS number_of_runners_signed_up
FROM cte_1
GROUP BY weeks

/*
weeks	runners_signed_up
1	1
2	2
3	1
*/


--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?


WITH cte_1
AS(
SELECT ru.runner_id, (ru.pickup_time - co.order_time) as total_time
FROM runner_orders as ru
INNER JOIN customer_orders as co
ON ru.order_id = co.order_id
)

SELECT runner_id, (AVG(DATEPART(MINUTE, total_time))) AS avg_time
FROM cte_1
group by runner_id


/*
runner_id	avg_time
1	15
2	23
3	10
*/


--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?


WITH cte_1
AS(
SELECT co.order_id, (ru.pickup_time - co.order_time) as prep_time, 
		COUNT(pizza_id) OVER (partition by co.order_id )  AS pizzas_per_order
FROM runner_orders as ru
INNER JOIN customer_orders as co
ON ru.order_id = co.order_id
WHERE NOT EXISTS  (SELECT 1 
		from runner_orders ru  
		WHERE co.order_id = ru.order_id AND NOT COALESCE(cancellation, '') = '')

)

SELECT AVG(DATEPART(MINUTE,prep_time)) as prep_time_minutes, pizzas_per_order
FROM cte_1
group by pizzas_per_order

/*
prep_time_minutes	pizzas_per_order
12	1
18	2
29	3
*/


--4. What was the average distance traveled for each customer?

SELECT co.customer_id, AVG(ru.distance) AS avg_distance_by_customer_in_Km
  FROM runner_orders AS ru 
	inner JOIN customer_orders co
	ON ru.order_id = co.order_id 
group by co.customer_id

/*
customer_id	avg_distance_by_customer_in_Km
101	20.000000
102	16.733333
103	23.400000
104	10.000000
105	25.000000
*/


--5.What was the difference between the longest and shortest delivery times for all orders?

SELECT (MAX(CAST(duration as INT))) - (MIN(CAST(duration as INT))) AS total_difference
FROM runner_orders

-- total_difference = 30 min

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
 

SELECT order_id, runner_id, AVG(distance/duration) AS avg_speed
FROM runner_orders
where cancellation = ''
group by order_id, runner_id
ORDER BY order_id

/*
order_id	runner_id	avg_speed
1	1	0.62500000
2	1	0.74074074
3	1	0.67000000
4	2	0.58500000
5	3	0.66666666
7	2	1.00000000
8	2	1.56000000
10	1	1.00000000
*/


--7. What is the successful delivery percentage for each runner?


WITH cte_1
AS (
SELECT runner_id, (COUNT(runner_id))*100 AS percentages
		FROM runner_orders 
		WHERE cancellation = ''
		group by runner_id
		)
SELECT cte_1.runner_id, (percentages/(COUNT(ru.cancellation))) as percentages_successful_deliveries
FROM cte_1
full JOIN runner_orders AS ru
on cte_1.runner_id = ru.runner_id
group by cte_1.runner_id, cte_1.percentages
order by runner_id


SHORTER ANSWER SOMEONE IN STACKOVERFLOW.COM SHOWED ME:

select runner_id,
       count(case when cancellation = '' then 1 end) *100 / count(*) as percentage
from runner_orders
group by runner_id
order by runner_id

/*
runner_id	percentages_successful_deliveries
1	100
2	75
3	50
*/

--C. Ingredient Optimisation

--1.What are the standard ingredients for each pizza?
select pizza_id, string_agg(cast(topping_name as varchar),',') as ingredients
from pizza_recipes
inner join pizza_toppings 
on topping_id in (select [value] 
					from string_split(cast(toppings as varchar), ','))
group by pizza_id

/*
pizza_id	ingredients
1	Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami
2	Cheese,Mushrooms,Onions,Peppers,Tomatoes,Tomato Sauce
*/

