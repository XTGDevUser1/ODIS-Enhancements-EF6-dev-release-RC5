ALTER TABLE CLIENT 
ADD FTPFolder NVARCHAR(256) NULL

ALTER TABLE DocumentCategory
ADD IsShownOnClientPortal BIT NULL


Update DocumentCategory SET IsShownOnClientPortal =1 where Name='Contract'