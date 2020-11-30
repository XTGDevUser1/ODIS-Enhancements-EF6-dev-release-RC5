IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Payment_Receipt]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Payment_Receipt]
 END 
 GO  
/****** Object:  StoredProcedure [dbo].[dms_Payment_Receipt]    Script Date: 04/16/2013 15:52:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[dms_Payment_Receipt] 42
CREATE PROC [dbo].[dms_Payment_Receipt](@PaymentID  INT = NULL)
AS

BEGIN
SELECT
P.CCOrderID as [CCOrderID],
CONVERT(nvarchar(10),P.PaymentDate,101) as [PaymentDate],
PR.Name as [Service], --'Service',
SR.ServiceLocationAddress as [ServiceLocationAddress],
SR.DestinationAddress as [DestinationAddress],
P.CCNameOnCard as [NameOnCard],
PT.Name as [CardType],
P.CCPartial as [CardNumber],
(RIGHT('00' + convert(nvarchar(2),DATEPART(MM,P.CCExpireDate)),2) + '/' + convert(nvarchar(4),DATEPART(YYYY,P.CCExpireDate))) as [ExpirationDate],
cast(P.Amount as numeric(10,2)) AS Amount,
PTT.Name as Type,
PG.Name as [Program]
FROM Payment P
JOIN ServiceRequest SR ON SR.ID = P.ServiceRequestID
JOIN Product PR ON PR.ID = SR.PrimaryProductID
JOIN PaymentType PT ON PT.ID = P.PaymentTypeID
JOIN [Case] C ON C.ID = SR.CaseID
JOIN Program PG ON PG.ID = C.ProgramID
JOIN PaymentTransactionType PTT ON PTT.ID = P.PaymentTransactionTypeID
WHERE P.ID = @PaymentID
END
