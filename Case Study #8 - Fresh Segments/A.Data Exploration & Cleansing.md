# :orange: Case Study 8 - Fresh Segments: Solution A. Data Exploration and Cleansing

<p align="right"> Using Microsoft SQL Server </p>


###
**1. Update the `fresh_segments.interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month**

```sql
UPDATE interest_metrics
SET month_year = CONVERT(date, '01-' + month_year,105)

ALTER TABLE interest_metrics
ALTER COLUMN month_year DATE 

```

    Output (first 5 rows):

![image](https://user-images.githubusercontent.com/101379141/200456465-476c11d4-e4c4-45e0-a3af-71a868f6bd35.png)


**2. What is count of records in the `fresh_segments.interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the null values appearing first?**

 ```sql
SELECT  month_year ,
        COUNT( *) AS total_record
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year  ;
 ```

 ![image](https://user-images.githubusercontent.com/101379141/200456843-7614d8e3-afaf-40f1-ae94-59e70fcb25d5.png)


**3. What do you think we should do with these `null` values in the `fresh_segments.interest_metrics`?**

- Dropping the rows where the month_year value is NULL could be the right things to do. 
  - Firstly, It contains 8 % of total values, it would not affect much to final result.
  - Secondly, Dropping Null values of month_year also drop the Null Values of other columns as (_month,_year,interest_id)

```sql
SELECT 100* COUNT(*) / (SELECT COUNT(*) FROM interest_metrics ) AS Percent_Null
FROM interest_metrics
WHERE month_year is NULL ;
```
![image](https://user-images.githubusercontent.com/101379141/200459187-2ffd5939-05ce-4f57-b977-7ff7a4a44535.png)


**4. How many `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map` table? What about the other way around?**

- `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map`



 ```sql
SELECT COUNT(interest_id) as Count_different_id
FROM interest_metrics 
WHERE interest_id not in (SELECT ID from interest_map) AND interest_id IS NOT NULL;
```

![image](https://user-images.githubusercontent.com/101379141/200458093-0ad89379-16b0-485b-9d07-a1fd0134a97b.png)

       

- `id` values exist in the `fresh_segments.interest_map` table but not in the `fresh_segments.interest_metrics`


 ```sql
SELECT ID
FROM interest_map 
WHERE ID not in (SELECT DISTINCT interest_id from interest_metrics WHERE interest_id IS NOT NULL);
```

![image](https://user-images.githubusercontent.com/101379141/200458175-28fe8ed2-079b-4b11-8363-7c2165defd22.png)


**5. Summarise the id values in the `fresh_segments.interest_map` by its total record count in this table**


```sql
SELECT COUNT(*) AS COUNT_ID  
FROM interest_map;
 ```

![image](https://user-images.githubusercontent.com/101379141/200458359-4712322e-4d29-4213-b9af-3f84fda742e8.png)

6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where `interest_id = 21246` in your joined output and include all columns from `fresh_segments.interest_metrics` and all columns from `fresh_segments.interest_map` except from the `id` column.

- In my opinion, we should use left join between interest_metrics and interest_map table on interest_id . Because intrest_metrics is Fact Table and its interest_id need to be included in the final table to analyze to result

   

```sql
        SELECT mat.*
            ,map.interest_name
            ,map.interest_summary
            ,map.created_at
            ,map.last_modified
        FROM fresh_segments.interest_metrics AS mat
        LEFT JOIN fresh_segments.interest_map AS map
            ON mat.interest_id = map.id
        WHERE mat.interest_id = 21246;
```

![image](https://user-images.githubusercontent.com/101379141/200458538-7eca4f54-fa0b-4edf-82ee-f5f8a362fbbc.png)


7. Are there any records in your joined table where the `month_year` value is before the `created_at` value from the fresh_segments.`interest_map` table? Do you think these values are valid and why?


 ```sql
SELECT  Count(*)
FROM interest_metrics i1 
LEFT JOIN interest_map i2 ON i1.interest_id = i2.id 
WHERE month_year < created_at;
 ```

![image](https://user-images.githubusercontent.com/101379141/200458790-8bf00a1c-c4d1-4231-b984-9b645ff5ea19.png)

 
- There are total of 188 entries in the fresh_segments.interest_map table where the month_year value is before created_at value. this is valid because month_year column has been adjusted to the first day of the month in first question , they are represented as month and year of not exactly the date it created as created_at column in interest_map.

---
