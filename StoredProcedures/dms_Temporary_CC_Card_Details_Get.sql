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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Card_Details_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Card_Details_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Temporary_CC_Card_Details_Get 1
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Card_Details_Get] ( 
   @TempCCID Int = null 
 ) 
 AS 
 BEGIN 
  
SET NOCOUNT ON

SELECT	TCC.ID
		, TCC.CreditCardNumber AS TempCC
		, TCC.TotalChargedAmount AS CCCharge
		, TCC.IssueStatus AS IssueStatus
		, TCCS.Name AS MatchStatus
		, TCC.ExceptionMessage AS ExceptionMessage
		, TCC.OriginalReferencePurchaseOrderNumber AS CCOrigPO
		, TCC.ReferencePurchaseOrderNumber AS CCRefPO
		, TCC.Note
		,ISNULL(TCC.IsExceptionOverride,0) AS IsExceptionOverride
FROM	TemporaryCreditCard TCC
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
WHERE	TCC.ID = @TempCCID


END