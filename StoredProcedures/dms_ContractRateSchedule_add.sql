 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ContractRateSchedule_add]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ContractRateSchedule_add] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROCEDURE [dbo].[dms_ContractRateSchedule_add] (
	 @ContractRateScheduleID INT
	,@ContractID INT
	,@UserName nvarchar(50)
)
AS
BEGIN

	INSERT INTO [dbo].[ContractRateScheduleProduct]
			   ([ContractRateScheduleID]
			   ,[VendorLocationID]
			   ,[ProductID]
			   ,[RateTypeID]
			   ,[Price]
			   ,[Quantity]
			   ,[CreateDate]
			   ,[CreateBy])
	SELECT 
		@ContractRateScheduleID
		,NULL
		,p.ID ProductID
		,prt.RateTypeID
		,0.00
		,0
		,GETDATE()
		,@UserName
	FROM [Contract] c
	JOIN vendor v ON v.ID = c.VendorID 
	JOIN vendorproduct vp on vp.vendorid = v.id
	JOIN product p on p.ID = vp.ProductID
	JOIN productratetype prt ON prt.ProductID = p.ID
	JOIN ratetype rt ON rt.ID = prt.RateTypeID
	WHERE c.ID = @ContractID
	AND vp.IsActive = 1

END

