# 💵 Case Study #4 - Data Bank
<p align="right"> Using Microsoft SQL Server </p>

## 🏦 Solution - B. Customer Transactions

**1. What is the unique count and total amount for each transaction type?**

````sql
SELECT  txn_type, 
        COUNT(*) as total_transaction,
        SUM(txn_amount) as total_amount
FROM customer_transactions
GROUP BY txn_type;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195849785-9b45f0db-ac95-415e-aee1-52b3691305c3.png)
***

**2. What is the average total historical deposit counts and amounts for all customers?**

- Firstly, in CTE, we find the count of transaction and average transaction amount for each customer.
- Then, find the average of both columns where the transaction type is deposit.

````sql
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
````
**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195849910-c97df759-9635-4f87-82f2-45446ab3295f.png)

- The average historical deposit count is 5 and average historical deposit amounts are 508

***

**3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?**
- Firstly, We need to check about the distinct year of database, if there is only 1 year, we dont need to specific month and year in final result
```sql
SELECT DISTINCT  DATEPART(YEAR,txn_date) AS year 
FROM customer_transactions ;
```
  - The result is :

![image](https://user-images.githubusercontent.com/101379141/195850407-938d8fc7-6900-45de-9d36-d0ddd95f9130.png)

- Secondly, create a `CTE` with output counting the number of deposits, purchases and withdrawals for each customer grouped by month.
- Then, filter the results to 
  - more than 1 for deposits AND
    - 1 or more purchase(s) OR
    - 1 or more withdrawal(s) 
in a single month.

````sql
WITH CTE AS (
                SELECT customer_id, 
                        datepart(month,txn_date) as month,
                        SUM(CASE WHEN txn_type ='deposit' then 1 else 0 end) as  deposit_time,
                        SUM(CASE WHEN txn_type ='purchase' then 1 else 0 end) as  purchase_time,
                        SUM(CASE WHEN txn_type ='withdrawal' then 1 else 0 end) as  withdrawal_time   
                FROM customer_transactions
                GROUP BY customer_id,datepart(month,txn_date))

SELECT month, count(*)
FROM CTE 
WHERE deposit_time > 1 and (purchase_time =1 or withdrawal_time =1)
GROUP BY month;

````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195850907-8358d419-03df-4a29-9942-24949a570def.png)
***

**4. What is the closing balance for each customer at the end of the month? Also show the change in balance each month in the same table output.**

This is a particularly difficult question - with probably the most `CTE`s I have in a single query - there are 2 `CTE`s!
- First CTE, We calculate the amount of deposits, purchases and withdrawals for each customer grouped by month.
- Second CTE, We compute the total balance (deposit - purchase - withdrawal) each month, customer
- Finaly Select, We calculate the balance after each month of each customer by 'sliding method' (ROWS BETWEEN UNBOUNDED PRECEDING AND current ROW)

````sql
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
        SUM(total) OVER (PARTITION BY customer_id ORDER BY customer_id,month  ROWS BETWEEN UNBOUNDED PRECEDING AND current ROW) AS balance,
        total AS change_in_balance 
FROM CTE_2;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195851821-81127e6e-9a40-46f5-98b9-64cc26c5a4bc.png)

***

**5. What is the percentage of customers who increase their closing balance by more than 5%?:**

This is a particularly difficult question - with probably the most `CTE`s I have in a single query - there are 4 `CTE`s!
- The First CTE, We calculate the amount of deposits, purchases and withdrawals for each customer grouped by month.
- The Second CTE, We compute the total balance (deposit - purchase - withdrawal) each month, customer.
- Thirstly, We calculate the balance after each month of each customer by 'sliding method' (ROWS BETWEEN UNBOUNDED PRECEDING AND current ROW)
- In the next, we take the first value and last value of balance
- Final CTE, we calculate growing_rate of each customer
- Finaly Select, we take 5% of growing_rate customer, and compute total % of customer got growing rate 5%.
  - Dont forget to use Cast to transform final result to Float


```sql
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
```
**Answer:**

![image](https://user-images.githubusercontent.com/101379141/195853355-5bfe15af-8056-4082-bed4-c5dab228189c.png)
***

