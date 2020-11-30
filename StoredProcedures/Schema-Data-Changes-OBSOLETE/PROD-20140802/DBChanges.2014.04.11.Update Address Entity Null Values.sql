CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	AddressEntityID int  NULL ,
	StateProvince nvarchar(100)  NULL ,
	StateProvinceID INT  NULL,
	AECountryID INT NULL,
	AECountryCode NVARCHAR(20) NULL,
	SPCountryID INT NULL,
	CountryCode NVARCHAR(20) NULL
) 
INSERT INTO #tmpFinalResults

SELECT DISTINCT
	AE.ID,
	AE.StateProvince,
	SP.ID,
	AE.CountryID ,
	AE.CountryCode,
	SP.CountryID ,
	C.ISOCode 
from AddressEntity AE
LEFT JOIN StateProvince SP ON Sp.Abbreviation = AE.StateProvince
LEFT JOIN Country C ON C.ID = SP.CountryID
WHERE AE.StateProvince IS NOT NULL AND AE.StateProvinceID IS NULL
AND		AE.StateProvince NOT IN ( 'MI','MO','NL') AND SP.ID IS NOT NULL

Select * from #tmpFinalResults

UPDATE      AE
SET         StateProvinceID = TFR.StateProvinceID
		,   CountryCode = CASE 
							WHEN 	TFR.AECountryCode = NULL THEN TFR.CountryCode
							ELSE TFR.AECountryCode
						END
		,	CountryID = CASE 
							WHEN 	TFR.AECountryID = NULL THEN TFR.SPCountryID
							ELSE TFR.AECountryID
						END
							
FROM        AddressEntity AE
INNER JOIN  #tmpFinalResults TFR
ON          AE.ID = TFR.AddressEntityID

DROP TABLE  #tmpFinalResults

	