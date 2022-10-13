# 🧀🥓 C. Ingredient Optimisation Solutions

<p align="right"> Using Microsoft SQL Server </p>

## Contents:
- [Data Cleaning Solutions](#data-cleaning-for-this-section)
- [Question Solutions](#questions)

## Data Cleaning for this section 
### 1. Table: `#pizza_recipes`

#### Original table:
![image](https://user-images.githubusercontent.com/94410139/158227609-4fd32726-4918-4368-918b-c81aa48045db.png)

#### Changes:
- Splitting comma delimited lists into rows
- Creating a clean temp table 

```sql
DROP TABLE IF EXISTS #pizza_recipes;
SELECT pizza_id, 
        TRIM(topping_id.value) as topping_id,
        topping_name
INTO #pizza_recipes
FROM pizza_recipes p
CROSS APPLY string_split(p.toppings, ',') as topping_id
INNER JOIN pizza_toppings p2 ON TRIM(topping_id.value) = p2.topping_id
```
#### New table:
![image](https://user-images.githubusercontent.com/101379141/195526923-428d7053-1021-45f2-9c7d-e96141441627.png)

## Data Cleaning for question 4-5
### 2. Table: `#customer_orders` 

#### Original table: 
![image](https://user-images.githubusercontent.com/101379141/195491823-727ed58b-1eb7-4d7c-874d-569d9e55de5d.png)

#### Changes:
- Adding an Identity Column (to be able to uniquely identify every single pizza ordered) 

```sql
ALTER TABLE #customer_orders
ADD record_id INT IDENTITY(1,1)
```
![image](https://user-images.githubusercontent.com/101379141/195491565-90847021-72a6-445b-b92a-8cbef9114f67.png)

#
### 3. New Tables: `Exclusions` & `Extras` 

#### Changes:
- Splitting the exclusions & extras comma delimited lists into rows and storing in new tables

#### New Extras Table:
```sql
DROP TABLE IF EXISTS #extras
SELECT		
      c.record_id,
      TRIM(e.value) AS topping_id
INTO #extras
FROM #customer_orders as c
	    CROSS APPLY string_split(c.extras, ',') as e;
```
![image](https://user-images.githubusercontent.com/101379141/195492588-dc9a3348-61b8-4802-93c1-2188a6c1e717.png)

#### New Exclusions Table:
```sql
DROP TABLE IF EXISTS #exclusions
SELECT	c.record_id,
	      TRIM(e.value) AS topping_id
INTO #exclusions
FROM #customer_orders as c
	    CROSS APPLY string_split(c.exclusions, ',') as e;
```
![image](https://user-images.githubusercontent.com/101379141/195492431-73671fdb-df6e-45b2-b890-708c629547b2.png)
#
## Questions
### 1. What are the standard ingredients for each pizza?
- We can use `STRING_AGG()` to create a comma delimited list of the topping names.

```sql
WITH CTE AS (
              SELECT pizza_id, 
                      topping_name
              FROM #pizza_recipes p1
              INNER JOIN pizza_toppings p2 
              ON p1.topping_id = p2.topping_id
)
SELECT pizza_id, String_agg(topping_name,',') as Standard_toppings
FROM CTE
GROUP BY pizza_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195527944-fcd3b9c0-1d5b-46a2-b553-ea22945251d6.png)
#
### 2. What was the most commonly added extra?
- We use CTE, Subqueries, Unpivot method in this question:
  - In CTE, we use SUBSTRING to split topping to different column
  - Use UNPIVOT, to transfer table to multi-index column style to ordinary style


```sql
WITH CTE AS (SELECT pizza_id,
                    topping_type,
                    topping
FROM (SELECT pizza_id, 
              CAST(SUBSTRING(extras, 1,1) AS INT) AS topping_1, 
              CAST(SUBSTRING(extras,3,3) AS INT) as topping_2
      FROM #customer_orders
      WHERE extras is not null) p 
      UNPIVOT (topping for topping_type in (topping_1,topping_2)) as unpvt)

SELECT Topping, 
        topping_name, 
        COUNT(topping) AS Extra_Topping_Time
FROM CTE c
JOIN pizza_toppings p ON c.topping = p.topping_id
WHERE topping != 0
GROUP BY topping,topping_name;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195490789-74758669-b84c-43ed-82f7-b766633cdf78.png)

- The most common added : Bacon

#
### 3. What was the most common exclusion?
- Same as the question above but using the `COUNT of exclusions_id`.

```sql
WITH CTE AS (SELECT pizza_id,
                    topping_type,
                    topping
              FROM (SELECT pizza_id, 
                            CAST(SUBSTRING(exclusions, 1,1) AS INT) AS exclusions_1, 
                            CAST(SUBSTRING(exclusions,3,3) AS INT) as exclusions_2
              FROM #customer_orders
              WHERE exclusions is not null) p 
              UNPIVOT (topping for topping_type in (exclusions_1,exclusions_2)) as unpvt)

SELECT Topping, 
        topping_name,
        count(topping) AS exclusions_Topping_Time
FROM CTE c
JOIN pizza_toppings p ON c.topping = p.topping_id 
WHERE topping != 0
GROUP BY topping,topping_name
ORDER BY exclusions_Topping_Time DESC;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195491147-47364099-7995-4adb-8ebb-914b72930724.png)
- The most common exclusion topping is Cheese
#

#
### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


#### Explanation
- What this question is asking is for you to create a column in the customer_orders table where, for every record, it tells you the name of the pizza ordered as well as the names of any toppings added as extras or exclusions.

#### One way to achieve this
- Create `3 CTEs`: One for exclusions and one for extras and one for union (extras and exclusions).
  - We want to know what was excluded or added to each pizza.
  - In these CTEs we are going to SELECT the record_id (The unique identifier for every pizza ordered, [that we created in the data cleaning section](#2-table-customer_orders)) and the topping_name for those extras or exclusions.
    - We are using `STRING_AGG` to show those topping names in a comma delimited list (as that is how we need them in the final output).
    
- In the `final SELECT Statement` we are going to want to SELECT record_id,order_id in the customer_orders table and CONCAT(pizza name,  record_optionss) .
  - This is the example of the output we want to replicate with the CASE Statement:
  
     ```sql 
        - Meat Lovers
        - Meat Lovers - Exclude Beef
        - Meat Lovers - Extra Bacon
        - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
     ```
  - `  

```sql
with extras_cte AS (
                    SELECT 
                      record_id,
                      'Extra ' + STRING_AGG(t.topping_name, ', ') as record_options
                    FROM #extras e,
                         pizza_toppings t
                    WHERE e.topping_id = t.topping_id
                    GROUP BY record_id
                    ),
exclusions_cte AS
                  (
                    SELECT 
                      record_id,
                      'Exclude ' + STRING_AGG(t.topping_name, ', ') as record_options
                    FROM #exclusions e,
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

SELECT c.record_id, 
        c.order_id,
        CONCAT_WS(' - ', p.pizza_name, STRING_AGG(cte.record_options, ' - ')) as pizza_and_topping
FROM #customer_orders c
JOIN pizza_names p ON c.pizza_id = p.pizza_id
LEFT JOIN union_cte cte ON c.record_id = cte.record_id
GROUP BY
	c.record_id,
	p.pizza_name,
  c.order_id
ORDER BY 1;
```
#### exclusions CTE output
![image](https://user-images.githubusercontent.com/101379141/195494327-ab4a5f84-5c32-4d32-b43f-def828ac42b3.png)

#### extras CTE output
![image](https://user-images.githubusercontent.com/101379141/195494364-1f1086cb-efe9-42c1-bf97-af743424040b.png)

#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195494415-4803a537-18e6-42fb-848d-37427ca929e7.png)

#
### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


#### Explanation
- Here we want to create a new column in the customer_orders table in which it tells us, for each record, the pizza name as well as a list of the ingredients to use. 
- In the ingredient list we want to exclude the toppings the customer excluded (we dont want them to appear on the list) and add a '2x' infront of the toppings the customer added as extras. 

#### One way to achieve this
- we add topping name ino pizza_recipe and Use CASE WHEN to indentify and 2x with relevant ingredient ( if they are in #extras table)


#### new #pizza_recipes table 
![image](https://user-images.githubusercontent.com/101379141/195495321-abe45c47-fa69-49de-ba7e-87ef6465ab67.png)

```sql
WITH INGREDIENT_CTE AS (SELECT record_id,
                                pizza_name,
                                CASE WHEN p1.topping_id in (
                                                  SELECT topping_id
                                                  FROM #extras e
                                                  WHERE C.record_id = e.record_id
                                                 ) 
                                      THEN '2x' + p1.topping_name
                                      ELSE p1.topping_name
                                      END AS topping
                        FROM #customer_orders c 
                        JOIN pizza_names p2 ON c.pizza_id = p2.pizza_id
                        JOIN #pizza_recipes p1 ON c.pizza_id = p1.pizza_id
                        WHERE p1.topping_id NOT IN (SELECT topping_id 
                                                 FROM #exclusions e 
                                                 WHERE e.record_id = c.record_id)
                      )

SELECT record_id, 
      CONCAT(pizza_name +':' ,STRING_AGG(topping, ',' ) WITHIN GROUP (ORDER BY topping ASC)) AS ingredient_list
FROM INGREDIENT_CTE
GROUP BY  record_id,pizza_name
ORDER BY 1;
```
#### the ingredients CTE output
![image](https://user-images.githubusercontent.com/101379141/195495773-6084c212-914a-4443-a103-b7c7f00ea784.png)
#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195495709-0951043d-ebb1-4c39-b4db-c238cf2adc10.png)
#
### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

#### Explanation
- Here we want a list of the all the ingredients and a SUM of how many times each one has been used, in DESCENDING order (most used first).

#### One way to achieve this
- Create a `CTE`:
- In this CTE we are going to SELECT the record_id, the pizza_name, the topping_name, create a CASE Statement to show the times every ingredient was used in each pizza.
  - The `CASE Statemet`:
    - We want to generate a column (I called it times_used_topping) 
      - CASE WHEN the topping (topping_id) is found IN the extras_id column in the #extras table WHERE the records are the same
      - THEN return 2
      - ELSE return 1
   - We also include WHERE statement to eliminate 'excluded topping', cancelled pizza
- In the `final SELECT Statement`:
  - SELECT the topping_name
  - And a SUM of the topping_times_used
  - ORDER BY the topping_times_used in DESCENDING order (most frequently used first)

```sql
WITH INGREDIENT_CTE AS (SELECT record_id,
                                pizza_name, 
                                topping_name,
                                CASE WHEN p1.topping_id in (
                                  SELECT topping_id
                                  FROM #extras e
                                  WHERE C.record_id = e.record_id
                                ) THEN 2
                                ELSE 1
                                END AS times_used_topping
                        FROM #customer_orders c 
                        JOIN pizza_names p2 ON c.pizza_id = p2.pizza_id
                        JOIN #pizza_recipes p1 ON c.pizza_id = p1.pizza_id
                        JOIN #runner_orders r ON c.order_id = r.order_id
                        WHERE p1.topping_id NOT IN (SELECT topping_id 
                                                  FROM #exclusions e 
                                                  WHERE e.record_id = c.record_id) 
                                                  and r.cancellation is NULL
                         )

SELECT topping_name, 
        SUM(times_used_topping) AS times_used_topping
from INGREDIENT_CTE
GROUP BY topping_name
order by times_used_topping desc;

SELECT topping_name, 
        SUM(times_used_topping) AS times_used_topping
from INGREDIENT_CTE
GROUP BY topping_name
order by times_used_topping desc;
```
#### Fragment of ingredients CTE
![image](https://user-images.githubusercontent.com/101379141/195499293-117f860d-c191-4243-9b72-5a224317a170.png)
#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195500818-de57476b-78e3-445d-a985-d10e4504fdca.png)
