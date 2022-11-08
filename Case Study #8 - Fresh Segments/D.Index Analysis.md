# :orange: Case Study 8 - Fresh Segments: Solution D. Index Analysis

<p align="right"> Using Microsoft SQL Server </p>

The `index_value` is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

Average composition can be calculated by dividing the `composition` column by the `index_value` column rounded to 2 decimal places.

**1. What is the top 10 interests by the average composition for each month?**


```sql
WITH CTE AS (   SELECT  month_year, 
                        interest_name,
                        CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
                FROM interest_metrics i
                LEFT JOIN interest_map i2 ON i.interest_id = i2.id
                WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (SELECT     month_year, 
                        Interest_name,
                        average_composition,
                        rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
                FROM CTE)

SELECT *
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10;
```

Example output for **2018-07-01**:

![image](https://user-images.githubusercontent.com/101379141/200462840-8cf60272-aff2-4989-9b48-503738e84c74.png)


**2. For all of these top 10 interests - which interest appears the most often?**



```sql
WITH CTE AS (   SELECT  month_year, 
                        interest_name,
                        CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
                FROM interest_metrics i
                LEFT JOIN interest_map i2 ON i.interest_id = i2.id
                WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (SELECT     month_year, 
                        Interest_name,
                        average_composition,
                        rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
                FROM CTE)

SELECT interest_name, COUNT(*) AS Count_Appearance
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10
GROUP BY interest_name
ORDER BY Count_Appearance DESC ;
```

Output: First 10 results

![image](https://user-images.githubusercontent.com/101379141/200462975-67b8a700-2a46-4456-9ff8-909afa159099.png)


**3. What is the average of the average composition for the top 10 interests for each month?**


```sql
WITH CTE AS (   SELECT  month_year, 
                        interest_name,
                        CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
                FROM interest_metrics i
                LEFT JOIN interest_map i2 ON i.interest_id = i2.id
                WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (SELECT     month_year, 
                        Interest_name,
                        average_composition,
                        rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
                FROM CTE)

SELECT month_year, AVG(average_composition) AS AVERAGE_AVG_COMP
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10
GROUP BY month_year
ORDER BY month_year;
```

Output:

![image](https://user-images.githubusercontent.com/101379141/200463420-2e50685b-419e-4842-a92b-608365afccb5.png)



**4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.**

Required output for question 4:

    <details>
    <summary>Click to expand</summary>

    | month_year | interest_name                 | max_index_composition | 3_month_moving_avg | 1_month_ago                       | 2_months_ago                      |
    | :--------- | :---------------------------- | :-------------------- | :----------------- | :-------------------------------- | :-------------------------------- |
    | 2018-09-01 | Work Comes First Travelers    | 8.26                  | 7.61               | Las Vegas Trip Planners: 7.21     | Las Vegas Trip Planners: 7.36     |
    | 2018-10-01 | Work Comes First Travelers    | 9.14                  | 8.20               | Work Comes First Travelers: 8.26  | Las Vegas Trip Planners: 7.21     |
    | 2018-11-01 | Work Comes First Travelers    | 8.28                  | 8.56               | Work Comes First Travelers: 9.14  | Work Comes First Travelers: 8.26  |
    | 2018-12-01 | Work Comes First Travelers    | 8.31                  | 8.58               | Work Comes First Travelers: 8.28  | Work Comes First Travelers: 9.14  |
    | 2019-01-01 | Work Comes First Travelers    | 7.66                  | 8.08               | Work Comes First Travelers: 8.31  | Work Comes First Travelers: 8.28  |
    | 2019-02-01 | Work Comes First Travelers    | 7.66                  | 7.88               | Work Comes First Travelers: 7.66  | Work Comes First Travelers: 8.31  |
    | 2019-03-01 | Alabama Trip Planners         | 6.54                  | 7.29               | Work Comes First Travelers: 7.66  | Work Comes First Travelers: 7.66  |
    | 2019-04-01 | Solar Energy Researchers      | 6.28                  | 6.83               | Alabama Trip Planners: 6.54       | Work Comes First Travelers: 7.66  |
    | 2019-05-01 | Readers of Honduran Content   | 4.41                  | 5.74               | Solar Energy Researchers: 6.28    | Alabama Trip Planners: 6.54       |
    | 2019-06-01 | Las Vegas Trip Planners       | 2.77                  | 4.49               | Readers of Honduran Content: 4.41 | Solar Energy Researchers: 6.28    |
    | 2019-07-01 | Las Vegas Trip Planners       | 2.82                  | 3.33               | Las Vegas Trip Planners: 2.77     | Readers of Honduran Content: 4.41 |
    | 2019-08-01 | Cosmetics and Beauty Shoppers | 2.73                  | 2.77               | Las Vegas Trip Planners: 2.82     | Las Vegas Trip Planners: 2.77     |

    </details>

    Query:

```sql
WITH CTE AS (   SELECT  month_year, 
                        interest_name,
                        CAST( composition/index_value AS FLOAT) as average_composition
                FROM interest_metrics i
                LEFT JOIN interest_map i2 ON i.interest_id = i2.id
                WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (SELECT     month_year, 
                        Interest_name,
                        average_composition,
                        rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
                FROM CTE),

MAX_CTE AS  (   SELECT  month_year,
                        interest_name,
                        ROUND(AVG(average_composition),2) AS AVERAGE_AVG_COMP
                FROM RANK_CTE
                WHERE RANK_Avg_Comp = 1
                GROUP BY month_year,interest_name
                ),

AVG_3month_CTE AS (SELECT *,
                        ROUND(AVG(AVERAGE_AVG_COMP) OVER (ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW  ),2) AS '3_month_moving_avg'
                FROM MAX_CTE),


LAG_CTE as (SELECT *,
                        ROUND(LAG(AVERAGE_AVG_COMP,1) OVER(ORDER BY month_year),2) AS '1_month',
                        ROUND(LAG(AVERAGE_AVG_COMP,2) OVER(ORDER BY month_year),2) AS '2_month',
                        CONCAT( LAG(interest_name,1) OVER(ORDER BY month_year)  , ':',LAG(AVERAGE_AVG_COMP,1) OVER(ORDER BY month_year)) AS '1_month_ago'	,
                        CONCAT( LAG(interest_name,2) OVER(ORDER BY month_year)  , ':',LAG(AVERAGE_AVG_COMP,2) OVER(ORDER BY month_year)) AS '2_month_ago'
                        FROM AVG_3month_CTE )
                
SELECT month_year,
        interest_name,
        AVERAGE_AVG_COMP,
        [1_month_ago],
        [2_month_ago]
FROM LAG_CTE
WHERE [1_month] IS NOT NULL AND [2_month] IS NOT NULL;
```
Output:

![image](https://user-images.githubusercontent.com/101379141/200463318-844f9c39-6412-4ecf-acb2-19df05b76d86.png)   |


**5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?**

- One reason for the fluctuation of Max Average Composition is demanding of customer changing by season. You can see that, The topics relavant to traveling is hot one due to hot season of traveling (end of year or summer)
