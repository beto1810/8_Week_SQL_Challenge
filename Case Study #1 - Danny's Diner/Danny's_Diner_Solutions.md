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
SELECT  sales.customer_id, 
        count(distinct sales.order_date) as Total_days
FROM sales 
GROUP BY sales.customer_id;
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
    			SELECT customer_id, 
			       order_date,
			       product_name, 
    			       DENSE_RANK() OVER(ORDER BY order_date ) AS RANK
			FROM sales
			LEFT JOIN menu
			ON sales.product_id = menu.product_id 
			)
SELECT distinct customer_id,product_name
FROM PURCHASED_RANK 
WHERE RANK =1 
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
- We want to create total point column of each type product through SUM of CASE WHEN:
	- When the product name is sushi then multiply the price by 20, when not then multiply it by 10.


 

```sql
SELECT customer_id,
        SUM(CASE WHEN product_name = 'sushi' THEN price *20 
        ELSE price * 10 END ) AS total_point
FROM sales S
JOIN menu M ON S.product_id = M.product_id
GROUP BY  customer_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195244511-27eeec89-23af-4bb1-b52b-eccd64d04a7a.png)


# 

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

- I create a CTE table with valid_date that include 1 week after joining and end of January column
- For sushi earn x2 point, and items between join_date and valid_date earn x2 point (first week joining)
- I also including condition within January order_date <= last_date

```sql
WITH dates_cte AS(
		SELECT *, 
			DATEADD(DAY, 6, join_date) AS valid_date, 
			EOMONTH('2021-01-1') AS last_date
		FROM members
)

SELECT s.customer_id,
	sum(CASE WHEN s.product_id = 1 THEN price*20
		WHEN s.order_date between d.join_date and d.valid_date THEN price*20
		ELSE price*10 
	END) as total_points
FROM dates_cte d,
     sales s,
     menu m
WHERE d.customer_id = s.customer_id 
	AND m.product_id = s.product_id
	AND s.order_date <= d.last_date
GROUP BY s.customer_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195245665-a61d3320-82bb-4908-af12-5c787c2f32e1.png)

---

## Bonus Questions


###  Join all Thing & Rank All Things 

- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
- Replicate this output:

  <img width="300" src ="https://user-images.githubusercontent.com/101379141/195248839-b0d64ca9-7fc5-4e5e-bcd4-2db9769844a5.png">
  <img width="300" src="https://user-images.githubusercontent.com/101379141/195249157-85f417e7-47e4-4f51-b951-9a19f608290d.png">
 

#
- Join all Thing :For this create a CTE (named as member_table) to have column 'member' by order_date >= join_date.
- Rank All Things :Then SELECT everything from that table and add a new column for the ranking.
   - For the RANK we need to `PARTITION by both customer_id and member`.
   - You can use RANK or DENSE_RANK.
 
 ```sql
WITH member_table as (  SELECT  s.customer_id,
                                s.order_date,m.product_name,m.price,
                                CASE WHEN s.order_date >= me.join_date THEN 'Y'
                                ELSE 'N'  END AS member
                        FROM sales s
                        INNER JOIN menu m ON s.product_id = m.product_id
                        LEFT JOIN members me ON s.customer_id = me.customer_id
		)
SELECT  customer_id,
	order_date,
	product_name,
	price,
	member,
    CASE WHEN member ='N' THEN NULL 
    ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM member_table
 ```
#### Result Join all Thing 
![image](https://user-images.githubusercontent.com/101379141/195248725-0fd80f0b-5e74-4442-b463-37f0c238ae1a.png)

#### Result Rank All Things 
![image](https://user-images.githubusercontent.com/101379141/195246512-67e21eb2-0c3b-4795-81b8-f6d4ea650f1f.png)

