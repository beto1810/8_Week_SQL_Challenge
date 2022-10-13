# 🥑 A. Customer Journey Solutions

<p align="right"> Using Microsoft SQL Server </p>

#
## Question
Based off the 8 sample customers provided in the sample from the subscriptions table (customer_id 1, 2, 11, 13, 15, 16, 18, 19), write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
--> I created a subscriptions_demo version

```sql
DROP TABLE IF EXISTS subscriptions_demo
CREATE TABLE subscriptions_demo (
  customer_id INTEGER,
  plan_id INTEGER,
  start_date DATE
);

INSERT INTO subscriptions_demo
  (customer_id, plan_id, start_date)
VALUES 
('1',	'0',	'2020-08-01'),
('1',	'1',	'2020-08-08'),
('2',	'0',	'2020-09-20'),
('2',	'3',	'2020-09-27'),
('11','0',	'2020-11-19'),
('11','4'	,'2020-11-26'),
('13','0',	'2020-12-15'),
('13','1'	,'2020-12-22'),
('13',	'2'	,'2021-03-29'),
('15',	'0'	,'2020-03-17'),
('15', '2'	,'2020-03-24'),
('15',	'4'	,'2020-04-29'),
('16',	'0'	,'2020-05-31'),
('16',	'1'	,'2020-06-07'),
('16',	'3'	,'2020-10-21'),
('18',	'0'	,'2020-07-06'),
('18',	'2'	,'2020-07-13'),
('19',	'0'	,'2020-06-22'),
('19',	'2'	,'2020-06-29'),
('19',	'3',	'2020-08-29');
```
#### SQL Query

- To see a customers jouney we want to SELECT the customer_id, the plan_name (to see the different plans they have subscribed to) and the start_date (to see when). 
- We can also add a column to show how long it took them to change, upgrade or cancel their subscription. 
  - For this we can use the `LAG()` Window Function:
  
    > `LAG()` let's you compare the current row to the previous row (or row above). It lets you access the value on the previous row from the current row. 

    - using  DATEDIFF(day,...) Between start_date & LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date):
      - start_date - LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) 
    - We can also add a column with the difference in MONTHS:
      - using  DATEDIFF(month,...) Between start_date & LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) 
      

```sql
SELECT s.customer_id,
       p.plan_name,
       s.start_date,
       DATEDIFF(day, LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date),start_date ) AS days_diff,
       DATEDIFF(month,LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date),start_date) as months_diff
FROM   subscriptions_demo AS s
JOIN   plans AS p
ON     s.plan_id = p.plan_id
;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195536196-a7ea92d5-800a-4898-a6d9-0c3fd7da8161.png)

- Customer 1 signed up for a free trial on the 1st of August 2020 and decided to subscribe to the basic monthly plan right after it ended. 
- Customer 2 signed up for a free trial on the 20th of September 2020 and decided to upgrade to the pro annual plan right after it ended.
- Customer 11 signed up for a free trial on the 19th of November 2020 and decided to cancel their subscription on the billing date. 
- Customer 13 signed up for a free trial on the 15th of December 2020, decided to subscribe to the basic monthly plan right after it ended and upgraded to the pro monthly plan three months later. 
- Customer 15 signed up for a free trial on the 17th of March 2020 and then decided to upgrade to the pro monthly plan right after it ended for one month before cancelling it. 
- Customer 16 signed up for a free trial on the 31st of May 2020, decided to subscribe to the basic monthly plan right after it ended and upgraded to the pro annual plan four months later.
- Customer 18 signed up for a free trial on the 6th of July 2020 and then went on to pay for the pro monthly plan right after it ended. 
- Customer 19 signed up for a free trial on the 22nd of June 2020, went on to pay for the pro monthly plan right after it ended and upgraded to the pro annual plan two months in. 
