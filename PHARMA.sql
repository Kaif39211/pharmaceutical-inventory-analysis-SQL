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

copy fact_pharma_inventory(batch_id,product_name,mfg_date,exp_date,qty_on_hand,mrp_unit_price,unit_cost)
from 'C:\Users\kaif\OneDrive\Desktop\Expiry_Risk_Compliance_Supply_Chain_35000_Rows  pharma.csv'
delimiter','
csv header;

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

SELECT		
	COUNT(DISTINCT PRODUCT_NAME) AS TOTAL_UNIQUE_PRODUCTS
FROM
	FACT_PHARMA_INVENTORY;
--Total Capital Locked

SELECT
	SUM(QTY_ON_HAND * UNIT_COST) AS ABSOLUTE_TOTAL_VALUE
FROM
	FACT_PHARMA_INVENTORY;

--Inventory Value per Product (Top 10 Highest)

SELECT
	PRODUCT_NAME,
	SUM(QTY_ON_HAND * UNIT_COST) AS TOP_10_VALUE_PRODUCT
FROM
	FACT_PHARMA_INVENTORY
GROUP BY
	PRODUCT_NAME
ORDER BY
	TOP_10_VALUE_PRODUCT DESC
LIMIT
	10;

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

SELECT
	EXTRACT(
		YEAR
		FROM
			EXP_DATE
	) AS EXPIRY_YEAR,
	COUNT(*) AS BATCH_COUNT
FROM
	FACT_PHARMA_INVENTORY
GROUP BY
	EXTRACT(
		YEAR
		FROM
			EXP_DATE
	)
ORDER BY
	EXPIRY_YEAR;
--The Expiry Proximity Model (Risk Buckets)

SELECT
	BATCH_ID,
	PRODUCT_NAME,
	EXP_DATE,
	CASE
		WHEN (EXP_DATE - CURRENT_DATE) <= 30 THEN 'Critical Risk'
		WHEN (EXP_DATE - CURRENT_DATE) BETWEEN 31 AND 90  THEN 'High Risk'
		WHEN (EXP_DATE - CURRENT_DATE) BETWEEN 91 AND 180  THEN 'Medium Risk'
		WHEN (EXP_DATE - CURRENT_DATE) > 180 THEN 'safe'
	END AS RISK_BUCKETS
FROM
	FACT_PHARMA_INVENTORY
ORDER BY
	EXP_DATE;

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
    WHERE exp_date >= CURRENT_DATE + INTERVAL '90 days'
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


--The Post-Mortem Analysis(analyzes batches that have already expired)

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
		SUM(QTY_ON_HAND * UNIT_COST) * 100.0 / SUM(SUM(QTY_ON_HAND * UNIT_COST)) OVER (),
		2
	) AS RISK_PERCENTAGE
FROM
	FACT_PHARMA_INVENTORY
WHERE
	EXP_DATE BETWEEN CURRENT_DATE AND CURRENT_DATE  + INTERVAL '90 days'
GROUP BY
	PRODUCT_NAME
ORDER BY
	PRODUCT_RISK_VALUE DESC
LIMIT
	10;
	
--The Dead Stock Query (The item must still be physically in the warehouse,
                        --The item must be older than 365 days since it w	as manufactured,
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


ALTER TABLE fact_pharma_inventory
ADD COLUMN warehouse_id VARCHAR(20),
ADD COLUMN monthly_sales_volume INT DEFAULT 0,
ADD COLUMN discount_rate DECIMAL(5, 2) DEFAULT 0.00,
ADD COLUMN temperature_band VARCHAR(20),
ADD COLUMN inspection_status VARCHAR(15);

SELECT * FROM fact_pharma_inventory;


TRUNCATE TABLE fact_pharma_inventory;


copy fact_pharma_inventory(batch_id,product_name,mfg_date,exp_date,qty_on_hand,mrp_unit_price,unit_cost)
from 'C:\Users\kaif\OneDrive\Desktop\Expiry_Risk_Compliance_Supply_Chain_35000_Rows  pharma.csv'
delimiter','
csv header;

SELECT * FROM fact_pharma_inventory;

--Total Products/Total Value/Missing IDs

SELECT COUNT(DISTINCT PRODUCT_NAME) AS TOTAL_UNIQUE_PRODUCTS 
FROM FACT_PHARMA_INVENTORY;

SELECT SUM(QTY_ON_HAND * UNIT_COST) AS ABSOLUTE_TOTAL_VALUE 
FROM FACT_PHARMA_INVENTORY;

SELECT COUNT(CASE WHEN BATCH_ID IS NULL THEN 1 END) AS missing_ids 
FROM FACT_PHARMA_INVENTORY;

--Top 10 High-Value Products

SELECT PRODUCT_NAME, 
       SUM(QTY_ON_HAND * UNIT_COST) AS TOP_10_VALUE_PRODUCT
FROM FACT_PHARMA_INVENTORY
WHERE QTY_ON_HAND > 0
GROUP BY PRODUCT_NAME
ORDER BY TOP_10_VALUE_PRODUCT DESC 
LIMIT 10;

--The 90-Day Cash Trap

SELECT
	CASE
		WHEN (EXP_DATE - CURRENT_DATE) <= 30 THEN 'Critical Risk'
		WHEN (EXP_DATE - CURRENT_DATE) BETWEEN 31 AND 90  THEN 'High Risk'
		WHEN (EXP_DATE - CURRENT_DATE) BETWEEN 91 AND 180  THEN 'Medium Risk'
		WHEN (EXP_DATE - CURRENT_DATE) > 180 THEN 'Safe'
	END AS RISK_BUCKETS,
    SUM(QTY_ON_HAND * UNIT_COST) AS total_value_at_risk
FROM FACT_PHARMA_INVENTORY
WHERE QTY_ON_HAND > 0
GROUP BY 
    CASE
		WHEN (EXP_DATE - CURRENT_DATE) <= 30 THEN 'Critical Risk'
		WHEN (EXP_DATE - CURRENT_DATE) BETWEEN 31 AND 90  THEN 'High Risk'
		WHEN (EXP_DATE - CURRENT_DATE) BETWEEN 91 AND 180  THEN 'Medium Risk'
		WHEN (EXP_DATE - CURRENT_DATE) > 180 THEN 'Safe'
	END;


--Product-Level Risk Contribution (%)

SELECT PRODUCT_NAME, 
       SUM(QTY_ON_HAND * UNIT_COST) AS RISK_VALUE,
       ROUND(SUM(QTY_ON_HAND * UNIT_COST) * 100.0 / SUM(SUM(QTY_ON_HAND * UNIT_COST)) OVER(), 2) AS RISK_PERCENTAGE
FROM FACT_PHARMA_INVENTORY
WHERE EXP_DATE <= CURRENT_DATE + INTERVAL '90 days' 
  AND QTY_ON_HAND > 0
GROUP BY PRODUCT_NAME
ORDER BY RISK_VALUE DESC 
LIMIT 10;

--Zombie Stock Isolation

SELECT PRODUCT_NAME, 
       COUNT(BATCH_ID) AS DEAD_BATCHES, 
       SUM(QTY_ON_HAND * UNIT_COST) AS TOTAL_CAPITAL_LOCKED_DEADSTOCK
FROM FACT_PHARMA_INVENTORY
WHERE QTY_ON_HAND > 0 
  AND (CURRENT_DATE - MFG_DATE) > 365 
GROUP BY PRODUCT_NAME
ORDER BY TOTAL_CAPITAL_LOCKED_DEADSTOCK DESC 
LIMIT 5;

--Slow-Mover Detection

SELECT 
    product_name, 
    unit_cost, 
    qty_on_hand, 
    monthly_sales_volume
FROM fact_pharma_inventory
WHERE monthly_sales_volume < 5 
  AND qty_on_hand > 200
ORDER BY qty_on_hand DESC;


--Warehouse Risk Ranking

WITH WarehouseScoring AS (
    SELECT 
        warehouse_id,
        SUM(CASE WHEN exp_date <= CURRENT_DATE + INTERVAL '90 days' THEN 3 ELSE 0 END) AS expiry_penalty,
        SUM(CASE WHEN inspection_status = 'Fail' THEN 4 ELSE 0 END) AS compliance_penalty
    FROM fact_pharma_inventory 
    GROUP BY warehouse_id
)
SELECT 
    warehouse_id, 
    (expiry_penalty + compliance_penalty) AS composite_risk_score
FROM WarehouseScoring 
ORDER BY composite_risk_score DESC;


--Discount Effectiveness

SELECT 
    product_name, 
    discount_rate, 
    ROUND((monthly_sales_volume * 1.0 / NULLIF(qty_on_hand, 0)), 4) AS turnover_ratio
FROM fact_pharma_inventory
WHERE discount_rate > 0 
  AND qty_on_hand > 0
ORDER BY discount_rate DESC;
