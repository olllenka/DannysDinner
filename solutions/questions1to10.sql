/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

--1
select customer_id, sum(price) total_spending
from sales s join menu m on s.product_id = m.product_id
group by customer_id
order by total_spending;

--2
select customer_id, count(distinct order_date) days
from sales
group by customer_id
order by customer_id;

--3
WITH ranked_sales AS (
    SELECT 
        s.customer_id,
        m.product_name,
        s.order_date,
        DENSE_RANK() OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.order_date ASC
        ) as rnk
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m 
        ON s.product_id = m.product_id
)
SELECT 
    customer_id,
    product_name
FROM ranked_sales
WHERE rnk = 1
GROUP BY customer_id, product_name;

--4 What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id) orders
from sales s join menu m on s.product_id = m.product_id
group by m.product_name
order by orders desc
limit 1;

--5 Which item was the most popular for each customer?
WITH product_counts AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(s.product_id) AS order_count
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m 
        ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
),
ranked_products AS (
    SELECT 
        customer_id,
        product_name,
        order_count,
        DENSE_RANK() OVER (
            PARTITION BY customer_id 
            ORDER BY order_count DESC
        ) AS rnk
    FROM product_counts
)
SELECT 
    customer_id,
    product_name,
    order_count
FROM ranked_products
WHERE rnk = 1;

with 
 orders_count as (
  select s.customer_id, m.product_name, count(s.product_id) order_count
  from sales s join menu m on s.product_id = m.product_id
  group by customer_id, product_name
  order by customer_id, order_count desc
 ),
 orders_rank as (
  select customer_id, product_name, order_count,
  dense_rank() over (partition by customer_id order by order_count desc) as rnk
  from orders_count
 )
select customer_id, product_name, order_count
from orders_rank
where rnk = 1

--6 Which item was purchased first by the customer after they became a member?
with ranked_order_as_member as (
select s.customer_id, m.product_name, 
order_date, join_date,
dense_rank() over (partition by s.customer_id order by s.order_date) rnk
from sales s 
 join menu m on s.product_id = m.product_id
 join members mem on s.customer_id = mem.customer_id
 where s.order_date >= mem.join_date
)
select customer_id, product_name
from ranked_order_as_member
where rnk = 1;

--7 Which item was purchased just before the customer became a member?
with ranked_order_before_member as (
select s.customer_id, m.product_name, 
order_date, join_date,
row_number() over (partition by s.customer_id order by s.order_date desc, product_name) rnk
from sales s 
 join menu m on s.product_id = m.product_id
 join members mem on s.customer_id = mem.customer_id
 where s.order_date < mem.join_date
)
select customer_id, product_name
from ranked_order_before_member
where rnk = 1;

--8 What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(s.product_id) total_items, sum(m.price) total_amount
from sales s 
 join menu m on s.product_id = m.product_id
 join members mem on s.customer_id = mem.customer_id
where s.order_date < mem.join_date
group by s.customer_id
order by customer_id

--9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with lost_points_before_member as (
select s.customer_id, m.product_name, 
order_date, join_date,
case
 when m.product_name = 'sushi' then m.price * 20
 else m.price * 10
 end as points
from sales s 
 join menu m on s.product_id = m.product_id
 join members mem on s.customer_id = mem.customer_id
 where s.order_date < mem.join_date
)
select customer_id, sum(points)
from lost_points_before_member
group by customer_id;

--shorter with 'case when' inside sum()
select s.customer_id, 
sum(case
 when m.product_name = 'sushi' then m.price * 20
 else m.price * 10
 end) as points
from sales s 
 join menu m on s.product_id = m.product_id
 join members mem on s.customer_id = mem.customer_id
where s.order_date < mem.join_date
group by s.customer_id;

--10 In the first week after a customer joins the program (including their join date) they earn 2x points on all 
--items, not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id, 
sum(case
 when s.order_date < (mem.join_date + 7) then m.price * 20
 when m.product_name = 'sushi' then m.price * 20
 else m.price * 10
 end) as points
from sales s 
 join menu m on s.product_id = m.product_id
 join members mem on s.customer_id = mem.customer_id
where s.order_date >= mem.join_date and s.order_date <= '2021-01-31'
group by s.customer_id;

WITH filtered_sales AS (
    SELECT 
        s.customer_id,
        s.order_date,
        mem.join_date,
        m.product_name,
        m.price
    FROM dannys_diner.sales s 
    JOIN dannys_diner.menu m 
        ON s.product_id = m.product_id
    JOIN dannys_diner.members mem 
        ON s.customer_id = mem.customer_id
    WHERE s.order_date >= mem.join_date 
      AND s.order_date <= '2021-01-31'
),
calculated_points AS (
    SELECT 
        customer_id,
        CASE
            WHEN order_date < (join_date + 7) THEN price * 20
            WHEN product_name = 'sushi' THEN price * 20
            ELSE price * 10
        END AS points
    FROM filtered_sales
)
SELECT 
    customer_id,
    SUM(points) AS total_points
FROM calculated_points
GROUP BY customer_id
ORDER BY customer_id;