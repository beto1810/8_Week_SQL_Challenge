# 💵⭐ D. Pricing and Ratings Solutions

<p align="right"> Using Microsoft SQL Server </p>

#
## Questions

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
- Here we will want to use a CTE method with a CASE Statement .
    - CASE WHEN the pizza name is Meatlovers 
    - THEN add 12 (dollars)
    - ELSE add 10
  
- SUM pizza_cost in the next SELECT.
    
```sql
WITH CTE AS (SELECT pizza_id, 
                    pizza_name,
                    CASE WHEN pizza_name = 'Meatlovers' THEN 12
                      ELSE 10 END AS pizza_cost
             FROM pizza_names) 

SELECT SUM(pizza_cost) as total_revenue
FROM #customer_orders c 
JOIN #runner_orders r ON c.order_id = r.order_id
JOIN CTE c2 ON c.pizza_id = c2.pizza_id
WHERE r.cancellation is NULL;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195514689-cd40ad60-0e94-4256-8dd9-ff2e3954a5af.png)
#
### 2. What if there was an additional $1 charge for any pizza extras? (Add cheese is $1 extra)

#### One way to do this
- Here we need to create a `CTE`:
  - This CTE will show the inital price of each pizza (each record_id) and type of topping extras and exclusions.
    - In it we need to SELECT the exclusion,extras and build CASE Statements to list pirce of pizza.
  
- In the `final SELECT Statement`:
  - we are going to add SUM of CASE Statement  initial_price + pizza_topping extras cost

```sql
WITH pizza_cte AS
          (SELECT 
                  (CASE WHEN pizza_id=1 THEN 12
                        WHEN pizza_id = 2 THEN 10
                        END) AS pizza_cost, 
                  c.exclusions,
                  c.extras
          FROM #runner_orders r
          JOIN #customer_orders c ON c.order_id = r.order_id
          WHERE r.cancellation IS  NULL
          )
SELECT 
      SUM(CASE WHEN extras IS NULL THEN pizza_cost
               WHEN DATALENGTH(extras) = 1 THEN pizza_cost + 1
               ELSE pizza_cost + 2
                END ) AS total_earn
FROM pizza_cte;
```
#### pizza CTE output
![image](https://user-images.githubusercontent.com/101379141/195516580-b7641187-9215-460e-96a4-0742e8cea89d.png)

#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195516682-f3441803-17a9-4012-9ff6-21d272cf1e65.png)
#
### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

```sql
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


```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195516961-88a7bf3d-a07f-4bec-b81b-7d75fb69f2ae.png)
#
### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? 
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas

```sql
SELECT customer_id , 
        c.order_id, 
        runner_id, 
        rating, 
        order_time, 
        pickup_time, 
        datepart( minute,pickup_time - order_time) as Time__order_pickup, 
        r.duration, 
        round(avg(distance/duration*60),2) as avg_Speed, 
        COUNT(pizza_id) AS Pizza_Count
FROM #customer_orders c
LEFT JOIN #runner_orders r ON c.order_id = r.order_id 
LEFT JOIN ratings r2 ON c.order_id = r2.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id , c.order_id, runner_id, rating, order_time, pickup_time, datepart( minute,pickup_time - order_time) , r.duration
ORDER BY c.customer_id;

```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195517205-b1c78ce7-47aa-46b4-9bf9-8e551ead209d.png)
#
### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

#### One way to achieve this 
- Here we are going to create `CTE`:
  - We want this table to show the order_id, how much the pizzas cost per order
- Then in the `final SELECT Statement`:
  - We want to SUM the revenue made from the pizzas
  - SUM all distance * 0.3  that was paid to the runners
  - and take that runner_cost away from the pizza_revenue to give us the profit gained
 
```sql
WITH CTE AS (SELECT c.order_id,
                    SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12
                          ELSE 10 END) AS pizza_cost
             FROM pizza_names p
             JOIN #customer_orders c ON p.pizza_id =c.pizza_id
             GROUP BY c.order_id) 

SELECT SUM(pizza_cost) AS revenue, 
       SUM(distance) *0.3 as total_cost,
       SUM(pizza_cost) - SUM(distance)*0.3 as profit
FROM #runner_orders r 
JOIN CTE c ON R.order_id =C.order_id
WHERE r.cancellation is NULL
```
####  CTE output
![image](https://user-images.githubusercontent.com/101379141/195524663-0c1e08a7-2588-466b-9bba-3fb6831938f2.png)
#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195524723-407b3ff2-4337-452a-a273-c3d7f5f05bbb.png)
