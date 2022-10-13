# 🥑 A. Data Anlysis Questions Solutions

<p align="right"> Using Microsoft SQL Server </p>

#
## Questions


### 1. How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT( DISTINCT customer_id) AS Number_Customer
FROM subscriptions;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195536812-efd46f66-3180-49be-9dd0-45736d7bc35f.png)

#
### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value.

#### SQL Query 
- I want to know how many people have subscribed for a free trial each month.
- One way to do this is to use `DATE_PART()` to extract the `MONTH` from the start_date and then do a `COUNT` of `customer_id`.
- I need to use a `WHERE` clause because I only want records where the `plan_id is 0` (free trial).

```sql
SELECT DATEPART(month, start_date) as month ,
       DATEPART(year, start_date) as year,
       COUNT(customer_id) as number_of_trial
FROM subscriptions s
LEFT JOIN plans p ON s.plan_id =p.plan_id
WHERE plan_name = 'trial'
GROUP BY DATEPART(month, start_date),
         DATEPART(year, start_date)
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195537920-882e5fb0-b4de-4720-a1bc-b14387ed2e05.png)

- March had the most free trial subscriptions with 94.
- February had the least with 68.

#
### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.

#### SQL Query
- I want to know the events (number of subscriptions) for each plan after 2020.
- In the WHERE clause I will use `DATE_PART()` to specify we want the `YEAR` of star_date to be `after 2020`.

```sql
SELECT s.plan_id,
        plan_name , 
        COUNT(s.plan_id) AS number_of_trial
FROM subscriptions s 
LEFT JOIN plans p ON s.plan_id = p.plan_id
WHERE DATEPART(year,start_date) > 2020
GROUP BY s.plan_id,plan_name;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195538124-fe468e73-d2ee-4944-af9c-9bc087658513.png)

- After 2020 (So, in 2021) there were 71 plan churns (cancellations)
- 63 upgrades to pro annual plans
- 60 upgrades to pro monthly plans
- 8 subscriptions to the basic monthly plan
- And no subscriptions to free trials 

#
### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

#### SQL Query

```sql
SELECT
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(CASE WHEN plan_id = 4 THEN 1 ELSE NULL END) AS churned_customers,
    ROUND(CAST(SUM(CASE WHEN plan_id = 4 THEN 1 ELSE NULL END) AS decimal(5,1)) /
        CAST(COUNT(DISTINCT customer_id) AS Decimal(5,1)) * 100,1) AS pct_churn
FROM subscriptions;

```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195538456-1f98d8e2-6b89-4e85-b19c-65bf78c5ec05.png)
#
### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

#### SQL Query
- I want to know how many people churned (cancelled their subscription) straight after their free trial.
  - One way to do this is by first, creating a `CTE`:
     - I creating a next_plan column with LEAD() method to find the current plan. If theres is not next plan, result would be NULL 
- In the `final SELECT Statement`:
   - I am goin to COUNT next plan with WHERE condition is plan_id = 0 for trial and next_plan = 4 is churn 
   - And I am going to devide them by the total customers to get the percentage. 
      - Using CAST to transform data type to FLOAT

```sql
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
```
#### CTE 
![image](https://user-images.githubusercontent.com/101379141/195539989-e90009e5-c617-4e4a-b0fe-04cc73d5c6d1.png)

#### Result 
![image](https://user-images.githubusercontent.com/101379141/195541128-4bc9ec2f-894d-4625-90b4-ec7304e250f7.png)
#
### 6. What is the number and percentage of customer plans after their initial free trial?

#### SQL Query
- In this questions we are asked to find out what customers subscribed to after their free trial.
- For each plan_name we want to know: the number of customers that subscribed to it after the free trial and the percentage of the total.
- Let's start by creating a `CTE`:
  - I creating a next_plan column with LEAD() method to find the current plan. If theres is not next plan, result would be NULL
- In the `final SELECT Statement`:
  - I want to SELECT the plan_name (as we want to GROUP BY it as well as next_plan).
  - A COUNT of the number of times each plan . And Divide it for total distinct customer in Subqueries
  

```sql
WITH CTE AS(SELECT *, 
        LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
FROM subscriptions) 

SELECT plan_name, count(*) as num_plan, Cast(count(next_plan) as float) * 100 / (select count(distinct customer_id) from subscriptions) as perc_next_plan
FROM CTE c 
LEFT JOIN plans p ON c.next_plan = p.plan_id
WHERE  c.plan_id = 0 and next_plan is not NULL
GROUP BY plan_name,next_plan;
```

#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195542079-0778f5bf-bcba-4d92-ada0-73a07aa4d815.png)
#
### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

#### SQL Query
- I want to know how many customers were subscribed to each plan on 2020-12-31, and that as a percent of the total. 
- Firstly I need to know what plan each customer was subscribed to on 2020-12-31.
 - I creating a next_date column with LEAD() method to find the current plan with codition WHERE < '2021'. If theres is not next date, result would be NUL 
- In the `final SELECT Statement`:
  - I want to SELECT the plan_name (as I want to GROUP BY it as well as plane_id).
  - A COUNT of the customers.  
  - That same COUNT over the total customers subqueries , to get the percent of the total.
  - A WHERE clause to filter  

```sql
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
```


#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195543099-52de65ce-0fdf-48fb-9133-24fab37c061a.png)
#
### 8. How many customers have upgraded to an annual plan in 2020?

#### SQL Query 
- I want a COUNT of customers that have a annual_plan in 2020: 
- WHERE start_date <='2020-12-31' 
- AND the plan_name is pro annual

```sql
SELECT plan_name, 
        COUNT(s.plan_id) as number_annual_plan
FROM subscriptions s
INNER JOIN plans p ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual' and start_date <='2020-12-31'
GROUP BY plan_name;

```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195543705-f1aeae40-47cf-4610-92ae-8303b9d0e3fe.png)
#
### 9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?

#### SQL Query
- I need to find everyones join_date as well as the date that each customer upgraded to the annual plan. 
- I create `2 CTEs`:
  - START_CTE :
    - SELECT START_DATE.
  - ANNUAL_CTE :
    - SELECT start_date of 'pro annual' plan
- `Final Select Statement`:
  - We need the AVERAGE of the differences between the upgrade_date and the join_date. 


```sql
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
LEFT JOIN START_CTE C1 ON C2.customer_id =C1.customer_id;
```

#### Result
![image](https://user-images.githubusercontent.com/101379141/195549536-0dbefe58-09ae-4ea4-b990-73465aad4881.png)

#
#### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

#### SQL Query
- For this question we still want to find the same average as above but we want to break it down into periods. 
- I create `4 CTEs`:
  - START_CTE :
    - SELECT START_DATE.
  - ANNUAL_CTE :
    - SELECT start_date of 'pro annual' plan
  - DIFF_DAY_CTE :
    - SELECT DATEDIFF between start_date and start date of 'pro annual' plan
  - GROUP_DAY_CTE:
    - grouping  each 30 days
- Final `Select Statement`:
    - Concat and count group_day
 

```sql
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
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195551939-438a1c0b-1ce8-4d40-a661-68cac85e1113.png)


#
### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

#### SQL Query

- I want to know how many customers passed from having a pro monthyl plan (plan_id = 2) to a basic monthly plan (plan_id = 1) in the year 2020.
- I can use the LEAD() Window Function.

```sql
WITH CTE AS(SELECT *, 
        LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
FROM subscriptions
WHERE start_date <= '2020-12-31')

SELECT COUNT(*) as num_downgrade
FROM CTE 
WHERE next_plan = 1 and plan_id = 2;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195554743-e1e25d26-9ad1-4acd-b3cb-268813bd42f6.png)
