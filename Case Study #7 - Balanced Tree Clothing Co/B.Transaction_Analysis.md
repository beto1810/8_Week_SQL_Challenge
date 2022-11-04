# 👕 Case Study #6 - Balanced Tree Clothing Co.
<p align="right"> Using Microsoft SQL Server </p>

## 👩🏻‍💻 Solution - B. Transaction Analysis

***

**1. How many unique transactions were there?**
```sql
SELECT COUNT(DISTINCT txn_id) as Unique_trans
FROM sales;
```

![image](https://user-images.githubusercontent.com/101379141/199992545-1172ae4e-770a-4699-907e-b9eb4cdb5fc3.png)


**2. What is the average unique products purchased in each transaction?**

```sql
SELECT COUNT(qty) / COUNT(DISTINCT txn_id) as average_unique_product 
FROM sales ;
```
![image](https://user-images.githubusercontent.com/101379141/199993180-068f7d85-fe22-4e7d-a575-c4ba96ace3d1.png)

**3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?**

```sql
WITH CTE AS ( 
            SELECT  DISTINCT txn_id,
                    SUM(qty * price) as total_revenue
            FROM sales
            GROUP BY txn_id
            )

SELECT  distinct PERCENTILE_CONT(0.25)  WITHIN GROUP (ORDER BY total_revenue ) 
                            OVER () AS percentile_25 , 
        PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY total_revenue ) 
                            OVER () AS percentile_50,
        PERCENTILE_CONT(0.75)  WITHIN GROUP (ORDER BY total_revenue ) 
                            OVER () AS percentile_75                      
FROM CTE ;
```

![image](https://user-images.githubusercontent.com/101379141/199993935-16f19ee0-2a00-4d98-8de9-61f66e736a74.png)


**4. what is the average discount value per transaction?**

```sql
SELECT SUM(qty * price * (cast(discount as decimal(10,2)) /100) ) / COUNT (distinct txn_id) AS average_discount 
FROM sales ;

```
![image](https://user-images.githubusercontent.com/101379141/199994672-1ae40440-f3e2-41f3-86b0-a49ae4f2d6d6.png)



**5. What is the percentage split of all transactions for members vs non-members?**

```sql
WITH CTE_member AS (SELECT distinct txn_id, 
                            member, 
                            CASE WHEN member = 1 then 1 
                                ELSE 0 END AS member_int
                    FROM sales)

SELECT CAST( 100* SUM(member_int) AS FLOAT)/COUNT (txn_id) AS perc_trans_mems,
        100 - CAST( 100* SUM(member_int) AS FLOAT)/COUNT (txn_id) as perc_trans_non_mems
FROM CTE_member ;
```

![image](https://user-images.githubusercontent.com/101379141/199995120-a6f2d803-abc3-45bf-ae08-a93627d44ad7.png)


- The percentage of member's transactions is 60.2
- The percentage of non-member transactions is 39.8

**6. What is the average revenue for member transactions and non-member transactions?**

```sql
WITH CTE_revenue AS (SELECT DISTINCT txn_id,
                            member,
                            SUM(qty * price) as revenue
                    FROM sales
                    GROUP BY txn_id,member )

SELECT  DISTINCT member ,  
        AVG(revenue) OVER (PARTITION BY member) as average_revenue
FROM CTE_revenue
```
![image](https://user-images.githubusercontent.com/101379141/199995404-8c36491d-a99a-40e1-893f-5a6bfcc252dc.png)

- The average revenue for member transactions is 516
- The average revenue for non-member transactions is 515
***
