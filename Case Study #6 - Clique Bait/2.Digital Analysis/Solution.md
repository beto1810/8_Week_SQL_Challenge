# 🐟 Case Study #6 - Clique Bait

## 👩🏻‍💻 Solution - A. Digital Analysis

**1. How many users are there?**

````sql
SELECT COUNT(DISTINCT user_id)  AS Total_User 
FROM users 
````

![image](https://user-images.githubusercontent.com/101379141/197101422-886c3d1a-da6e-4e06-86b4-a277f150c2d8.png)

**2. How many cookies does each user have on average?**

````sql
SELECT COUNT(DISTINCT user_id)  AS Total_User,
        COUNT(cookie_id) as total_cookie,
        cast(COUNT(cookie_id) as float) / COUNT(DISTINCT user_id)  as average_cookie
FROM users 
````

![image](https://user-images.githubusercontent.com/101379141/197101610-555e3807-4f4d-4a49-b7b4-c97720752551.png)

**3. What is the unique number of visits by all users per month?**
- First, extract numerical month from `event_time` so that we can group the data by month.
- Unique is a keyword to use `DISTINCT`.

````sql
SELECT DATEPART(MONTH, event_time) AS month ,
        COUNT(DISTINCT visit_id ) as number_visit
FROM events
GROUP BY DATEPART(MONTH, event_time)
ORDER BY month
````

![image](https://user-images.githubusercontent.com/101379141/197101708-7c643a7b-ea33-4164-ad63-2ac9ea023b25.png)

**4. What is the number of events for each event type?**

````sql
SELECT event_type,
        count(event_type) as number_events
FROM events
GROUP BY event_type 
ORDER BY event_type;
````

![image](https://user-images.githubusercontent.com/101379141/197101756-7afab09d-a239-46f1-9afa-8490b42d45d3.png)

**5. What is the percentage of visits which have a purchase event?**
- Join the events and events_identifier table and filter by `Purchase` event only. 
- As the data is now filtered to having `Purchase` events only, counting the distinct visit IDs would give you the number of purchase events.
- Then, divide the number of purchase events with a subquery of total number of distinct visits from the `events` table.

````sql
SELECT event_name, 
        COUNT(e1.event_type) as number_events,
        CAST(100* CAST(COUNT(e1.event_type) AS FLOAT) / (SELECT COUNT( DISTINCT VISIT_ID) FROM events) AS DECIMAL(10,2)) AS Percent_visit
FROM events e1
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE event_name = 'Purchase'
GROUP BY event_name;
````

![image](https://user-images.githubusercontent.com/101379141/197101880-4746d94b-8766-4126-9bd3-d3042f858156.png)

**6. What is the percentage of visits which view the checkout page but do not have a purchase event?**
The strategy to answer this question is to breakdown the question into 2 parts.

Part 1: Create a `CTE` and using `CASE statements`, find the `SUM()` of:
- `page_name` = 'Checkout' (Checkout), and assign "1" to these events. These events are when user viewed the checkout page.
- `event_name` ='Purchase' and assign "1" to these events. These events signifies users who made a purchase.


Part 2: Using the table we have created, find the percentage of visits which view checkout page.

````sql
WITH CTE AS  (  SELECT 
                        SUM( CASE WHEN page_name = 'Checkout' then 1 else 0 end ) AS checkout_visit,
                        SUM( CASE WHEN event_name = 'Purchase' then 1 else 0 end ) as purchase_visit
                FROM events e1
                JOIN event_identifier e2 ON e1.event_type = e2.event_type
                JOIN page_hierarchy p ON e1.page_id = p.page_id
                WHERE page_name = 'Checkout' or  event_name = 'Purchase'
                )

SELECT 100*(checkout_visit - purchase_visit)/ cast(checkout_visit as float) as percent_not_purchase
FROM CTE 

````

![image](https://user-images.githubusercontent.com/101379141/197102260-32a165a1-34a5-48fe-9538-8f4d7fb82e98.png)

**7. What are the top 3 pages by number of views?**

````sql
SELECT  TOP 3 page_name, 
        COUNT (e1.page_id) AS total_view
FROM events e1 
JOIN page_hierarchy p ON e1.page_id = p.page_id
GROUP BY page_name
ORDER BY total_view DESC
````
![image](https://user-images.githubusercontent.com/101379141/197102364-c76ca704-b923-4724-a55f-96a5274acb30.png)


**8. What is the number of views and cart adds for each product category?**

````sql
SELECT  product_category, 
       SUM (CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS total_view, 
       SUM (CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS add_cart
FROM events e1 
JOIN page_hierarchy p ON e1.page_id = p.page_id
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE product_category IS NOT NULL 
GROUP BY product_category;

````

![image](https://user-images.githubusercontent.com/101379141/197102414-7da76616-e197-41d6-9626-58a577f2c1b9.png)

**9. What are the top 3 products by purchases?**

````sql
WITH CTE AS (SELECT visit_id
FROM events e1 
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE event_name = 'Purchase')

SELECT page_name, COUNT(e1.visit_id) as purchase_item
FROM events e1
RIGHT JOIN CTE C on e1.visit_id = C.visit_id
JOIN page_hierarchy p ON e1.page_id = p.page_id
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE product_category IS NOT NULL AND event_name = 'Add to Cart'
GROUP BY page_name
ORDER BY purchase_item DESC ;
````
![image](https://user-images.githubusercontent.com/101379141/197102489-d6fd6643-5535-4302-90a7-67801abc6b33.png)

***

