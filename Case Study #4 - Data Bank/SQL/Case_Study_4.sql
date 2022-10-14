--A. Customer Nodes Exploration
--1/How many unique nodes are there on the Data Bank system?
SELECT COUNT( DISTINCT node_id) as unique_nodes
FROM customer_nodes;

--2/What is the number of nodes per region?

SELECT c.region_id,
        region_name, 
        count(node_id) as total_nodes
FROM customer_nodes c 
JOIN regions r ON c.region_id = r.region_id
GROUP BY c.region_id,region_name
ORDER BY c.region_id;

--3/ How many customers are allocated to each region?
SELECT c.region_id,
        region_name,
        COUNT(distinct customer_id) as total_customers
FROM customer_nodes c 
JOIN regions r ON c.region_id = r.region_id
GROUP BY c.region_id, 
            region_name
ORDER BY c.region_id

--4/ How many days on average are customers reallocated to a different node?
SELECT AVG(DATEDIFF(day,start_date,end_date))
FROM customer_nodes
WHERE end_date != '9999-12-31';


--5/What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH CTE AS (SELECT region_id,
                    DATEDIFF(day,start_date,end_date) as allocation_days
            FROM customer_nodes
            WHERE end_date != '9999-12-31'
            )

SELECT distinct region_id , 
        PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS median,
        PERCENTILE_DISC(0.8) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS #80th_percentile,
        PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS #95TH_percentile
FROM CTE;


--B. Customer Transactions
--1/What is the unique count and total amount for each transaction type?
SELECT  txn_type, 
        count(*) as total_transaction,
        SUM(txn_amount) as total_amount
FROM customer_transactions
GROUP BY txn_type;

--2/What is the average total historical deposit counts and amounts for all customers?
WITH DEPOSIT_CTE AS (
                        SELECT  customer_id,
                                COUNT(customer_id) as time_deposit, 
                                AVG(txn_amount) as amount_deposit
                        FROM customer_transactions 
                        WHERE txn_type = 'deposit'
                        GROUP BY customer_id
                        ) 

SELECT AVG(time_deposit) AS avg_count,
        AVG(amount_deposit) AS avg_amount
FROM DEPOSIT_CTE;

--3/ For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

SELECT DISTINCT  DATEPART(YEAR,txn_date) AS year 
FROM customer_transactions ;

WITH CTE AS (
                SELECT customer_id, 
                        datepart(month,txn_date) as month,
                        SUM(CASE WHEN txn_type ='deposit' then 1 else 0 end) as  deposit_time,
                        SUM(CASE WHEN txn_type ='purchase' then 1 else 0 end) as  purchase_time,
                        SUM(CASE WHEN txn_type ='withdrawal' then 1 else 0 end) as  withdrawal_time   
                FROM customer_transactions
                GROUP BY customer_id,datepart(month,txn_date))

SELECT month, count(*) as total_customer
FROM CTE 
WHERE deposit_time > 1 and (purchase_time =1 or withdrawal_time =1)
GROUP BY month;

--4/What is the closing balance for each customer at the end of the month? Also show the change in balance each month in the same table output.

WITH CTE as (
                SELECT customer_id, 
                        DATEPART(MONTH,txn_date) as month, 
                        SUM(CASE WHEN txn_type ='deposit' then txn_amount else 0 end) as deposit,
                        SUM(CASE WHEN txn_type ='purchase' then - txn_amount else 0 end) as purchase ,
                        SUM(CASE WHEN txn_type ='withdrawal' then - txn_amount else 0 end)  as  withdrawal             
                from customer_transactions
                GROUP BY customer_id,DATEPART(MONTH,txn_date)
),

CTE_2 AS (
                SELECT customer_id,
                        month,(deposit +purchase +withdrawal) as total
                from CTE)

SELECT customer_id,
        month,  
        SUM(total) OVER (PARTITION BY customer_id ORDER BY customer_id,month  ROWS BETWEEN UNBOUNDED PRECEDING AND current ROW) AS balance,total AS change_in_balance 
FROM CTE_2;


--5/What is the percentage of customers who increase their closing balance by more than 5%?


WITH CTE as (
                SELECT customer_id, 
                        DATEPART(MONTH,txn_date) as month, 
                        SUM(CASE WHEN txn_type ='deposit' then txn_amount else 0 end) as deposit,
                        SUM(CASE WHEN txn_type ='purchase' then - txn_amount else 0 end) as purchase ,
                        SUM(CASE WHEN txn_type ='withdrawal' then - txn_amount else 0 end)  as  withdrawal             
                from customer_transactions
                GROUP BY customer_id,DATEPART(MONTH,txn_date)
),

CTE_2 AS (
                SELECT customer_id,
                        month,(deposit +purchase +withdrawal) as total
                from CTE),

CTE_3 AS (
                SELECT customer_id,
                        month,  
                        SUM(total) OVER (PARTITION BY customer_id ORDER BY customer_id,month  ROWS BETWEEN UNBOUNDED PRECEDING AND current ROW) AS balance,total AS change_in_balance 
                FROM CTE_2),

CTE_4 AS (      SELECT distinct customer_id , 
                        first_value(balance) over (partition by customer_id order by customer_id) as start_balance,
                        last_value(balance) over (partition by customer_id order by customer_id) as end_balance
                FROM cte_3 ),

CTE_5 AS (
                SELECT *, 
                ((end_balance - start_balance) * 100 / start_balance) as growing_rate
                FROM CTE_4
                WHERE ((end_balance - start_balance) * 100 / start_balance) >= 5 AND end_balance >start_balance)

SELECT CAST(COUNT (customer_id) AS FLOAT) * 100 / (SELECT COUNT (DISTINCT customer_id) from customer_transactions) as Percent_Customer
FROM CTE_5