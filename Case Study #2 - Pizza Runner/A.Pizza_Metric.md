# 🍕 A. Pizza Metrics Solutions

<p align="right"> Using Microsoft SQL Server </p>

## Questions

### 1. How many pizzas were ordered?

```sql
SELECT count(order_id) as total_pizza_ordered
FROM #customer_orders;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195295105-d313039e-8054-49ff-a1f5-059d785734c5.png)

#
### 2. How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT order_id) as unique_orders
FROM #customer_orders
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195295267-96f0c3b8-e7d5-441b-975c-3a4e36870cf3.png)
#
### 3. How many successful orders were delivered by each runner?

```sql
SELECT runner_id,
       COUNT(runner_id) AS successful_orders
FROM #runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195295640-95029d36-5e77-4a5f-9939-1e250b459d2a.png)

#
### 4. How many of each type of pizza was delivered?


```sql
SELECT pizza_id, 
       COUNT(pizza_id) as amount_of_dilivered_pizza
FROM #customer_orders c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS null
GROUP BY pizza_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195296832-dcd57890-0c22-445e-84f7-c3c179779151.png)

#
### 5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT customer_id,
        P.pizza_name, 
        COUNT(c.pizza_id) as amount_pizza
FROM #customer_orders c 
INNER JOIN pizza_names p ON c.pizza_id =p.pizza_id
GROUP BY customer_id,pizza_name
ORDER BY customer_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195297281-1cce363d-8988-4b0d-ab89-ac83ce1465aa.png)

#
### 6. What was the maximum number of pizzas delivered in a single order?
- Here we want the max number of pizzas `delivered` in a single order.
  - So we need a `WHERE` clause to filter only orders where `pickup_time IS NOT NULL` (order was not cancelled).
- Then we can use `SELECT TOP 1`, and `ORDER by the COUNT of pizza_id in DESCENDING order` (largest count first) to get the max count of pizzas delivered.

```sql
SELECT TOP 1 c.order_id, 
       COUNT(c.order_id) as number_order
FROM #customer_orders c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY c.order_id
ORDER BY number_order DESC;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195298260-4a37c6e3-312b-447b-affd-b926a541831d.png)

#
### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
- In this case, I use CTE, and CASE WHEN method to create a new column 'STATUS'  

```sql
WITH Status_table AS (
            SELECT order_id, 
                    customer_id,
                    pizza_id,
                    exclusions, 
                    extras, 
                    CASE WHEN exclusions is not null or extras is not null THEN 'CHANGE'
                      ELSE 'NOT CHANGE' END AS STATUS 
            FROM #customer_orders 
)
SELECT customer_id,
        STATUS, 
        COUNT(STATUS) as count
FROM Status_table s 
RIGHT JOIN #runner_orders r ON s.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id,STATUS
ORDER BY customer_id

```
#### Results
![image](https://user-images.githubusercontent.com/101379141/195299842-736cfa8d-ba7a-468a-b0f2-792cf0a4ab66.png)

#
### 8. How many pizzas were delivered that had both exclusions and extras?
- This is when `both fields` in the exclusions and extras columns `are populated`, so not NULL .
- Again, we want delivered pizzas so we need the same WHERE clause as before.

```sql
SELECT count(c.order_id) as both_exclusions_extras
FROM #customer_orders c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE exclusions is not null and extras is not null and r.cancellation is null
```
#### Results
![image](https://user-images.githubusercontent.com/101379141/195300360-72d19b1c-4b0c-4d24-bbca-95341cbff68a.png)

#
### 9. What was the total volume of pizzas ordered for each hour of the day?
- Here we can use `DATEPART` to `extract the HOUR from order_date`.
  - Using `DATENAME`would give us the same result.
    - The difference is DATEPART returns an intiger, while DATENAME returns a string.
  
```sql
SELECT DATEPART(HOUR, [order_time]) as hour_of_day, 
       COUNT (order_id) as pizza_count
FROM #customer_orders
GROUP BY DATEPART(HOUR, [order_time])
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195300844-f31063c1-dbca-404d-b4c3-647f744f3bca.png)

#
### 10. What was the volume of orders for each day of the week?
- Here we can use `DATENAME` to `extract the WEEKDAY with their actual names (Monday, Tuesday...)` instead of numbers (1, 2...) from order_time.
  
```sql
SELECT DATENAME(WEEKDAY,[order_time]) as weekday, 
        COUNT (order_id) as pizza_count
FROM #customer_orders
GROUP BY DATENAME(WEEKDAY,[order_time]);

```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195301182-58d957a6-6cd1-4c37-9b96-dc332a7e5f4d.png)
