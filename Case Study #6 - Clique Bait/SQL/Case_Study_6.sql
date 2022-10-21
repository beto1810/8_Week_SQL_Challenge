--/ 2. Digital Analysis

-- 1.How many users are there?
SELECT COUNT(DISTINCT user_id)  AS Total_User 
FROM users 

--2.How many cookies does each user have on average?
SELECT COUNT(DISTINCT user_id)  AS Total_User,
        COUNT(cookie_id) as total_cookie,
        cast(COUNT(cookie_id) as float) / COUNT(DISTINCT user_id)  as average_cookie
FROM users 

--3. What is the unique number of visits by all users per month?
SELECT DATEPART(MONTH, event_time) AS month ,
        COUNT(DISTINCT visit_id ) as number_visit
FROM events
GROUP BY DATEPART(MONTH, event_time)
ORDER BY month

--4. What is the number of events for each event type?
SELECT event_type,
        count(event_type) as number_events
FROM events
GROUP BY event_type 
ORDER BY event_type;

--5/What is the percentage of visits which have a purchase event?
SELECT event_name, 
        COUNT(e1.event_type) as number_events,
        CAST(100* CAST(COUNT(e1.event_type) AS FLOAT) / (SELECT COUNT( DISTINCT VISIT_ID) FROM events) AS DECIMAL(10,2)) AS Percent_visit
FROM events e1
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE event_name = 'Purchase'
GROUP BY event_name;

--6/ What is the percentage of visits which view the checkout page but do not have a purchase event?

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


--7/What are the top 3 pages by number of views?

SELECT  TOP 3 page_name, 
        COUNT (e1.page_id) AS total_view
FROM events e1 
JOIN page_hierarchy p ON e1.page_id = p.page_id
GROUP BY page_name
ORDER BY total_view DESC

--8/What is the number of views and cart adds for each product category?

SELECT  product_category, 
       SUM (CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS total_view, 
       SUM (CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS add_cart
FROM events e1 
JOIN page_hierarchy p ON e1.page_id = p.page_id
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE product_category IS NOT NULL 
GROUP BY product_category;

--9/What are the top 3 products by purchases?

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

--3. Product Funnel Analysis

-- Using a single SQL query - create a new output table which has the following details:

-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?
DROP TABLE IF EXISTS  product_stats;


WITH CTE AS (   SELECT distinct visit_id
                FROM events e1 
                JOIN event_identifier e2 ON e1.event_type = e2.event_type
                WHERE event_name = 'Page View'),

VIEW_CTE AS (   SELECT page_name,
                        product_category,
                        count(page_name) AS total_view
                        FROM events e1 
                        LEFT JOIN CTE c ON e1.visit_id = c.visit_id 
                        JOIN page_hierarchy p ON e1.page_id = p.page_id
                        JOIN event_identifier e2 ON e1.event_type = e2.event_type
                        WHERE product_category IS NOT NULL AND event_name = 'Page View' 
                        GROUP BY page_name,product_category),

ADD_CART_CTE AS (SELECT page_name,
                        product_category,
                        count(page_name) AS total_add
                        FROM events e1 
                        LEFT JOIN CTE c ON e1.visit_id = c.visit_id 
                        JOIN page_hierarchy p ON e1.page_id = p.page_id
                        JOIN event_identifier e2 ON e1.event_type = e2.event_type
                        WHERE product_category IS NOT NULL AND event_name = 'Add to Cart' 
                        GROUP BY page_name,product_category),

PURCHASE_CTE AS (SELECT visit_id
                FROM events e1 
                JOIN event_identifier e2 ON e1.event_type = e2.event_type
                WHERE event_name = 'Purchase'),
PURCHASE_CTE_2 AS (     SELECT  page_name,
                                product_category,
                                COUNT(e1.visit_id) as purchase_item
                        FROM events e1
                        RIGHT JOIN PURCHASE_CTE C on e1.visit_id = C.visit_id
                        JOIN page_hierarchy p ON e1.page_id = p.page_id
                        JOIN event_identifier e2 ON e1.event_type = e2.event_type
                        WHERE product_category IS NOT NULL AND event_name = 'Add to Cart'
                        GROUP BY page_name,product_category
                        )


SELECT v.page_name,
        v.product_category,
        total_view,
        total_add,
        purchase_item, 
        (total_add - purchase_item) as abadoned_item
INTO    product_stats
FROM VIEW_CTE V
LEFT JOIN ADD_CART_CTE A ON V.page_name = A.page_name
LEFT JOIN PURCHASE_CTE_2 P ON V.page_name = P.page_name
ORDER BY v.page_name;

SELECT * 
FROM product_stats;
-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

SELECT product_category,
        SUM (total_view) AS total_view,
        SUM(total_add) as total_add,
        SUM(purchase_item) as total_purchase, 
        SUM(abadoned_item) as abadoned_item
FROM product_stats
GROUP BY product_category;



-- Use your 2 new output tables - answer the following questions:

-- Which product had the most views, cart adds and purchases?
WITH RANK_CTE AS (SELECT *, 
                        RANK() OVER(ORDER BY total_view DESC) AS RANK_VIEW,
                        RANK() OVER(ORDER BY Total_add DESC) as RANK_ADD,
                        RANK() OVER(ORDER BY purchase_item DESC) as RANK_PURCHASE
                FROM product_stats)

SELECT *
FROM RANK_CTE
WHERE RANK_VIEW =1 
        OR RANK_ADD = 1
        OR RANK_PURCHASE = 1

-- Which product was most likely to be abandoned?
SELECT top 1 page_name,
        product_category,
        abadoned_item 
FROM product_stats 
ORDER BY abadoned_item DESC;
-- Which product had the highest view to purchase percentage?
SELECT  top 1 page_name,
        product_category,
        total_view,
        purchase_item,
        100*( cast(purchase_item as float)/ total_view) as percent_purchase
FROM product_stats 
ORDER BY percent_purchase DESC ;


-- What is the average conversion rate from view to cart add?
-- What is the average conversion rate from cart add to purchase?

SELECT  ROUND(avg(100*( cast(total_add as float)/ total_view)),2) as rate_view_add,
        ROUND(avg(100*( cast(purchase_item as float)/ total_add)),2) as rate_add_purchase
FROM product_stats 


--C. Campaigns Analysis

-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:

-- user_id
-- visit_id
-- visit_start_time: the earliest event_time for each visit
-- page_views: count of page views for each visit
-- cart_adds: count of product cart add events for each visit
-- purchase: 1/0 flag if a purchase event exists for each visit
-- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- impression: count of ad impressions for each visit
-- click: count of ad clicks for each visit
-- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

SELECT  user_id,
        visit_id,
        MIN(event_time) AS visit_start_time,
        SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
        SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
        SUM(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END) AS purchase,
        c.campaign_name,
        SUM(CASE WHEN event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impression,
        SUM(CASE WHEN event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
        STRING_AGG(CASE WHEN event_name = 'Add to Cart' AND p.product_id IS NOT NULL THEN page_name ELSE NULL END, ',' ) WITHIN GROUP (ORDER BY e.sequence_number) AS cart_products
FROM events e 
LEFT JOIN users u ON e.cookie_id = u.cookie_id
LEFT JOIN event_identifier e2 ON e.event_type = e2.event_type
LEFT JOIN campaign_identifier c ON e.event_time BETWEEN c.start_date and c.end_date
LEFT JOIN page_hierarchy p ON e.page_id = p.page_id
GROUP BY user_id,visit_id,c.campaign_name;