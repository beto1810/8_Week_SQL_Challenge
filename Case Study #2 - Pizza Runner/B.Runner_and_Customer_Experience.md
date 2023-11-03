# 🛵 B. Runner and Customer Experience Solutions

<p align="right"> Using Microsoft SQL Server </p>

## Questions

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
SET DATEFIRST 1; --Set Monday is the first day of week

SELECT DATEPART(WEEK,[registration_date])as week, 
        COUNT(runner_id) as runner_count 
FROM runners
GROUP BY DATEPART(WEEK,[registration_date]);
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195483753-fa8e56b1-a7b9-4630-95ab-0192ea537d74.png)

#
### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
- We create a time column through a CTE.
  - We can use `DATEDIFF` to find the difference between order_time and pickup_time in `MINUTES`
  - The CAST's were used to transform the numbers into FLOAT and to be able to round the numbers correctly. Doing it with ROUND wasn't working.  
 
```sql
WITH time_table AS (SELECT DISTINCT runner_id, 
                             r.order_id,
                             order_time, 
                             pickup_time, 
                             CAST(DATEDIFF( minute,order_time,pickup_time) AS FLOAT) as time
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id
WHERE r.cancellation IS NULL 
                )

SELECT runner_id, AVG(time)  AS average_time
FROM time_table
GROUP BY runner_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195485007-ff58fe67-e4ab-420e-9fd2-a22fa48ad99e.png)

- Runner 1's average is 14 mins 
- Runner 2's average is 20 mins 
- Whilst runner 3's average is 10 mins 

#
### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
WITH CTE AS (SELECT  c.order_id,
                      COUNT(c.order_id) as pizza_order,
                      order_time, pickup_time, 
                      CAST(DATEDIFF( minute,order_time,pickup_time) AS FLOAT) as time
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id
WHERE r.cancellation IS NULL 
GROUP BY  c.order_id,order_time, pickup_time)


SELECT pizza_order,
        AVG(time) AS avg_time_per_order, 
        (AVG(time)/ pizza_order) AS avg_time_per_pizza
FROM CTE
GROUP BY pizza_order

```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195486114-74b55689-b82b-4cf4-952e-68bf6fb20030.png)

- Here we can see that as the number of pizzas in an order goes up, so does the total prep time for that order, as you would expect.
- But then we can also notice that the average preparation time per pizza is higher when you order 1 than when you order multiple. 

#
### 4. What was the average distance travelled for each customer?

```sql
SELECT customer_id, 
        AVG(distance) AS Average_distance
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON c.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195486333-42721bfb-ab1f-43aa-9817-0f4f779aa915.png)

#
### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT  max(duration) as longest,
        min(duration) as shortest,
        max(duration) - min(duration) as dif_longest_shortest
FROM #runner_orders
WHERE cancellation is NULL
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195486569-ba6b2f60-e067-4b79-b7e0-0c1ad862e5e0.png)

- The difference between the longest and shortest delivery was 30 mins. 

#
### 6. What was the average speed for each runner for each delivery?
- Let's see the `speed for each runner for each delivery`:

```sql
SELECT runner_id, 
        order_id, 
        ROUND(AVG(distance/duration*60),2) as avg_time
FROM #runner_orders
WHERE cancellation is NULL 
GROUP BY runner_id,order_id
ORDER BY runner_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195486740-c42f2d32-b7e2-47b4-878c-f6865d6531e4.png)
- Now let's see the `average speed for each runner in total`: 



#
### 7. What is the successful delivery percentage for each runner?

```sql
with CTE AS (SELECT runner_id, order_id,
      CASE WHEN cancellation is NULL THEN 1
        ELSE 0 END AS Sucess_delivery
FROM #runner_orders)
SELECT runner_id, round( 100*sum(sucess_delivery)/count(*),0) as success_perc
FROM CTE
group by runner_id
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195487013-4620bbfd-5150-4e20-9ef9-0e2a210c8efb.png)
