# 🐟 Case Study #7 - Balanced Tree Clothing Co.
<p align="right"> Using Microsoft SQL Server </p>

## 👩🏻‍💻 Solution - A. High Level Sales Analysis

**1. What was the total quantity sold for all products?**

````sql
SELECT SUM(qty) AS total_sold_product
FROM sales
````
![image](https://user-images.githubusercontent.com/101379141/199990351-26ec3035-bf36-4955-8a1e-781fc641e625.png)

**2. What is the total generated revenue for all products before discounts?**

````sql
SELECT SUM(qty * price) as total_revenue
FROM sales
````

![image](https://user-images.githubusercontent.com/101379141/199990537-41a3cdd9-728b-40e0-b752-48652be206cf.png)

**3.What was the total discount amount for all products?**


````sql
SELECT SUM(qty * price * (cast(discount as decimal(10,2)) /100) ) as total_discount
FROM sales
````

![image](https://user-images.githubusercontent.com/101379141/199990766-c98eb556-73f2-4586-a87b-3f48bb72b4b6.png)


***
