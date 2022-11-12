#  👕 Case Study #7 - Balanced Tree Clothing Co.
<p align="right"> Using Microsoft SQL Server </p>

## 👩🏻‍💻 Solution - C. Product Analysis

**1. What are the top 3 products by total revenue before discount?**

We can calculate the total revenue by product and rank the results using the Top 3.
````sql
SELECT  TOP 3 prod_id, 
        product_name,
        SUM(qty * s.price) as total_revenue
FROM    sales s
JOIN product_details p ON s.prod_id = p.product_id
GROUP BY prod_id,product_name
ORDER BY total_revenue DESC
````
![image](https://user-images.githubusercontent.com/101379141/199997527-f4f9158d-bac5-4ea1-9879-8701fd81812b.png)

**2. What is the total quantity, revenue and discount for each segment?**

````sql
SELECT segment_name, 
        SUM(qty) AS total_quantity, 
        SUM(qty * s.price) as total_revenue,
        SUM(qty * s.price * (CAST(discount AS decimal(10,2)) / 100)) as total_discount
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY segment_name;
````

![image](https://user-images.githubusercontent.com/101379141/199997824-0aaa5df6-1823-4867-bb46-72bcfeb094f9.png)

**3.What is the top selling product for each segment?**

We can calculate the total revenue by product and rank the quantity of product by segment by using Rank() Window function In CTE and use WHERE condition to filter rank_selling = 1

````sql
WITH CTE_SEGMENT AS (   SELECT  product_name,
                                segment_name,
                                SUM(qty) as total_selling,
                                SUM(qty * s.price) as total_revenue,        
                                RANK() OVER (PARTITION BY segment_name ORDER BY SUM(QTY) DESC) AS rank_selling
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY segment_name,product_name)

SELECT  segment_name,
        product_name,
        total_selling,
        total_revenue
FROM CTE_SEGMENT
WHERE rank_selling = 1;
````

![image](https://user-images.githubusercontent.com/101379141/199998580-3ef03075-41ce-4e64-bbd9-d3fb93f3877e.png)

**4.What is the total quantity, revenue and discount for each category?**

````sql
SELECT category_name, 
        SUM(qty) AS total_quantity, 
        SUM(qty * s.price) as total_revenue,
        SUM(qty * s.price * (CAST(discount AS decimal(10,2)) / 100)) as total_discount
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY category_name;
````

![image](https://user-images.githubusercontent.com/101379141/199998844-61b6961c-f161-4942-b40f-275549fd911f.png)

**5.What is the top selling product for each category?**

We can calculate the total revenue by product and rank the quantity of product by category by using Rank() Window function In CTE and use WHERE condition to filter rank_selling = 1

````sql
WITH CTE_CATEGORY AS (  SELECT  product_name,
                                category_name,
                                SUM(qty) as total_selling,
                                SUM(qty * s.price) as total_revenue,
                                RANK() OVER (PARTITION BY category_name ORDER BY SUM(QTY) DESC) AS rank_selling
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY category_name,product_name)

SELECT  product_name,
        category_name,
        total_selling,
        total_revenue
FROM CTE_CATEGORY
WHERE rank_selling = 1;
````

![image](https://user-images.githubusercontent.com/101379141/199999062-f2eba757-7e5b-4fe5-8c18-0b4070f587ae.png)

**6.What is the percentage split of revenue by product for each segment?**
  - In this case we make 2 Steps:
      - Firstly, we create cte including segment, product and total revenue of each 
      - Secondly, We use window function to calculate the percent each
  
````sql
WITH CTE_SEGMENT AS (   SELECT  segment_name,
                                product_name,
                                sum(qty * s.price) as total_revenue
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY segment_name,product_name)

SELECT  segment_name,
        product_name,
        ROUND (100 *  CAST (total_revenue AS FLOAT)  / SUM(total_revenue) over (partition by segment_name  ORDER BY segment_name  ),2) as percent_revenue
FROM CTE_SEGMENT
ORDER BY segment_name, percent_revenue DESC ;
````

![image](https://user-images.githubusercontent.com/101379141/200000677-a47c6afb-6e5c-47ac-ab86-735f3a1eb004.png)

**7.What is the percentage split of revenue by segment for each category?**
  - In this case we make 2 Steps:
      - Firstly, we create cte including segment, category and total revenue of each 
      - Secondly, We use window function to calculate the percent each
  
````sql
WITH CTE_CATEGORY AS (  SELECT  category_name, 
                                segment_name,
                                SUM(qty * s.price) as total_revenue
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY category_name,segment_name)

SELECT  category_name,
        segment_name,
        ROUND (100 *  CAST (total_revenue AS FLOAT)  / SUM(total_revenue) over (partition by category_name  ORDER BY category_name  ),2) as percent_revenue
FROM CTE_CATEGORY
ORDER BY segment_name, percent_revenue DESC ;
````

![image](https://user-images.githubusercontent.com/101379141/200000777-22b17a83-1edd-4773-815f-b5072fbd705f.png)

**8.What is the percentage split of total revenue by category?**
  - In this case we make 2 Steps:
      - Firstly, we create cte including category and total revenue of each 
      - Secondly, We use window function to calculate the percent each
  
````sql
WITH CTE_CATEGORY AS (  SELECT  category_name, 
                                SUM(qty * s.price) as total_revenue
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY category_name)

SELECT  category_name, 
        total_revenue,
        ROUND (100 *  CAST (total_revenue as float) / sum(total_revenue) over(),2) as percent_revenue       
FROM CTE_CATEGORY
ORDER BY percent_revenue DESC ;
````

![image](https://user-images.githubusercontent.com/101379141/200001088-a21c3461-f55a-4bdc-883b-5259fa49ba58.png)

**9.What is the total transaction “penetration” for each product?**
**(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)**

- In this question, Penetration is computed by total transaction of each product divided by total of transactions, so we need to compute 2 things:
    - total_transaction for each product
    - total distinct transactions

```sql
SELECT  product_name,
        COUNT(txn_id) AS total_transaction,
        ROUND (100 *  CAST (COUNT(txn_id) as float) / ( SELECT COUNT(DISTINCT txn_id) 
                                                        FROM sales)
                                                           ,2)  as penetration       
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY product_name;
```

![image](https://user-images.githubusercontent.com/101379141/200001991-9096daba-b550-471d-a029-1d3f76d8aaf8.png)

**10.What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?**

This is a combinatorics question. We need to find all possible combinations of 3 different items from all the items in the list. The total number of items is 12, so we have 220 possible combinatations of 3 different items. 

The formula to count the number of combinations is:

![index](https://user-images.githubusercontent.com/98699089/154108351-75600543-8c50-4efb-bff3-bddc07b12fe1.png)

`12! / 3! * (12 - 9)! = 12! / 3! * 9! = 4 * 5 * 11 = 220`

- Firstly, CTE to list all transaction and their product
- Secondly, We use JOIN and condition to filter combination (hint: using '<' condition to remove the duplicate product name combinations)
```sql
WITH CTE AS (   SELECT  txn_id, 
                        p1.product_name
                FROM sales s 
                LEFT JOIN product_details  p1 ON s.prod_id = p1.product_id)

SELECT top 1
        C1.product_name AS PRODUCT_1,
        C2.product_name AS PRODUCT_2,
        C3.product_name AS PRODUCT_3,
        COUNT (*) AS time_trans
FROM CTE c1 
LEFT JOIN CTE C2 ON C1.txn_id =C2.txn_id  AND C1.product_name < c2.product_name
LEFT JOIN CTE C3 ON C1.txn_id = C3.txn_id AND C1.product_name < c3.product_name AND C2.product_name < c3.product_name
WHERE C1.product_name IS NOT NULL and C2.product_name IS NOT NULL AND C3.product_name IS NOT NULL
GROUP BY C1.product_name, C2.product_name,C3.product_name
ORDER BY time_trans DESC ;
```
![image](https://user-images.githubusercontent.com/101379141/200003583-4cf8b1f9-16f3-4cf4-9f03-dd469669e294.png)

***
