/****** Object:  UserDefinedTableType [dbo].[IntTableType]    Script Date: 8/18/2015 2:54:54 PM ******/
CREATE TYPE [dbo].[IntTableType] AS TABLE(
       [ID] [int] NOT NULL,
       PRIMARY KEY CLUSTERED 
(
       [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO
