# 💻 Pizza Runner Data Cleaning

<p align="right"> Using Microsoft SQL Server </p>

## Initial Cleaning:

### 1. Table: `customer_orders`

#### Original Table:
![image](https://user-images.githubusercontent.com/101379141/195287305-bce41c1a-8cab-475e-98c0-f3f64786bd39.png)

#### Changes:
- Changing all the NULL and 'null' to blanks
- Creating a clean temp table 

```sql
DROP TABLE IF EXISTS #customer_orders;
SELECT order_id, 
        customer_id,
        pizza_id, 
        CASE WHEN exclusions = '' OR exclusions like 'null' THEN NULL
            ELSE exclusions END AS exclusions,
        CASE WHEN extras = '' OR extras like 'null' THEN NULL
            ELSE extras END AS extras, 
        order_time
INTO #customer_orders -- create TEMP TABLE
FROM customer_orders;
```
#### Cleaned table:
![image](https://user-images.githubusercontent.com/101379141/195287781-927b309c-14ec-4f64-ae00-e76d34c88be5.png)

#
### 2. Table: `runner_orders`

#### Original Table:
![image](https://user-images.githubusercontent.com/101379141/195288132-fee8e31e-d19e-462b-88ce-f6129982b269.png)

#### Changes:
- Changing all the NULL and 'null' to blanks for strings
- Changing all the 'null' to NULL for non strings
- Removing 'km' from distance
- Removing anything after the numbers from duration
- Creating a clean temp table 

```sql
DROP TABLE IF EXISTS #runner_orders
SELECT  order_id, 
        runner_id,
        CASE 
          WHEN pickup_time LIKE 'null' THEN NULL
          ELSE pickup_time 
          END AS pickup_time,
        CASE 
          WHEN distance LIKE 'null' THEN NULL
          WHEN distance LIKE '%km' THEN TRIM('km' from distance) 
          ELSE distance END AS distance,
        CASE 
          WHEN duration LIKE 'null' THEN NULL 
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
```
#### Cleaned Table:
![image](https://user-images.githubusercontent.com/101379141/195291586-76484f29-f489-479d-a070-341ffce6783d.png)

# 
### 3. Changing data types
- For #runner_orders table:
  - Change pickup_time DATETIME
  - Change distance to FLOAT
  - Change duration to INT
- For pizza_names table:
  - Change pizza_name to VARCHAR(MAX)
- For pizza_recipes table:
  - Change toppings to VARCHAR(MAX)
- For pizza_toppings table:
  - Change topping_name to VARCHAR(MAX)
```sql
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
```
