
--The exclusions and extras columns will need to be cleaned up before using them.
-- changing 'null' texts to NULL marker
 
update customer_orders
set exclusions =
(	case
		--change null strings and empty rows to NULL placeholder for efficency and data consistency sake
		when exclusions = 'null' or exclusions = '' then NULL
		else exclusions
	end
);

update customer_orders
set extras = 
(
	case
		--change null strings and empty rows to NULL placeholder for efficency and data consistency sake
		when extras = 'null' or extras = '' then NULL
		else extras
	end
);

--CHECKING THE DATATYPES OF EACH COLUMN OF EACH TABLE

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'runner_orders';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customer_orders';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'pizza_names';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'pizza_recipes';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'pizza_toppings';

/* issues to clean from the runners_orders
1. change datatype of pickup column from varchar to datetime
2. strip km from distance and convert to int.
3. strip all string from duration and convert to int.
4. change data type of pizza_name, pizza_toppings to varchar from text
*/
--1) remove all occurances of km from distance
update runner_orders
set distance = cast(REPLACE(distance,'km','') as float)
where distance like '%km';


update runner_orders
set distance=
(
	CASE WHEN distance ='null' THEN NULL
	ELSE distance
	END
);


--2) removing all variations of 'min' and changing to int in duration
update runner_orders
set duration =
(
	case
		when duration like '% minutes' then CAST(replace(duration,'minutes','') as int)
		when duration like '%minutes' then CAST(replace(duration,'minutes','') as int)
		when duration like '% mins' then CAST(replace(duration,'mins','') as int)
		when duration like '%mins' then CAST(replace(duration,'mins','') as int)
		when duration like '% minute' then CAST(replace(duration,'minute','') as int)
		when duration = 'null' then NULL
	else duration
	end
);

--3) changing all nulls in cancellations to NULL
UPDATE runner_orders
SET cancellation =
(
	CASE
		WHEN cancellation = 'null' then NULL
	ELSE cancellation
	END
);

--4. CHANGE nulls TO NULL in runner_orders for pickup_time
UPDATE runner_orders
set pickup_time =
(
	CASE
		WHEN pickup_time = 'null' then NULL
	END
);
--CHANGING THE DATATYPE OF Topping_name in pizza_toppings to varchar
ALTER TABLE pizza_toppings
ALTER COLUMN topping_name varchar(35);

--CHANGING THE DATATYPE OF Pizza_name in pizza_name to varchar
ALTER TABLE pizza_names
ALTER COLUMN pizza_name varchar(35);

--CHANGING THE DATATYPE OF duration in runner_orders to int
ALTER TABLE runner_orders
ALTER COLUMN duration int

-- CHANGING THE DATATYPE OF pickup_time in runner_orders to datetime
ALTER TABLE runner_orders
ALTER COLUMN pickup_time datetime

--CHANGING THE DATATYPE OF distance in runner_orders to float
ALTER TABLE runner_orders
ALTER COLUMN distance float

--CHANGING THE DATATYPE OF toppins in pizza_recipes to varchar
ALTER TABLE pizza_recipes
ALTER COLUMN toppings varchar(25)


--split toppings column by , in the pizza_recipe and save in a new table called new pizza recipe
--create new pizza recipe table
SELECT pr.pizza_id, CAST(value AS INT) AS toppings
INTO new_pizza_recipe
FROM pizza_recipes as pr
-- using the cross apply function to apply the string_split table function to every row in the pr (pizza_recipes) table
CROSS APPLY STRING_SPLIT(pr.toppings, ',');


--Transaction code to rename the new_pizza_recipe as pizza_recipe
--show that the following code should be treated as a whole and rolled back if necessary
BEGIN TRANSACTION;
-- begining of the try block
BEGIN TRY
	-- stored procedure that renames pizza_recipes to old_pizza_recipe and new_pizza_recipes to pizza_recipes
    EXEC sp_rename 'pizza_recipes', 'old_pizza_recipe';
    EXEC sp_rename 'new_pizza_recipe', 'pizza_recipes';
	-- delete old_pizza_recipe
    DROP TABLE old_pizza_recipe;
	-- make the changes permanent if no errors occur
    COMMIT;
    PRINT 'Transaction committed.';
END TRY
-- begining of the catch block
BEGIN CATCH
	-- check if theres an active transaction ongoing and undoes (rollback) any changes made
    IF @@TRANCOUNT > 0
        ROLLBACK;
    PRINT 'Transaction rolled back.';
	-- raise the exception
    THROW;
END CATCH;


--create a view that seperates the commas in the extra and exclusion columns on the customers orders table.
-- Create a view named Customer_cleaned
CREATE VIEW Customer_cleaned AS 

-- Select columns from the customer_orders table and perform data cleaning
SELECT 
    order_id,              -- Select order_id column
    customer_id,           -- Select customer_id column
    pizza_id,              -- Select pizza_id column
    order_time,            -- Select order_time column
    
    -- Clean the exclusions column
    CASE
        WHEN exclusions IS NOT NULL THEN
            CASE
                -- If exclusions column does not contain a comma, retain original value
                WHEN exclusions NOT LIKE '%,%' THEN exclusions
                -- If exclusions column contains a comma, split the value and select the first part
                ELSE new_exclusions.value
            END
        ELSE NULL            -- If exclusions column is NULL, set the value to NULL
    END AS exclusions_value,

    -- Clean the extras column
    CASE
        WHEN extras IS NOT NULL THEN
            CASE
                -- If extras column does not contain a comma, retain original value
                WHEN extras NOT LIKE '%,%' THEN extras
                -- If extras column contains a comma, split the value and select the first part
                ELSE new_extras.value
            END
        ELSE NULL            -- If extras column is NULL, set the value to NULL
    END AS extras_value

-- Select data from the customer_orders table and apply STRING_SPLIT function
FROM customer_orders

-- Apply STRING_SPLIT function to split exclusions column and assign an alias
CROSS APPLY STRING_SPLIT(ISNULL(exclusions, ''), ',') as new_exclusions

-- Apply STRING_SPLIT function to split extras column and assign an alias
CROSS APPLY STRING_SPLIT(ISNULL(extras, ''), ',') as new_extras;



