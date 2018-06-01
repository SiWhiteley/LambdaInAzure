/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2014 (12.0.2569)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2014
    Target Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [AdventureWorksDW2012]
GO

/****** Object:  StoredProcedure [dbo].[StreamTransactions]    Script Date: 08/10/2017 21:03:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[StreamTransactions]
AS
SELECT top 1
	SalesOrderNumber,
	ProductKey,
	OrderDateKey,
	OrderQuantity,
	UnitPrice,
	DiscountAmount,
	SalesAmount,
	TaxAmt
FROM [dbo].[FactInternetSales]
ORDER BY NEWID()

GO


