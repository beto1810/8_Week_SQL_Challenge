
--A.High Level Sales Analysis
--1/What was the total quantity sold for all products?
SELECT SUM(qty) AS total_sold_product
FROM sales;
--2/What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) as total_revenue
FROM sales;
--3/What was the total discount amount for all products?
SELECT SUM(qty * price * (cast(discount as decimal(10,2)) /100) ) as total_discount
FROM sales

--B.Transaction Analysis
--1.How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) as Unique_trans
FROM sales;

--2.What is the average unique products purchased in each transaction?
SELECT COUNT(qty) / COUNT(DISTINCT txn_id) as average_unique_product 
FROM sales ;

--3.What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH CTE AS ( 
            select   distinct txn_id,
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

--4.What is the average discount value per transaction?

SELECT SUM(qty * price * (cast(discount as decimal(10,2)) /100) ) / COUNT (distinct txn_id) AS average_discount 
FROM sales ;


--5.What is the percentage split of all transactions for members vs non-members?

WITH CTE_member AS (SELECT distinct txn_id, 
                            member, 
                            CASE WHEN member = 1 then 1 
                                ELSE 0 END AS member_int
                    FROM sales)

SELECT CAST( 100* SUM(member_int) AS FLOAT)/COUNT (txn_id) AS perc_trans_mems,
        100 - CAST( 100* SUM(member_int) AS FLOAT)/COUNT (txn_id) as perc_trans_non_mems
FROM CTE_member ;

--6/What is the average revenue for member transactions and non-member transactions?

WITH CTE_revenue AS (SELECT DISTINCT txn_id,
                            member,
                            SUM(qty * price) as revenue
                    FROM sales
                    GROUP BY txn_id,member )

SELECT  DISTINCT member ,  
        AVG(revenue) OVER (PARTITION BY member)  as average_revenue
FROM CTE_revenue

--C.Product Analysis

--1.What are the top 3 products by total revenue before discount?
SELECT  TOP 3 prod_id, 
        product_name,
        SUM(qty * s.price) as total_revenue
FROM    sales s
JOIN product_details p ON s.prod_id = p.product_id
GROUP BY prod_id,product_name
ORDER BY total_revenue DESC

--2. What is the total quantity, revenue and discount for each segment?
SELECT segment_name, 
        SUM(qty) AS total_quantity, 
        SUM(qty * s.price) as total_revenue,
        SUM(qty * s.price * (CAST(discount AS decimal(10,2)) / 100)) as total_discount
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY segment_name;

--3.What is the top selling product for each segment?
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
--4.What is the total quantity, revenue and discount for each category?
SELECT category_name, 
        SUM(qty) AS total_quantity, 
        SUM(qty * s.price) as total_revenue,
        SUM(qty * s.price * (CAST(discount AS decimal(10,2)) / 100)) as total_discount
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY category_name;

--5.What is the top selling product for each category?
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

--6. What is the percentage split of revenue by product for each segment?
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

--7. What is the percentage split of revenue by segment for each category?

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

--8.What is the percentage split of total revenue by category?

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

--9.What is the total transaction “penetration” for each product? 
--(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

SELECT  product_name,
        COUNT(txn_id) AS total_transaction,
        ROUND (100 *  CAST (COUNT(txn_id) as float) / ( SELECT COUNT(DISTINCT txn_id) 
                                                        FROM sales)
                                                           ,2)  as penetration       
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY product_name;


--10.What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

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

--D. Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.


SELECT  *
FROM product_hierarchy AS p
JOIN product_hierarchy AS p1 on p.parent_id = p1.id
JOIN product_hierarchy AS p2 on p1.parent_id = p2.id
JOIN product_prices AS pp on p.id = pp.id



