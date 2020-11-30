
IF NOT EXISTS ( SELECT * 
				FROM	ProgramConfiguration 
				WHERE	ConfigurationTypeID = (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
				AND		ConfigurationCategoryID = (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')
				AND		Name = 'AllowRegisterMember')
BEGIN
	INSERT INTO ProgramConfiguration (
				ProgramID,
				ConfigurationTypeID,
				ConfigurationCategoryID,
				Name,
				Value,
				IsActive,
				CreateDate,
				CreateBy
				)

	SELECT (SELECT ID FROM Program WHERE Name = 'Ford'),
			(SELECT ID FROM ConfigurationType WHERE Name = 'Application'),
			(SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule'),
			'AllowRegisterMember',
			'Yes',
			1,
			GETDATE(),
			'system'
END
GO


 ---Script to setup RentalCover.com Email Notification Subscriptions


-----------------------------------------------------------------------
----- RentalCover.COM Event for getting copy of Payment Receipt

-- Insert Event
IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'SendPaymentReceiptCopyToClient')
BEGIN
	INSERT Event (EventTypeID, EventCategoryID, Name, Description, IsShownOnScreen, IsActive, CreateBy, CreateDate)
	VALUES ((SELECT ID FROM EventType WHERE Name = 'System'), (SELECT ID FROM EventCategory WHERE Name='Payment'), 'SendPaymentReceiptCopyToClient','Send Payment Receipt Copy To Client', 0, 1, 'system', GETDATE())
END

-- Insert Template
IF NOT EXISTS (SELECT ID FROM Template WHERE Name = 'RentalCover_PaymentReceiptEmail')
BEGIN
	INSERT Template (Name, Subject, Body, IsActive, CreateDate, CreateBy, ModifyDate, ModifyBy)
	VALUES ('RentalCover_PaymentReceiptEmail', 'RentalCover - Payment Receipt Copy', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> <html xmlns="http://www.w3.org/1999/xhtml">     <head>     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />     <title>Payment Receipt: COACH-NET&reg; RV TECHNICAL &amp; ROADSIDE ASSISTANCE</title>     <style type="text/css"> #outlook a {  padding: 0; } body {  width: 100% !important; } .ReadMsgBody {  width: 100%; } .ExternalClass {  width: 100%; } body {  -webkit-text-size-adjust: none; } body {  margin: 0;  padding: 0; } img {  border: 0;  height: auto;  line-height: 100%;  outline: none;  text-decoration: none; } table td {  border-collapse: collapse; } #backgroundTable {  height: 100% !important;  margin: 0;  padding: 0;  width: 100% !important; } body, #backgroundTable {  background-color: #FAFAFA; } #templateContainer {  border: 1px solid #DDDDDD; } h1, .h1 {  color: #202020;  display: block;  font-family: Arial;  font-size: 34px;  font-weight: bold;  line-height: 100%;  margin-top: 0;  margin-right: 0;  margin-bottom: 10px;  margin-left: 0;  text-align: left; } h2, .h2 {  color: #202020;  display: block;  font-family: Arial;  font-size: 30px;  font-weight: bold;  line-height: 100%;  margin-top: 0;  margin-right: 0;  margin-bottom: 10px;  margin-left: 0;  text-align: left; } h3 { color:#cc0000;} h3, .h3 {  color: #cc0000;  display: block;  font-family: Arial;  font-size: 18px;  font-weight: bold;  line-height: 100%;  margin-top: 0;  margin-right: 0;  margin-bottom: 10px;  margin-left: 0;  text-align: left; } h4, .h4 {  color: #202020;  display: block;  font-family: Arial;  font-size: 16px;  font-weight: bold;  line-height: 100%;  margin-top: 0;  margin-right: 0;  margin-bottom: 5px;  margin-left: 0;  text-align: left; } .hr {  border: none;  background-color: #000000;  color: #000;  height: 2px; } hr {  border: none;  background-color: #000000;  color: #000;  height: 2px; } #templatePreheader {  background-color: #FAFAFA; } .preheaderContent div {  color: #505050;  font-family: Arial;  font-size: 10px;  line-height: 100%;  text-align: left; } .preheaderContent div a:link, .preheaderContent div a:visited, .preheader content div a .yshortcuts {  color: #336699;  font-weight: normal;  text-decoration: underline; } #templateHeader {  background-color: #FFFFFF;  border-bottom: 0; } .headerContent {  color: #202020;  font-family: Arial;  font-size: 34px;  font-weight: bold;  line-height: 100%;  padding: 0;  text-align: center;  vertical-align: middle; } .headerContent a:link, .headerCont ent a:visited, .headerContent a .yshortcuts {  color: #336699;  font-weight: normal;  text-decoration: underline; } #headerImage {  height: auto;  max-width: 600px !important; } #templateContainer, .bodyContent {  background-color: #FFFFFF; } .bodyContent div {  color: #505050;  font-family: Arial;  font-size: 14px;  line-height: 150%;  text-align: left !important; } .bodyContent div a:link, .bodyContent div a:visited, .bodyContent div a .yshortcuts {  color: #336699;  font-weight: normal;  text-decoration: underline; } .bodyContent img {  display: inline;  height: auto; } #templateFooter {  background-color: #FFFFFF;  border-top: 0; } .footerContent div {  color: #707070;  font-family: Arial;  font-size: 12px;  line-height: 125%;  text-align: left; } .footerContent div a:link, .footerContent div a:visited, /* Yahoo! Mail Override */ .footerContent div a .yshortcuts {  color: #336699;  font-weight: normal;  text-decoration: underline; } .footerContent img {  display: inline; } #social {  background-color: #FAFAFA;  border: 0; } #social div {  text-align: center; } #utility {  background-color: #FFFFFF;  border: 0; } #utility div {  text-align: center; } </style>     </head>     <body style="margin: 0;padding: 0;background-color: #FAFAFA;height: 100% !important;width: 100% !important;">     <center>       <table border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="backgroundTable" style="margin: 0;padding: 0;background-color: #FAFAFA;height: 100% !important;width: 100% !important;">         <tr>           <td align="center" valign="top" style="border-collapse: collapse;"><table border="0" cellpadding="10" cellspacing="0" width="600" id="templatePreheader" >               <tr>               <td valign="top" class="preheaderContent" style="border-collapse: collapse;"></td>             </tr>             </table>             <table border="0" cellpadding="0" cellspacing="0" width="600" id="templateContainer" style="background-color: #FFFFFF" style="border:1px solid #dddddd;background-color:#ffffff">               <tr>                 <td align="center" valign="top"><table border="0" cellpadding="0" cellspacing="0" width="600" id="templateHeader">                     <tr>                     <td class="headerContent"></td>                   </tr>                   </table></td>               </tr>               <tr>                 <td align="center" valign="top"><table border="0" cellpadding="0" cellspacing="0" width="600" id="templateBody" style="border-collapse: collapse;">                     <tr>                     <td valign="top" class="bodyContent" style="border-collapse: collapse;background-color: #FFFFFF;"><table border="0" cellpadding="20" cellspacing="0" width="100%">                         <tr>                         <td align="left" valign="top"><div>                             <h3 class="h3"><span style="color:#cc0000;"> COACH-NET&reg; RV TECHNICAL &amp; ROADSIDE ASSISTANCE</span></h3> <br />                               <br />                             <h4 class="h4">                               Payment Receipt</h4>                             <div style="color: #505050;font-family: Arial;font-size: 14px;line-height: 150%;text-align: left;">                             <p> Thank you for your payment! This email confirms the charges made to your credit                               card for the roadside service. <br />                               <br />                               Below is a summary of your service: </p>                           </div>                             <h4 class="h4"> <br />                               Service Information</h4>                                                          <div style="color: #505050;font-family: Arial;font-size: 14px;line-height: 150%;text-align: left;">                             <table width="100%" border="0" class="bodyContent" style="border-top:2px solid #000000;background-color:#ffffff">                               <tr>                                 <td width="22%" style="border-collapse: collapse;"> Order Number: </td>                                 <td width="78%" style="border-collapse: collapse;"><strong>${CCOrderID}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;"> Date: </td>                                 <td style="border-collapse: collapse;"><strong>${PaymentDate}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;"> Service: </td>                                 <td style="border-collapse: collapse;"><strong>${Service}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;"> Location: </td>                                 <td style="border-collapse: collapse;"><strong>${ServiceLocationAddress}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;"> Destination: </td>                                 <td style="border-collapse: collapse;"><strong>${DestinationAddress}</strong></td>                               </tr>                             </table>                             </div>                              <br />                           <h4 class="h4">                               Payment Information</h4>                             <div style="color: #505050;font-family: Arial;font-size: 14px;line-height: 150%;text-align: left;">                             <table width="100%" border="0" class="bodyContent"  style="border-top:2px solid #000000;background-color:#ffffff">                               <tr>                                 <td width="22%" style="border-collapse: collapse;"> Card Name: </td>                                 <td width="78%" style="border-collapse: collapse;"><strong>${NameOnCard}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;"> Card Type: </td>                                 <td style="border-collapse: collapse;"><strong>${CardType}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;"> Card Number: </td>                                 <td style="border-collapse: collapse;"><strong>${CCPartial}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;"> Card Expiration: </td>                                 <td style="border-collapse: collapse;"><strong>${ExpirationDate}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;"> Amount: </td>                                 <td style="border-collapse: collapse;"><strong>${Amount}</strong></td>                               </tr>                               <tr>                                 <td style="border-collapse: collapse;">Type:</td>                                 <td style="border-collapse: collapse;"><strong>${type}</strong></td>                               </tr>                             </table>                           </div>                             <br />                              <div style="color: #505050;font-family: Arial;font-size: 14px;line-height: 150%;text-align: left;">                             <p>                              We appreciate your continued business. </p>                             <p> Thank you <br />                               </p>                           </div>                           </div></td>                       </tr>                       </table></td>                   </tr>                   </table></td>               </tr>               <tr>                 <td align="center" valign="top"><table border="0" cellpadding="10" cellspacing="0" width="600" id="templateFooter">                     <tr>                     <td valign="top" class="footerContent"><table border="0" cellpadding="10" cellspacing="0" width="100%">                         <tr>                         <td width="350" valign="top"><div class="footerContent"> <br />                             <strong>Our contact information is:</strong> <br />                             800 Point Vista Dr Ste 532<br />                             Hickory Creek, TX 75065<br />                             (888)777-9312 </div></td>                         <td valign="top" width="190">&nbsp;</td>                       </tr>                       </table></td>                   </tr>                   </table></td>               </tr>             </table>             <br /></td>         </tr>       </table>     </center> </body> </html>', 1, GETDATE(), 'system', NULL, NULL)
END

-- Insert EventTemplate
IF NOT EXISTS (SELECT ID FROM EventTemplate WHERE EventID = (SELECT ID FROM Event WHERE Name='SendPaymentReceiptCopyToClient') AND TemplateID = (SELECT ID FROM Template WHERE Name='RentalCover_PaymentReceiptEmail') )
BEGIN
	INSERT EventTemplate (EventID, TemplateID, IsDefault)
	VALUES ((SELECT ID FROM Event WHERE Name='SendPaymentReceiptCopyToClient'), (SELECT ID FROM Template WHERE Name='RentalCover_PaymentReceiptEmail'), 1)
END

-- Insert Subscriptions
IF NOT EXISTS (SELECT ID FROM EventSubscription WHERE EventID = (SELECT ID FROM Event WHERE Name = 'SendPaymentReceiptCopyToClient') AND ContactMethodID = 4 AND Email = 'rusty.hancock@martexsoftware.com')
BEGIN
	INSERT EventSubscription (EventID, EventTypeID, EventCategoryID, ContactMethodID, EventTemplateID, PhoneTypeID, PhoneNumber, Email, IsActive, CreateDate, CreateBy, NotificationRecipientTypeID, NotificationRecipient)
	VALUES ( (SELECT ID FROM Event WHERE Name='SendPaymentReceiptCopyToClient')
			, NULL
			, NULL
			, (SELECT ID FROM ContactMethod WHERE Name='Email')
			, (SELECT ID FROM EventTemplate WHERE EventID = (SELECT ID FROM Event WHERE Name='SendPaymentReceiptCopyToClient') AND TemplateID = (SELECT ID FROM Template WHERE Name='RentalCover_PaymentReceiptEmail') )
			, NULL
			, NULL
			, 'rusty.hancock@martexsoftware.com'
			, 1
			, GETDATE()
			, 'system'
			, NULL
			, NULL
			)
END



-- From TFS 646 and inputs from Rusty.
IF NOT EXISTS (SELECT * FROM NextAction WHERE Name = 'RepairFollowUp')  
BEGIN
 
INSERT NextAction (ContactCategoryID, Name, Description, DefaultPriorityID, IsActive, Sequence, DefaultScheduleDateInterval, DefaultScheduleDateIntervalUOM, DefaultAssignedToUserID)
VALUES (NULL, 'RepairFollowUp', 'Repair Follow Up', 1, 1, 16, NULL, NULL, (SELECT ID FROM [User] WHERE FirstName='Tech' AND LastName='User'))
UPDATE NextAction SET Sequence = 17 WHERE Name='TechAssist'
UPDATE NextAction SET Sequence = 18 WHERE Name='ScheduleService' 
  
END
