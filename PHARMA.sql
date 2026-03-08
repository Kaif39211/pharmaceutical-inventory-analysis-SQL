CREATE TABLE fact_pharma_inventory (
    batch_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(100),
    mfg_date DATE NOT NULL,
    exp_date DATE NOT NULL,
    qty_on_hand INT DEFAULT 0,
    mrp_unit_price DECIMAL(10, 2),
    unit_cost DECIMAL(10, 2)
);	


select * from fact_pharma_inventory;

COPY fact_pharma_inventory(batch_id, product_name, mfg_date, exp_date, qty_on_hand, mrp_unit_price, unit_cost)
FROM '/path/to/your/local/directory/Expiry_Risk_Compliance_Supply_Chain_35000_Rows_pharma.csv'
DELIMITER ','
CSV HEADER;

select * from fact_pharma_inventory;

SELECT COUNT(*) FROM fact_pharma_inventory;

SELECT 
    COUNT(*) - COUNT(batch_id) AS missing_ids,
    COUNT(*) - COUNT(exp_date) AS missing_expiry_dates
FROM fact_pharma_inventory;



                                       --Inventory Visibility

--Show only 20 rows

SELECT
	*
FROM
	FACT_PHARMA_INVENTORY
LIMIT
	20;

--Count the total_unique_products 

SELECT COUNT(DISTINCT product_name) AS total_unique_products 
FROM fact_pharma_inventory;

--Total Capital Locked

SELECT SUM(qty_on_hand * unit_cost) AS absolute_total_value 
FROM fact_pharma_inventory;

--Inventory Value per Product (Top 10 Highest)

SELECT PRODUCT_NAME,SUM(qty_on_hand * unit_cost) as	top_10_value_product from fact_pharma_inventory group by PRODUCT_NAME
order by top_10_value_product desc
limit 10;

--Expiry Awareness (The 30-Day Warning)

SELECT
	PRODUCT_NAME,
	EXP_DATE
FROM
	FACT_PHARMA_INVENTORY
WHERE
	EXP_DATE BETWEEN CURRENT_DATE AND CURRENT_DATE  + INTERVAL '30 days'
ORDER BY
	EXP_DATE;

--Count of Products by Expiry Year

select  extract(year from exp_date) as expiry_year,
        count(*) as batch_count
		from FACT_PHARMA_INVENTORY
		group by extract(year from exp_date)
		order by expiry_year;

--The Expiry Proximity Model (Risk Buckets)

select batch_id,product_name,exp_date,
case when (exp_date - current_date) <=30 then 'Critical Risk'
     when (exp_date - current_date) between 31 and 90 then 'High Risk'
	 when (exp_date - current_date) between 91 and 180 then 'Medium Risk'
	 when (exp_date - current_date) >180 then 'safe'
	 end as Risk_Buckets from FACT_PHARMA_INVENTORY
	 order by exp_date;

--Expiry Exposure % (Calculate the percentage of our total inventory value that is expiring within the next 90 days)

WITH total_inventory AS (
    SELECT 
        SUM(qty_on_hand * unit_cost) AS total_value
    FROM fact_pharma_inventory
),

expiry_90_days AS (
    SELECT 
        SUM(qty_on_hand * unit_cost) AS expiring_value
    FROM fact_pharma_inventory
    WHERE exp_date <= CURRENT_DATE + INTERVAL '90 days'
)

SELECT 
    e.expiring_value,
    t.total_value,
    ROUND(
        (e.expiring_value / t.total_value) * 100,
        2
    ) AS expiry_exposure_percent
FROM total_inventory t
CROSS JOIN expiry_90_days e;


-- POST-MORTEM ANALYSIS: Calculates the total sunk cost (hard loss) and lost opportunity (lost revenue) for inventory that has already expired. Identifies the top 10 worst offenders.
WITH
	EXPIRE_PRODUCT AS (
		SELECT
			PRODUCT_NAME,
			BATCH_ID,
			EXP_DATE,
			QTY_ON_HAND,
			MRP_UNIT_PRICE,
			UNIT_COST
		FROM
			FACT_PHARMA_INVENTORY
		WHERE
			EXP_DATE <= CURRENT_DATE - 1
	)
SELECT
	PRODUCT_NAME,
	COUNT(BATCH_ID) AS EXP_BATCH_ID,
	SUM(QTY_ON_HAND * UNIT_COST) AS TOTAL_HARD_LOSS,
	SUM(QTY_ON_HAND * MRP_UNIT_PRICE) AS TOTAL_LOST_REVENUE
FROM
	EXPIRE_PRODUCT
GROUP BY
	PRODUCT_NAME
ORDER BY
	TOTAL_HARD_LOSS DESC
LIMIT
	10;


--90-Day Risk Contribution Percentage(all the money sitting in the 90-day risk bucket, what percentage is each specific product responsible for)

SELECT
    PRODUCT_NAME,
    SUM(QTY_ON_HAND * UNIT_COST) AS PRODUCT_RISK_VALUE,
    ROUND(
        SUM(QTY_ON_HAND * UNIT_COST) * 100.0
        / SUM(SUM(QTY_ON_HAND * UNIT_COST)) OVER (),
        2 
    ) AS RISK_PERCENTAGE
FROM
    FACT_PHARMA_INVENTORY
WHERE
    EXP_DATE BETWEEN CURRENT_DATE 
                 AND CURRENT_DATE + INTERVAL '90 days'
GROUP BY
    PRODUCT_NAME
ORDER BY
    PRODUCT_RISK_VALUE DESC
LIMIT 10;
	
--The Dead Stock Query (The item must still be physically in the warehouse,
                        --The item must be older than 365 days since it was manufactured,
                        --total count of dead batches,absolute Total Capital Locked in this dead stock)

SELECT
	PRODUCT_NAME,
	COUNT(BATCH_ID) AS DEAD_BATCHES,
	SUM(QTY_ON_HAND * UNIT_COST) AS TOTAL_CAPITAL_LOCKED_DEADSTOCK
FROM
	FACT_PHARMA_INVENTORY
WHERE
	QTY_ON_HAND > 0
	AND (CURRENT_DATE - MFG_DATE > 365)
GROUP BY
	PRODUCT_NAME
ORDER BY
	TOTAL_CAPITAL_LOCKED_DEADSTOCK DESC
LIMIT
	10;




















































































































