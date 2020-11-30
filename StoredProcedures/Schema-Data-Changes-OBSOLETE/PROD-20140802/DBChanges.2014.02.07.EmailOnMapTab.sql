
--New Enhancement: Email on Map Tab --
--**********Create an new table ContactEmailDeclineReason ****----

Create Table [dbo].[ContactEmailDeclineReason]
(ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
[Reason] nvarchar(50) NULL,
[Description]  nvarchar(255) NULL,
[Sequence] int NULL,
[IsActive] bit NULL)
 


--****Insert values into ContactEmailDeclineReason ****--

 Insert Into [dbo].[ContactEmailDeclineReason]
 ([Reason],[Description],[Sequence],[IsActive])
 values
 ('DeclinedSurvery','Declined Survey',1,1)


 
  Insert Into [dbo].[ContactEmailDeclineReason]
 ([Reason],[Description],[Sequence],[IsActive])
 values
 ('Noemailaccount','No email account',2,1)


--*****Add new columns in Case Table *********--

ALTER TABLE [dbo].[Case]
ADD  ContactEmail nvarchar(255) NULL, ReasonID Int NULL 


ALTER TABLE [dbo].[Case]
ADD FOREIGN KEY (ReasonID) REFERENCES [dbo].[ContactEmailDeclineReason](ID)