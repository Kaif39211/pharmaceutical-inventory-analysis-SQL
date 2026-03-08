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