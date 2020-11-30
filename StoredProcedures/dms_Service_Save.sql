 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Service_Save]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Service_Save]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
CREATE PROC dms_Service_Save(@serviceRequestID INT
,@inputXML NVARCHAR(MAX)
,@userName NVARCHAR(50)
,@vehicleTypeID INT = NULL)  
AS  
BEGIN  
 DECLARE @idoc int  
 EXEC sp_xml_preparedocument @idoc OUTPUT, @inputXML  
   
 DECLARE @tmpForInput TABLE  
 (  
  ServiceRequestID INT NULL,  
  ProductCategoryQuestionID INT NOT NULL,  
  Answer NVARCHAR(MAX) NULL,  
  CreateDate DATETIME DEFAULT GETDATE(),  
  CreatedBy NVARCHAR(50) NULL,  
  ModifyDate DATETIME DEFAULT GETDATE(),  
  ModifiedBy NVARCHAR(50) NULL  
 )  
  
 INSERT INTO @tmpForInput( ProductCategoryQuestionID,  
  Answer  
    )  
 SELECT    
  ProductCategoryQuestionID,  
  Answer  
 FROM   
  OPENXML (@idoc,'/ROW/Data',1) WITH (  
   ProductCategoryQuestionID INT,  
   Answer NVARCHAR(MAX)  
  )   
   
 UPDATE @tmpForInput  
 SET  ServiceRequestID = @serviceRequestID,  
   CreatedBy    = @userName,  
   ModifiedBy    = @userName  
 
 
-- KB: Let's clear off existing values and add the new values.
 DELETE FROM ServiceRequestDetail WHERE ServiceRequestID = @serviceRequestID
   
 -- INSERT NEW Records  
 INSERT INTO  ServiceRequestDetail   
 SELECT  
  T.[ServiceRequestID],  
  T.[ProductCategoryQuestionID],  
  T.[Answer],  
  T.[CreateDate],  
  T.[CreatedBy],  
  T.[ModifyDate],  
  T.[ModifiedBy]  
 FROM @tmpForInput T   
 WHERE T.ProductCategoryQuestionID NOT IN (SELECT ProductCategoryQuestionID FROM ServiceRequestDetail WHERE ServiceRequestID = @serviceRequestID)    
  
 -- CR: 1097 : Set the product IDs based on the answers provided.
 DECLARE @vehicleCategoryID INT = NULL
 DECLARE @isPossibleTow BIT = 0
 DECLARE @productCategoryID INT = NULL
 DECLARE @programID INT = NULL
 DECLARE @pPrimaryProductID INT = NULL
 DECLARE @pSecondaryProductID INT = NULL
  
 DECLARE @primaryProductID INT = NULL
 DECLARE @secondaryProductID INT = NULL
 DECLARE @isPrimaryServiceCovered BIT = NULL
 DECLARE @isSecondaryServiceCovered BIT = NULL
 DECLARE @towProductCategoryID int = NULL
 SET @towProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow')
 DECLARE @tmpPrograms TABLE
 (
 LevelID INT IDENTITY(1,1),
 ProgramID INT
 )
 SELECT @vehicleCategoryID = SR.VehicleCategoryID,
   @productCategoryID = SR.ProductCategoryID,
   @isPossibleTow = SR.IsPossibleTow,
   @programID = C.ProgramID
 FROM  ServiceRequest SR,
   [Case] C
 WHERE  SR.CaseID = C.ID
 AND  SR.ID = @serviceRequestID
  
 INSERT INTO @tmpPrograms
 SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)
  /*
 *  Determine PrimaryProducID
 *  Get value from ServiceType dropdown
 *  Look at all the answers to those category questions and see if any have a ProductID defined.
 *  If a ProductCategoryQuestionValue.ProductID is defined for any of the answers given for this category then use that ProductID to set PrimaryProductID
 *  Right now there is only 1 question/answer that will have a product defined and that is Lockout / Do you need a locksmith? / Yes / ProductID=9
 *  If Tow is selected in the ServiceType dropdown then there might be a special type tow product defined on an answer under towing. This will go in PrimaryProductID because Tow is set as the primary service.
 */
 
 SELECT @pPrimaryProductID = W.ProductID
 FROM
 (SELECT TOP 1 PCQV.ProductID
 FROM  ProductCategoryQuestionValue PCQV
 JOIN  ServiceRequestDetail SRD ON PCQV.ProductCategoryQuestionID = SRD.ProductCategoryQuestionID AND SRD.Answer = PCQV.Value
 JOIN  ProductCategoryQuestion PCQ ON PCQV.ProductCategoryQuestionID = PCQ.ID
 WHERE  SRD.ServiceRequestID = @serviceRequestID
 AND   PCQ.ProductCategoryID = @productCategoryID
 AND   PCQV.ProductID IS NOT NULL) W
    /*Tim's SQL: Logic to select Basic Lockout over Locksmith within Lockout Product Category */
    
IF @pPrimaryProductID IS NULL AND @productCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')
BEGIN
 SET @pPrimaryProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')
END
/* Select Tire Change over Tire Repair when one of the tire services is not specifically selected */
IF @pPrimaryProductID IS NULL AND @productCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')
BEGIN
 SET @pPrimaryProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)
END
/*  
 *  Determine SecondaryProductID
 *  If IsPossibleTow = Yes then look for a secondary product id.
 *  It turns out that we can't just pass Tow-LD every time. We have to look at some answers to Tow questions to see if there is a special type of tow needed.
 *  Look through the Tow category answers to see if any have a ProductID defined, if they do then use that to set the SecondaryProductID sent to the stored proc.
 *  Right now there is only one question: Speical Tow that has answers that will have ProductID's defined. Flatbed Tow, Enclosed Hauler, etc.
 */
 
 IF @isPossibleTow = 1
 BEGIN
  SELECT @pSecondaryProductID = W.ProductID
  FROM
  (SELECT TOP 1 PCQV.ProductID
  FROM  ProductCategoryQuestionValue PCQV
  JOIN  ProductCategoryQuestion PCQ ON PCQ.ID = PCQV.ProductCategoryQuestionID
  JOIN  ServiceRequestDetail SRD ON PCQV.ProductCategoryQuestionID = SRD.ProductCategoryQuestionID AND SRD.Answer = PCQV.Value
  WHERE  SRD.ServiceRequestID = @serviceRequestID
  AND   PCQ.ProductCategoryID = @towProductCategoryID
  AND   PCQV.ProductID IS NOT NULL
  ) W
  
 END
 
 ;WITH wPrimaryProducts
 AS
 (
  SELECT ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
  T.ProgramID AS ProgramID, 
  p.ID AS ProductID,
  pp.ID AS ProgramProductID,
  pp.IsReimbursementOnly
  FROM dbo.Product p
  JOIN dbo.ProductType pt ON p.ProductTypeID = pt.ID
  JOIN dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
  JOIN dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
  JOIN dbo.ProgramProduct pp ON pp.ProductID = P.ID --AND pp.ProgramID = @programID
  JOIN @tmpPrograms T ON pp.ProgramID = T.ProgramID
  WHERE 
  (p.ID = @pPrimaryProductID)
  OR
  (
   @pPrimaryProductID IS NULL
   AND pt.Name = 'Service'
   AND pst.Name = 'PrimaryService'
   AND pc.ID = @productCategoryID
   AND (p.VehicleTypeID = @vehicleTypeID OR p.VehicleTypeID IS NULL)
   AND (p.VehicleCategoryID = @vehicleCategoryID OR p.VehicleCategoryID IS NULL)
  )
 )
 SELECT @primaryProductID = ProductID,
 @isPrimaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
         THEN 0 
         ELSE 1 
        END 
 FROM wPrimaryProducts
 ;WITH wSecondaryProducts
 AS
 (
  SELECT ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
  T.ProgramID AS ProgramID, 
  p.ID AS ProductID,
  pp.ID AS ProgramProductID,
  pp.IsReimbursementOnly
  FROM dbo.Product p
  JOIN dbo.ProductType pt ON p.ProductTypeID = pt.ID
  JOIN dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
  JOIN dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
  JOIN dbo.ProgramProduct pp ON pp.ProductID = p.ID -- AND pp.ProgramID = @programID
  JOIN @tmpPrograms T ON pp.ProgramID = T.ProgramID
  WHERE 
  (p.ID = @pSecondaryProductID)
  OR
  (
   @pSecondaryProductID IS NULL
   AND pt.Name = 'Service'
   AND pst.Name = 'PrimaryService'
   AND @isPossibleTow = 'TRUE'
   AND pc.ID = @towProductCategoryID
   AND (p.VehicleTypeID = @vehicleTypeID OR p.VehicleTypeID IS NULL)
   AND (p.VehicleCategoryID = @vehicleCategoryID OR p.VehicleCategoryID IS NULL) 
  )
 )
 SELECT @secondaryProductID = ProductID,
   @isSecondaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
            THEN 0 
            ELSE 1 
           END 
 FROM wSecondaryProducts
 UPDATE ServiceRequest
 SET 
  PrimaryProductID = @primaryProductID,
  SecondaryProductID = @secondaryProductID,
  IsPrimaryProductCovered = @isPrimaryServiceCovered,
  IsSecondaryProductCovered = @isSecondaryServiceCovered
 WHERE ID = @serviceRequestID

  
   
END  
  

           