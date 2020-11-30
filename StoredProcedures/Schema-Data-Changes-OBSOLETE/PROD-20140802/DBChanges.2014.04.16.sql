ALTER TABLE NextAction ADD DefaultScheduleDateInterval INT NULL
ALTER TABLE NextAction ADD DefaultScheduleDateIntervalUOM NVARCHAR(20) NULL


INSERT INTO NextAction Values(NULL,'CreditCardNeeded','Credit Card Needed',NULL,1,NULL,0,'Seconds')

