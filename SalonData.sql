
--1/ Create DATABASE
CREATE DATABASE SALONDATA ON 
(NAME=N'SALONDATA', FILENAME=N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\SALONDATA.mdf')
LOG ON 
(NAME=N'SALON_LOG', FILENAME=N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\SALONDATA_LOG.ldf')


USE SALONDATA

CREATE TABLE brows_and_Lashes_Data
(
	[Timestamp] [datetime2](7) NOT NULL,
	[Servicio] [nvarchar](50) NOT NULL,
	[Costo] [varchar](20) NULL,
	[Método_de_pago] [nvarchar](50) NOT NULL,
	[total] [varchar](20) NULL,
	[Sacado_de_caja] [nvarchar](50) NOT NULL,
	[Si_pagado] [nvarchar](50) NOT NULL,
	[Metodo_de_pago] [nvarchar](50) NOT NULL,
	[Fecha] [DATE] NOT NULL,
	[Month] [nvarchar](50) NOT NULL,
	[Week_starting] [date] NOT NULL,
	[transaction_ID] [nvarchar](50) NOT NULL
) 

DROP TABLE brows_and_Lashes_Data

SET DATEFORMAT mdy

BULK INSERT brows_and_Lashes_Data 
FROM 'C:\Users\Nai\Documents\proyectos\SalonSQL\ByL_form.csv'
WITH 
(
CODEPAGE = '65001',
FIRSTROW = 2,
FIELDTERMINATOR=',',
ROWTERMINATOR='\n', 
FORMAT ='CSV'
) 




SELECT DISTINCT Servicio FROM brows_and_Lashes_Data

DROP TABLE NEWTABLE 

SELECT
	IDENTITY(INT, 1, 1) AS SERVICE_ID,
	"SERVICE"
INTO
	SERVICES
FROM
	(
	SELECT
		DISTINCT SERVICIO AS "SERVICE"
	FROM
		BROWS_AND_LASHES_DATA 
) AS S

SELECT
	IDENTITY(INT, 1, 1) AS pm_ID,
	"payment_method"
INTO
	PAYMENT_METHODS
FROM
	(
	SELECT
		DISTINCT Metodo_de_pago AS "payment_method"
	FROM
		BROWS_AND_LASHES_DATA 
) AS p


-- Bringing the table and changing the 'costo' and 'total' format from VARCHAR to MONEY


SELECT fecha,
		(SELECT service_id FROM SERVICES 
		WHERE servicio= "service" 
		) as service_id,
		TRY_PARSE (REPLACE(costo,'$','')AS MONEY) as costo,
		(SELECT pm_id FROM PAYMENT_METHODS
		WHERE metodo_de_pago = payment_method
		) as pm_id,
		TRY_PARSE (REPLACE(total,'$','')AS MONEY) as total
FROM BROWS_AND_LASHES_DATA 

--creating a new table 'TRANSACTIONS'


SELECT fecha
	,(
		SELECT service_id
		FROM SERVICES
		WHERE servicio = "service"
		) AS service_id
	,TRY_PARSE(REPLACE(costo, '$', '') AS MONEY) AS costo
	,(
		SELECT pm_id
		FROM PAYMENT_METHODS
		WHERE metodo_de_pago = payment_method
		) AS pm_id
	,TRY_PARSE(REPLACE(total, '$', '') AS MONEY) AS total
INTO TRANSACTIONS
FROM BROWS_AND_LASHES_DATA 

SELECT * FROM TRANSACTIONS

--CREATE VIEW where i can see payment_method, services, transaction. (join)

CREATE VIEW Table_transactions AS
SELECT TRANSACTIONS.fecha,
SERVICES.SERVICE,
PAYMENT_METHODS.payment_method,
TRANSACTIONS.costo,
TRANSACTIONS.total
FROM TRANSACTIONS
inner join PAYMENT_METHODS on transactions.pm_id=payment_methods.pm_id
inner join Services on TRANSACTIONS.service_id=services.service_id

SELECT* FROM Table_transactions


-- Earnings per motnh 
DECLARE 
@colums NVARCHAR(MAX) = '';
SELECT 
@colums +=   DATENAME(month,fecha) + ','
FROM Table_transactions;
SET @colums = LEFT(@colums,LEN(@colums) - 1);

PRINT @colums;

SELECT *
FROM
(
SELECT  DATENAME(month,fecha) MES,round(total,2,2) as total  
FROM Table_transactions


) AS TablePivot
PIVOT
(
	sum(total) 
	FOR MES 
	IN ( July,August, June, May, November, October, September)
)
AS PivotTable


--best month selling


SELECT TOP 1 * FROM
(
SELECT DATENAME(month,fecha) as MES, CAST(SUM(total) as int) TOTAL
FROM Table_transactions
GROUP BY DATENAME(month,fecha) 
) a
order by total DESC

-- Lowest month selling


SELECT TOP 1 DATENAME(month,fecha) as MES,CAST (SUM(total)as  int) TOTAL
FROM Table_transactions
GROUP BY DATENAME(month,fecha) 
order by total ASC 




-- what is the most popular service?

SELECT  TOP 1 service,COUNT(SERVICE)as count 
FROM Table_transactions
group by service
Order by count desc



-- How much earnign % the most popular service represents?


SELECT TOP 1 service,CAST(SUM(TOTAL) AS INT) AS 'Total Price Product',
(SUM(TOTAL)*100)/SUM(SUM(TOTAL)) OVER () AS 'Percentage of Total Price'
FROM table_transactions
GROUP BY SERVICE
ORDER BY 'Total Price Product' desc



--How much HAVE we PAID for the POS provider?

SELECT SUM(COSTO)-SUM(TOTAL) POS_PAYMENT
FROM Table_transactions


-- How much will be the earnings if we reduce the POS percentage?

SELECT cast(SUM(COSTO) AS INT) 'Total Earnings'
FROM Table_transactions



