# :orange: Case Study 8 - Fresh Segments: Solution B. Interest Analysis

<p align="right"> Using Microsoft SQL Server </p>

**1. Which interests have been present in all `month_year` dates in our dataset?**


 ```sql
 SELECT  interest_name, 
        COUNT (month_year) AS TIME 
FROM interest_metrics i1
LEFT JOIN interest_map i2 ON i1.interest_id = i2.id 
WHERE month_year IS NOT NULL
GROUP BY  interest_name
HAVING COUNT(month_year) >= (SELECT COUNT(DISTINCT month_year) FROM interest_metrics)
ORDER BY TIME DESC ;      
 ```

 ![image](https://user-images.githubusercontent.com/101379141/200459568-5fdabdc7-0b1a-4248-a04c-f267cc2e6160.png)


    <br/>

**2. Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?**


```sql
WITH ID_CTE AS (SELECT  interest_id , 
                        COUNT(DISTINCT month_year) as total_months
                FROM interest_metrics i1
                WHERE month_year IS NOT NULL
                GROUP BY interest_id),
Month_CTE AS (  SELECT total_months,
                        CAST (COUNT(DISTINCT interest_id) AS FLOAT) as interest_count
                FROM ID_CTE
                GROUP BY total_months)
SELECT  total_months,
        interest_count,
        FORMAT ( SUM(interest_count) OVER(ORDER BY total_months DESC  ) / SUM(interest_count) OVER(), 'P') AS cumulative_percent  
FROM Month_CTE;
 ```

![image](https://user-images.githubusercontent.com/101379141/200459700-f4e5e70a-9c41-4e80-9cc2-29a58fe8d955.png)


**3. If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?**


```sql
WITH REMOVE_CTE AS (    SELECT  interest_id , 
                                COUNT(DISTINCT month_year) as total_months
                        FROM interest_metrics i1
                        WHERE month_year IS NOT NULL
                        GROUP BY interest_id
                        HAVING COUNT(DISTINCT month_year) < 6)
SELECT COUNT(*) AS data_remove
FROM interest_metrics i 
RIGHT JOIN REMOVE_CTE r ON i.interest_id = r.interest_id;

```

![image](https://user-images.githubusercontent.com/101379141/200460015-0a5d4300-d6c3-4d1d-a3f5-70c2c296f4c7.png)


**4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.**


```sql
WITH REMOVE_CTE AS (    SELECT  interest_id , 
                                COUNT(DISTINCT month_year) as total_months
                        FROM interest_metrics i1
                        WHERE month_year IS NOT NULL
                        GROUP BY interest_id
                        HAVING COUNT(DISTINCT month_year) < 6
                        ),

REMOVE_Month_CTE AS (   SELECT month_year, count(*) as total_remove
                        FROM interest_metrics i 
                        RIGHT JOIN REMOVE_CTE r ON i.interest_id = r.interest_id
                        GROUP BY month_year
                        ),

ORIGINAL_CTE AS (       SELECT month_year, count(*) as total_original
                        FROM interest_metrics i 
                        WHERE month_year is not null 
                        GROUP BY month_year 
                )

SELECT O.month_year,
        total_original,
        total_remove,
        format( cast(total_remove as float) / total_original,'p') as remove_percent
FROM ORIGINAL_CTE O
JOIN REMOVE_Month_CTE R on O.month_year = R.month_year
ORDER BY O.month_year;
```

![image](https://user-images.githubusercontent.com/101379141/200460143-4d731cbe-af40-4312-9dd1-1c5d58034478.png)

- Overall, We can see that the percent of removed month_year which have cumulative percent lower than 90% , is very low and not significant. So removing these values can increase performance by attracting customer to interest one. So it's okie to remove these one. 


**5. After removing these interests - how many unique interests are there for each month?**


```sql
WITH INTEREST_CTE AS    (SELECT interest_id , 
                                COUNT(DISTINCT month_year) as total_months
                        FROM interest_metrics i1
                        WHERE month_year IS NOT NULL
                        GROUP BY interest_id
                        HAVING COUNT(DISTINCT month_year) >= 6
                        )

SELECT month_year,
        COUNT(*) AS interest_month_cnt
FROM interest_metrics i1
RIGHT JOIN  INTEREST_CTE i2 ON I1.interest_id = I2.interest_id
WHERE month_year IS NOT NULL
GROUP BY month_year
ORDER BY month_year;
```
![image](https://user-images.githubusercontent.com/101379141/200460404-0ac74dcc-06ce-4cd4-83c0-f6096c182ab4.png)

---
