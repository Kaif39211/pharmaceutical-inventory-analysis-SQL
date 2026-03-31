# Pharmaceutical Inventory Audit — Expiry Risk & Capital Exposure Analysis

> **35,000+ Records | PostgreSQL | CTEs · Window Functions · CASE Logic**

---

<img width="187" height="81" alt="image" src="https://github.com/user-attachments/assets/36c2fc4a-42f7-4026-86c3-0a042a8e44c2" />
<img width="180" height="89" alt="image" src="https://github.com/user-attachments/assets/554583c8-6a18-4295-9fdb-db8f8af38969" />
<img width="127" height="86" alt="image" src="https://github.com/user-attachments/assets/3cd0a0a6-c1cc-40fe-8a35-81af364380c4" />


---

## The Problem

In pharmaceutical supply chains, sitting inventory is never neutral. It is either **moving toward revenue** or **moving toward a write-off**. Expiry dates are hard deadlines. Regulatory gaps are legal liability. And dead stock is capital that has quietly stopped working.

This project is a full-spectrum operational audit of 35,000+ global pharmaceutical inventory records — designed to surface exactly where the money is stuck, where the risk is building, and what needs to happen next.

---

## What Was Built

A series of PostgreSQL analytical models across **4 operational phases**, each designed to answer a specific financial question:

| Phase | Focus |
|---|---|
| Phase 1 | Capital Baseline & Product Concentration |
| Phase 2 | 90-Day Expiry Risk Exposure |
| Phase 3 | Dead Stock Isolation & Historical Loss |
| Phase 4 | Warehouse Risk Ranking & Operational Efficiency |

---

## Technical Stack

- **Database Engine:** PostgreSQL
- **Window Functions** — Real-time risk contribution percentages across the full inventory
- **CTEs (Common Table Expressions)** — Multi-stage expiry exposure and post-mortem calculations
- **CASE Logic** — Automated triage buckets replacing manual tracking
- **Data QA** — NULL-handling and batch-integrity checks before any analysis runs

---

## The 12-Point Audit: Findings & Impact

### Phase 1 — Capital Baseline & Visibility

**1. Total Capital Lockup**
Calculated the exact working capital sitting in storage across all warehouses using `SUM(Unit_Cost × Quantity_On_Hand)`. This is the number that anchors every downstream decision.

**2. Top 10 High-Value Products**
Identified the 10 products consuming the largest share of inventory value. These are the SKUs that demand disproportionate security, climate control, and sales attention.


<img width="326" height="276" alt="image" src="https://github.com/user-attachments/assets/5c4b044b-d409-4795-ab0b-5ecac377f2a2" />


**3. Data Integrity Audit**
Scanned all 35,000+ rows for missing `Batch_ID` and `Exp_Date`. Undocumented batches are not a data quality issue — they are a compliance failure waiting to happen.

---

### Phase 2 — Expiry Risk & Financial Exposure

**4. The 90-Day Cash Trap — 12.79% Exposure**
The Expiry Exposure Model (built via CTEs) found that **12.79% of total warehouse capital** is locked in inventory expiring within 90 days. That is not a footnote. That is a cash flow threat requiring immediate B2B discount protocols.


<img width="259" height="125" alt="image" src="https://github.com/user-attachments/assets/7c7ce033-724d-4df5-9d68-3b4e70d0db74" />


**5. Automated Expiry Proximity Triage**
A `CASE` statement model auto-categorizes every SKU into four risk buckets:

| Bucket | Window | Action |
|---|---|---|
| 🔴 Critical Risk | ≤ 30 days | Immediate liquidation |
| 🟠 High Risk | 31–90 days | B2B discounting |
| 🟡 Medium Risk | 91–180 days | Monitor & prioritize |
| 🟢 Safe | > 180 days | Standard operations |

**6. Product-Level Risk Contribution (%)**
Window functions calculate each SKU's exact share of the total 90-day risk value. Procurement knows precisely which products are driving exposure — not just that exposure exists.


<img width="396" height="273" alt="image" src="https://github.com/user-attachments/assets/63ddc0d4-8341-475b-9145-95399b9a848c" />


---

### Phase 3 — Dead Stock & Historical Loss

**7. Zombie Stock Isolation**
Isolated inventory physically unmoved for over 365 days with zero recent sales. `DermaLux_458` alone accounts for **$172.3M in locked capital** — sitting untouched for over a year.

<img width="583" height="153" alt="image" src="https://github.com/user-attachments/assets/2e62262f-7004-4bde-a53b-d095e168102c" />


**8. Historical Revenue Post-Mortem**
Analyzed expired batches to calculate total hard loss vs. total lost revenue opportunity. `GlucoBalance_494` is the worst historical offender — **over 7cr in lost revenue** from expired stock that was never moved.

**9. Slow-Mover Detection — Future Dead Stock Flag**
Flagged SKUs with monthly sales under 5 units, holding over 200 units in stock at high unit cost. These are not dead yet — but the model catches them before they cross the 365-day threshold.


<img width="498" height="10062" alt="image" src="https://github.com/user-attachments/assets/066130d3-a36e-4120-9553-10d9e0e2d3a9" />


---

### Phase 4 — Advanced Operational Analytics

**10. Warehouse Risk Ranking (Composite Score)**
Assigned composite risk scores per warehouse (+3 for expiry < 90 days, +4 for non-compliant batches, etc.) to rank which facilities need immediate intervention. Regional managers get a clear priority list, not a raw data dump.


<img width="278" height="126" alt="image" src="https://github.com/user-attachments/assets/a9bd20c5-a4a6-4018-9c2c-9e94f4e5d7a8" />


**11. Cold-Chain Integrity Analysis**
Segmented inspection failure rates by temperature band (2–8°C vs. 16–25°C). Infrastructure failures destroying stock before expiry are isolated from inventory planning failures — two different problems requiring two different fixes.

**12. Discount Effectiveness Simulation**
Modeled the correlation between discount rate and actual turnover ratio. The question being answered: are current discount strategies actually moving high-risk stock, or are they failing silently?

<img width="368" height="24030" alt="image" src="https://github.com/user-attachments/assets/57b4104d-d276-4b6f-ae5a-3735d52a8232" />


---

## Core SQL — Architecture Highlights

### I. Expiry Exposure Model (CTE)

```sql
WITH total_inventory AS (
    SELECT SUM(qty_on_hand * unit_cost) AS total_value
    FROM fact_pharma_inventory
),
expiry_90_days AS (
    SELECT SUM(qty_on_hand * unit_cost) AS expiring_value
    FROM fact_pharma_inventory
    WHERE exp_date <= CURRENT_DATE + INTERVAL '90 days'
    AND exp_date >= CURRENT_DATE
)
SELECT
    e.expiring_value,
    t.total_value,
    ROUND((e.expiring_value / t.total_value) * 100, 2) AS expiry_exposure_percent
FROM total_inventory t
CROSS JOIN expiry_90_days e;
```

### II. Dead Stock Targeter

```sql
SELECT
    product_name,
    COUNT(batch_id)                        AS dead_batches,
    SUM(qty_on_hand * unit_cost)           AS total_capital_locked
FROM fact_pharma_inventory
WHERE qty_on_hand > 0
  AND (CURRENT_DATE - mfg_date) > 365
GROUP BY product_name
ORDER BY total_capital_locked DESC
LIMIT 10;
```

### III. Automated Risk Triage (CASE Buckets)

```sql
SELECT
    product_name,
    exp_date,
    CASE
        WHEN exp_date <= CURRENT_DATE + INTERVAL '30 days'  THEN 'Critical Risk'
        WHEN exp_date <= CURRENT_DATE + INTERVAL '90 days'  THEN 'High Risk'
        WHEN exp_date <= CURRENT_DATE + INTERVAL '180 days' THEN 'Medium Risk'
        ELSE 'Safe'
    END AS risk_bucket
FROM fact_pharma_inventory
WHERE qty_on_hand > 0
ORDER BY exp_date ASC;
```

> Full script: [`PHARMA.sql`](./PHARMA.sql)

---

## Executive Recommendations

**1. Immediate Liquidation Protocol**
Target all Critical Risk (0–30 day) inventory and the `DermaLux_458` dead stock position for immediate B2B bulk discounting. Recovering 40–60% of capital is better than writing off 100%.

**2. Procurement Freeze — GlucoBalance_494**
Hard stop on new procurement until the 7cr historical cash bleed is stabilized and turnover ratios show improvement. Buying more of a non-moving SKU is not a strategy.

**3. FEFO Picking Implementation**
Integrate the `risk_buckets` query into the warehouse management system (WMS) daily workflow. Shift warehouse picking from FIFO (First-In-First-Out) to **FEFO (First-Expired-First-Out)** — expiry date drives pick sequence, not arrival date.

**4. Slow-Mover Escalation Cycle**
Run the slow-mover detection query monthly. Any SKU flagged for 3 consecutive months gets automatic escalation to the procurement review board before it becomes the next `DermaLux_458`.

---

## Dataset

- **Records:** 35,000+ pharmaceutical inventory rows
- **Source:** Simulated dataset modeled on real-world pharma supply chain structures
- **Schema:** Product, Batch, Warehouse, Expiry Date, Manufacturing Date, Quantity, Cost, Sales Volume, Inspection Status, Temperature Band, Discount Rate

---

*Role: Data Analyst — Inventory & Operational Risk*



**Role: Data Analyst — Sales & Logistics Operations** 

 
 **Others Project -**
 
 1) https://github.com/Kaif39211/pharmaceutical-inventory-analysis-SQL 
                                              2) https://github.com/Kaif39211/KM_Logistics_2022_Analysis.xlsx


                      
## **Contact: [LinkedIn](http://www.linkedin.com/in/kaif-mahaldar-18300b333) | [Email](mailto:kaifmahaldar5@gmail.com)**
