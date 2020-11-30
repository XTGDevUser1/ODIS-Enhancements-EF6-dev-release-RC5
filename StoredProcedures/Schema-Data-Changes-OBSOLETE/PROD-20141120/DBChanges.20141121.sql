

INSERT INTO Event VALUES((SELECT ID FROM EventType WHERE Name = 'System'),(SELECT ID FROM EventCategory WHERE Name  = 'Search'),'BingMapDown','Bing Map Service Down',0,1,'System',GETDATE())
