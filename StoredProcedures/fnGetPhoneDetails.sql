IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetPhoneDetails]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetPhoneDetails]
GO
CREATE FUNCTION dbo.fnGetPhoneDetails(@EntityName NVARCHAR(50),@PhoneTypeName NVARCHAR(50),@RecordID INT)
RETURNS @PhoneDetails TABLE
(
		PhoneID INT,
		PhoneEntityID INT,
		PhoneRecordID INT,
		PhoneTypeID INT,
	    PhoneNumber NVARCHAR(100)
)
AS
BEGIN
	
	with wPhone AS(
						SELECT TOP 1 * FROM PhoneEntity 
						WHERE EntityID = (SELECT EntityID FROM Entity WHERE Name = @EntityName)
					    AND RecordID = @RecordID
						AND PhoneTypeID = (SELECT PhoneTypeID FROM PhoneType WHERE Name = @PhoneTypeName)
					)
	
	INSERT INTO @PhoneDetails 
	SELECT ID,
		   EntityID,
		   RecordID,
		   PhoneTypeID,
		   PhoneNumber
	FROM wPhone
	RETURN 
END




