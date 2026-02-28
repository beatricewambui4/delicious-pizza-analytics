CREATE DATABASE DELICIOUS_PIZZA_ANALYTICS;
USE DELICIOUS_PIZZA_ANALYTICS;

#create a table for the above database
CREATE TABLE DELICIOUS_PIZZA_ANALYTICS_TABLE(
pizza_id INT,	
order_id	INT,
pizza_name_id	VARCHAR(100),
quantity	INT,
order_date	DATE,
order_time	TIME,
unit_price	DECIMAL(10,2),
total_price	DECIMAL(10,2),
pizza_size	VARCHAR(5),
pizza_category	VARCHAR(50),
pizza_ingredients	VARCHAR(5000),
pizza_name VARCHAR(50)
);

#insert data into the database
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/pizza_sales_excel_file.csv"
INTO TABLE DELICIOUS_PIZZA_ANALYTICS_TABLE
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS(
pizza_id,	
    order_id,	
    pizza_name_id,	
    quantity,	
    @order_date,
    @order_time,	
    @unit_price,	
    @total_price,
    pizza_size,
    pizza_category,	
    pizza_ingredients,	
    pizza_name
)
SET 
    order_date = CASE
                    WHEN @order_date = '' THEN NULL
                    ELSE STR_TO_DATE(@order_date, '%m/%d/%Y')
                 END,
order_time = CASE
                    WHEN @order_time = '' THEN NULL
                    ELSE STR_TO_DATE(@order_time, '%h:%i:%s %p')
                 END,
                 
    unit_price = CASE
                    WHEN @unit_price = '' THEN NULL
                    ELSE CAST(
                            REPLACE(REPLACE(TRIM(@unit_price), '$', ''), ',', '')
                         AS DECIMAL(10,2))
                 END,
    total_price = CASE
                    WHEN @total_price = '' THEN NULL
                    ELSE CAST(
                            REPLACE(REPLACE(TRIM(@total_price), '$', ''), ',', '')
                         AS DECIMAL(10,2))
                 END;

#understanding the data first before querying it
SELECT * FROM delicious_pizza_analytics_table;

#Querying the data
#Revenue Overview
#What is the total revenue generated over the entire year?
SELECT
SUM(total_price) AS Total_Revenue
FROM delicious_pizza_analytics_table;

#What is the average order value (total revenue ÷ number of unique orders)?
SELECT
SUM(total_price)/COUNT(DISTINCT order_id) AS Average_Order_Value
FROM delicious_pizza_analytics_table;

#How many total pizzas were sold? 
SELECT
SUM(quantity) AS Total_Pizza_Sold
FROM delicious_pizza_analytics_table;

#How many unique orders were placed?
SELECT
COUNT(DISTINCT order_id) AS Unique_Orders_Placed
FROM delicious_pizza_analytics_table;

#What is the average number of pizzas per order?
SELECT
SUM(quantity)/COUNT(DISTINCT order_id) AS Average_Pizza_per_order
FROM delicious_pizza_analytics_table;

#Sales Trends Over Time
#What are the monthly revenue totals? 
SELECT
MONTHNAME(order_date) AS Month_Name,
SUM(total_price) AS Total_Revenue_Per_Month
FROM delicious_pizza_analytics_table
GROUP BY Month_Name;

#Which month performed best and worst?
SELECT
SUM(total_price) AS Total_Revenue,
MONTHNAME(order_date) AS Month_Name
FROM delicious_pizza_analytics_table
GROUP BY Month_Name
ORDER BY Total_Revenue DESC
LIMIT 1;

#Which day of the week generates the highest number of orders? 
SELECT
SUM(total_price) AS Total_Revenue,
DAYNAME(order_date) AS Day_Name
FROM delicious_pizza_analytics_table
GROUP BY Day_Name
ORDER BY Total_Revenue DESC
LIMIT 1; 

#Which day of the week generates the lowest number of orders
SELECT
SUM(total_price) AS Total_Revenue,
DAYNAME(order_date) AS Day_Name
FROM delicious_pizza_analytics_table
GROUP BY Day_Name
ORDER BY Total_Revenue
LIMIT 1;

#During which hour of the day are the most orders placed? 
SELECT
HOUR(order_time) AS Hour_Name,
SUM(total_price) AS Total_Hour_Revenue
FROM delicious_pizza_analytics_table
GROUP BY Hour_Name
ORDER BY Total_Hour_Revenue DESC
LIMIT 1;

#Plot or describe the distribution across the day.
SELECT
SUM(total_price) Total_Revenue,
COUNT(DISTINCT order_id) AS Total_Orders,
HOUR(order_time) Hour_of_Day
FROM delicious_pizza_analytics_table
GROUP BY Hour_of_Day
ORDER BY Total_Revenue DESC;

#Pizza Performance
#What are the top 5 best-selling pizzas by quantity sold?
SELECT
SUM(quantity) AS Quantity_Sold,
pizza_name
FROM delicious_pizza_analytics_table
GROUP BY pizza_name
ORDER BY Quantity_Sold DESC
LIMIT 5;
#What are the bottom 5 worst-selling pizzas by quantity sold?
SELECT
pizza_name,
SUM(total_price) AS Quantity_Sold
FROM delicious_pizza_analytics_table
GROUP BY pizza_name
ORDER BY Quantity_Sold
LIMIT 5;

#Which pizza generates the most revenue? 
SELECT
pizza_name,
SUM(total_price) AS Total_Revenue
FROM delicious_pizza_analytics_table
GROUP BY pizza_name
ORDER BY Total_Revenue DESC
LIMIT 1;

#Which generates the least?
SELECT
pizza_name,
SUM(total_price) AS Total_Revenue
FROM delicious_pizza_analytics_table
GROUP BY pizza_name
ORDER BY Total_Revenue 
LIMIT 1;
#Are the best-sellers by quantity also the best-sellers by revenue, or do they differ? What might explain any differences?
WITH BY_Quantity_Sold AS (
SELECT
SUM(quantity) AS Quantity_Sold,
pizza_name,
RANK() OVER(ORDER BY SUM(quantity) DESC) AS Quantity_Rank
FROM delicious_pizza_analytics_table
GROUP BY pizza_name
),
BY_Total_Revenue AS(
		SELECT
		pizza_name,
		SUM(total_price) AS Total_Revenue,
        RANK() OVER(ORDER BY SUM(total_price) DESC) AS Revenue_Rank
		FROM delicious_pizza_analytics_table
		GROUP BY pizza_name
)

SELECT
qs.pizza_name,
qs.Quantity_Sold,
tr.pizza_name,
tr.Total_Revenue
FROM BY_Quantity_Sold qs
JOIN BY_Total_Revenue tr
ON qs.Quantity_Rank=1 AND Revenue_Rank=1;

#Category & Size Analysis
#What percentage of total sales does each pizza category (e.g., Classic, Veggie, Chicken, Supreme) contribute?
WITH Total_Revenue AS(
SELECT
SUM(total_price) AS Total_Sales
FROM delicious_pizza_analytics_table
),
Revenue_By_Category AS (
SELECT
SUM(total_price) AS Sales_per_Category,
pizza_category
FROM delicious_pizza_analytics_table
GROUP BY pizza_category
)

SELECT
pizza_category,
(Sales_per_Category/Total_Sales)*100 AS Percentage_Sales_Per_Category
FROM Total_Revenue, Revenue_By_Category
ORDER BY Percentage_Sales_Per_Category DESC;

#What is the most popular pizza size by number of orders? 
SELECT
COUNT(DISTINCT order_id) AS Total_Orders,
pizza_size
FROM delicious_pizza_analytics_table
GROUP BY pizza_size
ORDER BY Total_Orders DESC
LIMIT 1;

#Does this change when you look at revenue instead of quantity?
WITH BY_Revenue AS (
SELECT 
SUM(total_price) AS Total_Revenue,
pizza_size,
RANK() OVER(ORDER BY SUM(total_price) DESC) Revenue_Rank
FROM delicious_pizza_analytics_table
GROUP BY pizza_size
),
BY_Quantity_Sold AS (
SELECT
COUNT(DISTINCT order_id) AS Total_Orders,
pizza_size,
RANK() OVER(ORDER BY COUNT(DISTINCT order_id) DESC) AS Quantity_Rank
FROM delicious_pizza_analytics_table
GROUP BY pizza_size
)
SELECT
br.pizza_size,
br.Total_Revenue,
qs.pizza_size,
qs.Total_Orders
FROM BY_Revenue br
JOIN BY_Quantity_Sold qs
ON br.Revenue_Rank=1 AND qs.Quantity_Rank=1;

#Which category has the highest average unit price?
SELECT
AVG(unit_price) AS Average_Unit_Price,
pizza_category
FROM delicious_pizza_analytics_table
GROUP BY pizza_category
ORDER BY Average_Unit_Price DESC
LIMIT 1;

#Ingredient Intelligence
#What are the top 10 most frequently used ingredients across all pizzas sold (weighted by quantity)?
WITH Exploded AS (
    SELECT
        TRIM(ingredient.value) AS Single_Ingredient,
        quantity
    FROM delicious_pizza_analytics_table,
    JSON_TABLE(
        CONCAT('["', REPLACE(pizza_ingredients, ', ', '","'), '"]'),
        '$[*]' COLUMNS (value VARCHAR(100) PATH '$')
    ) AS ingredient
)
SELECT
    Single_Ingredient,
    SUM(quantity) AS Total_Times_Used
FROM Exploded
GROUP BY Single_Ingredient
ORDER BY Total_Times_Used DESC
LIMIT 10;

#Are there any ingredients that appear exclusively in low-selling pizzas? What might this suggest?
WITH Pizza_Sales AS (
    SELECT
        pizza_name,
        SUM(quantity) AS Total_Quantity
    FROM delicious_pizza_analytics_table
    GROUP BY pizza_name
),
Low_Sellers AS (
    SELECT pizza_name
    FROM Pizza_Sales
    ORDER BY Total_Quantity ASC
    LIMIT 5
),
All_Ingredients AS (
    SELECT
        TRIM(ingredient.value) AS Single_Ingredient,
        pizza_name
    FROM delicious_pizza_analytics_table,
    JSON_TABLE(
        CONCAT('["', REPLACE(pizza_ingredients, ', ', '","'), '"]'),
        '$[*]' COLUMNS (value VARCHAR(100) PATH '$')
    ) AS ingredient
    GROUP BY Single_Ingredient, pizza_name
),
Low_Seller_Ingredients AS (
    SELECT DISTINCT ai.Single_Ingredient
    FROM All_Ingredients ai
    JOIN Low_Sellers ls ON ai.pizza_name = ls.pizza_name
),
High_Seller_Ingredients AS (
    SELECT DISTINCT ai.Single_Ingredient
    FROM All_Ingredients ai
    WHERE ai.pizza_name NOT IN (SELECT pizza_name FROM Low_Sellers)
)
SELECT
    lsi.Single_Ingredient AS Exclusive_Low_Seller_Ingredient
FROM Low_Seller_Ingredients lsi
LEFT JOIN High_Seller_Ingredients hsi
    ON lsi.Single_Ingredient = hsi.Single_Ingredient
WHERE hsi.Single_Ingredient IS NULL;






