
---*********** Queue Color Enhancement DB Scripts *********----

-- 1.CREATE A NEW TABLE --

CREATE TABLE [dbo].[QueueStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Minutes] [int] NULL,
	[Color] [nvarchar](100) NULL,
	[SRStatusName] [nvarchar](50) NULL,
	[Action] [nvarchar](100) NULL,
	[IsActive] [bit] NULL,
	[Sequence] [int] NULL
	)
	

-- 2. INSERT RECORDS INTO "[dbo].[QueueStatus]" TABLE --

-- ENTRY - MANUAL CLOSED LOOP--

INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (0
           ,'#EE6F4C'
           ,'Entry'
           ,'Manual Closed Loop'
           ,1
           ,1)
GO



--ENTRY - SCHEDULED DATE --

INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (0
           ,'#F1DD40'
           ,'Entry'
           ,'Scheduled'
           ,1
           ,1)
GO



INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (16
           ,'#EE6F4C'
           ,'Entry'
           ,'Scheduled'
           ,1
           ,1)
GO

-- ENTRY --

INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (31
           ,'#F1DD40'
           ,'Entry'
           ,NULL
           ,1
           ,1)
GO



INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (46
           ,'#EE6F4C'
           ,'Entry'
           ,NULL
           ,1
           ,1)
GO





-- SUBMITTED - MANUAL CLOSED LOOP--

INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (0
           ,'#EE6F4C'
           ,'Submitted'
           ,'Manual Closed Loop'
           ,1
           ,2)
GO

--SUBMITTED - SCHEDULED DATE --

INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (0
           ,'#F1DD40'
           ,'Submitted'
           ,'Scheduled'
           ,1
           ,2)
GO



INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (16
           ,'#EE6F4C'
           ,'Submitted'
           ,'Scheduled'
           ,1
           ,2)
GO

--SUBMITTED--


INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (31
           ,'#F1DD40'
           ,'Submitted'
           ,NULL
           ,1
           ,2)
GO



INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (61
           ,'#EE6F4C'
           ,'Submitted'
           ,NULL
           ,1
           ,2)
GO



--DISPATCHED -MANUAL CLOSED LOOP --

INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (0
           ,'#EE6F4C'
           ,'Dispatched'
           ,'Manual Closed Loop'
           ,1
           ,3)
GO


--DISPATCHED - SCHEDULED DATE --

INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (0
           ,'#F1DD40'
           ,'Dispatched'
           ,'Scheduled'
           ,1
           ,3)
GO



INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (16
           ,'#EE6F4C'
           ,'Dispatched'
           ,'Scheduled'
           ,1
           ,3)
GO


--DISPATCHED --


INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (61
           ,'#F1DD40'
           ,'Dispatched'
           ,NULL
           ,1
           ,3)
GO



INSERT INTO [dbo].[QueueStatus]
           ([Minutes]
           ,[Color]
           ,[SRStatusName]
           ,[Action]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (81
           ,'#EE6F4C'
           ,'Dispatched'
           ,NULL
           ,1
           ,3)
GO