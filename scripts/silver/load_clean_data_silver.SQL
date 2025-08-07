/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @strt_time DATETIME, @end_time DATETIME,@batch_strt_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_strt_time = GETDATE();
		PRINT '======================';
		PRINT 'LOADING SILVER LAYER';
		PRINT '======================';
		PRINT '=============================================================';
		PRINT '----------------------';
		PRINT 'LOADING CRM';
		PRINT '----------------------';		

--Loading data into silver_crm_cust_info

		SET @strt_time = GETDATE();
		PRINT 'TRUNCATING TABLE: silver_crm_cust_info';
		TRUNCATE TABLE silver_crm_cust_info;
		PRINT 'INSERTING INTO TABLE: silver_crm_cust_info';
		INSERT INTO silver_crm_cust_info (
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_marital_status,
				cst_gndr,
				cst_create_date
				)


		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname, --Removing white spaces from firstname
			TRIM(cst_lastname) AS cst_lastname, --Removing white spaces from lastname

			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' --Mapping 'S' as Single
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'--Mapping 'M' as Married
			ELSE 'N/A'
			END AS cst_marital_status,/* Data Normalization/standardaization 
			means maps coded values to meaningfull, user-friendly descriptions */
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' -- Mapping 'F' as Female
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' -- Mapping 'M' as Male
			ELSE 'N/A' 
			END AS cst_gndr,/* Data Normalization/standardaization 
			means maps coded values to meaningfull, user-friendly descriptions */
			cst_create_date

		FROM (
		-- Removing duplicates in primary key
			SELECT *,
			ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_key
			FROM bronze_crm_cust_info
			WHERE cst_id IS NOT NULL
			)t
		WHERE flag_key = 1
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST (DATEDIFF(SECOND,@strt_time , @end_time) AS NVARCHAR(50) ) + ' seconds' 
		PRINT '-------------------------------------------------------------';

--Loading data into silver_crm_prd_info
		SET @strt_time = GETDATE();

		PRINT 'TRUNCATING TABLE: silver_crm_prd_info';
		TRUNCATE TABLE silver_crm_prd_info;
		PRINT 'INSERTING INTO TABLE: silver_crm_prd_info';
		INSERT INTO silver_crm_prd_info (
					prd_id,
					cat_id,
					prd_key,
					prd_nm,
					prd_cost,
					prd_line,
					prd_start_dt,
					prd_end_dt)

		SELECT 
			prd_id, -- No issues in prd_id primary key

			SUBSTRING(prd_key, 1, 5) AS cat_id, /* Created a cat_id( Category ID) from prd_key
			so that we can use it in table :bronze_erp_px_cat_g1v2 */

			SUBSTRING(prd_key, 7, len(prd_key)) as prd_key ,/* Created a proper prd_key by removing 
			Category ID from start */

			prd_nm,

			ISNULL(prd_cost, 0) AS prd_cost, /* Handling NULLs ( Assigning NULLs value 0 ) */

			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'R' THEN 'Road'
				WHEN 'T' THEN 'Touring'
				ELSE 'N/A'
			END AS prd_line,/* Mapping different values a proper name */

			CAST(prd_start_dt AS DATE) AS prd_start_dt, /* Removing unwanted time details
			from Start Date */

			CAST((LEAD(prd_start_dt) OVER(PARTITION BY PRD_KEY ORDER BY prd_start_dt)-1) AS DATE) AS prd_end_dt
			/* Fixes the End date cause Start date greater than End Date
			also removing the unwanted time details */
		FROM bronze_crm_prd_info
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST (DATEDIFF(SECOND,@strt_time , @end_time) AS NVARCHAR(50) ) + ' seconds' ;
		PRINT '-------------------------------------------------------------';
--Loading into silver_crm_sales_details

		SET @strt_time = GETDATE();
		PRINT 'TRUNCATING TABLE: silver_crm_sales_details';
		TRUNCATE TABLE silver_crm_sales_details;
		PRINT 'INSERTING INTO TABLE: silver_crm_sales_details';

		INSERT INTO silver_crm_sales_details (
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				sls_order_dt,
				sls_ship_dt,
				sls_due_dt,
				sls_sales,
				sls_quantity,
				sls_price)

		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,

			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt, -- Correcting Invalid data and Casting Datatype

			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,-- Correcting Invalid data and Casting Datatype

			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,-- Correcting Invalid data and Casting Datatype

			CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales,-- Recalculating Sales if value is missing or incorrect

			sls_quantity,

			CASE 
				WHEN sls_price IS NULL OR sls_price <= 0 THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
				ELSE sls_price
			END AS sls_price -- Recalculating price if value is incorrect
		FROM bronze_crm_sales_details

		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST (DATEDIFF(SECOND,@strt_time , @end_time) AS NVARCHAR(50) ) + ' seconds' ;
		PRINT '-------------------------------------------------------------';
		PRINT '=============================================================';
		
		PRINT '----------------------';
		PRINT 'LOADING ERP';
		PRINT '----------------------';	
--Loading data into silver_erp_cust_az12
		SET @strt_time = GETDATE();
		PRINT 'TRUNCATING TABLE: silver_erp_cust_az12';
		TRUNCATE TABLE silver_erp_cust_az12;
		PRINT 'INSERTING INTO TABLE: silver_erp_cust_az12';

		INSERT INTO silver_erp_cust_az12(
			cid,
			bdate,
			gen
		)


		SELECT

			CASE
				WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
				ELSE cid
			END AS cid,-- Removing unwanted NAS so that it can be used as product key in another table

			CASE
				WHEN bdate > GETDATE() THEN NULL
				ELSE bdate
			END bdate, --Assigning null to the bdate which is greater than today's date

			CASE
				WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
				ELSE 'N/A'
			END AS gen -- Correcting the gender
		FROM bronze_erp_cust_az12
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST (DATEDIFF(SECOND,@strt_time , @end_time) AS NVARCHAR(50) ) + ' seconds'; 
		PRINT '-------------------------------------------------------------';
		
		
--Loading data into silver_erp_loc_a101
		SET @strt_time = GETDATE();
		PRINT 'TRUNCATING TABLE: silver_erp_loc_a101';
		TRUNCATE TABLE silver_erp_loc_a101;
		PRINT 'INSERTING INTO TABLE: silver_erp_loc_a101';
		INSERT INTO silver_erp_loc_a101 ( cid, cntry)

		SELECT 
			REPLACE(cid,'-','') AS cid,--Correcting cid so that it can be used as customer key
			CASE 
				WHEN UPPER(TRIM(cntry)) IN ('DE','GERMANY') THEN 'Germany'
				WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
				WHEN UPPER(TRIM(cntry )) = '' OR cntry IS NULL THEN 'N/A'
				ELSE TRIM(cntry)
			END AS cntry -- Correcting the country
		FROM bronze_erp_loc_a101
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST (DATEDIFF(SECOND,@strt_time , @end_time) AS NVARCHAR(50) ) + ' seconds' ;
		PRINT '-------------------------------------------------------------';

--Loading data into silver_erp_px_cat_g1v2
		SET @strt_time = GETDATE();
		PRINT 'TRUNCATING TABLE: silver_erp_px_cat_g1v2';
		TRUNCATE TABLE silver_erp_px_cat_g1v2;
		PRINT 'INSERTING INTO TABLE: silver_erp_px_cat_g1v2';

		INSERT INTO silver_erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance)
		SELECT 
			REPLACE(id,'_','-'),
			cat,
			subcat,
			maintenance
		FROM bronze_erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST (DATEDIFF(SECOND,@strt_time , @end_time) AS NVARCHAR(50) ) + ' seconds'; 
		PRINT '-------------------------------------------------------------';
		PRINT '=============================================================';
		SET @batch_end_time = GETDATE();

		PRINT '///////////////////////////////////';
		PRINT 'TOTAL LOADING TIME: ' + CAST (DATEDIFF(SECOND,@batch_strt_time , @batch_end_time) AS NVARCHAR(50) ) + ' seconds';
		PRINT '//////////////////////////////////';
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
