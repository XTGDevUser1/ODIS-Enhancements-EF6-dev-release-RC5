IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_UpdateTempCreditCardDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
GO

--EXEC dms_CCImport_UpdateTempCreditCardDetails
CREATE PROC [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
AS
BEGIN

BEGIN TRY
 

CREATE TABLE #TempCardsNotPosted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL)

DECLARE @postedStatus INT
DECLARE @startROWParent INT 
DECLARE @totalRowsParent INT,
		@creditcardNumber INT,
		@totalApprovedAmount money,
		@totalChargedAmount money,
		@maxLastChargeDate datetime

SET @postedStatus = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Posted')

INSERT INTO #TempCardsNotPosted
SELECT DISTINCT TCCD.TemporaryCreditCardID FROM
TemporaryCreditCardDetail TCCD
JOIN TemporaryCreditCard TCC ON TCC.ID = TCCD.TemporaryCreditCardID
WHERE TCC.TemporaryCreditCardStatusID NOT IN (SELECT ID FROM TemporaryCreditCardStatus WHERE Name IN ('Cancelled','Posted'))
AND TCC.IssueDate > DATEADD(mm, -3, GETDATE())

SET @startROWParent =  (SELECT MIN([RowNum]) FROM #TempCardsNotPosted)
SET @totalRowsParent = (SELECT MAX([RowNum]) FROM #TempCardsNotPosted)

WHILE(@startROWParent <= @totalRowsParent)  
BEGIN

SET @creditcardNumber = (SELECT ID FROM #TempCardsNotPosted WHERE [RowNum] = @startROWParent)
SET @maxLastChargeDate = (SELECT MAX(ChargeDate) FROM TemporaryCreditCardDetail WHERE TemporaryCreditCardID =  @creditcardNumber)

UPDATE TemporaryCreditCard
SET LastChargedDate = @maxLastChargeDate
WHERE ID =  @creditcardNumber

IF((SELECT Count(*) FROM TemporaryCreditCardDetail 
   WHERE TransactionType='Cancel' AND TemporaryCreditCardID = @creditcardNumber) > 0)
 BEGIN
	UPDATE TemporaryCreditCard 
	SET IssueStatus = 'Cancel'
	WHERE ID = @creditcardNumber
 END
 
 SET @totalApprovedAmount = (SELECT TOP 1 ApprovedAmount FROM TemporaryCreditCardDetail
							 WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Approve'
							 AND TransactionSequence IS NOT NULL
							 ORDER BY TransactionSequence DESC)
SET @totalChargedAmount = (SELECT SUM(ChargeAmount) FROM TemporaryCreditCardDetail
						   WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Charge')

UPDATE TemporaryCreditCard
SET ApprovedAmount = @totalApprovedAmount,
	TotalChargedAmount = @totalChargedAmount
WHERE ID = @creditcardNumber
						 
SET @startROWParent = @startROWParent + 1

END

DROP TABLE #TempCardsNotPosted



END TRY
BEGIN CATCH
		
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	
END CATCH

END

GO

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_PurchaseOrderTemplate_select]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_PurchaseOrderTemplate_select]
GO
/****** Object:  StoredProcedure [dbo].[dms_users_list]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dms_PurchaseOrderTemplate_select] 108,1
CREATE PROCEDURE [dbo].[dms_PurchaseOrderTemplate_select]   
   @PurchaseOrderID int,  
   @ContactLogID int  
 AS   
 BEGIN   
    
 SET NOCOUNT ON  
  
DECLARE @TalkedTo nvarchar(50)  
DECLARE @FaxNo nvarchar(50)  
DECLARE @VendorCallback nvarchar(50)
DECLARE @VendorBilling nvarchar(50)
  
SELECT @TalkedTo = CL.TalkedTo,   
@FaxNo = REPLACE(CL.PhoneNumber, ' ','')   
FROM ContactLog CL  
WHERE CL.ID = @ContactLogID  
  
 
SELECT   
@TalkedTo as POTo,  
V.Name as VendorName,  
V.VendorNumber,  
@FaxNo as FaxPhoneNumber,  
ACFrom.Value as POFrom,  
ACVendorCallbackPhone.Value as VendorCallback,
ACBilling.Value as VendorBilling,
PO.IssueDate,  
--CONVERT(VARCHAR(8), PO.IssueDate, 108) + '-' + CONVERT(VARCHAR(10), PO.IssueDate, 101) as IssueDate,
PO.PurchaseOrderNumber,  
PO.CreateBy as OpenedBy,  
COALESCE(PC.Name, PC2.Name) as ServiceName,  
PO.EtaMinutes,  
CASE WHEN Isnull(C.IsSafe,1) = 1 THEN 'Y'  
ELSE 'N'  
END AS Safe,  
CASE WHEN Isnull(PO.IsMemberAmountCollectedByVendor,0) = 1 THEN 'Y'  
ELSE 'N'  
END AS MemberPay,  
REPLACE(RTRIM(COALESCE(M.FirstName, '') +     
          COALESCE(' ' + LEFT(M.MiddleName,1), '') +    
          COALESCE(' ' + M.LastName, '')), '  ', ' ')     
          as MemberName,     
MS.MembershipNumber,  
dbo.fnc_FormatPhoneNumber(C.ContactPhoneNumber,0) as ContactPhoneNumber,  
dbo.fnc_FormatPhoneNumber(C.ContactAltPhoneNumber,0) as ContactAltPhoneNumber,  
SR.ServiceLocationDescription,  
SR.ServiceLocationAddress,  
SR.ServiceLocationCrossStreet1 + COALESCE(' & ' + SR.ServicelocationCrossStreet2, '') as ServiceLocationCrossStreet,  
SR.ServiceLocationCity + ', ' + ServiceLocationStateProvince as CityState,  
SR.ServiceLocationPostalCode as Zip,  
SR.DestinationDescription,  
SR.DestinationAddress,  
SR.DestinationCrossStreet1 + COALESCE(' & ' + SR.DestinationCrossStreet2, '') as DestinationCrossStreet,  
SR.DestinationCity + ', ' + ServiceLocationStateProvince as DestinationCityState,  
SR.DestinationPostalCode as DestinationZip,  
C.VehicleYear,   
--C.VehicleMake,  
--C.VehicleModel,  
CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END AS VehicleMake,
CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END AS VehicleModel,
C.VehicleDescription,  
C.VehicleColor,  
C.VehicleLicenseState + COALESCE('/' + C.VehicleLicenseNumber,'') as License,  
C.VehicleVIN,  
C.VehicleChassis,  
C.VehicleLength,  
C.VehicleEngine,  
REPLACE(RVT.Name,'Class','') as Class  
FROM PurchaseOrder PO  
JOIN ServiceRequest SR ON PO.ServiceRequestID = SR.ID  
JOIN [Case] C ON C.ID = SR.CaseID   
JOIN VendorLocation VL on VL.ID = PO.VendorLocationID   
JOIN Vendor V on V.ID = VL.VendorID   
JOIN ApplicationConfiguration ACFrom ON ACFrom.Name = 'POFaxFrom'  
JOIN ApplicationConfiguration ACVendorCallbackPhone ON ACVendorCallbackPhone.Name = 'VendorCallback'  
JOIN ApplicationConfiguration ACBilling ON ACBilling.Name = 'VendorBilling'  
LEFT JOIN Product P ON P.ID = PO.ProductID
LEFT JOIN ProductCategory PC ON PC.ID = P.ProductCategoryID
JOIN ProductCategory PC2 ON PC2.ID = SR.ProductCategoryID
JOIN Member M on M.ID = C.MemberID   
JOIN Membership MS ON MS.ID = M.MembershipID   
LEFT JOIN RVType RVT ON RVT.ID = C.VehicleRVTypeID   
WHERE PO.ID = @PurchaseOrderID   
  
END



GO

/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1, 1, NULL, NULL  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]  
       @ProgramID INT   
      , @ProductCategoryID INT  
      , @VehicleCategoryID INT  
      , @VehicleTypeID INT  
      , @SecondaryCategoryID INT = NULL  
      , @ServiceRequestID  INT = NULL  
      , @ProductID INT = NULL  
      , @IsPrimaryOverride BIT = NULL
AS  
BEGIN   
  
	SET NOCOUNT ON    
	SET FMTONLY OFF    

	--KB: 
	SET @ProductID = NULL

	DECLARE @SecondaryProductID INT
		,@OverrideCoverageLimit money 

	/*** Determine Primary and Secondary Product IDs ***/  
	/* Ignore Vehicle related values for Product Categories not requiring a Vehicle */
	IF @ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE IsVehicleRequired = 0)
	BEGIN
		SET @VehicleCategoryID = NULL
		SET @VehicleTypeID = NULL
	END

	/* Select Basic Lockout over Locksmith when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')  
	END  

	/* Select Tire Change over Tire Repair when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)  
	END  

	IF @ProductID IS NULL  
	SELECT @ProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @ProductCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  


	IF @SecondaryCategoryID IS NOT NULL  
	SELECT @SecondaryProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @SecondaryCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  

	-- Coverage Limit Override for Ford ESP vehicles E/F 650 and 750
	IF @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Extended Service Plan (RV & COMM)')
	BEGIN
	IF EXISTS(
		SELECT * 
		FROM [Case] c
		JOIN ServiceRequest sr ON sr.CaseID = c.ID
		WHERE sr.ID = @ServiceRequestID
			AND (SUBSTRING(c.VehicleVIN, 6, 1) IN ('6','7')
				OR c.VehicleModel IN ('F-650', 'F-750'))
		)
		SET @OverrideCoverageLimit = 200.00
	END
   
	SELECT ISNULL(pc.Name,'') ProductCategoryName  
		,pc.ID ProductCategoryID  
		--,pc.Sequence  
		,ISNULL(vc.Name,'') VehicleCategoryName  
		,vc.ID VehicleCategoryID  
		,pp.ProductID  

		,CAST (pp.IsServiceCoverageBestValue AS BIT) AS IsServiceCoverageBestValue
		,CASE WHEN @OverrideCoverageLimit IS NOT NULL THEN @OverrideCoverageLimit ELSE pp.ServiceCoverageLimit END AS ServiceCoverageLimit
		,pp.CurrencyTypeID   
		,pp.ServiceMileageLimit   
		,pp.ServiceMileageLimitUOM   
		,1 AS IsServiceEligible
		--TP: Below logic is not needed; Only eligible services will be added to ProgramProduct 
		--,CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0   
		--              WHEN pp.IsServiceCoverageBestValue = 1 THEN 1  
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.ProductID IN (SELECT p.ID FROM Product p WHERE p.ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE Name IN ('Info', 'Tech', 'Concierge'))) THEN 1
		--              WHEN pp.ServiceCoverageLimit > 0 THEN 1  
		--              ELSE 0 END IsServiceEligible  
		,pp.IsServiceGuaranteed   
		,pp.ServiceCoverageDescription  
		,pp.IsReimbursementOnly  
		,CASE WHEN ISNULL(@IsPrimaryOverride,0) = 0 AND pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END AS IsPrimary  
	FROM ProgramProduct pp (NOLOCK)  
	JOIN Product p ON p.ID = pp.ProductID  
	LEFT OUTER JOIN ProductCategory pc (NOLOCK) ON pc.ID = p.ProductCategoryID  
	LEFT OUTER JOIN VehicleCategory vc (NOLOCK) ON vc.id = p.VehicleCategoryID  
	WHERE pp.ProgramID = @ProgramID  
	AND (pp.ProductID = @ProductID OR pp.ProductID = @SecondaryProductID)  
	ORDER BY   
	(CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC  
	,pc.Sequence  
     
END  

