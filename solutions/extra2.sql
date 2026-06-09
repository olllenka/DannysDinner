--view with ranking
--Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

CREATE VIEW dannys_diner.insights_table_with_ranking as 
 SELECT customer_id, order_date, product_name, price, member,
 CASE
  WHEN member = 'N' then NULL
  ELSE DENSE_RANK() OVER (partition by customer_id, member order by order_date) 
  END as ranking
 from insights_table; 

SELECT * FROM dannys_diner.insights_table_with_ranking;
