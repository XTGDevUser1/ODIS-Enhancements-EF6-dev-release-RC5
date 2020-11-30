/****** Object:  Table [dbo].[ClaimVehicleDiagnosticCode]    Script Date: 10/04/2013 13:41:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ClaimVehicleDiagnosticCode](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClaimID] [int] NULL,
	[VehicleDiagnosticCodeID] [int] NULL,
	[VehicleDiagnosticCodeType] [nvarchar](50) NULL,
	[IsPrimary] [bit] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_ClaimVehicleDiagnosticCode] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ClaimVehicleDiagnosticCode]  WITH CHECK ADD  CONSTRAINT [FK_ClaimVehicleDiagnosticCode_Claim] FOREIGN KEY([ClaimID])
REFERENCES [dbo].[Claim] ([ID])
GO

ALTER TABLE [dbo].[ClaimVehicleDiagnosticCode] CHECK CONSTRAINT [FK_ClaimVehicleDiagnosticCode_Claim]
GO

ALTER TABLE [dbo].[ClaimVehicleDiagnosticCode]  WITH NOCHECK ADD  CONSTRAINT [FK_ClaimVehicleDiagnosticCode_ClaimVehicleDiagnosticCode] FOREIGN KEY([VehicleDiagnosticCodeID])
REFERENCES [dbo].[VehicleDiagnosticCode] ([ID])
GO

ALTER TABLE [dbo].[ClaimVehicleDiagnosticCode] NOCHECK CONSTRAINT [FK_ClaimVehicleDiagnosticCode_ClaimVehicleDiagnosticCode]
GO

ALTER TABLE [dbo].[Document]
ADD IsShownOnVendorPortal bit NULL
GO


--Sanghi For Vendor Portal Contact Us Page
INSERT INTO ApplicationConfiguration(Name,Value,CreateBy,CreateDate) 
VALUES('ContactUsEmail','rustyh@martexsoftware.com','SYS',GETDATE())