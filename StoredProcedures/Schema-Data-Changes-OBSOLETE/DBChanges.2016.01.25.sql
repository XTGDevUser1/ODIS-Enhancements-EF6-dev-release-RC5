IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'Latitude' AND Object_ID = Object_ID(N'Latitude'))
BEGIN
    ALTER TABLE StateProvince ADD Latitude DECIMAL(10,7) NULL
END
IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'Latitude' AND Object_ID = Object_ID(N'Longitude'))
BEGIN
    ALTER TABLE StateProvince ADD Longitude DECIMAL(10,7) NULL
END
IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'Latitude' AND Object_ID = Object_ID(N'Color'))
BEGIN
    ALTER TABLE StateProvince ADD Color NVARCHAR(6) NULL
END