USE [E-commerce_App_TB];
SELECT * FROM customer;
SELECT * FROM Product;
SELECT * FROM transactions;
SELECT * From click_stream;


-- Check the number of records in each table:
SELECT COUNT(*) FROM Customer;
SELECT COUNT(*) FROM Product;
SELECT COUNT(*) FROM transactions;
SELECT COUNT(*) FROM click_stream;


-- TRANSACTIONS
-- "There are no related columns from the Product table in the other three tables; 
-- however, the Transaction table includes a column named product_metadata, which is formatted as JSON and contains data that establishes a relationship with the Product table."
-- Now Extracting 'product_id', 'quantity', and 'item_price' from the JSON-formatted 'product_metadata' column in 'transactions' 
-- Each record in 'product_metadata' may contain multiple products, each with details like 'product_id', 'quantity', and 'item_price'.

		SELECT 
			t.*,
			JSON_VALUE(value, '$.product_id') AS product_id,
			JSON_VALUE(value, '$.quantity') AS quantity,
			JSON_VALUE(value, '$.item_price') AS item_price
		FROM 
			transactions t
		CROSS APPLY 
			OPENJSON(REPLACE(t.product_metadata, '''', '"')) AS value;


-- Saving the changes to trasaction Table
-- Step 1: Add New Columns to the Transactions Table
ALTER TABLE transactions
ADD product_id INT,         
    quantity INT,           
    item_price FLOAT;  

-- Step 2: Update the Transactions Table with Extracted Values
UPDATE t
SET 
    t.product_id = JSON_VALUE(value, '$.product_id'),
    t.quantity = JSON_VALUE(value, '$.quantity'),
    t.item_price = JSON_VALUE(value, '$.item_price')
FROM 
    transactions t
CROSS APPLY 
    OPENJSON(REPLACE(t.product_metadata, '''', '"')) AS value;


-- Check the changes made
SELECT * FROM transactions;


-- All the information from 'product_metadata' column has been extracted to new columns
-- So the 'product_metadata' column is not required now 
-- Droping the 'product_metadata' column
ALTER TABLE transactions 
DROP COLUMN product_metadata;

-- Check the changes made
SELECT * FROM transactions;


---Now there are a event_metadata column in click_stream where product_id, quantity, item_price, search_keywords, promo_code, promo_amount, payment_status are included.
-- I will only search_keywords as other informations are already in another table and some of them are not important for analysis 
		SELECT 
			cs.*,
			JSON_VALUE(REPLACE(REPLACE(cs.event_metadata, '''', '"'), CHAR(10), ''), '$.search_keywords') AS search_keywords
		FROM 
			click_stream cs
			CROSS APPLY 
			OPENJSON(REPLACE(REPLACE(cs.event_metadata, '''', '"'), CHAR(10), '')) AS value;


-- Saving the changes to Click_stream Table
-- Step 1: Add New Column to the Click_stream Table
ALTER TABLE click_stream
ADD search_keywords NVARCHAR (30);  

-- Step 2: Update the Click_stream Table with Extracted Values
UPDATE cs
	SET 
    cs.search_keywords = JSON_VALUE(REPLACE(REPLACE(cs.event_metadata, '''', '"'), CHAR(10), ''), '$.search_keywords')
	FROM 
    click_stream cs
	CROSS APPLY 
	OPENJSON(REPLACE(REPLACE(cs.event_metadata, '''', '"'), CHAR(10), '')) AS value;

-- The required information from 'event_metadata' column has been extracted to new column
-- So the 'event_metadata' column is not required now 
-- Droping the 'event_metadata' column
ALTER TABLE click_stream 
DROP COLUMN event_metadata;

-- Check the changes made
SELECT * FROM click_stream;




--***HANDLING MISSING / NULL VALUES***


--CUSTOMER table

-- Checking for missing Values in Customer Table
SELECT 
    COUNT(CASE WHEN first_name IS NULL THEN 1 END) AS missing_first_name,
    COUNT(CASE WHEN last_name IS NULL THEN 1 END) AS missing_last_name,
    COUNT(CASE WHEN username IS NULL THEN 1 END) AS missing_username,
    COUNT(CASE WHEN email IS NULL THEN 1 END) AS missing_email,
    COUNT(CASE WHEN gender IS NULL THEN 1 END) AS missing_gender,
    COUNT(CASE WHEN device_type IS NULL THEN 1 END) AS missing_device_type,
    COUNT(CASE WHEN device_id IS NULL THEN 1 END) AS missing_device_id,
    COUNT(CASE WHEN device_version IS NULL THEN 1 END) AS missing_device_version,
    COUNT(CASE WHEN home_location_lat IS NULL THEN 1 END) AS missing_home_location_lat,
    COUNT(CASE WHEN home_location_long IS NULL THEN 1 END) AS missing_home_location_long,
    COUNT(CASE WHEN home_location IS NULL THEN 1 END) AS missing_home_location,
    COUNT(CASE WHEN home_country IS NULL THEN 1 END) AS missing_home_country,
    COUNT(CASE WHEN first_join_date IS NULL THEN 1 END) AS missing_first_join_date
FROM 
    customer;


-- There is one missing value in the column "home_location_lat"
-- Droping the row where the missing value is as Latitute can not be made manually
DELETE FROM customer
WHERE home_location_lat IS NULL;

-- Now there is no NULL values in Customer Table 



-- PRODUCT Table
-- Checking for missing Values 
SELECT 
    COUNT(CASE WHEN id IS NULL THEN 1 END) AS missing_id,
    COUNT(CASE WHEN gender IS NULL THEN 1 END) AS missing_gender,
    COUNT(CASE WHEN masterCategory IS NULL THEN 1 END) AS missing_masterCategory,
    COUNT(CASE WHEN subCategory IS NULL THEN 1 END) AS missing_subCategory,
    COUNT(CASE WHEN articleType IS NULL THEN 1 END) AS missing_articleType,
    COUNT(CASE WHEN baseColour IS NULL THEN 1 END) AS missing_baseColour,
    COUNT(CASE WHEN season IS NULL THEN 1 END) AS missing_season,
    COUNT(CASE WHEN year IS NULL THEN 1 END) AS missing_year,
    COUNT(CASE WHEN usage IS NULL THEN 1 END) AS missing_usage,
    COUNT(CASE WHEN productDisplayName IS NULL THEN 1 END) AS missing_productDisplayName
FROM 
    product;


-- There is 21 NULL values in column 'season'
-- and 1 Null value in both table 'year' and 'usage'

-- Filling the NULL values with Unknown for 'Season' Column
UPDATE product
SET season = 'Unknown'
WHERE season IS NULL;

-- Filling the NULL values of 'year' with mostly used year
UPDATE product
SET year = 
	(SELECT TOP 1 year
    FROM product
    WHERE year IS NOT NULL
    GROUP BY year
    ORDER BY COUNT(*) DESC)
WHERE year IS NULL;

-- Filling the NULL values with Unknown for 'usage' Column
UPDATE product
SET usage = 
	(SELECT TOP 1 usage
    FROM product
    WHERE usage IS NOT NULL
    GROUP BY usage
    ORDER BY COUNT(*) DESC)
WHERE usage IS NULL;


-- Now there is no NULL values in Customer Table 




-- TRANSACTIONS Table
-- Checking for missing Values 
SELECT 
    COUNT(CASE WHEN created_at IS NULL THEN 1 END) AS missing_created_at,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS missing_customer_id,
    COUNT(CASE WHEN booking_id IS NULL THEN 1 END) AS missing_booking_id,
    COUNT(CASE WHEN session_id IS NULL THEN 1 END) AS missing_session_id,
    COUNT(CASE WHEN payment_method IS NULL THEN 1 END) AS missing_payment_method,
    COUNT(CASE WHEN payment_status IS NULL THEN 1 END) AS missing_payment_status,
    COUNT(CASE WHEN promo_amount IS NULL THEN 1 END) AS missing_promo_amount,
    COUNT(CASE WHEN promo_code IS NULL THEN 1 END) AS missing_promo_code,
    COUNT(CASE WHEN shipment_fee IS NULL THEN 1 END) AS missing_shipment_fee,
    COUNT(CASE WHEN shipment_date_limit IS NULL THEN 1 END) AS missing_shipment_date_limit,
    COUNT(CASE WHEN shipment_location_lat IS NULL THEN 1 END) AS missing_shipment_location_lat,
    COUNT(CASE WHEN shipment_location_long IS NULL THEN 1 END) AS missing_shipment_location_long,
    COUNT(CASE WHEN total_amount IS NULL THEN 1 END) AS missing_total_amount,
	COUNT(CASE WHEN product_id IS NULL THEN 1 END) AS missing_product_id,
	COUNT(CASE WHEN quantity IS NULL THEN 1 END) AS missing_quantity,
	COUNT(CASE WHEN item_price IS NULL THEN 1 END) AS missing_item_price
FROM 
    transactions;

-- There is 526048 NULL values in promo_code and 1 in shipment_location_lat
-- Check what percentage of total Values are NULL in Promo_code column
SELECT 
    COUNT(promo_code) AS total_NULL, (COUNT(CASE WHEN promo_code IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percentage_null
FROM 
    transactions;
-- 61% NULL values Promo_code column. As most of the values are missing, I decided to DROP the Column 
-- BUT before Dropping the column, I will create another column where it will be stated if the promocode has been used or not. 

-- adding new Column
ALTER TABLE transactions
ADD promo_code_used NVARCHAR(10);

--  update the new column based on whether the promo_code is NULL or not
UPDATE transactions
SET promo_code_used = 
	CASE WHEN promo_code IS NULL THEN 'Not Used' 
	ELSE 'Used'
	END;

-- Now DROP original promo_code column
ALTER TABLE transactions
DROP COLUMN promo_code;

-- Now Droping the only row from 'Shipment_location_lat' where the missing value is Latitute and it can not be made manually
DELETE FROM transactions
WHERE shipment_location_lat IS NULL;
--// NOW after handling the missing values, there is no missing value in the 'transactions' table



-- CLICK_STREAM Table
-- Checking for missing Values 
SELECT 
    COUNT(CASE WHEN session_id IS NULL THEN 1 END) AS session_id,
    COUNT(CASE WHEN event_name IS NULL THEN 1 END) AS event_name,
    COUNT(CASE WHEN event_time IS NULL THEN 1 END) AS event_time,
    COUNT(CASE WHEN event_id IS NULL THEN 1 END) AS event_id,
    COUNT(CASE WHEN traffic_source IS NULL THEN 1 END) AS traffic_source,
    COUNT(CASE WHEN search_keywords IS NULL THEN 1 END) AS search_keywords
FROM 
    click_stream;

-- There are 11660336 NULL values in search_keywords column
SELECT COUNT(*) AS Total_rows,
	(COUNT(CASE WHEN search_keywords IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS 'NULL_%_of_search'
	FROM click_stream;

--// This column contains 90% NULL values where making any decision depending on 10% data can be biased 
--// So I deceided to remove this column too
ALTER TABLE click_stream
DROP COLUMN search_keywords;

-- Check the changes
SELECT * FROM click_stream;




-- ***REMOVING UNNECESSARY COLUMNS**

--From Customer Table 
-- Removing column email, device_id, device_version;
ALTER TABLE customer 
DROP COLUMN email, device_id, device_version;

--Check the changes
SELECT * FROM customer;

--From Customer Table 
ALTER TABLE click_stream
DROP COLUMN event_id;

SELECT * FROM click_stream;



-- ***CHECK DUPLICATES***

-- Check duplicates for Customer Table
SELECT COUNT(*) AS duplicate_count
	FROM Customer
	GROUP BY 
		customer_id, first_name, last_name, username, gender, 
		birthdate,device_type, home_location_lat, home_location_long, 
		home_location, home_country, first_join_date
	HAVING COUNT(*) > 1;
--// No duplicate found


-- Check duplicates for transactions Table
SELECT COUNT(*) AS duplicate_count
FROM 
    transactions
GROUP BY 
    created_at, customer_id, booking_id, session_id, payment_method, payment_status, 
    promo_amount, promo_code_used, shipment_fee, shipment_date_limit, shipment_location_lat, 
    shipment_location_long, total_amount, product_id, quantity, item_price
HAVING 
    COUNT(*) > 1;
--// No duplicate found


-- Check duplicates for product Table
SELECT 
    COUNT(*) AS duplicate_count
FROM 
    product
GROUP BY 
    id, gender, masterCategory, subCategory,
	articleType, baseColour, season, year,
	usage, productDisplayName
HAVING 
    COUNT(*) > 1;
--// No duplicate found


-- Check duplicates for product Table
WITH CTE_duplicates_rmv AS (
			SELECT *, ROW_NUMBER() OVER(PARTITION BY session_id, event_name, event_time, traffic_source ORDER BY session_id, event_name, event_time, traffic_source) AS row_number
			FROM click_stream)
	SELECT * FROM CTE_duplicates_rmv
	WHERE row_number > 1 
--// There are 8138 duplicate Rows in click_stream


-- Removing all the Duplicate rows
WITH CTE_duplicates_rmv AS (
			SELECT *, ROW_NUMBER() OVER(PARTITION BY session_id, event_name, event_time, traffic_source ORDER BY session_id, event_name, event_time, traffic_source) AS row_number
			FROM click_stream)
DELETE FROM CTE_duplicates_rmv
	WHERE row_number > 1 

SELECT * from product;



-- ***Converting All amount from Indonesian Rupiah to USD
-- As the data is till 2022, I will convert the currency convertion rate according to DEC 2022
-- currency convertion rate according to DEC 2022 was 1 USD = 14200 Indonesian Rupiah. 

-- //In Transaction Table
--First converting the currency to USD for the column "promo_amount"
SELECT promo_amount, CAST(ROUND(promo_amount / 14200.0, 2) AS DECIMAL(10, 2)) AS promo_amount_USD
FROM transactions;

--Converting the currency to USD for the column "shipment_fee"
SELECT shipment_fee, CAST(ROUND(shipment_fee / 14200.0, 2) AS DECIMAL(10, 2)) AS shipment_fee_USD
FROM transactions;

SELECT total_amount, CAST(ROUND(total_amount / 14200.0, 2) AS DECIMAL(10, 2)) AS total_amount_USD
FROM transactions;

SELECT item_price, CAST(ROUND(item_price / 14200.0, 2) AS DECIMAL(10, 2)) AS item_price_USD
FROM transactions;

-- ADDING Columns with currency Conversion
ALTER TABLE transactions
ADD item_price_USD DECIMAL(10, 2);

ALTER TABLE transactions
ADD shipment_fee_USD DECIMAL(10, 2);

ALTER TABLE transactions
ADD promo_amount_USD DECIMAL(10, 2);

ALTER TABLE transactions
ADD total_amount_USD DECIMAL(10, 2);



UPDATE transactions
	SET
		item_price_USD = CAST(ROUND(item_price / 14200.0, 2) AS DECIMAL(10, 2)),
		shipment_fee_USD = CAST(ROUND(shipment_fee / 14200.0, 2) AS DECIMAL(10, 2)),
		promo_amount_USD = CAST(ROUND(promo_amount / 14200.0, 2) AS DECIMAL(10, 2)),
		total_amount_USD = CAST(ROUND(total_amount / 14200.0, 2) AS DECIMAL(10, 2));


-- As all the currency columns have been converted into USD, Now the old columns are not required
-- Removing the columns where the Currecncy is in Indonesian Rupiah
ALTER TABLE transactions
DROP COLUMN item_price, shipment_fee, promo_amount, total_amount;

--Creating a new column for "AGE", 
-- We are counting a the Age as of Dec 2022 as the data is till 2022. 

ALTER TABLE customer
ADD age_as_of_2022 INT;

UPDATE customer
	SET
    age_as_of_2022 = DATEDIFF(YEAR, birthdate, '2022-12-31') ;

--Checking the Change 
SELECT * FROM customer;


-- Checking who has highest amount of bookings with total expenditure
SELECT 		
	c.first_name, t.customer_id, COUNT(booking_id) as total_order, SUM(total_amount_USD) as total_spent
FROM transactions t
	JOIN customer c ON c.customer_id = t.customer_id 
GROUP BY  c.first_name, t.customer_id
ORDER BY COUNT(booking_id) DESC;

SELECT * FROM transactions
WHERE customer_id = 8;

-- Adding two columns for every customer having highest number of bookings with total expenditure
-- Also filling the NULL with Zero. 
ALTER TABLE customer 
ADD total_spent DECIMAL (10,2);

ALTER TABLE customer 
ADD total_bookings INT;


UPDATE customer
		SET 
			total_spent = COALESCE(t.total_spent, 0),
			total_bookings = COALESCE(t.total_bookings, 0)
		FROM customer c
		LEFT JOIN (
				SELECT 
				customer_id,
				SUM(total_amount_USD) AS total_spent,
				COUNT(booking_id) AS total_bookings
		FROM transactions
		GROUP BY customer_id) t 
		ON c.customer_id = t.customer_id;

-- Checking the changes
SELECT * FROM customer;



