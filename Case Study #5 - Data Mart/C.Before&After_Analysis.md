# 🛒 Case Study #5 - Data Mart
<p align="right"> Using Microsoft SQL Server </p>

## 🧼 Solution - C. Before & After Analysis

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the `week_date` value of `2020-06-15` as the baseline week where the Data Mart sustainable packaging changes came into effect. We would include all `week_date` values for `2020-06-15` as the start of the period after the change and the previous week_date values would be before.

Using this analysis approach - answer the following questions:

**1. What is the total sales for the 4 weeks before and after `2020-06-15`? What is the growth or reduction rate in actual values and percentage of sales?**

Before we start, we find out the week_number of `'2020-06-15'` so that we can use it for filtering. 

````sql
SELECT  DISTINCT week_number
FROM clean_weekly_sales
WHERE week_date = '2020-06-15';
````

![image](https://user-images.githubusercontent.com/101379141/197123478-4f7eed7d-dd62-4cb1-831c-91553aa81500.png)

The week_number is 25. Then, I created  CTEs
- SUM sales CASE-WHEN 4 weeks before and after  25th week

````sql
WITH CTE AS (
        SELECT 
                SUM (CASE WHEN week_number BETWEEN 21 AND 24 THEN sales END) AS before_change,
                SUM (CASE WHEN week_number BETWEEN 25 AND 28 THEN sales END) AS after_change
        FROM clean_weekly_sales
        WHERE calendar_year = '2020' 
                AND week_number BETWEEN 21 AND 28
                )

SELECT *, 
        (after_change - before_change ) AS sale_change,
        100 * (cast(after_change as float) - before_change) / before_change as rate_change
FROM CTE ;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197123731-ff9e0c71-f43d-48e8-a763-4b48fefef38f.png)

Since the new sustainable packaging came into effect, the sales has dropped by $26,884,188 at a negative 1.146%. 
A new packaging isn't the best idea - as customers may not recognise your product's new packaging on the shelves!

***

**2. What about the entire 12 weeks before and after?**

We can apply the same logic and solution to this question. 

````sql
WITH CTE AS (
        SELECT 
                SUM (CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_change,
                SUM (CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_change
        FROM clean_weekly_sales
        WHERE calendar_year = '2020' 
                AND week_number BETWEEN 13 AND 36
                )

SELECT *, 
        (after_change - before_change ) AS sale_change,
        100 * (cast(after_change as float) - before_change) / before_change as rate_change
FROM CTE ;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197124094-cbd2ff2a-1c2e-44db-8d6c-6581e817ec14.png)

The sales has gone down even more with a negative 2.138%! 

***

**3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?**

I'm breaking down this question to 2 parts.

**Part 1: How do the sale metrics for 4 weeks before and after compare with the previous years in 2018 and 2019?**
- Basically, the question is asking us to find the sales variance between 4 weeks before and after `'2020-06-15'` for years 2018, 2019 and 2020. Perhaps we can find a pattern here.
- We can apply the same solution as above and add `calendar_year` into the syntax. 

````sql
WITH CTE_4w AS (SELECT calendar_year,
                      SUM (CASE WHEN week_number BETWEEN 21 AND 24 THEN sales END) AS before_change_4_week,
                      SUM (CASE WHEN week_number BETWEEN 25 AND 28 THEN sales END) AS after_change_4_week,
                      SUM (CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_change_12_week,
                      SUM (CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_change_12_week
                FROM clean_weekly_sales
                GROUP BY calendar_year)

SELECT calendar_year,
        before_change_4_week,
        after_change_4_week,
        (after_change_4_week - before_change_4_week ) AS sale_change_4w,
        round(100 * (cast(after_change_4_week as float) - before_change_4_week) / before_change_4_week,2) as rate_change_4w
FROM CTE_4w
order by calendar_year;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197124302-70c7617c-77b1-41d8-ab63-7c0719ebeb00.png)


We can see that in 2018 and 2019, there's a sort of consistent increase in sales in week 25 to 28 is 0.19 and 0.1 respectively 

However, after the new packaging was implemented in 2020's week 25, there was a significant drop in sales at 1.15% and compared to the previous years.

**Part 2: How do the sale metrics for 12 weeks before and after compare with the previous years in 2018 and 2019?**
- Use the same solution above and change to week 13 to 24 for before and week 25 to 36 for after.

````sql
WITH CTE_12w AS (SELECT calendar_year,
                        SUM (CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_change_12_week,
                        SUM (CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_change_12_week
                FROM clean_weekly_sales
                GROUP BY calendar_year)

SELECT calendar_year,
        before_change_12_week,
        after_change_12_week,
        (after_change_12_week - before_change_12_week ) AS sale_change_12w,
        round(100 * (cast(after_change_12_week as float) - before_change_12_week) / before_change_12_week,2) as rate_change_12w
FROM CTE_12w
order by calendar_year;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197124647-37406e33-f161-4c7f-a9a4-3bc2ec8d6bc6.png)



***

