# Case Study #7: Balanced Tree Clothing Co.

<img src="https://8weeksqlchallenge.com/images/case-study-designs/7.png" alt="Image" width="300" height="300">

## 📚 Table of Contents
- [Business Task](#business-task)
- [Case Study Solution](#case-study-solution)
  - [A. High Level Sales Analysis](#a-high-level-sales-analysis)
  - [B. Transaction Analysis](#b-transaction-analysis)
  - [C. Product Analysis](#c-product-analysis)
  - [D. Bonus Challenge](#d-bonus-challenge)
- [📃 What can you practice with this case study?](#what-can-you-practice-with-this-case-study)

***

## Business Task

Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.

## Entity Relationship Diagram
For this case study there is a total of 4 datasets for this case study - however you will only need to utilise 2 main tables to solve all of the regular questions, and the additional 2 tables are used only for the bonus challenge question!

![image](https://user-images.githubusercontent.com/101379141/199987521-b92c9ea7-3aa3-499f-9480-f05b31de9b58.png)

![image](https://user-images.githubusercontent.com/101379141/199987654-65cb6974-93c2-4c17-83ba-78f0ca7af532.png)

![image](https://user-images.githubusercontent.com/101379141/199987769-fb0a7363-d025-4d15-951e-6e779b733df6.png)

![image](https://user-images.githubusercontent.com/101379141/199987882-85b57005-baa6-4dfc-8199-5b5d45c4ccc0.png)

![image](https://user-images.githubusercontent.com/101379141/199987928-3da7a54c-a7e7-4a0d-8483-4c865d7acb85.png)


## Case Study Solution

***

### A. High Level Sales Analysis

View my solution [here](https://github.com/beto1810/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/A.High%20Level%20Sales%20Analysis.md).

1. What was the total quantity sold for all products?
2. What is the total generated revenue for all products before discounts?
3. What was the total discount amount for all products?

***

### B. Transaction Analysis


View my solution [here](https://github.com/beto1810/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/B.Transaction_Analysis.md).

1. How many unique transactions were there?
2. What is the average unique products purchased in each transaction?
3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
4. What is the average discount value per transaction?
5. What is the percentage split of all transactions for members vs non-members?
6. What is the average revenue for member transactions and non-member transactions?
***

### C. Product Analysis

View my solution [here](https://github.com/beto1810/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/C.Product_Analysis.md).

1. What are the top 3 products by total revenue before discount?
2. What is the total quantity, revenue and discount for each segment?
3. What is the top selling product for each segment?
4. What is the total quantity, revenue and discount for each category?
5. What is the top selling product for each category?
6. What is the percentage split of revenue by product for each segment?
7. What is the percentage split of revenue by segment for each category?
8. What is the percentage split of total revenue by category?
9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
  

***
### D. Bonus Challenge
View my solution [here](https://github.com/beto1810/8_Week_SQL_Challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/D.Bonus%20Challenge.md).

Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

Hint: you may want to consider using a recursive CTE to solve this problem!

***
#
## What can you practice with this case study?
- Creating Tables
- JOINS
- CTE's
- Window Functions RANK
- CASE Statements
- As well as other functions, operators and clauses
- PERCENTILE_CONT 

