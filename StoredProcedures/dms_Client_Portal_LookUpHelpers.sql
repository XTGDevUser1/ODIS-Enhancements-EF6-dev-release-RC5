
-- LOOKUP SP Details
-- dms_ClientPortal_program_list
-- dms_ClientPortal_prefix_list
-- dms_ClientPortal_suffix_list
-- dms_ClientPortal_phoneTypes_list
-- dms_ClientPortal_country_list
-- dms_ClientPortal_state_list
-- dms_ClientPortal_addressType_list


-----------------------------------------------------
---------- LOOK UP SP FOR Client Portal--------------
---------- Author : Sanghi Krishna ------------------
---------- Created on : 05.July.2013-----------------

---------- Check Schema for Program -----------------
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_NAME = 'Program' 
              AND  COLUMN_NAME = 'IsWebRegistrationEnabled') 
BEGIN
	ALTER TABLE Program ADD IsWebRegistrationEnabled BIT NULL
END

GO

---------- SP TO GET ALL PROGRAMS  -----------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ClientPortal_program_list]') AND type in (N'P', N'PC'))
DROP PROC [dbo].[dms_ClientPortal_program_list]
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_program_list](
@clientID INT
) 
AS
BEGIN
	SELECT	[ID],
			[Name],
			[Description] 
	FROM	Program (NOLOCK)
	WHERE	ClientID = @ClientID
	AND		IsActive = 1
	AND		IsWebRegistrationEnabled = 1
	AND		IsGroup <> 1
	ORDER BY Name

END




GO
---------- END FOR ALL PROGRAMS --------------------


---------- SP TO GET ALL Prefix  -------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ClientPortal_prefix_list]') AND type in (N'P', N'PC'))
DROP PROC [dbo].[dms_ClientPortal_prefix_list]
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_prefix_list] 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM Prefix (NOLOCK)
	ORDER BY Sequence ASC
END
GO
---------- END FOR Prefix  ------------------------


---------- SP TO GET ALL Suffix  -------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ClientPortal_suffix_list]') AND type in (N'P', N'PC'))
DROP PROC [dbo].[dms_ClientPortal_suffix_list]
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_suffix_list] 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM Suffix(NOLOCK)
	ORDER BY Sequence ASC
END
GO
---------- END FOR Suffix  ------------------------


---------- SP TO GET ALL Phone Types  -------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ClientPortal_phoneTypes_list]') AND type in (N'P', N'PC'))
DROP PROC [dbo].[dms_ClientPortal_phoneTypes_list]
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_phoneTypes_list] 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM PhoneType(NOLOCK) 
	WHERE IsActive = 1
	ORDER BY Sequence ASC
END
GO
---------- END FOR Phone Types  ------------------------


---------- SP TO GET ALL Country  -------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ClientPortal_country_list]') AND type in (N'P', N'PC'))
DROP PROC [dbo].[dms_ClientPortal_country_list]
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_country_list] 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [ISOCode] FROM Country (NOLOCK)
	WHERE IsActive = 1
	ORDER BY Sequence ASC
END
GO
---------- END FOR Country  ------------------------


---------- SP TO GET ALL State by Country  ------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ClientPortal_state_list]') AND type in (N'P', N'PC'))
DROP PROC [dbo].[dms_ClientPortal_state_list]
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_state_list](@countryID INT = NULL)
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Abbreviation] FROM StateProvince(NOLOCK)
	WHERE (@countryID IS NULL) OR (CountryID = @countryID)
	ORDER BY Sequence ASC
END
GO
---------- END FOR State List------------------------

---------- SP TO GET ALL Address Types---------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ClientPortal_addressType_list]') AND type in (N'P', N'PC'))
DROP PROC [dbo].[dms_ClientPortal_addressType_list]
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_addressType_list]
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM AddressType(NOLOCK)
	WHERE IsActive = 1
	ORDER BY Sequence ASC
END
GO
---------- END FOR Address Type ---------------------




