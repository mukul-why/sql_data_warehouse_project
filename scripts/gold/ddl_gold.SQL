/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
		ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key,
		ci.cst_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		la.cntry AS country,
		CASE 
			WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
			ELSE COALESCE( ca.gen , 'N/A')
		END AS gender,
		ci.cst_marital_status AS marital_status,
		ca.bdate as birthdate,
		ci.cst_create_date AS create_date 
FROM		silver_crm_cust_info AS ci
LEFT JOIN	silver_erp_cust_az12 AS ca
ON			ci.cst_key = ca.cid
LEFT JOIN	silver_erp_loc_a101 AS la
ON			ci.cst_key = la.cid;
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
SELECT 
		ROW_NUMBER() OVER(ORDER BY pc.prd_start_dt, pc.prd_key) AS product_key,
		pc.prd_id AS product_id,
		pc.prd_key AS product_number,
		pc.prd_nm AS product_name,
		pc.cat_id AS category_id,
		pd.cat AS category,
		pd.subcat AS subcategory ,
		pd.maintenance,
		pc.prd_cost AS cost,
		pc.prd_line AS product_line,
		pc.prd_start_dt AS start_date
FROM silver_crm_prd_info AS pc
LEFT JOIN silver_erp_px_cat_g1v2 AS pd
ON pc.cat_id = pd.id
WHERE pc.prd_end_dt IS NULL; --FILTER OUT HISTORICAL DATA (only current data is shown)
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
		sls_ord_num AS order_number,
		p.product_key,
		c.customer_key,
		sls_order_dt AS order_date,
		sls_ship_dt AS shipping_date,
		sls_due_dt AS due_date,
		sls_sales AS sales_amount,
		sls_quantity AS quantity,
		sls_price AS price

FROM silver_crm_sales_details s
LEFT JOIN gold.dim_products p
ON s.sls_prd_key = p.product_number
LEFT JOIN gold.dim_customers c
ON s.sls_cust_id = c.customer_id
