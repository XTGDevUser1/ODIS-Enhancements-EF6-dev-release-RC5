IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Claim_FordQFC_Create]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claim_FordQFC_Create] 
 END 
 GO  
 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Claim_FordQFC_Create]
AS
BEGIN

      INSERT INTO [dbo].[Claim]
                     ([ClaimTypeID]
                     ,[ClaimCategoryID]
                     ,[ClaimStatusID]
                     ,[ProgramID]
                     ,[MemberID]
                     ,[VendorID]
                     ,[PurchaseOrderID]
                     ,[ClaimDate]
                     ,[ReceivedDate]
                     ,[ReceiveContactMethodID]
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
                     ,[ServiceMiles]
                     ,[IsServiceReceiptOnFile]
                     ,[VehicleTypeID]
                     ,[VehicleCategoryID]
                     ,[RVTypeID]
                     ,[VehicleVIN]
                     ,[VehicleYear]
                     ,[VehicleMake]
                     ,[VehicleMakeOther]
                     ,[VehicleModel]
                     ,[VehicleModelOther]
                     ,[VehicleChassis]
                     ,[VehicleEngine]
                     ,[VehicleTransmission]
                     ,[WarrantyStartDate]
                     ,[WarrantyYears]
                     ,[WarrantyMiles]
                     ,[CurrentMiles]
                     ,[NextActionID]
                     ,[NextActionAssignedToUserID]
                     ,[NextActionScheduledDate]
                     ,[AmountRequested]
                     ,[AmountApproved]
                     ,[ClaimDecisionDate]
                     ,[ClaimDecisionBy]
                     ,[ClaimRejectReasonID]
                     ,[ClaimRejectReasonOther]
                     ,[GWOApprovalCode]
                     ,[CUDLCaseNumber]
                     ,[ACESReferenceNumber]
                     ,[ACESSubmitDate]
                     ,[ACESOutcome]
                     ,[ACESClearedDate]
                     ,[ClientPaymentID]
                     ,[ACESAmount]
                     ,[ExportDate]
                     ,[ExportBatchID]
                     ,[PaymentTypeID]
                     ,[PaymentDate]
                     ,[PaymentAmount]
                     ,[PaymentPayeeName]
                     ,[CheckNumber]
                     ,[CheckClearedDate]
                     ,[PassthruAccountingInvoiceBatchID]
                     ,[FeeAccountingInvoiceBatchID]
                     ,[SourceSystemID]
                     ,[IsActive]
                     ,[CreateDate]
                     ,[CreateBy]
					 ,[ACESClaimStatusID])

      SELECT  
            (SELECT ID FROM ClaimType WHERE Name = 'FordQFC') ClaimTypeID
            ,(SELECT ID FROM ClaimCategory WHERE Name = 'RoadsideService') ClaimCategoryID
            ,(SELECT ID FROM ClaimStatus WHERE Name = 'Approved') ClaimStatusID
            ,p.ID AS ProgramID
            ,m.ID AS MemberID
            ,vl.VendorID
            ,po.ID AS PurchaseOrderID
            ,PO.CreateDate AS ClaimDate
            ,PO.CreateDate AS ReceivedDate
            ,(SELECT ID FROM ContactMethod WHERE Name = 'Phone') AS ReceiveContactMethod
            ,(
				'Ford QFC' + ' - ' + (SELECT Name FROM Product WHERE ID = PO.ProductID) +
				'; Agent: ' + c.CreateBy +
				'; Contact: ' + LEFT(dbo.fnc_ProperCase(CASE WHEN ISNULL(c.ContactFirstName,'') <> '' THEN c.ContactFirstName ELSE '' END +
					CASE WHEN ISNULL(c.ContactLastName,'') <> '' THEN CASE WHEN ISNULL(c.ContactFirstName,'') <> '' THEN ' ' ELSE '' END + c.ContactLastName ELSE '' END),50) +
				'; Vehicle License: ' + CASE WHEN c.VehicleLicenseState IS NOT NULL THEN UPPER(c.VehicleLicenseState) + '-' ELSE '' END +
					UPPER(ISNULL(c.VehicleLicenseNumber,'')) +
				CASE WHEN (SELECT pc.Name FROM Product p JOIN ProductCategory pc on pc.ID = p.ProductCategoryID WHERE p.ID = PO.ProductID) = 'Tow' 
						THEN '; Reason: ' + 
							CASE WHEN  
								  ISNULL((SELECT srd.Answer 
									FROM ServiceRequest sr 
									LEFT OUTER JOIN ServiceRequestDetail srd ON srd.ServiceRequestID = sr.ID AND 
										srd.ProductCategoryQuestionID = 1 
									WHERE sr.ID = PO.ServiceRequestID),'') <> ''
								THEN
								  ISNULL((SELECT CASE WHEN srd.Answer = 'Other' THEN '' ELSE srd.Answer END 
									FROM ServiceRequest sr 
									LEFT OUTER JOIN ServiceRequestDetail srd ON srd.ServiceRequestID = sr.ID AND 
										srd.ProductCategoryQuestionID = 1 -- Reason for Tow response
									WHERE sr.ID = PO.ServiceRequestID),'') 
									+ ' ' +
								  ISNULL((SELECT srd.Answer 
									FROM ServiceRequest sr 
									LEFT OUTER JOIN ServiceRequestDetail srd ON srd.ServiceRequestID = sr.ID AND 
										srd.ProductCategoryQuestionID = 2 ---- Response to Other reason 
									WHERE sr.ID = PO.ServiceRequestID),'') 
								ELSE 'No Reason Provided' 
								END
						ELSE '' 
						END 
				) AS ClaimDescription
            ,LEFT(dbo.fnc_ProperCase(CASE WHEN ISNULL(c.ContactFirstName,'') <> '' THEN c.ContactFirstName ELSE '' END +
            CASE WHEN ISNULL(c.ContactLastName,'') <> '' THEN CASE WHEN ISNULL(c.ContactFirstName,'') <> '' THEN ' ' ELSE '' END + c.ContactLastName ELSE '' END),50) AS ContactName
            ,c.ContactPhoneNumber
            ,m.Email AS ContactEmailAddress
            ,NULL AS PayeeType
            ,NULL AS PaymentAddressLine1
            ,NULL AS PaymentAddressLine2
            ,NULL AS PaymentAddressLine3
            ,NULL AS PaymentAddressCity
            ,NULL AS PaymentAddressStateProvince
            ,NULL AS PaymentAddressStateProvinceID
            ,NULL AS PaymentAddressPostalCode
            ,NULL AS PaymentAddressCountryCode
            ,NULL AS PaymentAddressCountryID
            ,(SELECT ProductCategoryID From Product WHERE ID = PO.ProductID) AS ServiceProductCategoryID
            ,dbo.fnc_ProperCase(SR.ServiceLocationAddress) AS ServiceLocation
            ,dbo.fnc_ProperCase(SR.DestinationAddress) AS DestinationLocation
            ,(SELECT v.Name 
                        FROM Vendor v 
                        JOIN VendorLocation vl on vl.vendorid = v.id 
                        WHERE vl.ID = SR.DestinationVendorLocationID) 
                  AS ServiceFacilityName
            ,(SELECT vl.PartsAndAccessoryCode 
                        FROM Vendor v 
                        JOIN VendorLocation vl on vl.vendorid = v.id 
                        WHERE vl.ID = SR.DestinationVendorLocationID) 
                  AS ServiceFacilityPACode
            ,SR.ServiceMiles AS ServiceMiles
            ,NULL AS IsServiceReceiptOnFile
            ,c.VehicleTypeID
            ,c.VehicleCategoryID
            ,c.VehicleRVTypeID AS RVTypeID
            ,UPPER(c.VehicleVIN) AS VehicleVIN
            ,c.VehicleYear
            ,c.VehicleMake
            ,c.VehicleMakeOther
            ,c.VehicleModel
            ,c.VehicleModelOther
            ,c.VehicleChassis
            ,c.VehicleEngine
            ,c.VehicleTransmission
            ,c.VehicleWarrantyStartDate AS WarrantyStartDate
            ,NULL AS WarrantyYears
            ,NULL AS WarrantyMiles
            ,c.VehicleCurrentMileage AS CurrentMiles
            ,NULL AS NextActionID
            ,NULL AS NextActionAssignedToUserID
            ,NULL AS NextActionScheduledDate
            ,VI.InvoiceAmount AS AmountRequested
            ,VI.PaymentAmount AS AmountApproved
            ,GETDATE() AS ClaimDecisionDate
            ,'system' AS ClaimDecisionBy
            ,NULL AS ClaimRejectReasonID
            ,NULL AS ClaimRejectReasonOther
            ,NULL AS GWOApprovalCode
            ,NULL AS CUDLCaseNumber
            ,NULL AS ACESReferenceNumber

            --,ACESSubmitDate = CASE WHEN PO.CreateDate > '2013-07-31' OR VI.ID IS NULL THEN NULL ELSE VI.CreateDate END
            --,ACESOutcome = CASE WHEN PO.CreateDate > '2013-07-31' OR VI.ID IS NULL THEN NULL ELSE 'Approved' END 
            --,ACESClearedDate = CASE WHEN PO.CreateDate > '2013-07-31' OR VI.ID IS NULL THEN NULL ELSE DATEADD(mm,0,DATEADD(mm, DATEDIFF(m,0,VI.CreateDate)+1,0)) END
            --,ACESAmount = CASE WHEN PO.CreateDate > '2013-07-31' OR VI.ID IS NULL THEN NULL ELSE PO.CoachNetServiceAmount END

            ,NULL AS ACESSubmitDate
            ,NULL AS ACESOutcome
            ,NULL AS ACESClearedDate
            ,NULL AS ClientPaymentID
            ,NULL AS ACESAmount
            ,NULL AS ExportDate
            ,NULL AS ExportBatchID
            ,NULL AS PaymentTypeID
            ,NULL AS PaymentDate
            ,NULL AS PaymentAmount
            ,NULL AS PaymentPayeeName
            ,NULL AS CheckNumber
            ,NULL AS CheckClearedDate
            ,NULL AS PassthruAccountingInvoiceBatchID
            ,NULL AS FeeAccountingInvoiceBatchID
            ,(SELECT ID FROM SourceSystem WHERE Name = 'Dispatch') AS SourceSystemID
            ,1 AS IsActive
            ,GETDATE() AS CreateDate
            ,'System' AS CreateBy
            ,(SELECT ID FROM ACESClaimStatus WHERE Name = 'Pending')
      FROM PurchaseOrder PO
      JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID
      JOIN ServiceRequest SR ON PO.ServiceRequestID = SR.ID
      JOIN [Case] c ON SR.CaseID = c.ID
      JOIN Member m ON c.MemberID = m.ID
      JOIN Program p ON m.ProgramID = p.ID
      JOIN VendorLocation vl ON po.VendorLocationID = vl.ID
      WHERE p.Name = 'Ford QFC'
      AND PO.IsActive = 1
      AND CoachNetServiceAmount > 0
      AND PO.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid'))
      AND NOT EXISTS (
            SELECT *
            FROM Claim 
            WHERE Claim.PurchaseOrderID = PO.ID
            AND Claim.ClaimTypeID = (SELECT ID FROM ClaimType WHERE Name = 'FordQFC'))

END

