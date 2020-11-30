 
 --Enhancement - Remove "Ford Survery Email" actions in Finish Tab --
 
 Update [dbo].[ContactAction]
 Set [IsActive] = 0
 where Name='MailFordSurvey'
 
 Update [dbo].[ContactAction]
 Set [IsActive] = 0
 where Name='TextFordSurvey'