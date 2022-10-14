# 💵 Case Study #4 - Data Bank
<p align="right"> Using Microsoft SQL Server </p>

## 🏦 Solution - A. Customer Nodes Exploration

**1. How many unique nodes are there on the Data Bank system?**

````sql
SELECT COUNT( DISTINCT node_id) as unique_nodes
FROM customer_nodes
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195846878-a315e2b5-0ade-4b43-aa5e-42b57c640733.png)
- There are 5 unique nodes on Data Bank system.

***

**2. What is the number of nodes per region?**

````sql
SELECT c.region_id,
        region_name, 
        count(node_id) as total_nodes
FROM customer_nodes c 
JOIN regions r ON c.region_id = r.region_id
GROUP BY c.region_id,region_name
ORDER BY c.region_id
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195847042-ca686a02-65c6-456b-836b-f4af6557321d.png)
***

**3. How many customers are allocated to each region?**

````sql
SELECT c.region_id,
        region_name,
        COUNT(distinct customer_id) as total_customers
FROM customer_nodes c 
JOIN regions r ON c.region_id = r.region_id
GROUP BY c.region_id, 
            region_name
ORDER BY c.region_id
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195847115-53cf988d-a57b-4621-b8fc-54525cb0f89a.png)
***

**4. How many days on average are customers reallocated to a different node?**

````sql
SELECT AVG(DATEDIFF(day,start_date,end_date))
FROM customer_nodes
WHERE end_date != '9999-12-31';
````

**Answer:**

<img width="178" alt="image" src="https://user-images.githubusercontent.com/81607668/130345231-fd91f86f-1a2a-466a-b5b4-ccee80d15c92.png">

- On average, customers are reallocated to a different node every 24 days.

***

**5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?**
- This question asks median (percentile 50), 80th and 95th percentile. We can use PERCENTILE_DISC to get the result.
  - There 2 method to get result of percentile [percentile_disc & percentile_cont](https://www.mssqltips.com/sqlservertutorial/9128/sql-server-statistical-window-functions-percentile-disc-and-percentile-cont/#:~:text=PERCENTILE_DISC%20and%20PERCENTILE_CONT,-Both%20functions%20calculate&text=The%20main%20difference%20between%20the,while%20PERCENTILE_CONT%20will%20interpolate%20values.&text=The%20WITHIN%20GROUP%20clause%20specifies,percentile%20should%20be%20computed%20over.)
```sql
WITH CTE AS (SELECT region_id,
                    DATEDIFF(day,start_date,end_date) as allocation_days
            FROM customer_nodes
            WHERE end_date != '9999-12-31'
            )

SELECT distinct region_id , 
        PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS median,
        PERCENTILE_DISC(0.8) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS #80th_percentile,
        PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS #95TH_percentile
FROM CTE
```
**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195848444-31bb4ef6-e100-45c1-848d-edb36d555188.png)


