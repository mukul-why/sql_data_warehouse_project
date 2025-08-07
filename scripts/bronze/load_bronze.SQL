/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from CSV files to bronze tables.

Parameters:
	None. 
	This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @bronze_strt_time DATETIME, @bronze_end_time DATETIME;
	BEGIN TRY
		PRINT '===============================================================';
		PRINT 'LOADING TO BRONZE LAYER';
		PRINT '===============================================================';
		SET @bronze_strt_time = GETDATE();
	/*----------------------------------------------------------------------------------------------*/
		PRINT '---------------------------------------------------------------';
		PRINT 'LOADING DATA TO CRM TABLES';
		PRINT '---------------------------------------------------------------';
		/*--Inserting Data into bronze_crm_cust_info*/
		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze_crm_cust_info';
		TRUNCATE TABLE bronze_crm_cust_info;

		PRINT 'INSERTING INTO bronze_crm_cust_info';
		BULK INSERT bronze_crm_cust_info
		FROM 'C:\MyProjects\SQL Datawarehouse Project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();	
		PRINT '------------------';
		PRINT 'LOAD DURATION =' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + 'seconds';
		PRINT '------------------';
	/*----------------------------------------------------------------------------------------------
		--Inserting Data into bronze_crm_prd_info*/
		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze_crm_prd_info';
		TRUNCATE TABLE bronze_crm_prd_info;
		PRINT 'INSERTING INTO bronze_crm_prd_info';
		BULK INSERT bronze_crm_prd_info
		FROM 'C:\MyProjects\SQL Datawarehouse Project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT '------------------';
		PRINT 'LOAD DURATION =' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + 'seconds';
		PRINT '------------------';	
	/*----------------------------------------------------------------------------------------------
		--Inserting Data into bronze_crm_sales_details*/
		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze_crm_sales_details';
		TRUNCATE TABLE bronze_crm_sales_details;
		PRINT 'INSERTING INTO bronze_crm_sales_details';
		BULK INSERT bronze_crm_sales_details
		FROM 'C:\MyProjects\SQL Datawarehouse Project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			); 
		SET @end_time = GETDATE();	
		PRINT '------------------';
		PRINT 'LOAD DURATION =' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + 'seconds';
		PRINT '------------------';
	/*----------------------------------------------------------------------------------------------*/
		PRINT '---------------------------------------------------------------';
		PRINT 'LOADING DATA TO ERP TABLES';
		PRINT '---------------------------------------------------------------';
		/*--Inserting Data into bronze_erp_cust_az12*/
		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze_erp_cust_az12';
		TRUNCATE TABLE bronze_erp_cust_az12;
		PRINT 'INSERTING INTO bronze_erp_cust_az12';
		BULK INSERT bronze_erp_cust_az12
		FROM 'C:\MyProjects\SQL Datawarehouse Project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT '------------------';
		PRINT 'LOAD DURATION =' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + 'seconds';
		PRINT '------------------';	
	/*----------------------------------------------------------------------------------------------
		--Inserting Data into bronze_erp_loc_a101*/
		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze_erp_loc_a101';
		TRUNCATE TABLE bronze_erp_loc_a101;
		PRINT 'INSERTING INTO bronze_erp_loc_a101';
		BULK INSERT bronze_erp_loc_a101
		FROM 'C:\MyProjects\SQL Datawarehouse Project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT '------------------';
		PRINT 'LOAD DURATION =' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + 'seconds';
		PRINT '------------------';	
	/*--------------------------------------------------------------------------------------------
		--Inserting Data into bronze_erp_px_cat_g1v2*/
		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze_erp_px_cat_g1v2';
		TRUNCATE TABLE bronze_erp_px_cat_g1v2;
		PRINT 'INSERTING INTO bronze_erp_px_cat_g1v2';
		BULK INSERT bronze_erp_px_cat_g1v2
		FROM 'C:\MyProjects\SQL Datawarehouse Project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT '------------------';
		PRINT 'LOAD DURATION =' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + 'seconds';
		PRINT '------------------';	

		SET @bronze_end_time = GETDATE();
		PRINT '////////////////////////////////////';
		PRINT 'LOADING BRONZE LAYER IS COMPELETED!!!';
		PRINT 'TOTAL DURATION TO LOADING BRONZE LAYER = ' + CAST(DATEDIFF(SECOND, @bronze_strt_time, @bronze_end_time) AS NVARCHAR(10)) + 'seconds';
		PRINT '////////////////////////////////////';
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
