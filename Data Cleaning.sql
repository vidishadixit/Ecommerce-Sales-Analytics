Create database Ecommerce

use Ecommerce

-- customer review table has two columns has date and timestamps- review_creation_date & review_answer_timestamp
-- review id has null

select * from Customers_review_table

-- customer unique id has some duplicate values

select customer_unique_id, count(*) from Customers_table
group by customer_unique_id
having count(*)>1

--2997 unique_ids are duplicated

select * from Customers_table
where customer_unique_id = '6223bdc5aab952ee49dea3511f89e7ec'

/*
6b83a587d5729ff8db4a0c007024d1aa	79f227df52caf2b68d36e990ff3fc652
bd3d0f3d1788cdcc21aa86f223d60b7b	79f227df52caf2b68d36e990ff3fc652

3842f59262a8439427f8fe9da5e62286	6223bdc5aab952ee49dea3511f89e7ec
7f697183db41b9bfde416dad05efc578	6223bdc5aab952ee49dea3511f89e7ec

customer_id: Changes with every order. It's the ID used in the orders table and can appear multiple times for the same customer.
customer_unique_id: Always the same for the same person, across multiple orders. This is the true unique customer ID.
*/

select order_id, count(*) from order_items_table
group by order_id
having count(*)>1
--9803 rows duplicated

select * from Order_items_table
where order_id = '390cb12cd3157360539ab0739c1b8fa9'

/*
390cb12cd3157360539ab0739c1b8fa9	1
390cb12cd3157360539ab0739c1b8fa9	2
order_id contains multiple products, each of those products will have a separate row, 
and order_item_id distinguishes them within that order.
*/

select * from orders_table

/* Order_approved_at, Order_delivered_carrier_date and order_delivered_customer_date are null and depend upon order_status column
checking that if order_status is delivered and these are null or not
*/

select order_status, count(*) from orders_table
group by order_status

/*
data flow would be 
1. created, invoiced, processing, approved, shipped, delivered
2. created, unavailable
3. created , invoiced, processing, approved, canceled

approved	2
delivered	96478
created		5
invoiced	314
processing	301
unavailable	609
canceled	625
shipped		1107
*/

--data inconsistancies check

select order_status, count(*) as inconsistency_count from orders_table
where
	   (order_status = 'delivered' AND (order_approved_at IS NULL OR order_delivered_carrier_date IS NULL OR order_delivered_customer_date IS NULL))
    OR (order_status = 'shipped' AND (order_approved_at IS NULL OR order_delivered_carrier_date IS NULL OR order_delivered_customer_date IS NOT NULL))
    OR (order_status = 'approved' AND (order_approved_at IS NULL OR order_delivered_carrier_date IS NOT NULL OR order_delivered_customer_date IS NOT NULL))
    OR (order_status = 'created' AND (order_approved_at IS NOT NULL OR order_delivered_carrier_date IS NOT NULL OR order_delivered_customer_date IS NOT NULL))
    OR (order_status = 'canceled' AND order_delivered_customer_date IS NOT NULL)
    OR (order_status = 'unavailable' AND order_delivered_customer_date IS NOT NULL)
group by order_status
order by inconsistency_count

/*
order_status	inconsistency_count
canceled		6
delivered		23
*/

SELECT *
FROM orders_table
WHERE order_status = 'canceled'
  AND order_delivered_customer_date IS NOT NULL;

-- these 6 may be mistakenly marked as canceled as all 6 rows has approved, delivered carrier and delivered customer dates.
-- changing status for the same

update orders_table
set order_status = 'delivered'
where order_status = 'canceled'
AND order_approved_at IS NOT NULL
AND order_delivered_carrier_date IS NOT NULL
AND order_delivered_customer_date IS NOT NULL;

select count(order_status) from orders_table
where order_status = 'delivered' -- before count 96478, after should be 96484

-- delivered status
SELECT *
FROM orders_table
WHERE order_status = 'delivered'
  AND (
    order_approved_at IS NULL OR
    order_delivered_carrier_date IS NULL OR
    order_delivered_customer_date IS NULL
  );

/* 23 delivered order has nulls. I'm marking as validation issues
*/ 

alter table orders_table
alter column validation_issues varchar (50)

Update orders_table
set validation_issues =

case when order_status = 'delivered' and 
	(order_approved_at is null 
	or order_delivered_customer_date is null 
	or order_delivered_carrier_date is null)
then 'Missing Data for Delivered Order'
else 'OK'
end

select * from orders_table

SELECT validation_issues, COUNT(*) AS count
FROM orders_table
GROUP BY validation_issues;

/*
validation_issues					count
OK									99418
Missing Data for Delivered Order	23
*/

select product_category_name, count(*) from products_table
group by product_category_name
order by count(*) desc

--610 are null

SELECT *
FROM products_table
WHERE product_category_name IS NULL

--a41e356c76fab66334f36de622ecbd3a

select
	o.product_id,
	p.Product_category_name
from
	Products_table P
join Order_items_table O
on P.Product_id = O.product_id
where 
	p.Product_category_name is null --1603

SELECT COUNT(DISTINCT o.product_id) AS used_null_category_products
FROM products_table p
JOIN order_items_table o
    ON p.product_id = o.product_id
WHERE p.product_category_name IS NULL; --610

/*
all 610 products are used in orders table. But don't have category. It could impact
1. Category-wise sales analysis
2. Customer behavior insights
3. Inventory or product management reports

I'm marking them as 'Uncategoriezed'
*/

UPDATE products_table
SET product_category_name = 'uncategorized'
WHERE product_category_name IS NULL;

/*Uncategorized and duplicate-like categories (e.g., appliances vs appliances_2, 
Home comfort vs Home comfort_2) may cause reporting noise. Consolidating categories.
*/

update Products_table
set product_category_name = 'appliances'
where product_category_name = 'appliances_2'

update Products_table
set product_category_name = 'Home comfort'
where product_category_name = 'Home comfort_2'
