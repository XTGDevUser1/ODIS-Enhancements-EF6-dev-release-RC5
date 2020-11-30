IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_Claims]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_Claims] 
 END 
 GO  
CREATE VIEW [dbo].[vw_Claims]
AS
SELECT cl.[ID] ClaimID
      ,cl.[ClaimTypeID]
      ,ct.Name ClaimType
      ,cl.[ClaimCategoryID]
      ,cc.Name ClaimCategory
      ,[ClaimStatusID]
      ,cs.Name ClaimStatus
      ,cl.[ProgramID]
      ,pr.[Description] Program
      ,[MemberID]
      ,COALESCE(mbr.FirstName + ' ','') + COALESCE(mbr.LastName,'') MemberName
      --,[VehicleID]
      ,[VendorID]
      ,vn.VendorNumber
      ,vn.Name VendorName
      ,[PurchaseOrderID]
      ,po.PurchaseOrderNumber
      ,[ClaimDate]
      ,[ReceivedDate]
      ,[ReceiveContactMethodID]
      ,ctm.[Description] ReceiveContactMethod
      ,[ClaimDescription]
      ,[ContactName]
      ,[ContactPhoneNumber]
      ,[ContactEmailAddress]
      ,[PayeeType]
      ,[PaymentAddressLine1]
      ,[PaymentAddressLine2]
      ,[PaymentAddressLine3]
      ,[PaymentAddressCity]
      ,[PaymentAddressStateProvince]
      ,[PaymentAddressStateProvinceID]
      ,[PaymentAddressPostalCode]
      ,[PaymentAddressCountryCode]
      ,[PaymentAddressCountryID]
      ,[ServiceProductCategoryID]
      ,[ServiceLocation]
      ,[DestinationLocation]
      ,[ServiceFacilityName]
      ,[ServiceFacilityPACode]
      ,cl.[ServiceMiles]
      ,[IsServiceReceiptOnFile]
      ,[VehicleOwnerName]
      ,[VehicleTypeID]
      ,vt.[Description] VehicleType
      ,cl.[VehicleCategoryID]
      ,vc.[Description] VehicleCategory
      --,[RVTypeID]
      ,[VehicleVIN]
      ,[VehicleYear]
      ,[VehicleMake]
      ,[VehicleMakeOther]
      ,[VehicleModel]
      ,[VehicleModelOther]
      ,[VehicleChassis]
      ,[VehicleEngine]
      ,[VehicleTransmission]
      ,[IsFirstOwner]
      ,[WarrantyStartDate]
      ,[WarrantyYears]
      ,[WarrantyMiles]
      ,[CurrentMiles]
      --,[NextActionID]
      --,[NextActionAssignedToUserID]
      --,[NextActionScheduledDate]
      ,[AmountRequested]
      ,[AmountApproved]
      ,[ClaimDecisionDate]
      ,[ClaimDecisionBy]
      ,[ClaimRejectReasonID]
      ,crr.[Description] ClaimRejectReason
      ,[ClaimRejectReasonOther]
      ,[GWOApprovalCode]
      ,[CUDLCaseNumber]
      ,[ACESReferenceNumber]
      ,[ACESSubmitDate]
      ,[ACESOutcome]
      ,[ACESClearedDate]
      --,[ClientPaymentID]
      ,[ACESAmount]
      --,[ExportDate]
      --,[ExportBatchID]
      ,[PaymentTypeID]
      ,pt.[Description] PaymentType
      ,[PaymentDate]
      ,[PaymentAmount]
      ,[PaymentPayeeName]
      ,[CheckNumber]
      ,[CheckClearedDate]
      ,[PassthruAccountingInvoiceBatchID]
      ,[FeeAccountingInvoiceBatchID]
      ,cl.[SourceSystemID]
      ,ss.[Description] SourceSystem
      ,cl.[IsActive]
      ,cl.[CreateDate]
      ,cl.[CreateBy]
      ,cl.[ModifyDate]
      ,cl.[ModifyBy]
      ,[ACESClaimStatusID]
      ,[ACESFeeAmount]
FROM dbo.Claim cl
JOIN dbo.ClaimType ct on ct.ID = cl.ClaimTypeID
JOIN dbo.ClaimCategory cc on cc.ID = cl.ClaimCategoryID
JOIN dbo.ClaimStatus cs on cs.ID = cl.ClaimStatusID
JOIN dbo.Program pr on pr.ID = cl.ProgramID
JOIN dbo.Client clt on clt.ID = pr.ClientID
LEFT OUTER JOIN dbo.ClaimRejectReason crr on crr.ID = cl.ClaimRejectReasonID
LEFT OUTER JOIN PurchaseOrder po on po.ID = cl.PurchaseOrderID
LEFT OUTER JOIN Member mbr on mbr.ID = cl.MemberID
LEFT OUTER JOIN Vendor vn on vn.ID = cl.VendorID
LEFT OUTER JOIN ContactMethod ctm on ctm.ID = cl.ReceiveContactMethodID
LEFT OUTER JOIN VehicleType vt on vt.ID = cl.VehicleTypeID
LEFT OUTER JOIN VehicleCategory vc on vc.ID = cl.VehicleCategoryID
LEFT OUTER JOIN PaymentType pt on pt.ID = cl.PaymentTypeID
LEFT OUTER JOIN SourceSystem ss on ss.ID = cl.SourceSystemID
GO

