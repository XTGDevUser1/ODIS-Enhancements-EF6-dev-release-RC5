ALTER TABLE UserInvite
ADD IsActive BIT NULL

UPDATE UserInvite SET IsActive = 1

ALTER TABLE UserInvite
ADD SentDate DATETIME NULL

UPDATE UserInvite SET SentDate = CreateDate

--Select * from UserInvite
