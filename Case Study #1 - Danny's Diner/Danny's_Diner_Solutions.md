# 🍜 Danny's Diner Solutions

<p align="right"> Using Microsoft SQL Server </p>

## Questions

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT customer_id,sum(menu.price) as Total_Spent
FROM sales 
Inner join menu 
ON sales.product_id = menu.product_id 
GROUP BY customer_id;
```
#### Result 
![1](https://user-images.githubusercontent.com/101379141/195239786-d226d0f5-f2df-4ad5-8af7-1d4f1328c091.PNG)


#

### 2. How many days has each customer visited the restaurant?

```sql
SELECT sales.customer_id, count(distinct sales.order_date) as Total_days
FROM sales 
GROUP BY sales.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195240029-ed43606c-04e1-4294-a556-d7e5ef63c733.png)

#

### 3. What was the first item from the menu purchased by each customer?


- Create a  Common Table Expressions (CTE), I named it as PURCHASED_RANK: 
  - In it, create a new column to show a `ranking of the items purchased by each customer (customer_id) based on the date of purchase (order_date):
    - Rank 1 will be the first item purchased with the earliest date
    - For this you can use `RANK` or `DENSE_RANK`(I use DENSE_RANK  in this case)


```sql
WITH PURCHASED_RANK AS (
    SELECT customer_id, order_date,product_name, 
    DENSE_RANK() OVER(ORDER BY order_date ) AS RANK
    FROM sales
    INNER JOIN menu
    ON sales.product_id = menu.product_id 
)
SELECT customer_id,product_name
FROM PURCHASED_RANK 
WHERE RANK =1 
GROUP BY customer_id,product_name;
```
#### PURCHASED_RANK table output:

  ![image](https://user-images.githubusercontent.com/101379141/195240779-8e92b247-2439-4d05-a9e5-5d8c5b91c062.png)

  
#### Question Result: 

  ![image](https://user-images.githubusercontent.com/101379141/195240845-06d17220-da1c-4c36-8705-442f4b45ad34.png)


  - Customer A's first orders were Curry & Sushi
  - Customer B's was Curry
  - Customer C's was Ramen 

#

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 
 ```sql
SELECT TOP 1 (COUNT(s.product_id)) AS most_purchased, product_name
FROM dbo.sales AS s
JOIN dbo.menu AS m
 ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY most_purchased DESC
 ```
 #### Result
![image](https://user-images.githubusercontent.com/101379141/195241146-aaad00b0-3f07-4922-9a71-2008899df3c5.png)


#

### 5. Which item was the most popular for each customer?

- Create a `CTE` names as rank_favorite_item 
- In it, create a new column to show a `ranking of the items purchased by each customer (customer_id) based on the times purchased (COUNT of product_id).
  - Rank 1 will be the most purchased item, 2 the second...
  - For this you can use RANK or DENSE_RANK.
- From that CTE we then want to `select the most purchased item by each customer`. 
  - This is `WHERE rank = 1`

```sql
WITH rank_favorite_item AS (
    		SELECT customer_id,
		       product_name, 
		       COUNT(sales.product_id) AS NUMBER_ORDER,
     		       rank() OVER(PARTITION BY customer_id 
     		ORDER BY COUNT(sales.product_id) DESC) AS RANK
    		FROM sales
    		INNER JOIN menu
   		ON sales.product_id = menu.product_id
   		GROUP BY customer_id,product_name
)
SELECT customer_id,product_name,NUMBER_ORDER
FROM rank_favorite_item
WHERE RANK =1;
```

#### rank_favorite_item table output:
  ![image](https://user-images.githubusercontent.com/101379141/195241494-fe29e637-b037-41a5-97ac-2624e5a0c3eb.png)


#### Question Result:
  ![image](https://user-images.githubusercontent.com/101379141/195241578-55a26af0-874a-432c-916c-02f4055ae9f8.png)

- Customer A's favourite item is Ramen
- Customer B likes all items 
- Customer C likes Ramen

#

### 6. Which item was purchased first by the customer after they became a member?

- Create a `CTE` named as 'rank_purchase_item'
  - In it, create a new column to show a `ranking of the items purchased by each customer (customer_id) based on the date of purchase (order_date)`. 
    - Rank 1 will be the first item purchased
    - For this you can use RANK or DENSE_RANK.
  - We need to include a `WHERE clause` in the CTE as we `only want items purchased after they became a member`.
    - WHERE order_date >= join_date
- From that CTE we then want to `select the first item purchased by each customer`. 
  - This is `WHERE rank = 1`

```sql
WITH rank_purchase_item AS(
    	     SELECT sales.customer_id, 
                    product_name, 
		    order_date, 
		    join_date,
                    DENSE_RANK() OVER(Partition by sales.customer_id ORDER BY order_date) AS RANK 
             FROM sales 
	     INNER JOIN menu
	     ON sales.product_id = menu.product_id
	     INNER JOIN members
	     ON sales.customer_id = members.customer_id
	     WHERE sales.order_date >= members.join_date
)
SELECT customer_id, product_name
FROM rank_purchase_item
WHERE RANK =1;
```
#### rank_purchase_item table output:

![image](https://user-images.githubusercontent.com/101379141/195242365-6a550795-7b3e-4ed4-ab3d-b82ff8e90685.png)


#### Result
![image](https://user-images.githubusercontent.com/101379141/195242423-438ec3b1-a5dc-47af-81e9-6c1c19242aaa.png)

- Customer A purchased Curry firstly 
- Customer B puchased Sushi firstly

#

### 7. Which item was purchased just before the customer became a member?

- Create a `CTE` as rank_purchase_order
  - In it, create a new column to show a `ranking of the items purchased by each customer (customer_id) based on the date of purchase (order_date) in descending order`. 
    - Rank 1 will be the last item purchased (the item purchased on latest date)
    - For this you can use RANK or DENSE_RANK.
  - We need to include a `WHERE clause` in the CTE as we `only want items purchased before they became a member`.
    - WHERE order_date < join_date
- From that CTE we then want to `select the first item purchased by each customer`. 
  - This is `WHERE rank = 1`

```sql
WITH rank_purchase_order AS (
                            SELECT sales.customer_id, 
			     	    product_name, 
				    order_date, 
				    join_date,
    				    DENSE_RANK() OVER(Partition by sales.customer_id ORDER BY order_date DESC) AS RANK 
   			    FROM sales 
			    INNER JOIN menu
			    ON sales.product_id = menu.product_id
			    INNER JOIN members
			    ON sales.customer_id = members.customer_id
			    WHERE sales.order_date < members.join_date
                             )
SELECT customer_id, product_name
FROM rank_purchase_order
WHERE RANK =1
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195243167-bd39a9d5-86c5-4cfb-839c-8693d6cda346.png)


- Customer A's last item purchased before becoming a member was Sushi & Curry
- Customer B's was Sushi

#

### 8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT  sales.customer_id,
        count(product_name) as total_item, 
        SUM(price) as Total_amount_spent
FROM sales 
INNER JOIN menu
ON sales.product_id = menu.product_id
INNER JOIN members
ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195243359-53025f99-414e-4872-a41a-6121f4af2a71.png)

#

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

- Every $1 = 10 points.
- For sushi $1 = 20 points (2 x 10). 
- We want to create point column of each type product through CTE :
	- When the product name is sushi then multiply the price by 20, when not then multiply it by 10.
- Then sum all the points.

 

```sql
WITH CTE3 AS(
    SELECT product_id,product_name, price,
    CASE WHEN product_name = 'sushi' THEN price *20 
         ELSE price * 10 END AS point 
    FROM menu 
)

SELECT customer_id, sum(point ) as total_point
FROM sales s
INNER JOIN CTE3 c3
ON s.product_id = c3.product_id
GROUP BY  customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195244002-ea3699a8-48c4-48ca-9f62-dd28477836f2.png)


# 

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

- On the week the customer joins (from join date to 7 days after) $1 = 20 points.
- Every other day $1 = 10 points.
- For this we can create 2 CTE's, one to calculate join week points and another for normal day points.
  - For the `join_week_points CTE`:
    - Here we want to calculate the points earned by each customer on their join week.
    - Multiply the price x 20 and SUM all the points.
    - Use a `WHERE` clause to filter only the items purchased `BETWEEN` the join date and 7 days after (a week).
  - For the `normal_points CTE`:
    - Here we want to calculate the points earned by each customer for the month of January, excluding the join week.
    - Use the same SUM function with the CASE statement as for the previous question.
    - Use a `WHERE` clause to filter the items puchased on the `month of January` (MONTH(order_date) = 1). 
    - AND the items purchased `NOT BETWEEN` the join date and 7 days after (filter out join week).
- From those CTE's we want to select the customer_id's and the sum of join_week_points and normal_points.

```sql
WITH 
     join_week_points AS (
                         SELECT s.customer_id,
                                SUM(m.price * 20) AS join_week_points
                         FROM   sales AS s
                         JOIN   menu AS m
                         ON     s.product_id = m.product_id
                         JOIN   members AS c
                         ON     s.customer_id = c.customer_id
                         WHERE  s.order_date BETWEEN c.join_date AND DATEADD(DAY, 7, c.join_date)
                         GROUP  BY s.customer_id
                         ),

     normal_points   AS (
                         SELECT s.customer_id,
                                SUM(CASE 
                                        WHEN m.product_name = 'sushi' 
                                        THEN m.price * 20 
                                        ELSE m.price * 10 
                                    END) AS normal_points
                         FROM   sales AS s
                         JOIN   menu AS m
                         ON     s.product_id = m.product_id
                         JOIN   members AS c
                         ON     s.customer_id = c.customer_id
                         WHERE  MONTH(s.order_date) = 1
                         AND    s.order_date NOT BETWEEN c.join_date AND DATEADD(DAY, 7, c.join_date)
                         GROUP  BY s.customer_id
                         )
SELECT j.customer_id,
       j.join_week_points + n.normal_points AS total_points_january
FROM   join_week_points AS j
JOIN   normal_points AS n
ON     j.customer_id = n.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158180650-7806642f-356b-4bac-bbae-36d02cc3e0ee.png)

---

## Bonus Questions

### 1. Join All Things

- Replicate this output:

  <img width="300" src="https://user-images.githubusercontent.com/94410139/158183700-39da11dc-067d-42e7-8367-86dc3c182031.png">
#    
- For this we can use `CASE WHEN EXISTS`:
  - When the `customer_id EXISTS in the members table and the order_date is after or on the join_date` then 'Y' (they are a member at that time), else 'N' (they are not).
 
```sql
SELECT s.customer_id,
       s.order_date,
       m.product_name,
       m.price,
       CASE 
           WHEN EXISTS ( 
                        SELECT customer_id
                        FROM   members AS c
                        WHERE  s.customer_id = c.customer_id
                        AND    s.order_date >= c.join_date
                        )
		   THEN 'Y'
		   ELSE 'N'
           END AS member
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158208767-322aa72f-cb40-4f86-9b1b-327625381b52.png)

#

### 2. Rank All Things

- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
- Replicate this output:

  <img width="300" src="https://user-images.githubusercontent.com/94410139/158209150-dc41af27-5565-42b7-9fea-af8f553f6801.png">
#
- For this create a CTE with the joined table from the last question.
- Then SELECT everything from that table and add a new column for the ranking.
   - For the RANK we need to `PARTITION by both customer_id and member`.
   - You can use RANK or DENSE_RANK.
 
 ```sql
 WITH joined_table AS (
                       SELECT s.customer_id,
                              s.order_date,
                              s.product_id,
                              m.product_name,
                              m.price,
                              CASE 
                                  WHEN EXISTS ( 
                                               SELECT customer_id
                                               FROM   members AS c
                                               WHERE  s.customer_id = c.customer_id
                                               AND    s.order_date >= c.join_date
                                               )
                                  THEN 'Y'
                                  ELSE 'N'
                              END AS member			                 
                       FROM   sales AS s
                       JOIN   menu AS m
                       ON     s.product_id = m.product_id
                       )
SELECT customer_id,
        order_date,
        product_name,
        price,
        member,
        CASE  
            WHEN member = 'Y'
            THEN DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
            ELSE NULL
        END AS ranking
FROM   joined_table
 ```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158212209-f8c8a19f-197a-4db0-bb8b-592cb629251a.png)

