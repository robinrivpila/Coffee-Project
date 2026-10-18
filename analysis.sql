-- Monday Coffee -- Data Analysis
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports and Data Analysis

-- Coffee Consumer Count
-- 1. How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT city_name, (population * .25) AS estimated_coffee_consumers, city_rank
FROM city
ORDER BY (population * .25) DESC;

-- Total Revenue from Coffee Sales
-- 2. What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT city_name, SUM(total) AS total_revenue_Q4
FROM sales AS s
JOIN customers as c ON s.customer_id = c.customer_id
JOIN city AS ci ON c.city_id = ci.city_id
WHERE sale_date BETWEEN '2023-10-01' AND '2023-12-31'
GROUP BY c.city_name
ORDER BY SUM(total) DESC;

-- Sales count for each product
-- 3. How many units of each coffee product have been sold?
SELECT p.product_name, COUNT(*) AS product_sold
FROM products AS p
JOIN sales AS s ON p.product_id = s.product_id
GROUP BY product_name
ORDER BY 2 DESC;

-- Average Sales Amount per City
-- 4. What is the average sales amount per customer in each city?
SELECT ci.city_name, ROUND(SUM(s.total)/COUNT(DISTINCT(c.customer_id)),2) AS avg_sales
FROM sales AS s 
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY 2 DESC;

-- City Population and Coffee Consumers
-- 5. Provide a list of cities along with their populations and estimated coffee consumers.
SELECT c.city_name, c.population, (population * .25) AS coffee_consumers, COUNT(DISTINCT(customer_id)) AS customers_amnt
FROM city AS c
JOIN customers AS cu ON c.city_id = cu.city_id
GROUP BY city_name, 2;

-- Top Selling Products by City
-- 6. What are the top 3 selling products in each city based on sales volume?
SELECT p.product_name, c.city_name, COUNT(s.product_id) AS sale_vol_by_product 
FROM city as c
JOIN customers as cu ON c.city_id = cu.city_id
JOIN sales as s ON cu.customer_id = s.customer_id
JOIN products as p ON s.product_id = p.product_id
GROUP BY 1, 2
ORDER BY  3 DESC, 2;

-- customer Segmentation by City
-- 7. How many unique customers are there in each city who have purchased coffee products?
SELECT ci.city_name,
	COUNT(DISTINCT(c.customer_id)) AS unique_customer
FROM city AS ci
JOIN customers as c ON ci.city_id = c.city_id
JOIN sales as s ON c.customer_id = s.customer_id
WHERE product_id BETWEEN 1 AND 14
GROUP BY 1
ORDER BY 2 DESC;
		

-- Average Sale vs Rent
-- 8. Find each city and their average sale per customer and avg rent per customer
WITH city_table
AS
(
	SELECT ci.city_name, 
			SUM(s.total) AS total_sale,
			COUNT(DISTINCT(s.customer_id)) AS total_cust,
            ROUND(SUM(s.total)/COUNT(DISTINCT(c.customer_id)),2) AS avg_sales
	FROM sales AS s 
	JOIN customers AS c ON s.customer_id = c.customer_id
	JOIN city AS ci ON c.city_id = ci.city_id
	GROUP BY ci.city_name
	ORDER BY 2 DESC
),
city_rent AS
(
	SELECT city_name, estimated_rent
	FROM city
)
SELECT 
	cr.city_name,
    cr.estimated_rent,
    ct.total_cust,
    ct.avg_sales,
    ROUND(cr.estimated_rent/ct.total_cust,2) AS avg_rent_cust
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;

-- Monthly Sales Growth
-- 9. Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly). 
-- by each city
WITH 
monthly_sales AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM s.sale_date) AS month,
		EXTRACT(YEAR FROM s.sale_date) AS year,
		SUM(s.total) AS total_revenue
	FROM sales AS s
	JOIN customers AS c
		ON s.customer_id = c.customer_id
	JOIN city AS ci 
		ON c.city_id = ci.city_id
	GROUP BY 1,2,3
	ORDER BY 1,3,2
),
growth_ratio AS
(
	SELECT
		city_name,
		month,
		year, 
		total_revenue AS cur_month_sale,
		LAG(total_revenue,1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
	FROM monthly_sales
)
SELECT city_name,
		month,
        year,
        cur_month_sale,
        last_month_sale,
        ROUND(((cur_month_sale-last_month_sale)/last_month_sale)* 100,2) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
;


-- Market Potential Analysis
-- 10. Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table
AS
(
	SELECT ci.city_name, 
			SUM(s.total) AS total_sale,
			COUNT(DISTINCT(s.customer_id)) AS total_cust,
            ROUND(SUM(s.total)/COUNT(DISTINCT(c.customer_id)),2) AS avg_sales
	FROM sales AS s 
	JOIN customers AS c ON s.customer_id = c.customer_id
	JOIN city AS ci ON c.city_id = ci.city_id
	GROUP BY ci.city_name
	ORDER BY 2 DESC
),
city_rent AS
(
	SELECT 
		city_name, 
        estimated_rent, 
        ROUND((population * .25 )/1000000 ,2)AS est_coffee_consumer_in_mil
	FROM city
)
SELECT 
	cr.city_name,
    ct.total_sale,
    cr.estimated_rent,
    ct.total_cust,
    est_coffee_consumer_in_mil,
    ct.avg_sales,
    ROUND(cr.estimated_rent/ct.total_cust,2) AS avg_rent_cust
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;
