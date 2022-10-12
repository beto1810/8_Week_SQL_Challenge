-- Update tables
DROP TABLE IF EXISTS #customer_orders;
SELECT order_id, customer_id,pizza_id, 
    CASE WHEN exclusions = '' OR exclusions like 'null' THEN NULL
        ELSE exclusions END AS exclusions,
    CASE WHEN extras = '' OR extras like 'null' THEN NULL
        ELSE extras END AS extras, 
        order_time
INTO #customer_orders -- create TEMP TABLE
FROM customer_orders;

DROP TABLE IF EXISTS #runner_orders
SELECT order_id, runner_id,
  CASE 
    WHEN pickup_time LIKE 'null' THEN ' '
    ELSE pickup_time 
    END AS pickup_time,
  CASE 
    WHEN distance LIKE 'null' THEN ' '
    WHEN distance LIKE '%km' THEN TRIM('km' from distance) 
    ELSE distance END AS distance,
  CASE 
    WHEN duration LIKE 'null' THEN ' ' 
    WHEN duration LIKE '%mins' THEN TRIM('mins' from duration) 
    WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)        
    WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)       
    ELSE duration END AS duration,
  CASE 
    WHEN cancellation LIKE 'null' THEN NULL
    WHEN cancellation = '' THEN NULL
    ELSE cancellation END AS cancellation
INTO #runner_orders
FROM runner_orders;

ALTER TABLE #runner_orders
ALTER COLUMN pickup_time DATETIME

ALTER TABLE #runner_orders
ALTER COLUMN distance FLOAT

ALTER TABLE #runner_orders
ALTER COLUMN duration INT;

ALTER TABLE pizza_names
ALTER COLUMN pizza_name VARCHAR(MAX);

ALTER TABLE pizza_recipes
ALTER COLUMN toppings VARCHAR(MAX);

ALTER TABLE pizza_toppings
ALTER COLUMN topping_name VARCHAR(MAX)

-- A. Pizza Metrics
PRINT('A. Pizza Metrics')
--1.How many pizzas were ordered?
print('1.How many pizzas were ordered?')

SELECT count(order_id) as total_pizza_ordered
FROM #customer_orders;


-- 2 How many unique customer orders were made?
print('2 How many unique customer orders were made?')

SELECT count(DISTINCT order_id) as unique_orders
FROM #customer_orders

--3/ How many successful orders were delivered by each runner?
print('3/ How many successful orders were delivered by each runner?')

SELECT runner_id,count(runner_id) AS successful_orders
FROM #runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;



--4/How many of each type of pizza was delivered?
print('4/How many of each type of pizza was delivered?')

SELECT pizza_id, COUNT(pizza_id) as amount_of_dilivered_pizza
FROM #customer_orders c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS null
GROUP BY pizza_id;

--5/How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id,P.pizza_name, count(c.pizza_id) as amount_pizza
FROM #customer_orders c 
INNER JOIN pizza_names p ON c.pizza_id =p.pizza_id
GROUP BY customer_id,pizza_name
ORDER BY customer_id;

--6/ What was the maximum number of pizzas delivered in a single order?

WITH CTE AS (
  SELECT c.order_id, count(c.order_id) as number_order
  FROM #customer_orders c 
  RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
  WHERE r.cancellation is NULL
  GROUP BY c.order_id
)
SELECT max(number_order) as maximum_order
FROM CTE;

--7/ For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH CTE AS (
  SELECT order_id, customer_id,pizza_id,exclusions, extras, 
  CASE WHEN exclusions is not null or extras is not null THEN 'CHANGE'
  ELSE 'NOT CHANGE' END AS STATUS 
  FROM #customer_orders 
)
SELECT customer_id,STATUS, COUNT(STATUS)
FROM CTE c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id,STATUS
ORDER BY customer_id

--8/ How many pizzas were delivered that had both exclusions and extras?

SELECT count(c.order_id) as both_exclusions_extras
FROM #customer_orders c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE exclusions is not null and extras is not null and r.cancellation is null;

--9/ What was the total volume of pizzas ordered for each hour of the day?
print('9/ What was the total volume of pizzas ordered for each hour of the day?')

SELECT DATEPART(HOUR, [order_time]) as hour_of_day, count (order_id) as pizza_count
FROM #customer_orders
GROUP BY DATEPART(HOUR, [order_time])

--10/What was the volume of orders for each day of the week?
print('What was the volume of orders for each day of the week')


SELECT DATENAME(WEEKDAY,[order_time]) as weekday, count (order_id) as pizza_count
FROM #customer_orders
GROUP BY DATENAME(WEEKDAY,[order_time]);

---B. Runner and Customer Experience
--1/How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SET DATEFIRST 5;
select DATEPART(WEEK,[registration_date])as week, count(runner_id) as runner_count 
FROM runners
GROUP BY DATEPART(WEEK,[registration_date]);

--2/What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH CTE AS (SELECT DISTINCT runner_id, r.order_id,order_time, pickup_time, datepart( minute,pickup_time - order_time) as time
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id
WHERE r.cancellation IS NULL 
GROUP BY  runner_id,r.order_id,order_time, pickup_time)

SELECT runner_id, avg(time) AS average_time
FROM CTE
GROUP BY runner_id;

--3/ Is there any relationship between the number of pizzas and how long the order takes to prepare

WITH CTE AS (SELECT  c.order_id,count(c.order_id) as pizza_order,order_time, pickup_time, datepart( minute,pickup_time - order_time) as time
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id
WHERE r.cancellation IS NULL 
GROUP BY  c.order_id,order_time, pickup_time)


SELECT pizza_order,avg(time) AS avg_time
FROM CTE
GROUP BY pizza_order

--4/ What was the average distance travelled for each customer?

SELECT customer_id, AVG(distance) AS Average_distance
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON c.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id


--5/What was the difference between the longest and shortest delivery times for all orders?

SELECT  max(duration) - min(duration) as dif_longest_shortest
FROM #runner_orders
WHERE cancellation is NULL;

--6/ What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, round(avg(distance/duration*60),2) as avg_time
FROM #runner_orders
WHERE cancellation is NULL 
GROUP BY runner_id,order_id
ORDER BY runner_id;

--7/ What is the successful delivery percentage for each runner?
with CTE AS (SELECT runner_id, order_id,
      CASE WHEN cancellation is NULL THEN 1
      ELSE 0 END AS Sucess_delivery
FROM #runner_orders)
SELECT runner_id, round( 100*sum(sucess_delivery)/count(*),0) 
FROM CTE
group by runner_id


--C. Ingredient Optimisation
--1/What are the standard ingredients for each pizza?
drop table if exists pizza_recipes1;
create table pizza_recipes1 
(
 pizza_id int,
    toppings int);
insert into pizza_recipes1
(pizza_id, toppings) 
values
(1,1),
(1,2),
(1,3),
(1,4),
(1,5),
(1,6),
(1,8),
(1,10),
(2,4),
(2,6),
(2,7),
(2,9),
(2,11),
(2,12);

WITH CTE AS (
  SELECT pizza_id, topping_name
  FROM pizza_recipes1 p1
  INNER JOIN pizza_toppings p2 
  ON p1.toppings = p2.topping_id
)
SELECT pizza_id, String_agg(topping_name,',') as Standard_toppings
FROM CTE
GROUP BY pizza_id;

--2/What was the most commonly added extra?

WITH CTE AS (SELECT pizza_id,topping_type,topping
FROM (SELECT pizza_id, CAST(SUBSTRING(extras, 1,1) AS INT) AS topping_1, CAST(SUBSTRING(extras,3,3) AS INT) as topping_2
FROM #customer_orders
WHERE extras is not null) p 
UNPIVOT (topping for topping_type in (topping_1,topping_2)) as unpvt)

SELECT Topping, topping_name, count(topping) AS Extra_Topping_Time
FROM CTE c
JOIN pizza_toppings p ON c.topping = p.topping_id
WHERE topping != 0
GROUP BY topping,topping_name;

--3/What was the most common exclusion?

WITH CTE AS (SELECT pizza_id,topping_type,topping
FROM (SELECT pizza_id, CAST(SUBSTRING(exclusions, 1,1) AS INT) AS exclusions_1, CAST(SUBSTRING(exclusions,3,3) AS INT) as exclusions_2
FROM #customer_orders
WHERE exclusions is not null) p 
UNPIVOT (topping for topping_type in (exclusions_1,exclusions_2)) as unpvt)

SELECT Topping, count(topping) AS exclusions_Topping_Time
FROM CTE 
WHERE topping != 0
GROUP BY topping
ORDER BY exclusions_Topping_Time DESC;

--4/ Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers 



ALTER TABLE #customer_orders
ADD record_id INT IDENTITY(1,1);


-- to generate extra table
DROP TABLE IF EXISTS #extras
SELECT		
	c.record_id,
	TRIM(e.value) AS topping_id
INTO #extras
FROM 
	#customer_orders as c
	CROSS APPLY string_split(c.extras, ',') as e;


-- to generate exclusions table
DROP TABLE IF EXISTS #exclusions
SELECT		
	c.record_id,
	TRIM(e.value) AS topping_id
INTO #exclusions
FROM 
	#customer_orders as c
	CROSS APPLY string_split(c.exclusions, ',') as e;

with extras_cte AS
(
	SELECT 
		record_id,
		'Extra ' + STRING_AGG(t.topping_name, ', ') as record_options
	FROM
		#extras e,
		pizza_toppings t
	WHERE e.topping_id = t.topping_id
	GROUP BY record_id
),
exclusions_cte AS
(
	SELECT 
		record_id,
		'Exclude ' + STRING_AGG(t.topping_name, ', ') as record_options
	FROM
		#exclusions e,
		pizza_toppings t
	WHERE e.topping_id = t.topping_id
	GROUP BY record_id
),
union_cte AS
(
	SELECT * FROM extras_cte
	UNION
	SELECT * FROM exclusions_cte
)

SELECT 
	c.record_id, c.order_id,
	CONCAT_WS(' - ', p.pizza_name, STRING_AGG(cte.record_options, ' - '))
FROM 
	#customer_orders c
	JOIN pizza_names p
	ON c.pizza_id = p.pizza_id
	LEFT JOIN union_cte cte
	ON c.record_id = cte.record_id
GROUP BY
	c.record_id,
	p.pizza_name,
  c.order_id
ORDER BY 1;

--5/Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

DROP TABLE IF EXISTS #pizza_recipes;
SELECT pizza_id, TRIM(topping.value) as topping,topping_name
INTO #pizza_recipes
FROM pizza_recipes p
CROSS APPLY string_split(p.toppings, ',') as topping
INNER JOIN pizza_toppings p2 ON TRIM(topping.value) = p2.topping_id;

SELECT *
FROM #pizza_recipes;

WITH INGREDIENT_CTE AS (SELECT record_id,pizza_name,
      CASE WHEN p1.topping in (
        SELECT topping_id
        FROM #extras e
        WHERE C.record_id = e.record_id
      ) THEN '2x' + p1.topping_name
      ELSE p1.topping_name
      END AS topping
FROM #customer_orders c 
JOIN pizza_names p2 ON c.pizza_id = p2.pizza_id
JOIN #pizza_recipes p1 ON c.pizza_id = p1.pizza_id
WHERE p1.topping NOT IN (SELECT topping_id FROM #exclusions e WHERE e.record_id = c.record_id))

SELECT record_id, 
      CONCAT(pizza_name +':' ,STRING_AGG(topping, ',' ) WITHIN GROUP (ORDER BY topping ASC)) AS ingredient_list
FROM INGREDIENT_CTE
GROUP BY  record_id,pizza_name
ORDER BY 1;

--6/ What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH INGREDIENT_CTE AS (SELECT record_id,pizza_name, topping_name,
      CASE WHEN p1.topping in (
        SELECT topping_id
        FROM #extras e
        WHERE C.record_id = e.record_id
      ) THEN 2
      ELSE 1
      END AS topping
FROM #customer_orders c 
JOIN pizza_names p2 ON c.pizza_id = p2.pizza_id
JOIN #pizza_recipes p1 ON c.pizza_id = p1.pizza_id
JOIN #runner_orders r ON c.order_id = r.order_id
WHERE p1.topping NOT IN (SELECT topping_id FROM #exclusions e WHERE e.record_id = c.record_id) and r.cancellation is NULL)

SELECT topping_name, sum(topping) as times_used_topping
from INGREDIENT_CTE
GROUP BY topping_name
order by times_used_topping desc;

--D. Pricing and Ratings
--1/If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

WITH CTE AS (SELECT pizza_id, pizza_name,
                CASE WHEN pizza_name = 'Meatlovers' THEN 12
                ELSE 10 END AS pizza_cost
                FROM pizza_names) 

SELECT SUM(pizza_cost) as total_revenue
FROM #customer_orders c 
JOIN #runner_orders r ON c.order_id = r.order_id
JOIN CTE c2 ON c.pizza_id = c2.pizza_id
WHERE r.cancellation is NULL;

  --2/What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra

WITH CTE AS (SELECT pizza_id, pizza_name,
                CASE WHEN pizza_name = 'Meatlovers' THEN 12
                ELSE 10 END AS pizza_cost
                FROM pizza_names),

COST_CTE AS (SELECT SUM(pizza_cost) as total_revenue
FROM #customer_orders c 
JOIN #runner_orders r ON c.order_id = r.order_id
JOIN CTE c2 ON c.pizza_id = c2.pizza_id
WHERE r.cancellation is NULL),

CTE2 AS (SELECT COUNT(*) *1 AS total_extra
FROM #extras e)

select total_extra + total_revenue
FROM COST_CTE, CTE2;

WITH cte AS
(SELECT 
 (CASE WHEN pizza_id=1 THEN 12
    WHEN pizza_id = 2 THEN 10
    END) AS pizza_cost, 
    c.exclusions,
    c.extras
 FROM #runner_orders r
JOIN #customer_orders c ON c.order_id = r.order_id
WHERE r.cancellation IS  NULL)
SELECT 
 SUM(CASE WHEN extras IS NULL THEN pizza_cost
  WHEN DATALENGTH(extras) = 1 THEN pizza_cost + 1
        ELSE pizza_cost + 2
        END )
FROM cte;

--3/The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
  --how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS ratings
CREATE TABLE ratings 
 (order_id INTEGER,
    rating INTEGER);
INSERT INTO ratings
 (order_id ,rating)
VALUES 
(1,3),
(2,4),
(3,5),
(4,2),
(5,1),
(6,3),
(7,4),
(8,1),
(9,3),
(10,5); 

SELECT * 
from ratings
--4/Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? 
-- customer_id,order_id,runner_id,rating, order_time, pickup_time, Time between order and pickup, Delivery duration, Average speed, Total number of pizzas

SELECT customer_id , c.order_id, runner_id, rating, order_time, pickup_time, 
      datepart( minute,pickup_time - order_time) as Time__order_pickup, r.duration, 
      round(avg(distance/duration*60),2) as avg_Speed, 
      COUNT(pizza_id) AS Pizza_Count
FROM #customer_orders c
LEFT JOIN #runner_orders r ON c.order_id = r.order_id 
LEFT JOIN ratings r2 ON c.order_id = r2.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id , c.order_id, runner_id, rating, order_time, pickup_time, datepart( minute,pickup_time - order_time) , r.duration
ORDER BY c.customer_id;

--5/If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH CTE AS (SELECT pizza_id, pizza_name,
                CASE WHEN pizza_name = 'Meatlovers' THEN 12
                ELSE 10 END AS pizza_cost
                FROM pizza_names) 

SELECT SUM(pizza_cost) - SUM(distance *0.3) as profit , SUM(pizza_cost) AS revenue, SUM(distance *0.3) as total_cost
FROM #customer_orders c 
JOIN #runner_orders r ON c.order_id = r.order_id
JOIN CTE c2 ON c.pizza_id = c2.pizza_id
WHERE r.cancellation is NULL

--E. Bonus Questions
--If Danny wants to expand his range of pizzas - 
--How would this impact the existing data design? 
--Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

INSERT INTO pizza_names
(pizza_id, pizza_name)
values 
(3 , 'Supreme')

INSERT INTO pizza_recipes
(pizza_id, toppings)
VALUES
(3, '1,2,3,4,5,6,7,8,9,10,11,12')

SELECT * 
FROM pizza_names

SELECT * 
FROM pizza_recipes



