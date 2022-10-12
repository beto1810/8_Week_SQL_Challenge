---1/What is the total amount each customer spent at the restaurant
SELECT customer_id,sum(menu.price) as Total_price
FROM sales 
Inner join menu 
ON sales.product_id = menu.product_id 
GROUP BY customer_id;

--2/How many days has each customer visited the restaurant?
SELECT sales.customer_id, count(distinct sales.order_date) as Total_days
FROM sales 
GROUP BY sales.customer_id;

--3/. What was the first item from the menu purchased by each customer?

WITH CTE AS (
    SELECT customer_id, order_date,product_name, 
    DENSE_RANK() OVER(ORDER BY order_date ) AS RANK
    FROM sales
    INNER JOIN menu
    ON sales.product_id = menu.product_id 
)
SELECT customer_id,product_name
FROM CTE 
WHERE RANK =1 
GROUP BY customer_id,product_name;

--4/What is the most purchased item on the menu and how many times was it purchased by all customers ?

WITH CTE1 AS (
    SELECT product_name, COUNT(sales.product_id) AS NUMBER_ORDER,
     DENSE_RANK() OVER(ORDER BY COUNT(sales.product_id) ) AS RANK
    FROM sales
    INNER JOIN menu
    ON sales.product_id = menu.product_id
    GROUP BY product_name
)
SELECT product_name, NUMBER_ORDER
FROM CTE1
WHERE RANK =3;

SELECT TOP 1 (COUNT(s.product_id)) AS most_purchased, product_name
FROM dbo.sales AS s
JOIN dbo.menu AS m
 ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY most_purchased DESC ;

--5/ Which item was the most popular for each customer?

WITH CTE1 AS (
    SELECT customer_id,product_name, COUNT(sales.product_id) AS NUMBER_ORDER,
     rank() OVER(PARTITION BY customer_id 
     ORDER BY COUNT(sales.product_id) DESC) AS RANK
    FROM sales
    INNER JOIN menu
    ON sales.product_id = menu.product_id
    GROUP BY customer_id,product_name
)
SELECT customer_id,product_name,NUMBER_ORDER
FROM CTE1
WHERE RANK =1;


--6/Which item was purchased first by the customer after they became a member?
WITH CTE2 AS(
    SELECT sales.customer_id, product_name, order_date, join_date,
    DENSE_RANK() OVER(Partition by sales.customer_id ORDER BY order_date) AS RANK 
    FROM sales 
    INNER JOIN menu
    ON sales.product_id = menu.product_id
    INNER JOIN members
    ON sales.customer_id = members.customer_id
    WHERE sales.order_date > members.join_date
)
SELECT customer_id, product_name
FROM CTE2
WHERE RANK =1;

--7/Which item was purchased just before the customer became a member?
WITH CTE3 AS(
    SELECT sales.customer_id, product_name, order_date, join_date,
    DENSE_RANK() OVER(Partition by sales.customer_id ORDER BY order_date DESC) AS RANK 
    FROM sales 
    INNER JOIN menu
    ON sales.product_id = menu.product_id
    INNER JOIN members
    ON sales.customer_id = members.customer_id
    WHERE sales.order_date < members.join_date
)
SELECT customer_id, product_name
FROM CTE3
WHERE RANK =1;

--8/What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id,
count(product_name) as total_item, 
SUM(price) as Total_amount_spent
FROM sales 
INNER JOIN menu
ON sales.product_id = menu.product_id
INNER JOIN members
ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;

--9/If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CTE3 AS(
    SELECT product_id,product_name, price,
    CASE WHEN product_name = 'sushi' THEN price *20 
         ELSE price * 10 END AS point 
    FROM menu 
)

SELECT customer_id, sum(point ) as total_point
FROM sales s
INNER JOIN CTE3 c3
ON s.product_id = c3.product_id
GROUP BY  customer_id;

--10/In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January

WITH CTE4 AS (
    SELECT s.customer_id, product_name,
    CASE WHEN s.order_date < me.join_date and product_name ='sushi' THEN price *20
         WHEN s.order_date < me.join_date and product_name !='sushi' THEN price *10
         WHEN s.order_date > me.join_date THEN price *20
        ELSE price * 10 END As price1
    FROM sales s
    JOIN menu M ON s.product_id = m.product_id
    LEFT JOIN members me ON s.customer_id = me.customer_id   
)
SELECT customer_id, sum(price1) as total_point_end_Jan
from CTE4
group by customer_id;

--Extra 
WITH CTE5 as (SELECT s.customer_id,s.order_date,m.product_name,m.price,
    CASE WHEN s.order_date >= me.join_date THEN 'Y'
        ELSE 'N'  END AS member
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id
)
SELECT customer_id,order_date,product_name,price,member,
    CASE WHEN member ='N' THEN NULL 
    ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM CTE5