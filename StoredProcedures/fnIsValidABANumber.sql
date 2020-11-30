IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnIsValidABANumber') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnIsValidABANumber]
GO
CREATE function [dbo].[fnIsValidABANumber](@inputText NVARCHAR(9)) RETURNS BIT
AS
BEGIN
	DECLARE @InputNumber INT
	DECLARE @outPut BIT = 0;
	DECLARE @sum INT = 0;
	
	IF ISNUMERIC(@inputText) = 1
	BEGIN
		SET @InputNumber = CONVERT(INT,@inputText)
		IF(LEN(@inputText) = 9)
			BEGIN
	 			SET @sum = CAST(SUBSTRING(@inputText,1,1) AS INT) * 3 +
	 					   CAST(SUBSTRING(@inputText,2,1) AS INT) * 7 +
	 					   CAST(SUBSTRING(@inputText,3,1) AS INT) * 1 +
		 				   
	 					   CAST(SUBSTRING(@inputText,4,1) AS INT) * 3 +
	 					   CAST(SUBSTRING(@inputText,5,1) AS INT) * 7 +
	 					   CAST(SUBSTRING(@inputText,6,1) AS INT) * 1 +
		 				   
	 					   CAST(SUBSTRING(@inputText,7,1) AS INT) * 3 +
	 					   CAST(SUBSTRING(@inputText,8,1) AS INT) * 7 +
	 					   CAST(SUBSTRING(@inputText,9,1) AS INT) * 1
	 			IF(@sum % 10 = 0)
	 			BEGIN
	 				SET @outPut =  1;
	 			END
			END
		ELSE 
			BEGIN
				SET @outPut =  0;
			END
		END
	RETURN @outPut;
END





