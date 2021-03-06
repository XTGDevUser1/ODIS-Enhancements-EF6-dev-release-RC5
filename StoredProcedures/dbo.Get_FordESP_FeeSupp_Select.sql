/****** Object:  StoredProcedure [dbo].[Get_FordESP_FeeSupp_Select]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Get_FordESP_FeeSupp_Select]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Get_FordESP_FeeSupp_Select] 
 END 
 GO  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
--		exec [dbo].[Get_FordESP_FeeSupp_Select] 
--******************************************************************************************
--******************************************************************************************

CREATE Procedure [dbo].[Get_FordESP_FeeSupp_Select]
	
AS

	Select right(replicate('0',9)+convert(varchar,convert(int,bdil.Rate * 100000)),9)+'F' rate
		From dbo.BillingDefinitionInvoice bdi with(nolock)
		join dbo.BillingDefinitionInvoiceline bdil with(nolock) on bdi.Id = bdil.BillingDefinitionInvoiceID
	Where bdi.Name = 'Ford - ESP - Monthly Invoice'
		  and bdil.Sequence = 1
GO
