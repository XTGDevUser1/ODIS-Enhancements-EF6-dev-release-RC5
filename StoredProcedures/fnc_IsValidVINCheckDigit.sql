 /****** Object:  UserDefinedFunction [dbo].[fnc_IsValidVINCheckDigit]    Script Date: 27/10/2015 20:28:06 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_IsValidVINCheckDigit]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_IsValidVINCheckDigit]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_IsValidVINCheckDigit]    Script Date: 12/10/2012 20:03:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- SELECT dbo.fnc_IsValidVINCheckDigit('3FRNF6HP8CV192324')  
  
CREATE FUNCTION [dbo].[fnc_IsValidVINCheckDigit]   
(  
 @VIN nvarchar(17)  
)  
RETURNS bit  
AS  
BEGIN  
 --SET NOCOUNT ON  
  
 --DECLARE @VIN nvarchar(17)  
 --SET @VIN = '3FRNF6HP8CV192324'  
   
 -- Fail any VIN that contains non-alphanumeric characters   
 IF PATINDEX('%[^a-zA-Z0-9]%' , @VIN) > 0 OR LEN(@VIN) <> 17  
  RETURN 0  
  
 DECLARE @VINSum int, @Position int, @PositionValue int, @VINCheckDigit int, @IsValid bit  
  
 DECLARE @VinAlphaNumber TABLE (VIN_Alpha char(1), VIN_AlphaNumber int)  
 DECLARE @VINPositionWeight TABLE (VINPosition int, PositionWeight int)  
  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('A',1)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('B',2)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('C',3)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('D',4)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('E',5)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('F',6)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('G',7)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('H',8)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('J',1)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('K',2)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('L',3)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('M',4)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('N',5)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('P',7)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('R',9)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('S',2)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('T',3)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('U',4)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('V',5)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('W',6)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('X',7)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('Y',8)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('Z',9)  
  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (1, 8)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (2, 7)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (3, 6)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (4, 5)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (5, 4)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (6, 3)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (7, 2)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (8, 10)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (10, 9)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (11, 8)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (12, 7)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (13, 6)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (14, 5)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (15, 4)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (16, 3)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (17, 2)  
  
 SET @Position = 1  
 SET @VINSum = 0  
  
 WHILE @Position <= 17  
 BEGIN  
    
  IF @Position <> 9  
  BEGIN  
   SET @PositionValue = CASE WHEN ISNUMERIC(SUBSTRING(@VIN, @Position, 1)) = 1 THEN CONVERT(int, SUBSTRING(@VIN, @Position, 1)) ELSE (SELECT VIN_AlphaNumber FROM @VinAlphaNumber WHERE VIN_Alpha = SUBSTRING(@VIN, @Position, 1)) END  
   SET @VinSum = @VINSum + ((SELECT PositionWeight FROM @VINPositionWeight WHERE VINPosition = @Position) * @PositionValue)  
  END  
    
  SET @Position = @Position + 1  
    
 END  
  
 SET @VINCheckDigit = @VINSum % 11  
   
 SET @IsValid = 0  
 IF SUBSTRING(@VIN, 9, 1) = CASE WHEN @VINCheckDigit = 10 THEN 'X' ELSE CONVERT(char(1),@VINCheckDigit) END    
  SET @IsValid = 1  
  
 RETURN @IsValid  
  
END