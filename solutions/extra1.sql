--The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
--Recreate the following table output using the available data:
--  customer_id	 order_date	  product_name	price	member
--  A	         2021-01-01	  curry	        15	N


CREATE VIEW dannys_diner.insights_table as 
 SELECT s.customer_id, s.order_date, m.product_name, m.price, 
 CASE 
  WHEN mem.join_date IS NOT NULL AND s.order_date >= mem.join_date then 'Y'
  ELSE 'N' 
  END as member
 FROM sales s join menu m on s.product_id = m.product_id
 left join members mem on s.customer_id = mem.customer_id
 ORDER BY s.customer_id, s.order_date, m.price DESC;

SELECT * FROM dannys_diner.insights_table;
