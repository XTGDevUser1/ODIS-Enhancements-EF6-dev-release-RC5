--SELECT * FROM Vehicle
--select * from membership where id = 843
--select * from member where membershipid = 843
-- update member set programid = 3 where membershipid = 843
--select * from aspnet_users where username like '%demo%'
--select * from [User] where aspnet_userid = 'CD2712C6-DF90-4A5B-B7CC-59FE3C9A119E'
--select * from organizationclient where organizationid = 2
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_API_Member_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_API_Member_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 -- EXEC [dms_API_Member_Search] @userName = 'sysadmin',@lastName='Phani',@firstName='Nagubandi'
 CREATE PROCEDURE [dbo].[dms_API_Member_Search](   
		@customerID NVARCHAR(50)		=	NULL,
		@customerGroupID NVARCHAR(50)	=	NULL,
		@internalMemberID INT			=	NULL,
		@lastName NVARCHAR(100)			=	NULL,
		@firstName NVARCHAR(100)		=	NULL,
		@vehicleVIN NVARCHAR(17)		=	NULL,
		@userName NVARCHAR(50)			=	NULL
)
 AS     
 BEGIN     
      
SET NOCOUNT ON    
SET FMTONLY OFF    

CREATE TABLE #userClientPrograms
(
	ProgramID INT,
	ClientID INT
)

DECLARE @membershipEntityID INT  
SELECT @membershipEntityID = ID FROM Entity WHERE Name = 'Membership'  

DECLARE @memberEntityID INT  
SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  

DECLARE @homeAddressTypeID INT
SELECT @homeAddressTypeID = ID FROM AddressType WHERE Name='Home'




INSERT INTO #userClientPrograms
SELECT	P.ID,
		OC.ID
FROM	aspnet_users AU WITH (NOLOCK) 
JOIN	[User] U WITH (NOLOCK) ON U.aspnet_userId = AU.UserId
JOIN	[OrganizationClient] OC WITH (NOLOCK) ON U.OrganizationID = OC.OrganizationId
JOIN	[Program] P WITH (NOLOCK) ON P.ClientID = OC.ClientID
WHERE	AU.UserName = @userName

--select * from #userClientPrograms
DECLARE @sql NVARCHAR(MAX) = ''
-- Members
SET @sql = @sql + ' SELECT DISTINCT	M.ID	AS InternalMemberID,'
SET @sql = @sql + ' 		MS.ID	AS MembershipID,'
SET @sql = @sql + ' 		V.MembershipID AS VehicleMembershipID,'
SET @sql = @sql + ' 		V.MemberID AS VehicleMemberID,'
SET @sql = @sql + ' 		MS.MembershipNumber,'
SET @sql = @sql + ' 		MS.AltMembershipNumber,'
SET @sql = @sql + ' 		MS.ClientMembershipKey,'
SET @sql = @sql + ' 		M.FirstName,'
SET @sql = @sql + ' 		M.MiddleName,'
SET @sql = @sql + ' 		M.LastName,'
SET @sql = @sql + ' 		M.Prefix,'
SET @sql = @sql + ' 		M.Suffix,'
SET @sql = @sql + ' 		M.MemberNumber,'
SET @sql = @sql + ' 		M.EffectiveDate,'
SET @sql = @sql + ' 		M.ExpirationDate,'
SET @sql = @sql + ' 		P.Name AS Program,'
SET @sql = @sql + ' 		V.VIN,'
SET @sql = @sql + ' 		V.Year,'
SET @sql = @sql + ' 		V.Make,'
SET @sql = @sql + ' 		V.MakeOther,'
SET @sql = @sql + ' 		V.Model,'
SET @sql = @sql + ' 		V.ModelOther,'
SET @sql = @sql + ' 		V.LicenseState,'
SET @sql = @sql + ' 		V.LicenseNumber,'
SET @sql = @sql + ' 		V.Color,'
SET @sql = @sql + ' 		V.Length,'
SET @sql = @sql + ' 		V.Height,'
SET @sql = @sql + ' 		V.Description,'
SET @sql = @sql + ' 		V.Chassis,'
SET @sql = @sql + ' 		V.Engine,'
SET @sql = @sql + ' 		V.StartMileage,'
SET @sql = @sql + ' 		V.EndMileage,'
SET @sql = @sql + ' 		V.WarrantyStartDate,'
SET @sql = @sql + ' 		V.WarrantyEndDate,'
SET @sql = @sql + ' 		V.WarrantyMileage,'
SET @sql = @sql + ' 		V.WarrantyPeriod,'
SET @sql = @sql + ' 		V.WarrantyPeriodUOM,'
SET @sql = @sql + ' 		V.PurchaseDate,		'

SET @sql = @sql + ' 		AE.ID AS AddressID,		'
SET @sql = @sql + ' 		AE.EntityID AS AddressEntityID,		'
SET @sql = @sql + ' 		AE.AddressTypeID,		'
SET @sql = @sql + ' 		AEE.[Name] AS AddressEntity,		'
SET @sql = @sql + ' 		AEAT.Description AS AddressType,		'
SET @sql = @sql + ' 		AE.Line1, '
SET @sql = @sql + ' 		AE.Line2, '
SET @sql = @sql + ' 		AE.Line3, '
SET @sql = @sql + ' 		AE.City, '
SET @sql = @sql + ' 		AE.StateProvince, '
SET @sql = @sql + ' 		AE.PostalCode, '
SET @sql = @sql + ' 		AE.StateProvinceID, '
SET @sql = @sql + ' 		AE.CountryID, '
SET @sql = @sql + ' 		AE.CountryCode, '

SET @sql = @sql + ' 		PE.ID AS PhoneID,		'
SET @sql = @sql + ' 		PE.EntityID AS PhoneEntityID,		'
SET @sql = @sql + ' 		PE.PhoneTypeID,		'
SET @sql = @sql + ' 		PEE.[Name] AS PhoneEntity,		'
SET @sql = @sql + ' 		PEAT.Description AS PhoneType,		'
SET @sql = @sql + ' 		PE.PhoneNumber, '
SET @sql = @sql + ' 		PE.IndexPhoneNumber, '
SET @sql = @sql + ' 		PE.Sequence '

SET @sql = @sql + ' FROM	Member M WITH (NOLOCK) '
SET @sql = @sql + ' JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID'
SET @sql = @sql + ' JOIN	Program P WITH (NOLOCK) ON M.ProgramID = P.ID'
SET @sql = @sql + ' JOIN	#userClientPrograms UCP  ON UCP.ProgramID = P.ID'
SET @sql = @sql + ' LEFT JOIN Vehicle V WITH (NOLOCK) ON (V.MembershipID = MS.ID OR V.MemberID = M.ID) AND V.IsActive = 1'
SET @sql = @sql + ' LEFT JOIN AddressEntity AE WITH (NOLOCK) ON AE.RecordID = M.ID AND AE.EntityID =  '+ CONVERT(nvarchar(50), @memberEntityID) --+ ' AND AE.AddressTypeID = ' + CONVERT(nvarchar(50), @homeAddressTypeID)
SET @sql = @sql + ' LEFT JOIN PhoneEntity PE WITH (NOLOCK) ON PE.RecordID = M.ID AND PE.EntityID =  '+ CONVERT(nvarchar(50), @memberEntityID)
SET @sql = @sql + ' LEFT JOIN Entity AEE WITH (NOLOCK) ON AE.EntityID = AEE.ID ' 
SET @sql = @sql + ' LEFT JOIN AddressType AEAT WITH (NOLOCK) ON AE.AddressTypeID = AEAT.ID '
SET @sql = @sql + ' LEFT JOIN Entity PEE WITH (NOLOCK) ON PE.EntityID = PEE.ID ' 
SET @sql = @sql + ' LEFT JOIN PhoneType PEAT WITH (NOLOCK) ON PE.PhoneTypeID = PEAT.ID '
SET @sql = @sql + ' WHERE	1=1 '

IF @customerGroupID IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND	MS.MembershipNumber = @customerGroupID'
END
IF @customerID IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND M.MemberNumber = @customerID'
END
IF @internalMemberID IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND	M.ID = @internalMemberID'
END
IF @vehicleVIN IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND V.VIN = @vehicleVIN'
END
IF @lastName IS NOT NULL
BEGIN
	SET  @sql = @sql + ' AND M.LastName like ''%''+@lastName+''%'' '
END
IF @firstName IS NOT NULL
BEGIN
	SET  @sql = @sql + ' AND M.FirstName like ''%''+@firstName+''%'' '
END
SET @sql = @sql + ' AND		ISNULL(M.IsActive,0) = 1'
SET @sql = @sql + ' AND		ISNULL(MS.IsActive,0) = 1'
SET @sql = @sql + ' OPTION (RECOMPILE)'

EXEC sp_executesql @sql, N'@customerGroupID nvarchar(50), @customerID nvarchar(50),@internalMemberID INT,@vehicleVIN NVARCHAR(50),@lastName NVARCHAR(100),@firstName NVARCHAR(100)'
				, @customerGroupID,@customerID,@internalMemberID,@vehicleVIN,@lastName,@firstName

DROP TABLE #userClientPrograms
    
END