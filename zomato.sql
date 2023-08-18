/* 1. customers who have never ordered */

SELECT
  user_id,
  name,
  email
FROM
  zomato.users
WHERE
  user_id NOT IN (
  SELECT
    DISTINCT user_id
  FROM
    zomato.orders)

/* 2. Average Price per Dish */

SELECT
  f.f_name,
  AVG(m.price) AS average_price
FROM
  zomato.menu m
JOIN
  zomato.food f
ON
  m.f_id = f.f_id
GROUP BY
  f.f_name


  
/* 3. Top restaurant in terms of number of orders in a given month */

WITH
  monthly_orders AS (
  SELECT
    r_name,
    FORMAT_DATETIME("%B", DATETIME(o.date)) AS month_name,
    COUNT(*) AS order_num
  FROM
    zomato.orders o
  JOIN
    zomato.restaurants r
  ON
    o.r_id = r.r_id
  GROUP BY
    r_name,
    month_name)
SELECT
  r_name,
  month_name
FROM (
  SELECT
    *,
    MAX(order_num) OVER(PARTITION BY month_name) AS max_count
  FROM
    monthly_orders
  ORDER BY
    month_name)
WHERE
  order_num = max_count


  
/* 4. Restaurants with monthly sales greater than 500 */

SELECT
  r.r_name,
  SUM(amount) AS total,
  FORMAT_DATETIME("%B", DATETIME(date)) AS month_name
FROM
  zomato.orders o
JOIN
  zomato.restaurants r
ON
  o.r_id = r.r_id
GROUP BY
  r.r_name,
  month_name
HAVING
  total > 500


  
/* 5. Show all order details for each customer between 11th Jun and 9th July */

SELECT
  u.name,
  o.date,
  r.r_name,
  f.f_name
FROM
  zomato.orders o
JOIN
  zomato.users u
ON
  o.user_id = u.user_id
JOIN
  zomato.order_details od
ON
  o.order_id = od.order_id
JOIN
  zomato.food f
ON
  od.f_id = f.f_id
JOIN
  zomato.restaurants r
ON
  r.r_id = o.r_id
WHERE
  (o.date > '2022-06-10'
    AND o.date < '2022-07-10')



/* 6. Find the restaurant with max repeated customers. */

SELECT
  r_name,
  COUNT(*) AS loyal_customers
FROM (
  SELECT
    DISTINCT user_id,
    r_id,
    COUNT(*) AS visits
  FROM
    zomato.orders
  GROUP BY
    user_id,
    r_id
  HAVING
    COUNT(*)> 1) t
JOIN
  zomato.restaurants r
ON
  t.r_id = r.r_id
GROUP BY
  r_name
ORDER BY
  loyal_customers
LIMIT
  1


  
/* 7. Find most loyal customers for each restaurant */

WITH
  cte AS (
  SELECT
    DISTINCT u.name,
    r_name,
    COUNT(*) AS visits
  FROM
    zomato.orders o
  JOIN
    zomato.users u
  ON
    o.user_id = u.user_id
  JOIN
    zomato.restaurants r
  ON
    o.r_id = r.r_id
  GROUP BY
    u.name,
    r_name )
SELECT
  name,
  r_name,
  visits
FROM (
  SELECT
    *,
    MAX(visits) OVER(PARTITION BY r_name) AS most_visited
  FROM
    cte)
WHERE
  visits = most_visited


  
  /* 8. Find month on month revenue growth of zomato */

WITH
  Sales AS (
  SELECT
    FORMAT_DATETIME("%B", DATETIME(date)) AS month,
    SUM(amount) AS revenue
  FROM
    zomato.orders
  GROUP BY
    month
  ORDER BY
    month DESC)
SELECT
  *,
  ((revenue-prev)/prev)*100 AS growth
FROM (
  SELECT
    *,
    LAG(revenue) OVER(ORDER BY month DESC) AS prev
  FROM
    Sales
  ORDER BY
    month DESC)


  
/* 9. Find month on month growth of each restaurant */

WITH
  sales AS (
  SELECT
    r_name,
    FORMAT_DATETIME("%B", DATETIME(date)) AS month,
    SUM(amount) AS total
  FROM
    zomato.orders o
  JOIN
    zomato.restaurants r
  ON
    o.r_id = r.r_id
  GROUP BY
    r_name,
    month
  ORDER BY
    month DESC,
    r_name)
SELECT
  *,
  ROUND(((total-prev)/prev)*100,4)
FROM (
  SELECT
    *,
    LAG(total) OVER(PARTITION BY r_name ORDER BY month DESC) AS prev
  FROM
    sales)
  


/* 10. Favourite food of each customer. */

WITH
  cte AS (
  SELECT
    name,
    f_name
  FROM
    zomato.users u
  JOIN
    zomato.orders o
  ON
    u.user_id = o.user_id
  JOIN
    zomato.order_details od
  ON
    o.order_id = od.order_id
  JOIN
    zomato.food f
  ON
    od.f_id = f.f_id),
  cte1 AS (
  SELECT
    DISTINCT name,
    f_name,
    COUNT(f_name) OVER(PARTITION BY name, f_name) AS order_count,
  FROM
    cte)
SELECT
  name,
  f_name
FROM (
  SELECT
    *,
    MAX(order_count) OVER(PARTITION BY name) AS max_count
  FROM
    cte1)
WHERE
  order_count = max_count


