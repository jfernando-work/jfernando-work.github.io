/* Adding fields: item_cleaned, quantity_cleaned, price_cleaned, 
totalspent_cleaned, paymentmethod_cleaned, location_cleaned, transactiondate_cleaned. */
	
ALTER TABLE public."Cafe_Sales"
ADD COLUMN "Item_Cleaned" TEXT,
ADD COLUMN "Quantity_Cleaned" NUMERIC,
ADD COLUMN "PricePerUnit_Cleaned" NUMERIC,
ADD COLUMN "TotalSpent_Cleaned" NUMERIC,
ADD COLUMN "PaymentMethod_Cleaned" TEXT,
ADD COLUMN "Location_Cleaned" TEXT,
ADD COLUMN "TransactionDate_Cleaned" DATE;
ADD COLUMN "Day" TEXT,
ADD COLUMN "Month" TEXT;

-- Use CAST to convert and clean the numeric columns, replace ERROR and UNKNOWN values.
UPDATE public."Cafe_Sales"
SET 
    "Item_Cleaned" = 
        CASE 
            WHEN "Item" IN ('ERROR', 'UNKNOWN') THEN NULL
            ELSE "Item"
        END,
    
    "Quantity_Cleaned" = 
        CASE 
            WHEN "Quantity" IN ('ERROR', 'UNKNOWN') THEN NULL
            ELSE CAST("Quantity" AS NUMERIC)
        END,
    
    "PricePerUnit_Cleaned" = 
        CASE 
            WHEN "Price Per Unit" IN ('ERROR', 'UNKNOWN') THEN NULL
            ELSE CAST("Price Per Unit" AS NUMERIC)
        END,
    
    "TotalSpent_Cleaned" = 
        CASE 
            WHEN "Total Spent" IN ('ERROR', 'UNKNOWN') THEN NULL
            ELSE CAST("Total Spent" AS NUMERIC)
        END,
    
    "PaymentMethod_Cleaned" = 
        CASE 
            WHEN "Payment Method" IN ('ERROR', 'UNKNOWN') THEN NULL
            ELSE "Payment Method"
        END,
    
    "Location_Cleaned" = 
        CASE 
            WHEN "Location" IN ('ERROR', 'UNKNOWN') THEN NULL
            ELSE "Location"
        END,
    
    "TransactionDate_Cleaned" =
        CASE 
            WHEN "Transaction Date" IN ('ERROR', 'UNKNOWN') THEN NULL
            ELSE CAST("Transaction Date" AS DATE)
        END;


-- Subquery to create a table with items / pries. Join that back with all rows.
UPDATE public."Cafe_Sales" AS cs
SET "PricePerUnit_Cleaned" = prices."PricePerUnit_Cleaned"
FROM (
    SELECT DISTINCT "Item_Cleaned", "PricePerUnit_Cleaned"
    FROM public."Cafe_Sales"
    WHERE "Item_Cleaned" IS NOT NULL
    AND "PricePerUnit_Cleaned" IS NOT NULL
) AS prices
WHERE cs."Item_Cleaned" = prices."Item_Cleaned" 
AND cs."PricePerUnit_Cleaned" IS NULL;


-- Calculate the PricePerUnit_Cleaned for missing values.
UPDATE public."Cafe_Sales"
SET "PricePerUnit_Cleaned" = ROUND("TotalSpent_Cleaned" / "Quantity_Cleaned", 1)
WHERE "PricePerUnit_Cleaned" IS NULL;

-- Make sure data type is NUMERIC and that decimal is correct.
ALTER TABLE public."Cafe_Sales"
ALTER COLUMN "PricePerUnit_Cleaned" TYPE NUMERIC(10,1)
USING ROUND("PricePerUnit_Cleaned", 1);


-- Calculate any missing Quantities.
UPDATE public."Cafe_Sales"
SET "Quantity_Cleaned" = ("TotalSpent_Cleaned" / "PricePerUnit_Cleaned")
WHERE "Quantity_Cleaned" IS NULL;


-- Calculate any missing Total Spent values.
UPDATE public."Cafe_Sales"
SET "TotalSpent_Cleaned" = ("Quantity_Cleaned" * "PricePerUnit_Cleaned")
WHERE "TotalSpent_Cleaned" IS NULL;


-- Extract day and month values from TransactionDate.
UPDATE public."Cafe_Sales" 
SET 
    "Day" = TRIM(TO_CHAR("TransactionDate_Cleaned", 'Day')),
    "Month" = TRIM(TO_CHAR("TransactionDate_Cleaned", 'Month')); 

-- Fill in missing Items by using the PricePerUnit as a guide.
UPDATE public."Cafe_Sales"
SET "Item_Cleaned" = 
	CASE 
		WHEN "PricePerUnit_Cleaned" = 1 THEN 'Cookie'
		WHEN "PricePerUnit_Cleaned" = 1.5 THEN 'Tea'
		WHEN "PricePerUnit_Cleaned" = 2 THEN 'Coffee'
		WHEN "PricePerUnit_Cleaned" = 5 THEN 'Salad'
		ELSE "Item_Cleaned"
	END
WHERE "Item_Cleaned" IS NULL;


-- OPTIONAL: Select the rows without NULL values.
SELECT "Transaction ID", "Item_Cleaned", "Quantity_Cleaned", "PricePerUnit_Cleaned", 
"TotalSpent_Cleaned", "PaymentMethod_Cleaned", "Location_Cleaned", "TransactionDate_Cleaned",
"Day", "Month"
FROM public."Cafe_Sales"
WHERE "Item_Cleaned" IS NOT NULL AND 
"Quantity_Cleaned" IS NOT NULL AND
"PricePerUnit_Complete" IS NOT NULL AND
"TotalSpent_Cleaned" IS NOT NULL
ORDER BY "Transaction ID" ASC;