IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_member_contact_information_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_member_contact_information_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 	
 -- EXEC [dbo].[dms_member_contact_information_get] 541
 CREATE PROC [dbo].[dms_member_contact_information_get](@memberID INT = NULL)
 AS
 BEGIN

	SELECT AE.ID As AddressID,
		M.FirstName,
		M.LastName,
		M.ClientMemberType,
		AE.Line1 AS Address1,
		AE.Line2 AS Address2,
		AE.Line3 AS Address3,
		AE.City as City,
		AE.StateProvinceID as StateID,
		AE.StateProvince as State,
		AE.PostalCode as Zip,
		AE.CountryID as CountryID,
		AE.CountryCode as Country,
		PEH.ID as HomePhoneID,
		PEH.PhoneTypeID as HomePhoneTypeID,
		PEH.PhoneNumber as HomePhone,
		PEC.ID as CellPhoneID,
		PEC.PhoneTypeID as CellPhoneTypeID,
		PEC.PhoneNumber as CellPhone,
		PEW.ID as WorkPhoneID,
		PEW.PhoneTypeID as WorkPhoneTypeID,
		PEW.PhoneNumber as WorkPhone,
		M.Email as EMail
	FROM Member M
	LEFT JOIN AddressEntity AE  ON AE.EntityID = (Select ID From Entity where Name = 'Member') AND AE.RecordID = @MemberID AND AE.AddressTypeID = 1
	LEFT JOIN PhoneEntity PEH  ON PEH.EntityID = (Select ID From Entity where Name = 'Member') AND PEH.RecordID = @MemberID AND PEH.PhoneTypeID = (Select ID From PhoneType Where Name = 'Home')
	LEFT JOIN PhoneEntity PEC  ON PEC.EntityID = (Select ID From Entity where Name = 'Member') AND PEC.RecordID = @MemberID AND PEC.PhoneTypeID = (Select ID From PhoneType Where Name = 'Cell')
	LEFT JOIN PhoneEntity PEW ON PEW.EntityID = (Select ID From Entity where Name = 'Member') AND PEW.RecordID = @MemberID AND PEW.PhoneTypeID = (Select ID From PhoneType Where Name = 'Work')
	WHERE M.ID = @MemberID

END