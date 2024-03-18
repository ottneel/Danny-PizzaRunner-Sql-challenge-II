/* A. Pizza Metrics
1. How many pizzas were ordered? */

select count(order_id) as No_of_pizza_orders
from customer_orders

--2. How many unique customer orders were made?
select count(distinct customer_id) as unique_orders
from customer_orders;

--3. How many successful orders were delivered by each runner?
SELECT COUNT(pickup_time) AS successful_orders
FROM runner_orders
WHERE pickup_time IS NOT NULL
	AND cancellation IS NULL;

--4. How many of each type of pizza was delivered?
select count(co.order_id) as pizza_count_type, pn.pizza_name
from customer_orders as co
inner join pizza_names as pn on  co.pizza_id = pn.pizza_id
--select 1, prints 1 if the where condition returns as true. this is also a correlated subquery
-- where the condition in the subquery has a result, run the outer query
where exists (
	select 1
	from runner_orders as ro
	where co.order_id=ro.order_id and ro.cancellation is null
)
group by pn.pizza_name;

--5. How many Vegetarian and Meatlovers were ordered by each customer?
select co.customer_id, pn.pizza_name, count(co.order_id) as pizza_count_type
from customer_orders as co
inner join pizza_names as pn on  co.pizza_id = pn.pizza_id
group by co.customer_id, pn.pizza_name
order by co.customer_id;

--6. What was the maximum number of pizzas delivered in a single order?

select Max(order_count) as max_order_count
--inner query to select the count of pizzas, outer query to select the max.
from (
	select count(co.pizza_id) as order_count, co.order_id
	from customer_orders as co
	inner join pizza_names pn 
	on co.pizza_id=pn.pizza_id
	group by order_id
) as joined_table;

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select sq.customer_id,
	sum(case when sq.exclusions is null or sq.extras is null then 1 end) as orders_with_change,
	sum(case when sq.exclusions is null and sq.extras is null then 1 end) as orders_with_no_change
from (
	select customer_id,exclusions,extras
	from customer_orders as co
	inner join runner_orders as ro on co.order_id = ro.order_id
	where
		pickup_time is not null and cancellation is null
)as sq
group by sq.customer_id;

--8. How many pizzas were delivered that had both exclusions and extras?
select
	sum(case when co.exclusions is not null and co.extras is not null then 1 else 0 end) as pizza_with_changes
from customer_orders as co
where exists (
	select 1
	from runner_orders as ro
	where co.order_id = ro.order_id and ro.cancellation is null)

--9. What was the total volume of pizzas ordered for each hour of the day?
SELECT count(co.order_id) as total_volume, datepart(Hour, co.order_time) as hr_of_day
from customer_orders as co
group by  datepart(Hour,co.order_time)
order by hr_of_day;


--10.What was the volume of orders for each day of the week?
SELECT count(co.order_id) as total_volume, datepart(WEEKDAY, co.order_time) as day_of_week
from customer_orders as co
group by  datepart(WEEKDAY,co.order_time)
order by day_of_week;


		--B. Runner and Customer Experience
-- 1) How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select datepart(week, registration_date) as signup_week, count(runner_id) as number_of_runner
from runners
group by datepart(week, registration_date);


--2) What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

select ro.runner_id, avg(datediff(minute, co.order_time, ro.pickup_time)) as avg_arrival_time_in_mins
from customer_orders as co
inner join runner_orders as ro on co.order_id=ro.order_id
group by ro.runner_id;

--3). Is there any relationship between the number of pizzas and how long the order takes to prepare?
select datediff(minute, co.order_time, ro.pickup_time) as order_timing, count(co.order_id) no_pizza
from  customer_orders as co
inner join runner_orders as ro on co.order_id=ro.order_id
group by datediff(minute, co.order_time, ro.pickup_time);


--4. What was the average distance travelled for each customer?
select round(avg(ro.distance), 2) as avg_timing, co.customer_id
from customer_orders as co
inner join runner_orders as ro on co.order_id=ro.order_id
group by co.customer_id;
	
--5. What was the difference between the longest and shortest delivery times for all orders?
select (max(duration)-min(duration)) as duration_range
from runner_orders

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
/*Avg speed is calulated as distance/time
so id be using the distance column and the duration coln
to get the avgspeed per runner*/
select round((distance/(60*duration)),3) as avg_speed, ro.runner_id
from runner_orders as ro
GROUP BY ro.runner_id, distance,duration;

--7. What is the successful delivery percentage for each runner?
--duration/total(duration)*100

WITH runner_total_duration AS (
    SELECT
        runner_id,
        SUM(duration) AS total_duration
    FROM
        runner_orders
    GROUP BY
        runner_id
)
SELECT
    r.runner_id,
    r.total_duration,
    concat(round((r.total_duration * 100.0 / tds.sum_duration),2),'%') AS successful_delivery_percentage
FROM
    runner_total_duration r
CROSS JOIN
    (SELECT SUM(duration) AS sum_duration FROM runner_orders) tds;


--			C. Ingredient Optimisation
--1. What are the standard ingredients for each pizza?

select pr.pizza_id,pr.toppings,pt.topping_name,  pn.pizza_name
from pizza_recipes as pr
inner join pizza_toppings as pt on pr.toppings=pt.topping_id
inner join pizza_names as pn on pn.pizza_id = pr.pizza_id;


--3. What was the most common exclusion?
/*4. Generate an order item for each record in the customers_orders table in the format of one of the following:
	Meat Lovers
	Meat Lovers - Exclude Beef
	Meat Lovers - Extra Bacon
	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */

--2. What was the most commonly added extra?

SELECT COUNT(extras_value) AS extras_count, extras_value
FROM Customer_cleaned AS cc
GROUP BY extras_value
order by extras_count desc;


--3 What was the most common exclusion?

SELECT COUNT(exclusions_value) AS exclusions_count, exclusions_value
FROM Customer_cleaned AS cc
GROUP BY exclusions_value
order by exclusions_count desc;

/*4. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/


SELECT
	CASE WHEN exclude IS NULL AND extra IS NULL THEN pizza_name
	WHEN extra IS NULL THEN CONCAT(pizza_name, ' - ', exclude) 
	WHEN exclude IS NULL THEN CONCAT(pizza_name, ' - ', extra)
	WHEN extra IS NOT NULL AND exclude IS NOT NULL THEN CONCAT(pizza_name, ' - ', exclude, ' - ', extra)
	END AS order_item
FROM (
	SELECT order_id,
customer_id,
pizza_id,
exclusions,
extras,
order_time,
pizza_name,
Exclude,
	CASE
    WHEN extras IS NULL THEN NULL
    WHEN LEN(extras) = 1 THEN CONCAT('Extra ', topping_name)
    WHEN LEN(extras) > 1 AND extras = '1, 5' THEN 'Extra Bacon, Chicken'
    ELSE 'Extra Bacon, Cheese'
    END AS extra
FROM (
	    SELECT 
        order_id,
        customer_id,
        pizza_id,
        exclusions,
        extras,
        order_time,
        pizza_name,
        CASE
            WHEN exclusions IS NULL THEN NULL 
            WHEN LEN(exclusions) = 1 THEN CONCAT('Exclude ', topping_name)
            ELSE 'Exclude BBQ Sauce, Mushrooms'
        END AS Exclude
    FROM (
        SELECT 
            order_id,
            customer_id,
            c.pizza_id,
            exclusions,
            extras,
            order_time,
            pn.pizza_name
        FROM customer_orders AS c
        JOIN pizza_names AS pn
        ON pn.pizza_id = c.pizza_id
    ) AS piz
    LEFT JOIN pizza_toppings AS pt
    ON CHARINDEX(CAST(pt.topping_id AS VARCHAR(10)), piz.exclusions) > 0) as excludes
	
LEFT JOIN pizza_toppings AS pt
ON CHARINDEX(',' + CAST(pt.topping_id AS VARCHAR(10)) + ',', ',' + excludes.extras + ',') > 0) as final
ORDER BY order_id;



--D. Pricing and Ratings

--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
select * from customer_orders as co inner join pizza_names as pn on co.pizza_id=pn.pizza_id inner join runner_orders ro on co.order_id=ro.order_id;

select sum(price) as money_made
from (
	select pn.pizza_name,
		(case when pn.pizza_name = 'Meatlovers' and ro.cancellation is null then 12
		when pn.pizza_name = 'Vegetarian' and ro.cancellation is null then 10
		end) as price
	from customer_orders as co
	inner join pizza_names as pn on co.pizza_id = pn.pizza_id
	inner join runner_orders as ro on co.order_id=ro.order_id) as subquery

--2. What if there was an additional $1 charge for any pizza extras?
select sum(price) as money_made
from (
	select pn.pizza_name,
		(case when pn.pizza_name = 'Meatlovers' and ro.cancellation is null then 12
		when pn.pizza_name = 'Vegetarian' and ro.cancellation is null then 10
		end) as price
	from customer_orders as co
	inner join pizza_names as pn on co.pizza_id = pn.pizza_id
	inner join runner_orders as ro on co.order_id=ro.order_id) as subquery

with price_cte as (
	select subquery.pizza_name, (
		case when subquery.extras is not null then 13
		else price
		end) as price_with_extra_charge
	from (
		select pn.pizza_name ,co.extras,
			(case when pn.pizza_name = 'Meatlovers' and ro.cancellation is null then 12
			when pn.pizza_name = 'Vegetarian' and ro.cancellation is null then 10
			end) as price
		from customer_orders as co
		inner join pizza_names as pn on co.pizza_id = pn.pizza_id
		inner join runner_orders as ro on co.order_id=ro.order_id) as subquery
)

select sum(price_with_extra_charge) as price_with_extra_charge
from price_cte

/*3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset -
generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.*/


select runner_id,
	(case when ro.cancellation is not null then null
		when ro.duration between 1 and 5 then 5
		when ro.duration between 6 and 10 then 4
		when ro.duration between 11 and 15 then 3
		when ro.duration between 16 and 20 then 2
		else 1
	end ) as ratings
into runner_ratings
from runner_orders as ro;

/* 4 Using your newly generated table - can you join all of the information together 
to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas */

select co.customer_id, co.order_id, ro.runner_id, rr.ratings, co.order_time, ro.pickup_time, datediff(minute, co.order_time,ro.pickup_time) as time_diff, ro.duration, (ro.distance * ro.duration) as avg_speed_mins, count(co.order_id) over() as total_pizzas
from customer_orders as co
inner join runner_orders as ro on co.order_id=ro.order_id
inner join runner_ratings as rr on ro.runner_id=rr.runner_id;


/* 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
- how much money does Pizza Runner have left over after these deliveries?*/

with rf_cte as (
	select pn.pizza_name,
		(case when pn.pizza_name = 'Meatlovers' and ro.cancellation is null then 12
		when pn.pizza_name = 'Vegetarian' and ro.cancellation is null then 10
		end) as price, (ro.distance*0.30) as runner_fees
	from customer_orders as co
	inner join pizza_names as pn on co.pizza_id = pn.pizza_id
	inner join runner_orders as ro on co.order_id=ro.order_id)

select sum(rf_cte.price - rf_cte.runner_fees) as left_after_deliveries
from rf_cte

