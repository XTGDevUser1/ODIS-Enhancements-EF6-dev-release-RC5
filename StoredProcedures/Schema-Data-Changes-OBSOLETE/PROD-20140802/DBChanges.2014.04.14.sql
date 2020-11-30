--
-- Setup New Contact Category / Reason / Actions for NON-MEMBER
--

--select * from ContactCategory where name = 'Non-Member'
--select * from ContactReason where contactcategoryid = (select id from contactcategory where name = 'Non-Member')
--select * from ContactAction where contactcategoryid = (select id from contactcategory where name = 'Non-Member')
--select * from ContactCategory where isshownonfinish = 1 and isactive = 1 order by sequence

-- Add New ContactCategory
IF NOT EXISTS (SELECT * FROM ContactCategory WHERE Name = 'Non-Member')
	BEGIN
		INSERT INTO [dbo].[ContactCategory] ([Name],[Description],[IsShownOnFinish],[IsActive],[Sequence],[IsShownOnActivity])
		VALUES ('Non-Member', 'Non-Member', 1, 1, 12, 0)
	END
GO

-- Add New ContactReason
DECLARE @ContactCategory INT = (SELECT ID FROM ContactCategory WHERE Name = 'Non-Member')
IF NOT EXISTS (SELECT ID FROM ContactReason WHERE Name = 'Non-Member' AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactReason] ([ContactCategoryID],[Name],[Description],[IsActive],[IsShownOnScreen],[Sequence])
		VALUES (@ContactCategory, 'Non-Member', 'Non-Member', 1, 1, 5)
	END
GO

-- Add New ContactAction
DECLARE @ContactCategory INT = (SELECT ID FROM ContactCategory WHERE Name = 'Non-Member')
IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Transferred Call to Agero'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Transferred Call to Agero', 'Transferred to Agero', 1, 0, 1, 1, NULL)
	END

IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Wrong Number'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Wrong Number', 'Wrong Number', 1, 0, 1, 2, NULL)
	END
	
IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Hang up'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Hang up', 'Hang up', 1, 0, 1, 3, NULL)
	END

IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Havasu forward'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Havasu forward', 'Havasu forward', 1, 0, 1, 4, NULL)
	END		

IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Transferred to Member Service'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Transferred to Member Service', 'Transferred to Member Service', 1, 0, 1, 5, NULL)
	END		

IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Questions to become a member' AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Questions to become a member', 'Questions to become a member', 1, 0, 1, 6, NULL)
	END		
	
IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Dead air' AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Dead air', 'Dead air', 1, 0, 1, 7, NULL)
	END		
	
