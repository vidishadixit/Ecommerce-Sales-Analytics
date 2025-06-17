
/*
How much total money has the platform made so far, and how has it changed over time?
Which product categories are the most popular, and how do their sales numbers compare?
What is the average amount spent per order, and how does it change depending on the product category or payment method?
How many active sellers are there on the platform, and does this number go up or down over time?
Which products sell the most, and how have their sales changed over time?
Do customer reviews and ratings help products sell more or perform better on the platform? 
(Check sales with higher or lower ratings and identify if any correlation is there)
*/

use Ecommerce

select * from Customers_review_table
select * from Customers_table
select * from Order_items_table
select * from Orders_table
select * from Payments_table
select * from Products_table
select * from Sellers_table

-- 1. How much total money has the platform made so far, and how has it changed over time?


select 
	round(sum(P.Payment_value),2) as monthly_revenue,
	format(o.order_purchase_timestamp, 'yyyy-MM') as month
from
	Orders_table O
join Payments_table P
on O.Order_id = P.Order_id
where O.Order_status = 'delivered' and validation_issues = 'ok'
group by format(o.order_purchase_timestamp, 'yyyy-MM')
order by month

select
	pt.Product_category_name,
	round(sum(P.Payment_value),2) as monthly_revenue
from
	Orders_table O
join Payments_table P
on O.Order_id = P.Order_id
join Order_items_table OT  on ot.order_id=O.order_id
join Products_table PT on pt.product_id = ot.product_id
where O.Order_status = 'delivered' and validation_issues = 'ok'
group by pt.Product_category_name
order by monthly_revenue desc


/*
monthly_	revenue	month
47271.2		2016-10
19.62		2016-12
127430.74	2017-01
269458.98	2017-02
414369.39	2017-03
390952.18	2017-04
566872.73	2017-05
490225.6	2017-06
566403.93	2017-07
646000.61	2017-08
700976.01	2017-09
751140.27	2017-10
1153393.22	2017-11
843199.17	2017-12
1078606.86	2018-01
966554.97	2018-02
1120678		2018-03
1132933.95	2018-04
1128836.69	2018-05
1011561.35	2018-06
1027383.1	2018-07
985414.28	2018-08
*/

-- 2. Which product categories are the most popular, and how do their sales numbers compare?

select
	P.Product_category_name,
	count(*) as total_items_sold,
	round(sum(pt.payment_Value),2) as total_revenue 
from Products_table P
join Order_items_table OT on P.product_id = OT.product_id
join Orders_table O on OT.order_id=O.order_id
join Payments_table PT on O.order_id=PT.order_id
where P.Product_category_name !='Unrecognized'
and O.order_status not in ('unavailable','canceled') and validation_issues = 'ok'
group by P.Product_category_name
order by total_items_sold desc, total_revenue desc

/* These are popular product categories and their revenues
bed_table & bath		11804	1711100.89
beauty & health			9934	1653914.76
sports & leisure		8891	1381110.38
furniture & decoration	8703	1424287.63
computers & accessories	8035	1571423.69
*/

--3. What is the average amount spent per order, and how does it change depending on the product category or payment method?

select
	round(avg(Total_revenue),2) as Avg_Amount_spent_per_product
from 
	(
	select 
		O.Order_id,
		sum(pt.Payment_value) as Total_revenue
	from Orders_table O
	join Payments_table PT on O.order_id=PT.order_id
	where O.order_status = 'delivered' and o.validation_issues = 'ok'
	group by O.Order_id)
as Order_totals

-- 159.86

-- payment type

select
	pt.payment_type,
	round(avg(pt.payment_value),2) as Avg_Amount_spent_per_paymentType
from Payments_table PT
join Orders_table O on PT.order_id = O.order_id
where o.order_status = 'delivered' and o.validation_issues = 'ok'
group by pt.payment_type
order by Avg_Amount_spent_per_paymentType desc

/*
payment_type	Avg_Amount_spent_per_paymentType
credit_card		162.24
debit_card		140.11
boleto			144.34
voucher			62.45
*/

-- Product category
select
	P.Product_category_name,
	round(avg(pt.payment_Value),2) as Avg_Amount_spent_per_ProductCategory
from Products_table P
join Order_items_table OT on P.product_id = OT.product_id
join Orders_table O on OT.order_id=O.order_id
join Payments_table PT on O.order_id=PT.order_id
where P.Product_category_name !='Unrecognized' and (o.order_status = 'delivered' and o.validation_issues = 'ok')
group by P.Product_category_name
order by Avg_Amount_spent_per_ProductCategory desc

/*
pcs								1271.63
Fixed telephony					736.93
portable home oven & coffee		670.42
agriculture_industry & commerce	470.05
appliances_2					455.38
*/
-- 4. How many active sellers are there on the platform, and does this number go up or down over time?

select
	count(distinct seller_id) as active_sellers
from Order_items_table

--3095

select
	count(distinct OT.seller_id) as active_sellers,
	format(O.order_purchase_timestamp, 'yyyy-MM') as month
from Order_items_table OT
join Orders_table O
on OT.order_id = O.order_id
where O.order_status = 'delivered'
group by format(O.order_purchase_timestamp, 'yyyy-MM')
ORDER BY month

/*
gradually increasing active sellers over the time
active_sellers	month
1				2016-09
129				2016-10
1				2016-12
219				2017-01
402				2017-02
476				2017-03
488				2017-04
563				2017-05
519				2017-06
593				2017-07
683				2017-08
711				2017-09
762				2017-10
937				2017-11
846				2017-12
956				2018-01
928				2018-02
981				2018-03
1105			2018-04
1105			2018-05
1165			2018-06
1238			2018-07
1261			2018-08
*/

-- new sellers added each month
SELECT
    MIN(FORMAT(O.order_purchase_timestamp, 'yyyy-MM')) AS first_sale_month,
    OI.seller_id
FROM Order_items_table OI
JOIN Orders_table O ON OI.order_id = O.order_id
WHERE O.order_status = 'delivered'
GROUP BY OI.seller_id
ORDER BY first_sale_month;

-- 5.Which products sell the most, and how have their sales changed over time?

select
	P.product_id,
	p.product_category_name,
	count(*) as total_items_sold,
	round(sum(pt.payment_Value),2) as total_revenue,
	FORMAT(O.order_purchase_timestamp, 'yyyy-MM') as month
from Products_table P
join Order_items_table OT on P.product_id = OT.product_id
join Orders_table O on OT.order_id=O.order_id
join Payments_table PT on O.order_id=PT.order_id
where P.Product_category_name !='Unrecognized'
and (O.order_status not in ('unavailable','canceled') and o.validation_issues = 'ok')
group by P.product_id, p.product_category_name, FORMAT(O.order_purchase_timestamp, 'yyyy-MM') 
order by total_items_sold desc, total_revenue desc, month

/*
aca2eb7d00ea1a7b8ebd4e68314663af	124	13310.82	2018-01
53b36df67ebb7c41585e8d54d6772e08	115	13713.1		2018-05
422879e10f46682990de24d770e7f83d	96	10554.11	2017-11
aca2eb7d00ea1a7b8ebd4e68314663af	92	9610.77		2018-05
aca2eb7d00ea1a7b8ebd4e68314663af	88	9707.08		2018-04
*/

-- 6. Do customer reviews and ratings help products sell more or perform better on the platform? 
--(Check sales with higher or lower ratings and identify if any correlation is there)

select 
	P.product_category_name,
	count(*) as total_items_sold,
	CR.review_score
from Customers_review_table CR
join Orders_table O on CR.order_id = O.order_id
join order_Items_table OT on O.order_id = Ot.order_id
join products_table P on P.product_id = OT.product_id
where (O.order_status not in( 'unavailable', 'canceled') and o.validation_issues ='ok')
and p.product_category_name != 'unrecognized'
group by
	P.product_category_name, cr.review_score
order by total_items_sold desc, P.product_category_name, CR.review_score

/*
beauty & health			5855	5
bed_table & bath		5782	5
sports & leisure		5115	5
furniture & decoration	4449	5
computers & accessories	4199	5
*/

select 
	P.product_category_name,
	count(*) as total_items_sold,
	avg(CR.review_score) as Avg_rating
from Customers_review_table CR
join Orders_table O on CR.order_id = O.order_id
join order_Items_table OT on O.order_id = Ot.order_id
join products_table P on P.product_id = OT.product_id
where (O.order_status not in( 'unavailable', 'canceled') and o.validation_issues ='ok')
and p.product_category_name != 'unrecognized'
group by
	P.product_category_name
order by total_items_sold desc

/*
bed_table & bath		11118	3
beauty & health			9611	4
sports & leisure		8588	4
furniture & decoration	8291	3
computers & accessories	7804	3
*/

-- delivery performance
 select * from orders_table
 where order_delivered_customer_date > order_estimated_delivery_date;

select  
   order_id,
   DATEDIFF(day, order_delivered_customer_date, order_purchase_timestamp) as actual_shipping_days,
   DATEDIFF(day, order_estimated_delivery_date, order_purchase_timestamp) as estimated_shipping_days,
   case 
       when order_delivered_customer_date > order_estimated_delivery_date THEN 'Yes'
       else 'No'
	end as sla_violated
from Orders_table
where order_delivered_customer_date is not null
  and order_purchase_timestamp is not null
  and order_estimated_delivery_date is not null


 -- 7827 deliveries were late than estimated

select payment_type, count(*) from payments_table
group by payment_type
order by count(*) desc

/*
payment_type	(No column name)
credit_card		76795
boleto			19784 -- cash in spanish
voucher			5775
debit_card		1529
not_defined		3
*/

-- geographics
select * from Customers_table
select * from Order_items_table

select customer_city, customer_state, count(*)  from Customers_table
group by customer_city,customer_state order by count(*) desc

-- highest customers are from SP 41746

select customer_city, count(*) from Customers_table
where customer_state = 'sp'--41746
group by customer_city order by count(*) desc

-- customer segmentation

--1. Spending habbits total purchase value per customer
select
	C.customer_id,
	round(sum(Payment_value),2) as Total_purchase_value
from customers_table C
join Orders_table O on O.customer_id = C.customer_id
join Payments_table P on O.order_id =P.order_id
where O.order_status = 'delivered' and o.validation_issues = 'ok'
group by c.customer_id
order by Total_purchase_value desc

--2. Order frequency of customer
select
	purchase_segment,
	count(*) as no_of_customers
from
(
	select
	c.customer_unique_id,
	COUNT(o.order_id) AS total_orders,
    CASE 
        WHEN COUNT(order_id) = 1 THEN 'One-time'
        WHEN COUNT(order_id) BETWEEN 2 AND 4 THEN 'Occasional'
        ELSE 'Frequent'
    END AS purchase_segment
FROM 
    Orders_table o
join customers_table c on o.customer_id = c.customer_id
group by 
    c.customer_unique_id) as customer_segments
group by 
	purchase_segment

--3. Average order value- comparison across states, cities, product categories

select
	C.customer_id,
	c.customer_state,
	round(sum(Payment_value),2) as Total_payment_value,
	count(*) as No_of_Orders,
	round(sum(Payment_value),2)/count(*) as AOV
from customers_table C
join Orders_table O on O.customer_id = C.customer_id
join Payments_table P on O.order_id =P.order_id
where O.order_status = 'delivered' and o.validation_issues = 'ok'
group by c.customer_id, c.customer_state
order by AOV desc

--by state
select
	c.customer_state,
	round(sum(Payment_value),2) as Total_payment_value,
	count(*) as No_of_Orders,
	round(sum(Payment_value),2)/count(*) as AOV
from customers_table C
join Orders_table O on O.customer_id = C.customer_id
join Payments_table P on O.order_id =P.order_id
where O.order_status = 'delivered' and o.validation_issues = 'ok'
group by c.customer_state
order by AOV desc

-- by city
select
	c.customer_city,
	round(sum(Payment_value),2) as Total_payment_value,
	count(*) as No_of_Orders,
	round(sum(Payment_value),2)/count(*) as AOV
from customers_table C
join Orders_table O on O.customer_id = C.customer_id
join Payments_table P on O.order_id =P.order_id
where O.order_status = 'delivered' and o.validation_issues = 'ok'
group by c.customer_city, c.customer_state
order by AOV desc

-- product category
select
	Pt.Product_category_name,
	round(sum(Payment_value),2) as Total_payment_value,
	count(*) as No_of_Orders,
	round(sum(Payment_value),2)/count(*) as AOV
from Products_table PT
join Order_items_table OT on PT.product_id = OT.product_id
join Orders_table O on OT.order_id = O.order_id
join Payments_table P on O.order_id =P.order_id
where O.order_status = 'delivered' and o.validation_issues = 'ok'
group by Pt.Product_category_name
order by AOV desc

-- Review score

select
	CR.review_score,
	count(*) as total_orders
from
	Customers_review_table CR
join Orders_table O on CR.order_id = O.order_id
group by CR.review_score
order by total_orders desc

-- orders with 0 review scores
select
	CR.review_score,
	count(*) as total_orders
from
	Customers_review_table CR
right join Orders_table O on CR.order_id = O.order_id
group by CR.review_score
order by total_orders desc

--768 orders has 0 reviews

-- cancelled order analysis
select
	O.order_status,
	p.Payment_type,
	round(sum(P.payment_value),2) as refund
from 
	orders_table O
join payments_table P on P.order_id = O.order_id
where order_status = 'canceled'
group by
	o.order_status, p.payment_type
order by refund desc

/*
order_status	Payment_type	refund
canceled		credit_card		96626.73
canceled		voucher			25664.92
canceled		boleto			17504.1
canceled		debit_card		2711.27
canceled		not_defined		0
*/

select
	O.order_status,
	COUNT(DISTINCT O.order_id) AS canceled_orders
from 
	orders_table O
join payments_table P on P.order_id = O.order_id
where order_status = 'canceled'
group by
	o.order_status
order by canceled_orders desc
-- 619 orders

select
	O.order_status,
	ROUND(SUM(P.payment_value) / COUNT(DISTINCT O.order_id), 2) AS avg_refund_per_order
from 
	orders_table O
join payments_table P on P.order_id = O.order_id
where order_status = 'canceled'
group by
	o.order_status
order by avg_refund_per_order desc -- 230.22


select
	O.order_status,
	count(*) as Canceled_orders,
	format(O.order_purchase_timestamp, 'yyyy-MM') AS month
from 
	orders_table O
join payments_table P on P.order_id = O.order_id
where order_status = 'canceled'
group by o.order_status, format(O.order_purchase_timestamp, 'yyyy-MM')
order by Canceled_orders desc 

/*
canceled	85	2018-08
canceled	75	2018-02
canceled	42	2018-07
canceled	37	2017-11
canceled	36	2017-07
*/

