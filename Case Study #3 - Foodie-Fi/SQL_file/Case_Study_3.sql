-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

SELECT s.customer_id,
       p.plan_name,
       s.start_date,
       DATEDIFF(day, LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date),start_date ) AS days_diff,
       DATEDIFF(MONTH,LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date),start_date) as months_diff
FROM   subscriptions_demo AS s
JOIN   plans AS p
ON     s.plan_id = p.plan_id

-- B. Data Analysis Questions
--1/ How many customers has Foodie-Fi ever had?
SELECT COUNT( DISTINCT customer_id) AS Number_Customer
FROM subscriptions;

--2/What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT DATEPART(month, start_date) as month ,
       DATEPART(year, start_date) as year,
       COUNT(customer_id) as number_of_trial
FROM subscriptions s
LEFT JOIN plans p ON s.plan_id =p.plan_id
WHERE plan_name = 'trial'
GROUP BY DATEPART(month, start_date),
         DATEPART(year, start_date)



--3/What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT s.plan_id,
        plan_name , 
        COUNT(s.plan_id) AS number_of_trial
FROM subscriptions s 
LEFT JOIN plans p ON s.plan_id = p.plan_id
WHERE DATEPART(year,start_date) > 2020
GROUP BY s.plan_id,plan_name;

--4/What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 
COUNT(customer_id) as customer_churn, 
cast(COUNT(customer_id) as float) / ( select count(distinct customer_id) from subscriptions) * 100 as percentage_churn
FROM subscriptions s LEFT JOIN plans p ON  s.plan_id = p.plan_id
WHERE plan_name ='churn' 



SELECT
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(CASE WHEN plan_id = 4 THEN 1 ELSE NULL END) AS churned_customers,
    ROUND(CAST(SUM(CASE WHEN plan_id = 4 THEN 1 ELSE NULL END) AS decimal(5,1)) /
        CAST(COUNT(DISTINCT customer_id) AS Decimal(5,1)) * 100,1) AS pct_churn
FROM subscriptions;


--5/How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH CTE AS(SELECT *, 
                  LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
            FROM subscriptions
            ) 
SELECT plan_name , 
        COUNT(next_plan) as number_churn, 
        CAST(count(next_plan) AS FLOAT) * 100 / (select count(distinct customer_id) from subscriptions) as perc_straight_churn
FROM CTE c
LEFT JOIN plans p ON c.next_plan = p.plan_id
WHERE next_plan = 4 and c.plan_id = 0
GROUP BY plan_name;

--6/What is the number and percentage of customer plans after their initial free trial?


WITH CTE AS(SELECT *, 
        LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
FROM subscriptions) 

SELECT plan_name, 
        COUNT(*) as num_plan, 
        Cast(count(next_plan) as float) * 100 / (select count(distinct customer_id) from subscriptions) as perc_next_plan
FROM CTE c 
LEFT JOIN plans p ON c.next_plan = p.plan_id
WHERE  c.plan_id = 0 and next_plan is not NULL
GROUP BY plan_name,next_plan;


--7/ What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH CTE AS(SELECT *, 
        LEAD(start_date,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_date
FROM subscriptions
WHERE start_date <= '2020-12-31') 

SELECT C.plan_id,plan_name, 
        count(C.plan_id)  AS customer_count,  
        (CAST(count(C.plan_id) AS Float) *100 / (select count(distinct customer_id) FROM subscriptions) ) as Percentage_customer
FROM CTE c
LEFT JOIN plans P ON C.plan_id= P.plan_id
WHERE next_date is NULL or next_date >'2020-12-31' 
GROUP BY C.plan_id,plan_name
ORDER BY plan_id

--8/ How many customers have upgraded to an annual plan in 2020?

SELECT plan_name, count(s.plan_id) as number_annual_plan
FROM subscriptions s
INNER JOIN plans p ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual' and start_date <='2020-12-31'
GROUP BY plan_name;

--9/ How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH START_CTE AS (SELECT customer_id,
                    start_date 
             FROM subscriptions s
             INNER JOIN plans p ON s.plan_id = p.plan_id
             WHERE plan_name = 'trial' ),

ANNUAL_CTE AS (SELECT customer_id,
                start_date as start_annual
          FROM subscriptions s
          INNER JOIN plans p ON s.plan_id = p.plan_id
          WHERE plan_name = 'pro annual' )

SELECT Avg(DATEDIFF(day,start_date,start_annual)) as average_day
FROM ANNUAL_CTE C2
LEFT JOIN START_CTE C1 ON C2.customer_id =C1.customer_id

--10/Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH START_CTE AS (   
                SELECT customer_id,
                       start_date 
                FROM subscriptions s
                INNER JOIN plans p ON s.plan_id = p.plan_id
                WHERE plan_name = 'trial' ),

ANNUAL_CTE AS ( SELECT customer_id,
                       start_date as start_annual
                FROM subscriptions s
                INNER JOIN plans p ON s.plan_id = p.plan_id
                WHERE plan_name = 'pro annual' ),

DIFF_DAY_CTE AS (      SELECT DATEDIFF(day,start_date,start_annual) as diff_day
                FROM ANNUAL_CTE C2
                LEFT JOIN START_CTE C1 ON C2.customer_id =C1.customer_id),

GROUP_DAY_CTE AS (      SELECT*, FLOOR(diff_day/30) as group_day
                FROM DIFF_DAY_CTE)

SELECT CONCAT((group_day *30) +1 , '-',(group_day +1)*30, ' days') as days,
        COUNT(group_day) as number_days
FROM GROUP_DAY_CTE
GROUP BY group_day;


--11/How many customers downgraded from a pro monthly to a basic monthly plan in 2020?



WITH CTE AS(SELECT *, 
        LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
FROM subscriptions
WHERE start_date <= '2020-12-31')

SELECT COUNT(*) as num_downgrade
FROM CTE 
WHERE next_plan = 1 and plan_id = 2;








