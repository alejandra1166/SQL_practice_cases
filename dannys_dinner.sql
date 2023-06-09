-- The questions and database comes from https://8weeksqlchallenge.com/case-study-1/ 

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id
      , SUM(price) AS Total_by_Customer
FROM sales
inner JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id 

-- Customer A = 76
-- Customer B = 74
-- Customer C = 36

-- 2.  How many days has each customer visited the restaurant?

SELECT COUNT(DISTINCT (order_date)), customer_id
FROM sales
GROUP BY customer_id

-- Customer A = 4
-- Customer B = 6
-- Customer C = 2

-- 3.  What was the first item from the menu purchased by each customer?

WITH cte_product AS (
    SELECT sales.customer_id 
           , menu.product_name
           ,ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) row_a
    FROM sales
    INNER JOIN menu 
            ON sales.product_id = menu.product_id
)
SELECT customer_id, product_name
FROM cte_product
WHERE row_a = 1

-- Customer A = Sushi
-- Customer B = Curry
-- Customer C = Ramen

-- 4.  What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT menu.product_name
      ,COUNT(menu.product_name) AS Times_purchased
FROM menu
INNER JOIN sales
ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY Times_purchased DESC


--Ramen by 8 times


-- 5. Which item was the most popular for each customer?

WITH _listWithCount AS (
        SELECT  customer_id
                ,product_name
                ,COUNT(b.product_name) over(partition by a.customer_id, b.product_id) as Times_purchased
        from sales a
        inner join menu b 
		on a.product_id = b.product_id
)
SELECT customer_id,product_name,Times_purchased
FROM (
        select *,ROW_NUMBER() over(partition by  customer_id order by Times_purchased desc) rw
        from  _listWithCount
)d
where d.rw=1


--6. Which item was purchased first by the customer after they became a member?

WITH cte_1
AS(
SELECT sa.customer_id, 
		sa.order_date, 
		sa.product_id, 
		ROW_NUMBER() over(partition by  sa.customer_id order by order_date) rw
FROM sales AS sa
INNER JOIN members AS mem
ON  sa.customer_id = mem.customer_id
WHERE order_date >= join_date

)
SELECT cte_1.customer_id, menu.product_name
FROM cte_1
INNER JOIN menu
ON cte_1.product_id = menu.product_id
WHERE rw = 1

-- Customer A = Curry
-- Customer B = Sushi

-- 7. Which item was purchased just before the customer became a member?

WITH cte_1
AS(
SELECT sa.customer_id, 
		sa.order_date, 
		sa.product_id, 
		mem.join_date,
		ROW_NUMBER() over(partition by  sa.customer_id order by order_date DESC) rw
FROM sales AS sa
INNER JOIN members AS mem
ON  sa.customer_id = mem.customer_id
WHERE order_date < join_date

)
SELECT cte_1.customer_id, menu.product_name, order_date, Join_date
FROM cte_1
INNER JOIN menu
ON cte_1.product_id = menu.product_id
WHERE rw = 1

-- Customer A = Sushi
-- Customer B = Sushi


--8. What is the total items and amount spent for each member before they became a member?

SELECT
  mem.customer_id,
  COUNT(*) AS count_purchases_by_customer,
  SUM(menu.price) AS Amount_spend_by_customer
FROM sales AS sal
JOIN members AS mem 
ON sal.customer_id = mem.customer_id
JOIN menu 
ON menu.product_id = sal.product_id
WHERE sal.order_date < mem.join_date
GROUP BY
  mem.customer_id;

-- Customer A = 2, 25
-- Customer B = 3, 40

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte_1
AS (
SELECT sales.customer_id
	, sales.product_id
	, SUM(CASE WHEN sales.product_id = 1 THEN 200 ELSE 0 END ) AS ONE_X2
	, SUM(CASE WHEN sales.product_id = 2 THEN 150 ELSE 0 END) AS TWO
	, SUM(CASE WHEN sales.product_id = 3 THEN 120 ELSE 0 END) AS THREE

FROM sales
GROUP BY customer_id, sales.product_id
)

SELECT customer_id
		, SUM(ONE_X2+TWO+THREE) AS points
FROM cte_1
GROUP BY customer_id

-- Customer A = 860
-- Customer B = 940
-- Customer C = 360


--10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


WITH cte_1
AS (
SELECT sales.customer_id
	, (price * 10) AS points
	, CASE WHEN order_date between join_date and dateadd (day, 6, join_date) THEN (price * 20) ELSE (price * 10) END AS double_points_1st_week
FROM sales
INNER JOIN members
ON sales.customer_id = members.customer_id
INNER JOIN menu
ON sales.product_id = menu.product_id
WHERE sales.order_date BETWEEN '2021-01-01' AND '2021-01-31'
)

SELECT customer_id, SUM(double_points_1st_week) AS Total_Points
FROM cte_1
GROUP BY customer_id

