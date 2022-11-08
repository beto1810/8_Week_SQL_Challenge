# :orange: Case Study 8 - Fresh Segments: Solution C. Segment Analysis

<p align="right"> Using Microsoft SQL Server </p>

**1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any `month_year`? Only use the maximum composition value for each interest but you must keep the corresponding `month_year`**

- Let's create the filtered (sub_metrics) table first

```sql

DROP TABLE IF EXISTS sub_metrics;

WITH REMOVE_CTE AS    (SELECT interest_id , 
                                COUNT(DISTINCT month_year) as total_months
                        FROM interest_metrics i1
                        WHERE month_year IS NOT NULL
                        GROUP BY interest_id
                        HAVING COUNT(DISTINCT month_year) < 6
                        )
SELECT i.*
INTO sub_metrics 
FROM interest_metrics i
WHERE I.interest_id NOT IN (SELECT interest_id FROM REMOVE_CTE )

```

- Top 10 which have the largest composition values in any month_year ?

```sql
SELECT top 10 month_year, interest_name, composition
FROM sub_metrics s
LEFT JOIN interest_map  i ON S.interest_id = I.id
WHERE month_year is not null 
ORDER BY composition DESC ;
```

Result:

![image](https://user-images.githubusercontent.com/101379141/200461616-8bfaa39f-40fe-436f-91f8-526ee8240cc0.png)

- Bottom 10 interests which have the largest composition values in any month_year?


```sql
SELECT top 10 month_year, interest_name, composition
FROM sub_metrics s
LEFT JOIN interest_map  i ON S.interest_id = I.id
WHERE month_year is not null 
ORDER BY composition ;
```

Result:

![image](https://user-images.githubusercontent.com/101379141/200461758-4a7f96a7-dcd5-46dc-944e-3019e00c965f.png)


**2. Which 5 interests had the lowest average ranking value?**


```sql
SELECT top 5 interest_name, AVG(ranking) AS AVERAGE_RANK 
FROM sub_metrics s
LEFT JOIN interest_map  i ON S.interest_id = I.id
WHERE month_year is not null 
GROUP BY interest_name
ORDER BY AVERAGE_RANK DESC  ;
```

Output:
![image](https://user-images.githubusercontent.com/101379141/200461891-45a641cf-931f-489e-b5d4-9cf0219ce2bd.png)

**3. Which 5 interests had the largest standard deviation in their `percentile_ranking` value?**


```sql
SELECT  top 5 interest_name, 
        ROUND(STDEV(percentile_ranking),2) AS STD_DEV_ranking 
FROM sub_metrics s
LEFT JOIN interest_map  i ON S.interest_id = I.id
WHERE month_year is not null 
GROUP BY interest_name
ORDER BY STD_DEV_ranking DESC    ;
```

Output:
![image](https://user-images.githubusercontent.com/101379141/200462094-ca95ead6-2264-46c7-98e7-0aba5082d778.png)


**4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?**

- Because these 5 interest_name has the highest standard deviation so, the gap between max and min of their percentile_ranking is really large, and decrease dramatically by time . For example : percentile ranking of Techies peeked at 86.69 , but it fell to the lowest point with 7.92.

```sql
WITH TOP_5_CTE AS (     SELECT  TOP 5 interest_name, 
                                ROUND(STDEV(percentile_ranking),2) AS STD_DEV_ranking 
                        FROM sub_metrics s
                        LEFT JOIN interest_map  i ON S.interest_id = I.id
                        WHERE month_year is not null 
                        GROUP BY interest_name
                        ORDER BY STD_DEV_ranking DESC  ),

MIN_MAX_CTE AS (SELECT  month_year, 
                        interest_name,
                        percentile_ranking,
                        MAX(percentile_ranking) OVER(PARTITION BY interest_name   ) AS MAX_VALUE,
                        MIN(percentile_ranking) OVER(PARTITION BY interest_name  ) AS MIN_VALUE
                FROM sub_metrics s
                LEFT JOIN interest_map  i ON S.interest_id = I.id
                WHERE interest_name in (SELECT interest_name FROM TOP_5_CTE) 
                )

SELECT  month_year, 
        interest_name,
        percentile_ranking
FROM MIN_MAX_CTE 
WHERE  percentile_ranking = MAX_VALUE OR percentile_ranking  = MIN_VALUE      
ORDER BY interest_name,percentile_ranking DESC ;
```

Output:

![image](https://user-images.githubusercontent.com/101379141/200462361-544b97f5-75a5-4a33-921d-b813774a51db.png)


**5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?**

- In overall, I can make a conclusion that the customer have a high interest in traveling and buying luxury furniture  in interms of composition value and ranking. So increasing the the presence of advertising about these top interest topics is valuable step for increasing of performance.
- By the way, excluding the topics like Astrology or Video Games or limit their presence would bring positive performance for company. 

---
