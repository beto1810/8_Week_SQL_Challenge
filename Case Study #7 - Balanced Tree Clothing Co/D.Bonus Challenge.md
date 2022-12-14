#  👕 Case Study #7 - Balanced Tree Clothing Co.
<p align="right"> Using Microsoft SQL Server </p>

## 👩🏻‍💻 Solution - D. Bonus Challenge

Use a single SQL query to transform the `product_hierarchy` and `product_prices` datasets to the `product_details` table.

Hint: you may want to consider using a recursive CTE to solve this problem!

I did not use CTEs here, just consequent self joins on `parent_id` and `id` columns. The `product_name` column is generated by the `concat()` function.

```sql
SELECT  product_id,
        price,
        CONCAT(p.level_text, ' ', p1.level_text, ' - ', p2.level_text) AS product_name,
        p2.id AS category_id,
        p1.id AS segment_id,
        p.id AS style_id,
        p2.level_text AS category_name,
        p1.level_text AS segment_name,
        p.level_text AS style_name
FROM product_hierarchy AS p
JOIN product_hierarchy AS p1 on p.parent_id = p1.id
JOIN product_hierarchy AS p2 on p1.parent_id = p2.id
JOIN product_prices AS pp on p.id = pp.id
```
- In the First join - it filtered itself between parent_id and id to show the parent_id showing 2 types of category
![image](https://user-images.githubusercontent.com/101379141/200005340-e2237d0b-4640-4383-8040-9ecb059301dc.png)

- In the second join - to show the Category types and Segment types
![image](https://user-images.githubusercontent.com/101379141/200005889-93b8ab35-06c1-4d6f-b04b-af1760665328.png)

- In the final join - to filter the product_id and price and selected relevant column

![image](https://user-images.githubusercontent.com/101379141/200004368-8f284c2c-7754-48f7-8f97-c4a714b742b6.png)
