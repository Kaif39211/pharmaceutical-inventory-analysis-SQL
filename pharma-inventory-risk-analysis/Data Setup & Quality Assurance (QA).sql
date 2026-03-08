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

-- IMPORTANT: Replace the placeholder file path below with the local directory where you saved the 'pharma.csv' file on your machine.
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



--Show only 20 rows

SELECT
	*
FROM
	FACT_PHARMA_INVENTORY
LIMIT
	20;