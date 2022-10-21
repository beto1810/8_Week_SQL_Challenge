# 🛒 Case Study #5 - Data Mart

## 🛍 Solution - B. Data Exploration

**1. What day of the week is used for each week_date value?**

````sql
SELECT DISTINCT DATENAME(WEEKDAY,week_date) AS week_day
FROM clean_weekly_sales;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197109445-4a468c99-a609-4d7a-ad74-14676c240729.png)

- Monday is used for each `week_date` value.

**2. What range of week numbers are missing from the dataset?**

- First, generate the full range of week numbers for the entire year from 1st week to 52nd week.
- Secondly, select week include in data mart.
- Then, do a LEFT  JOIN of `numbers_week` with `WEEK_data` 

````sql
WITH numbers_week AS (
      SELECT 52 as week_number_year
      UNION all
      SELECT week_number_year - 1
      FROM numbers_week
      WHERE week_number_year > 1
     ),

WEEK_data as (
    SELECT DISTINCT week_number
    FROM clean_weekly_sales)

SELECT COUNT(*) AS missing_weeks
FROM numbers_week w1 
LEFT JOIN WEEK_data w2 ON w1.week_number_year = w2.week_number
WHERE week_number is NULL;

````

**Answer:**


![image](https://user-images.githubusercontent.com/101379141/197109844-466eac62-4263-4c3c-ba92-cd9c01716e31.png)

- 28 `week_number`s are missing from the dataset.

**3. How many total transactions were there for each year in the dataset?**

````sql
SELECT DISTINCT calendar_year, 
        SUM(transactions) AS total_transaction
FROM clean_weekly_sales
GROUP BY calendar_year;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197109933-506ec541-7698-4a66-9728-08d25b9b13c2.png)

**4. What is the total sales for each region for each month?**

 - ALTER COLUMN type to Bigint 

````sql
ALTER TABLE clean_weekly_sales
ALTER COLUMN sales BIGINT 

SELECT  region,
        month_number,
        SUM (sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region,month_number
ORDER BY region,month_number

````

**Answer:**


![image](https://user-images.githubusercontent.com/101379141/197110422-54263c7a-09c7-45b6-a6cb-d01f26c6a34e.png)

**5. What is the total count of transactions for each platform?**

````sql
SELECT platform,
        COUNT(transactions) as total_transaction
FROM clean_weekly_sales
GROUP BY platform
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197110509-1979ca8f-d0bc-4477-b7b0-ec82b6aa2123.png)
**6. What is the percentage of sales for Retail vs Shopify for each month?**

````sql
SELECT DISTINCT platform,  
        calendar_year,
        month_number,
        SUM(sales) OVER (PARTITION BY month_number,calendar_year,platform order by platform  ) as sale_monthly,
        100 * CAST(SUM(sales) OVER (PARTITION BY month_number,calendar_year,platform order by platform  ) AS FLOAT)  
            /  (SUM(sales) OVER (PARTITION BY calendar_year,platform order by platform  )) AS Percent_sales_monthly
FROM clean_weekly_sales
order by platform,calendar_year,month_number;

````

**Answer:**

_The results came up to 40 rows, so I'm only showing 20 of them. 

![image](https://user-images.githubusercontent.com/101379141/197110627-2a43c46c-e030-48ab-9c90-b1fd351af276.png)

**7. What is the percentage of sales by demographic for each year in the dataset?**

````sql
SELECT DISTINCT demographic,
        calendar_year,
        SUM(sales) OVER (PARTITION BY calendar_year, demographic order by demographic) AS total_sale,
        100 * CAST(SUM(sales) OVER (PARTITION BY calendar_year, demographic order by demographic) AS FLOAT)
        /  SUM(sales) OVER (PARTITION BY calendar_year) AS percent_sale
FROM clean_weekly_sales
ORDER BY demographic, calendar_year;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197110857-edbd9e6e-768a-4859-9197-dc3e9046a562.png)

**8. Which age_band and demographic values contribute the most to Retail sales?**

````sql
SELECT DISTINCT age_band, 
        demographic,
        SUM(sales) OVER (PARTITION BY age_band,demographic) as total_sale,
        100 * CAST(SUM(sales) OVER (PARTITION BY age_band,demographic) AS FLOAT)
        / (SELECT SUM(sales) from clean_weekly_sales) AS percent_sale
FROM clean_weekly_sales
ORDER BY percent_sale DESC;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197110942-fc65b9b7-b60b-43f5-8b0f-c3764884be22.png)


**9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?**

````sql
SELECT platform, 
        calendar_year, 
        AVG(avg_transaction) as avg_transaction_row,
        SUM(sales) / sum(transactions) AS avg_transaction_group
FROM clean_weekly_sales
GROUP BY platform, calendar_year
ORDER BY platform,calendar_year;
````

**Answer:**

![image](https://user-images.githubusercontent.com/101379141/197111827-4380dfbf-f765-4846-bdb8-b12660888569.png)

What's the difference between `avg_transaction_row` and `avg_transaction_group`?
- `avg_transaction_row` is the average transaction in dollars by taking each row's sales divided by the row's number of transactions.
- `avg_transaction_group` is the average transaction in dollars by taking total sales divided by total number of transactions for the entire data set.

The more accurate answer to find average transaction size for each year by platform would be `avg_transaction_group`.

***

