ALTER TABLE FeedbackType
ADD IsShownOnODIS BIT NULL



Update FeedbackType SET IsShownOnODIS = 1  where Name IN ('Problem','Suggestion','Comment','Other','ISPUpdates','MissingInfo')

--Select * from FeedbackType