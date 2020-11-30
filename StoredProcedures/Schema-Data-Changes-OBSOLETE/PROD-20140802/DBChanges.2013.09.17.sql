﻿-- Schema CHanges
ALTER TABLE Vendor
ADD IsACHActive BIT NULL
Go

ALTER TABLE Vendor
ADD ACHSignedByName NVARCHAR(255) NULL
GO

ALTER TABLE Vendor
ADD ACHSignedByTitle NVARCHAR(50) NULL
GO

ALTER TABLE Vendor
ADD ACHSignedByDate DATETIME NULL
GO

ALTER TABLE VendorRegion
ADD PhoneNumber NVARCHAR(50) NULL
GO


-- Changes from Tim
ALTER TABLE [dbo].[ServiceRequest]
ALTER COLUMN [AccountingInvoiceBatchID] int NULL;
GO

ALTER TABLE [dbo].[PurchaseOrder]
ALTER COLUMN [AccountingInvoiceBatchID] int NULL;
GO

ALTER TABLE [dbo].[VendorInvoice]
ALTER COLUMN [AccountingInvoiceBatchID] int NULL;
GO

ALTER TABLE [dbo].[VendorInvoice]
ALTER COLUMN [AccountingInvoiceBatchID] int NULL;
GO

ALTER TABLE [dbo].[Claim]
ALTER COLUMN [AccountingInvoiceBatchID] int NULL;
GO

ALTER TABLE [dbo].[Client]
DROP COLUMN AccountingCode
GO

-- Data 
-- Application Configuration Entries
IF NOT EXISTS(SELECT * FROM ApplicationConfiguration WHERE Name = 'DefaultClaimListDays')
BEGIN
	INSERT INTO ApplicationConfiguration(ApplicationConfigurationTypeID,Name,Value,CreateBy,CreateDate)
	VALUES ((SELECT ID FROM ApplicationConfigurationType WHERE Name = 'System'),
			'DefaultClaimListDays',
			'30',
			'System',
			GETDATE())
END

-- For Vendor Portal
INSERT INTO Securable VALUES('MENU_LEFT_VENDOR_PORTAL_ACH',NULL,NULL)
--Note Add AccessControlList



DELETE FROM Template WHERE Name IN ('TransitionRegistrationConfirmation',
'RegistrationConfirmation','ForgotPassword','VendorPortal_ApplicationConfirmation','Vendor_Welcome','RegisterVendor','VendorPortal_ChangePassword','VendorPortal_ForgotPassword')

ALTER TABLE Template
ALTER COLUMN Subject NVARCHAR(100)
GO

INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('VendorPortal_ApplicationConfirmation', 'Your VIP Application has been received', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Your VIP Application has been received. </title>
		<style type="text/css">
			/* /\/\/\/\/\/\/\/\/ CLIENT-SPECIFIC STYLES /\/\/\/\/\/\/\/\/ */
			#outlook a{padding:0;} /* Force Outlook to provide a view in browser message */
			.ReadMsgBody{width:100%;} .ExternalClass{width:100%;} /* Force Hotmail to display emails at full width */
			.ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {line-height: 100%;} /* Force Hotmail to display normal line spacing */
			body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;} /* Prevent WebKit and Windows mobile changing default text sizes */
			table, td{mso-table-lspace:0pt; mso-table-rspace:0pt;} /* Remove spacing between tables in Outlook 2007 and up */
			img{-ms-interpolation-mode:bicubic;} /* Allow smoother rendering of resized image in Internet Explorer */

			/* /\/\/\/\/\/\/\/\/ RESET STYLES /\/\/\/\/\/\/\/\/ */
			body{margin:0; padding:0;}
			img{border:0; height:auto; line-height:100%; outline:none; text-decoration:none;}
			table{border-collapse:collapse !important;}
			body, #bodyTable, #bodyCell{height:100% !important; margin:0; padding:0; width:100% !important;}

			/* /\/\/\/\/\/\/\/\/ TEMPLATE STYLES /\/\/\/\/\/\/\/\/ */

			/* ========== Page Styles ========== */

			#bodyCell{padding:20px;}
			#templateContainer{width:600px;}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			body, #bodyTable{
				/*@editable*/ background-color:#DEE0E2;
			}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			#bodyCell{
				/*@editable*/ border-top:4px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section email border
			* @tip Set the border for your email.
			*/
			#templateContainer{
				/*@editable*/ border:1px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section heading 1
			* @tip Set the styling for all first-level headings in your emails. These should be the largest of your headings.
			* @style heading 1
			*/
			h1{
				/*@editable*/ color:#202020 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:26px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 2
			* @tip Set the styling for all second-level headings in your emails.
			* @style heading 2
			*/
			h2{
				/*@editable*/ color:#404040 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 3
			* @tip Set the styling for all third-level headings in your emails.
			* @style heading 3
			*/
			h3{
				/*@editable*/ color:#606060 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 4
			* @tip Set the styling for all fourth-level headings in your emails. These should be the smallest of your headings.
			* @style heading 4
			*/
			h4{
				/*@editable*/ color:#808080 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/* ========== Header Styles ========== */

			/**
			* @tab Header
			* @section preheader style
			* @tip Set the background color and bottom border for your emails preheader area.
			* @theme header
			*/
			#templatePreheader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section preheader text
			* @tip Set the styling for your emails preheader text. Choose a size and color that is easy to read.
			*/
			.preheaderContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:125%;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Header
			* @section preheader link
			* @tip Set the styling for your emails preheader links. Choose a color that helps them stand out from your text.
			*/
			.preheaderContent a:link, .preheaderContent a:visited, /* Yahoo! Mail Override */ .preheaderContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Header
			* @section header style
			* @tip Set the background color and borders for your emails header area.
			* @theme header
			*/
			#templateHeader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section header text
			* @tip Set the styling for your emails header text. Choose a size and color that is easy to read.
			*/
			.headerContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ padding-top:0;
				/*@editable*/ padding-right:0;
				/*@editable*/ padding-bottom:0;
				/*@editable*/ padding-left:0;
				/*@editable*/ text-align:left;
				/*@editable*/ vertical-align:middle;
			}

			/**
			* @tab Header
			* @section header link
			* @tip Set the styling for your emails header links. Choose a color that helps them stand out from your text.
			*/
			.headerContent a:link, .headerContent a:visited, /* Yahoo! Mail Override */ .headerContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			#headerImage{
				height:auto;
				max-width:600px;
			}

			/* ========== Body Styles ========== */

			/**
			* @tab Body
			* @section body style
			* @tip Set the background color and borders for your emails body area.
			*/
			#templateBody{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Body
			* @section body text
			* @tip Set the styling for your emails main content text. Choose a size and color that is easy to read.
			* @theme main
			*/
			.bodyContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Body
			* @section body link
			* @tip Set the styling for your emails main content links. Choose a color that helps them stand out from your text.
			*/
			.bodyContent a:link, .bodyContent a:visited, /* Yahoo! Mail Override */ .bodyContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.bodyContent img{
				display:inline;
				height:auto;
				max-width:560px;
			}

			/* ========== Column Styles ========== */

			.templateColumnContainer{display:inline; width:260px;}

			/**
			* @tab Columns
			* @section column style
			* @tip Set the background color and borders for your emails column area.
			*/
			#templateColumns{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Columns
			* @section left column text
			* @tip Set the styling for your emails left column content text. Choose a size and color that is easy to read.
			*/
			.leftColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section left column link
			* @tip Set the styling for your emails left column content links. Choose a color that helps them stand out from your text.
			*/
			.leftColumnContent a:link, .leftColumnContent a:visited, /* Yahoo! Mail Override */ .leftColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Columns
			* @section right column text
			* @tip Set the styling for your emails right column content text. Choose a size and color that is easy to read.
			*/
			.rightColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section right column link
			* @tip Set the styling for your emails right column content links. Choose a color that helps them stand out from your text.
			*/
			.rightColumnContent a:link, .rightColumnContent a:visited, /* Yahoo! Mail Override */ .rightColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.leftColumnContent img, .rightColumnContent img{
				display:inline;
				height:auto;
				max-width:260px;
			}

			/* ========== Footer Styles ========== */

			/**
			* @tab Footer
			* @section footer style
			* @tip Set the background color and borders for your emails footer area.
			* @theme footer
			*/
			#templateFooter{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
			}

			/**
			* @tab Footer
			* @section footer text
			* @tip Set the styling for your emails footer text. Choose a size and color that is easy to read.
			* @theme footer
			*/
			.footerContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Footer
			* @section footer link
			* @tip Set the styling for your emails footer links. Choose a color that helps them stand out from your text.
			*/
			.footerContent a:link, .footerContent a:visited, /* Yahoo! Mail Override */ .footerContent a .yshortcuts, .footerContent a span /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/* /\/\/\/\/\/\/\/\/ MOBILE STYLES /\/\/\/\/\/\/\/\/ */

            @media only screen and (max-width: 480px){
				/* /\/\/\/\/\/\/ CLIENT-SPECIFIC MOBILE STYLES /\/\/\/\/\/\/ */
				body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:none !important;} /* Prevent Webkit platforms from changing default text sizes */
                body{width:100% !important; min-width:100% !important;} /* Prevent iOS Mail from adding padding to the body */

				/* /\/\/\/\/\/\/ MOBILE RESET STYLES /\/\/\/\/\/\/ */
				#bodyCell{padding:10px !important;}

				/* /\/\/\/\/\/\/ MOBILE TEMPLATE STYLES /\/\/\/\/\/\/ */

				/* ======== Page Styles ======== */

				/**
				* @tab Mobile Styles
				* @section template width
				* @tip Make the template fluid for portrait or landscape view adaptability. If a fluid layout doesnt work for you, set the width to 300px instead.
				*/
				#templateContainer{
					max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 1
				* @tip Make the first-level headings larger in size for better readability on small screens.
				*/
				h1{
					/*@editable*/ font-size:24px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 2
				* @tip Make the second-level headings larger in size for better readability on small screens.
				*/
				h2{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 3
				* @tip Make the third-level headings larger in size for better readability on small screens.
				*/
				h3{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 4
				* @tip Make the fourth-level headings larger in size for better readability on small screens.
				*/
				h4{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:100% !important;
				}

				/* ======== Header Styles ======== */

				#templatePreheader{display:none !important;} /* Hide the template preheader to save space */

				/**
				* @tab Mobile Styles
				* @section header image
				* @tip Make the main header image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#headerImage{
					height:auto !important;
					/*@editable*/ max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section header text
				* @tip Make the header content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.headerContent{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Body Styles ======== */

				/**
				* @tab Mobile Styles
				* @section body image
				* @tip Make the main body image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#bodyImage{
					height:auto !important;
					/*@editable*/ max-width:560px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section body text
				* @tip Make the body content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.bodyContent{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Column Styles ======== */

				.templateColumnContainer{display:block !important; width:100% !important;}

				/**
				* @tab Mobile Styles
				* @section column image
				* @tip Make the column image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				.columnImage{
					height:auto !important;
					/*@editable*/ max-width:260px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section left column text
				* @tip Make the left column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.leftColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/**
				* @tab Mobile Styles
				* @section right column text
				* @tip Make the right column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.rightColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Footer Styles ======== */

				/**
				* @tab Mobile Styles
				* @section footer text
				* @tip Make the body content text larger in size for better readability on small screens.
				*/
				.footerContent{
					/*@editable*/ font-size:14px !important;
					/*@editable*/ line-height:115% !important;
				}

				.footerContent a{display:block !important;} /* Place footer social and utility links on their own lines, for easier access */
			}
		</style>
		</head>
		<body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0">
        <center>
          <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
            <tr>
              <td align="center" valign="top" id="bodyCell"><!-- BEGIN TEMPLATE // -->
                
                <table border="0" cellpadding="0" cellspacing="0" id="templateContainer">
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN PREHEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templatePreheader">
                        <tr>
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">This is an automated message, if you think you have received this message in error please contact customer service. </td>
                          <!-- *|IFNOT:ARCHIVE_PAGE|* -->                          <!-- *|END:IF|* --> 
                        </tr>
                      </table>
                      
                      <!-- // END PREHEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN HEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                        <tr>
                          <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm.png" style="max-width:600px;" id="headerImage" /></td>
                        </tr>
                      </table>
                      
                      <!-- // END HEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN BODY // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                        <tr>
                          <td valign="top" class="bodyContent"><h1>Your VIP Application has been received. </h1>
                            <p><strong>Congratulations, you are on your way to become a VIP Certified Service Provider! </strong></p>
                          <p>Your application has been submitted for review and a VIP Representative will contacting you via email or phone soon. We look forward to working with you. After your application has been successfully processed you will receive further instructions on how to set up your VIP Online account access.</p>
                          <p>Regards,</p>
                          <p>VIP Customer Support</p></td>
                        </tr>
                      </table>
                      
                      <!-- // END BODY --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN COLUMNS // --> 
                      <!-- // END COLUMNS --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN FOOTER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateFooter">
                        <tr>
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.gif" alt="VIP is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Copyright &copy; 2013 VIP, All rights reserved �<a href="http://nmc.com/" target="_blank">National Motor Club of America</a>�Inc. </em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><a href="#">update subscription preferences</a>&nbsp; </td>
                        </tr>
                      </table>
                      
                      <!-- // END FOOTER --></td>
                  </tr>
                </table>
                
                <!-- // END TEMPLATE --></td>
            </tr>
          </table>
        </center>
</body>
</html>', 1, NULL, NULL, NULL, NULL)

INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('Vendor_SendRateSchedule', 'Rate Schedule Agreement for National Motor Club Vendor Network', 'Here is your proposed rate schedule.  Please review and send back a signed copy.', 1, NULL, NULL, NULL, NULL)

INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('Vendor_WelcomeToNetwork', 'Welcome to National Motor Club''s Vendor Network', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Welcome to the VIP Network</title>
		<style type="text/css">
			/* /\/\/\/\/\/\/\/\/ CLIENT-SPECIFIC STYLES /\/\/\/\/\/\/\/\/ */
			#outlook a{padding:0;} /* Force Outlook to provide a view in browser message */
			.ReadMsgBody{width:100%;} .ExternalClass{width:100%;} /* Force Hotmail to display emails at full width */
			.ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {line-height: 100%;} /* Force Hotmail to display normal line spacing */
			body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;} /* Prevent WebKit and Windows mobile changing default text sizes */
			table, td{mso-table-lspace:0pt; mso-table-rspace:0pt;} /* Remove spacing between tables in Outlook 2007 and up */
			img{-ms-interpolation-mode:bicubic;} /* Allow smoother rendering of resized image in Internet Explorer */

			/* /\/\/\/\/\/\/\/\/ RESET STYLES /\/\/\/\/\/\/\/\/ */
			body{margin:0; padding:0;}
			img{border:0; height:auto; line-height:100%; outline:none; text-decoration:none;}
			table{border-collapse:collapse !important;}
			body, #bodyTable, #bodyCell{height:100% !important; margin:0; padding:0; width:100% !important;}

			/* /\/\/\/\/\/\/\/\/ TEMPLATE STYLES /\/\/\/\/\/\/\/\/ */

			/* ========== Page Styles ========== */

			#bodyCell{padding:20px;}
			#templateContainer{width:600px;}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			body, #bodyTable{
				/*@editable*/ background-color:#DEE0E2;
			}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			#bodyCell{
				/*@editable*/ border-top:4px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section email border
			* @tip Set the border for your email.
			*/
			#templateContainer{
				/*@editable*/ border:1px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section heading 1
			* @tip Set the styling for all first-level headings in your emails. These should be the largest of your headings.
			* @style heading 1
			*/
			h1{
				/*@editable*/ color:#202020 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:26px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 2
			* @tip Set the styling for all second-level headings in your emails.
			* @style heading 2
			*/
			h2{
				/*@editable*/ color:#404040 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 3
			* @tip Set the styling for all third-level headings in your emails.
			* @style heading 3
			*/
			h3{
				/*@editable*/ color:#606060 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 4
			* @tip Set the styling for all fourth-level headings in your emails. These should be the smallest of your headings.
			* @style heading 4
			*/
			h4{
				/*@editable*/ color:#808080 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/* ========== Header Styles ========== */

			/**
			* @tab Header
			* @section preheader style
			* @tip Set the background color and bottom border for your emails preheader area.
			* @theme header
			*/
			#templatePreheader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section preheader text
			* @tip Set the styling for your emails preheader text. Choose a size and color that is easy to read.
			*/
			.preheaderContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:125%;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Header
			* @section preheader link
			* @tip Set the styling for your emails preheader links. Choose a color that helps them stand out from your text.
			*/
			.preheaderContent a:link, .preheaderContent a:visited, /* Yahoo! Mail Override */ .preheaderContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Header
			* @section header style
			* @tip Set the background color and borders for your emails header area.
			* @theme header
			*/
			#templateHeader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section header text
			* @tip Set the styling for your emails header text. Choose a size and color that is easy to read.
			*/
			.headerContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ padding-top:0;
				/*@editable*/ padding-right:0;
				/*@editable*/ padding-bottom:0;
				/*@editable*/ padding-left:0;
				/*@editable*/ text-align:left;
				/*@editable*/ vertical-align:middle;
			}

			/**
			* @tab Header
			* @section header link
			* @tip Set the styling for your emails header links. Choose a color that helps them stand out from your text.
			*/
			.headerContent a:link, .headerContent a:visited, /* Yahoo! Mail Override */ .headerContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			#headerImage{
				height:auto;
				max-width:600px;
			}

			/* ========== Body Styles ========== */

			/**
			* @tab Body
			* @section body style
			* @tip Set the background color and borders for your emails body area.
			*/
			#templateBody{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Body
			* @section body text
			* @tip Set the styling for your emails main content text. Choose a size and color that is easy to read.
			* @theme main
			*/
			.bodyContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Body
			* @section body link
			* @tip Set the styling for your emails main content links. Choose a color that helps them stand out from your text.
			*/
			.bodyContent a:link, .bodyContent a:visited, /* Yahoo! Mail Override */ .bodyContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.bodyContent img{
				display:inline;
				height:auto;
				max-width:560px;
			}

			/* ========== Column Styles ========== */

			.templateColumnContainer{display:inline; width:260px;}

			/**
			* @tab Columns
			* @section column style
			* @tip Set the background color and borders for your emails column area.
			*/
			#templateColumns{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Columns
			* @section left column text
			* @tip Set the styling for your emails left column content text. Choose a size and color that is easy to read.
			*/
			.leftColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section left column link
			* @tip Set the styling for your emails left column content links. Choose a color that helps them stand out from your text.
			*/
			.leftColumnContent a:link, .leftColumnContent a:visited, /* Yahoo! Mail Override */ .leftColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Columns
			* @section right column text
			* @tip Set the styling for your emails right column content text. Choose a size and color that is easy to read.
			*/
			.rightColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section right column link
			* @tip Set the styling for your emails right column content links. Choose a color that helps them stand out from your text.
			*/
			.rightColumnContent a:link, .rightColumnContent a:visited, /* Yahoo! Mail Override */ .rightColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.leftColumnContent img, .rightColumnContent img{
				display:inline;
				height:auto;
				max-width:260px;
			}

			/* ========== Footer Styles ========== */

			/**
			* @tab Footer
			* @section footer style
			* @tip Set the background color and borders for your emails footer area.
			* @theme footer
			*/
			#templateFooter{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
			}

			/**
			* @tab Footer
			* @section footer text
			* @tip Set the styling for your emails footer text. Choose a size and color that is easy to read.
			* @theme footer
			*/
			.footerContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Footer
			* @section footer link
			* @tip Set the styling for your emails footer links. Choose a color that helps them stand out from your text.
			*/
			.footerContent a:link, .footerContent a:visited, /* Yahoo! Mail Override */ .footerContent a .yshortcuts, .footerContent a span /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/* /\/\/\/\/\/\/\/\/ MOBILE STYLES /\/\/\/\/\/\/\/\/ */

            @media only screen and (max-width: 480px){
				/* /\/\/\/\/\/\/ CLIENT-SPECIFIC MOBILE STYLES /\/\/\/\/\/\/ */
				body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:none !important;} /* Prevent Webkit platforms from changing default text sizes */
                body{width:100% !important; min-width:100% !important;} /* Prevent iOS Mail from adding padding to the body */

				/* /\/\/\/\/\/\/ MOBILE RESET STYLES /\/\/\/\/\/\/ */
				#bodyCell{padding:10px !important;}

				/* /\/\/\/\/\/\/ MOBILE TEMPLATE STYLES /\/\/\/\/\/\/ */

				/* ======== Page Styles ======== */

				/**
				* @tab Mobile Styles
				* @section template width
				* @tip Make the template fluid for portrait or landscape view adaptability. If a fluid layout doesnt work for you, set the width to 300px instead.
				*/
				#templateContainer{
					max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 1
				* @tip Make the first-level headings larger in size for better readability on small screens.
				*/
				h1{
					/*@editable*/ font-size:24px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 2
				* @tip Make the second-level headings larger in size for better readability on small screens.
				*/
				h2{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 3
				* @tip Make the third-level headings larger in size for better readability on small screens.
				*/
				h3{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 4
				* @tip Make the fourth-level headings larger in size for better readability on small screens.
				*/
				h4{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:100% !important;
				}

				/* ======== Header Styles ======== */

				#templatePreheader{display:none !important;} /* Hide the template preheader to save space */

				/**
				* @tab Mobile Styles
				* @section header image
				* @tip Make the main header image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#headerImage{
					height:auto !important;
					/*@editable*/ max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section header text
				* @tip Make the header content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.headerContent{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Body Styles ======== */

				/**
				* @tab Mobile Styles
				* @section body image
				* @tip Make the main body image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#bodyImage{
					height:auto !important;
					/*@editable*/ max-width:560px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section body text
				* @tip Make the body content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.bodyContent{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Column Styles ======== */

				.templateColumnContainer{display:block !important; width:100% !important;}

				/**
				* @tab Mobile Styles
				* @section column image
				* @tip Make the column image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				.columnImage{
					height:auto !important;
					/*@editable*/ max-width:260px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section left column text
				* @tip Make the left column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.leftColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/**
				* @tab Mobile Styles
				* @section right column text
				* @tip Make the right column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.rightColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Footer Styles ======== */

				/**
				* @tab Mobile Styles
				* @section footer text
				* @tip Make the body content text larger in size for better readability on small screens.
				*/
				.footerContent{
					/*@editable*/ font-size:14px !important;
					/*@editable*/ line-height:115% !important;
				}

				.footerContent a{display:block !important;} /* Place footer social and utility links on their own lines, for easier access */
			}
		</style>
		</head>
		<body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0">
        <center>
          <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
            <tr>
              <td align="center" valign="top" id="bodyCell"><!-- BEGIN TEMPLATE // -->
                
                <table border="0" cellpadding="0" cellspacing="0" id="templateContainer">
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN PREHEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templatePreheader">
                        <tr>
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">This is an automated message, if you think you have received this message in error please contact customer service. </td>
                          <!-- *|IFNOT:ARCHIVE_PAGE|* -->                          <!-- *|END:IF|* --> 
                        </tr>
                      </table>
                      
                      <!-- // END PREHEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN HEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                        <tr>
                          <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm.png" style="max-width:600px;" id="headerImage" /></td>
                        </tr>
                      </table>
                      
                      <!-- // END HEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN BODY // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                        <tr>
                          <td valign="top" class="bodyContent"><h1>Welcome to the VIP Network</h1>
                            <h3>Get Paid Faster! Register your account and gain access full VIP access.</h3>
                          <p>You have made a smart descision to join the National Motor Club VIP Network. You now have access to thousands of members who need your services. By registering your account for online access you can get paid faster. [NEED COPY FOR THIS EMAIL]</p>
                          <p>You will need the following to register your account.</p>
                          <p>Vendor # [need this token] and your Federal Tax ID</p>
                          <p>Setup is quick and easy and you will gain instant access to all of the VIP features. So what are you waiting for? Register today!</p>
                          <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                            <tr>
                              <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/Verify" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click to Register your VIP Account</a></td>
                            </tr>
                          </table></td>
                        </tr>
                        <tr>
                          <td valign="top" class="bodyContent" ><p><strong>If you need anymore help please contact VIP Customer Service or call 800-863-6740. </strong></p>
                            <p>Regards,</p>
                            <p>VIP Customer Support</p></td>
                        </tr>
                       
                      </table>
                      
                      <!-- // END BODY --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN COLUMNS // --> 
                      <!-- // END COLUMNS --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN FOOTER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateFooter">
                        <tr>
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.gif" alt="VIP is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Copyright &copy; 2013 VIP, All rights reserved �<a href="http://nmc.com/" target="_blank">National Motor Club of America</a>�Inc. </em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><a href="#">update subscription preferences</a>&nbsp; </td>
                        </tr>
                      </table>
                      
                      <!-- // END FOOTER --></td>
                  </tr>
                </table>
                
                <!-- // END TEMPLATE --></td>
            </tr>
          </table>
        </center>
</body>
</html>', 1, NULL, NULL, NULL, NULL)

INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('VendorPortal_RegistrationConfirmation', 'Welcome to your new VIP Account', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>
Welcome to Your New VIP Account</title>
<style type="text/css">
/* /\/\/\/\/\/\/\/\/ CLIENT-SPECIFIC STYLES /\/\/\/\/\/\/\/\/ */
#outlook a {
	padding: 0;
} /* Force Outlook to provide a view in browser message */
.ReadMsgBody {
	width: 100%;
}
.ExternalClass {
	width: 100%;
} /* Force Hotmail to display emails at full width */
.ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {
	line-height: 100%;
} /* Force Hotmail to display normal line spacing */
body, table, td, p, a, li, blockquote {
	-webkit-text-size-adjust: 100%;
	-ms-text-size-adjust: 100%;
} /* Prevent WebKit and Windows mobile changing default text sizes */
table, td {
	mso-table-lspace: 0pt;
	mso-table-rspace: 0pt;
} /* Remove spacing between tables in Outlook 2007 and up */
img {
	-ms-interpolation-mode: bicubic;
} /* Allow smoother rendering of resized image in Internet Explorer */
/* /\/\/\/\/\/\/\/\/ RESET STYLES /\/\/\/\/\/\/\/\/ */
body {
	margin: 0;
	padding: 0;
}
img {
	border: 0;
	height: auto;
	line-height: 100%;
	outline: none;
	text-decoration: none;
}
table {
	border-collapse: collapse !important;
}
body, #bodyTable, #bodyCell {
	height: 100% !important;
	margin: 0;
	padding: 0;
	width: 100% !important;
}
/* /\/\/\/\/\/\/\/\/ TEMPLATE STYLES /\/\/\/\/\/\/\/\/ */

			/* ========== Page Styles ========== */

#bodyCell {
	padding: 20px;
}
#templateContainer {
	width: 600px;
}
/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
body, #bodyTable {
	/*@editable*/ background-color: #DEE0E2;
}
/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
#bodyCell {
	/*@editable*/ border-top: 4px solid #BBBBBB;
}
/**
			* @tab Page
			* @section email border
			* @tip Set the border for your email.
			*/
#templateContainer {
	/*@editable*/ border: 1px solid #BBBBBB;
}
/**
			* @tab Page
			* @section heading 1
			* @tip Set the styling for all first-level headings in your emails. These should be the largest of your headings.
			* @style heading 1
			*/
h1 {
	/*@editable*/ color: #202020 !important;
	display: block;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 26px;
	/*@editable*/ font-style: normal;
	/*@editable*/ font-weight: bold;
	/*@editable*/ line-height: 100%;
	/*@editable*/ letter-spacing: normal;
	margin-top: 0;
	margin-right: 0;
	margin-bottom: 10px;
	margin-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Page
			* @section heading 2
			* @tip Set the styling for all second-level headings in your emails.
			* @style heading 2
			*/
h2 {
	/*@editable*/ color: #404040 !important;
	display: block;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 20px;
	/*@editable*/ font-style: normal;
	/*@editable*/ font-weight: bold;
	/*@editable*/ line-height: 100%;
	/*@editable*/ letter-spacing: normal;
	margin-top: 0;
	margin-right: 0;
	margin-bottom: 10px;
	margin-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Page
			* @section heading 3
			* @tip Set the styling for all third-level headings in your emails.
			* @style heading 3
			*/
h3 {
	/*@editable*/ color: #606060 !important;
	display: block;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 16px;
	/*@editable*/ font-style: italic;
	/*@editable*/ font-weight: normal;
	/*@editable*/ line-height: 100%;
	/*@editable*/ letter-spacing: normal;
	margin-top: 0;
	margin-right: 0;
	margin-bottom: 10px;
	margin-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Page
			* @section heading 4
			* @tip Set the styling for all fourth-level headings in your emails. These should be the smallest of your headings.
			* @style heading 4
			*/
h4 {
	/*@editable*/ color: #808080 !important;
	display: block;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 14px;
	/*@editable*/ font-style: italic;
	/*@editable*/ font-weight: normal;
	/*@editable*/ line-height: 100%;
	/*@editable*/ letter-spacing: normal;
	margin-top: 0;
	margin-right: 0;
	margin-bottom: 10px;
	margin-left: 0;
	/*@editable*/ text-align: left;
}
/* ========== Header Styles ========== */

			/**
			* @tab Header
			* @section preheader style
			* @tip Set the background color and bottom border for your emails preheader area.
			* @theme header
			*/
#templatePreheader {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-bottom: 1px solid #CCCCCC;
}
/**
			* @tab Header
			* @section preheader text
			* @tip Set the styling for your emails preheader text. Choose a size and color that is easy to read.
			*/
.preheaderContent {
	/*@editable*/ color: #808080;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 10px;
	/*@editable*/ line-height: 125%;
	/*@editable*/ text-align: left;
}
/**
			* @tab Header
			* @section preheader link
			* @tip Set the styling for your emails preheader links. Choose a color that helps them stand out from your text.
			*/
.preheaderContent a:link, .preheaderContent a:visited, /* Yahoo! Mail Override */ .preheaderContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #606060;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
/**
			* @tab Header
			* @section header style
			* @tip Set the background color and borders for your emails header area.
			* @theme header
			*/
#templateHeader {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-top: 1px solid #FFFFFF;
	/*@editable*/ border-bottom: 1px solid #CCCCCC;
}
/**
			* @tab Header
			* @section header text
			* @tip Set the styling for your emails header text. Choose a size and color that is easy to read.
			*/
.headerContent {
	/*@editable*/ color: #505050;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 20px;
	/*@editable*/ font-weight: bold;
	/*@editable*/ line-height: 100%;
	/*@editable*/ padding-top: 0;
	/*@editable*/ padding-right: 0;
	/*@editable*/ padding-bottom: 0;
	/*@editable*/ padding-left: 0;
	/*@editable*/ text-align: left;
	/*@editable*/ vertical-align: middle;
}
/**
			* @tab Header
			* @section header link
			* @tip Set the styling for your emails header links. Choose a color that helps them stand out from your text.
			*/
.headerContent a:link, .headerContent a:visited, /* Yahoo! Mail Override */ .headerContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #EB4102;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
#headerImage {
	height: auto;
	max-width: 600px;
}
/* ========== Body Styles ========== */

			/**
			* @tab Body
			* @section body style
			* @tip Set the background color and borders for your emails body area.
			*/
#templateBody {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-top: 1px solid #FFFFFF;
	/*@editable*/ border-bottom: 1px solid #CCCCCC;
}
/**
			* @tab Body
			* @section body text
			* @tip Set the styling for your emails main content text. Choose a size and color that is easy to read.
			* @theme main
			*/
.bodyContent {
	/*@editable*/ color: #505050;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 16px;
	/*@editable*/ line-height: 150%;
	padding-top: 20px;
	padding-right: 20px;
	padding-bottom: 20px;
	padding-left: 20px;
	/*@editable*/ text-align: left;
}
/**
			* @tab Body
			* @section body link
			* @tip Set the styling for your emails main content links. Choose a color that helps them stand out from your text.
			*/
.bodyContent a:link, .bodyContent a:visited, /* Yahoo! Mail Override */ .bodyContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #EB4102;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
.bodyContent img {
	display: inline;
	height: auto;
	max-width: 560px;
}
/* ========== Column Styles ========== */

.templateColumnContainer {
	display: inline;
	width: 260px;
}
/**
			* @tab Columns
			* @section column style
			* @tip Set the background color and borders for your emails column area.
			*/
#templateColumns {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-top: 1px solid #FFFFFF;
	/*@editable*/ border-bottom: 1px solid #CCCCCC;
}
/**
			* @tab Columns
			* @section left column text
			* @tip Set the styling for your emails left column content text. Choose a size and color that is easy to read.
			*/
.leftColumnContent {
	/*@editable*/ color: #505050;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 14px;
	/*@editable*/ line-height: 150%;
	padding-top: 0;
	padding-right: 0;
	padding-bottom: 20px;
	padding-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Columns
			* @section left column link
			* @tip Set the styling for your emails left column content links. Choose a color that helps them stand out from your text.
			*/
.leftColumnContent a:link, .leftColumnContent a:visited, /* Yahoo! Mail Override */ .leftColumnContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #EB4102;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
/**
			* @tab Columns
			* @section right column text
			* @tip Set the styling for your emails right column content text. Choose a size and color that is easy to read.
			*/
.rightColumnContent {
	/*@editable*/ color: #505050;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 14px;
	/*@editable*/ line-height: 150%;
	padding-top: 0;
	padding-right: 0;
	padding-bottom: 20px;
	padding-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Columns
			* @section right column link
			* @tip Set the styling for your emails right column content links. Choose a color that helps them stand out from your text.
			*/
.rightColumnContent a:link, .rightColumnContent a:visited, /* Yahoo! Mail Override */ .rightColumnContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #EB4102;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
.leftColumnContent img, .rightColumnContent img {
	display: inline;
	height: auto;
	max-width: 260px;
}
/* ========== Footer Styles ========== */

			/**
			* @tab Footer
			* @section footer style
			* @tip Set the background color and borders for your emails footer area.
			* @theme footer
			*/
#templateFooter {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-top: 1px solid #FFFFFF;
}
/**
			* @tab Footer
			* @section footer text
			* @tip Set the styling for your emails footer text. Choose a size and color that is easy to read.
			* @theme footer
			*/
.footerContent {
	/*@editable*/ color: #808080;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 10px;
	/*@editable*/ line-height: 150%;
	padding-top: 20px;
	padding-right: 20px;
	padding-bottom: 20px;
	padding-left: 20px;
	/*@editable*/ text-align: left;
}
/**
			* @tab Footer
			* @section footer link
			* @tip Set the styling for your emails footer links. Choose a color that helps them stand out from your text.
			*/
.footerContent a:link, .footerContent a:visited, /* Yahoo! Mail Override */ .footerContent a .yshortcuts, .footerContent a span /* Yahoo! Mail Override */ {
	/*@editable*/ color: #606060;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}

/* /\/\/\/\/\/\/\/\/ MOBILE STYLES /\/\/\/\/\/\/\/\/ */

@media only screen and (max-width: 480px) {
/* /\/\/\/\/\/\/ CLIENT-SPECIFIC MOBILE STYLES /\/\/\/\/\/\/ */
body, table, td, p, a, li, blockquote {
	-webkit-text-size-adjust: none !important;
} /* Prevent Webkit platforms from changing default text sizes */
body {
	width: 100% !important;
	min-width: 100% !important;
} /* Prevent iOS Mail from adding padding to the body */
/* /\/\/\/\/\/\/ MOBILE RESET STYLES /\/\/\/\/\/\/ */
#bodyCell {
	padding: 10px !important;
}
/* /\/\/\/\/\/\/ MOBILE TEMPLATE STYLES /\/\/\/\/\/\/ */

				/* ======== Page Styles ======== */

				/**
				* @tab Mobile Styles
				* @section template width
				* @tip Make the template fluid for portrait or landscape view adaptability. If a fluid layout doesnt work for you, set the width to 300px instead.
				*/
#templateContainer {
	max-width: 600px !important;
	/*@editable*/ width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section heading 1
				* @tip Make the first-level headings larger in size for better readability on small screens.
				*/
h1 {
	/*@editable*/ font-size: 24px !important;
	/*@editable*/ line-height: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section heading 2
				* @tip Make the second-level headings larger in size for better readability on small screens.
				*/
h2 {
	/*@editable*/ font-size: 20px !important;
	/*@editable*/ line-height: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section heading 3
				* @tip Make the third-level headings larger in size for better readability on small screens.
				*/
h3 {
	/*@editable*/ font-size: 18px !important;
	/*@editable*/ line-height: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section heading 4
				* @tip Make the fourth-level headings larger in size for better readability on small screens.
				*/
h4 {
	/*@editable*/ font-size: 16px !important;
	/*@editable*/ line-height: 100% !important;
}
/* ======== Header Styles ======== */

#templatePreheader {
	display: none !important;
} /* Hide the template preheader to save space */
/**
				* @tab Mobile Styles
				* @section header image
				* @tip Make the main header image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
#headerImage {
	height: auto !important;
	/*@editable*/ max-width: 600px !important;
	/*@editable*/ width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section header text
				* @tip Make the header content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
.headerContent {
	/*@editable*/ font-size: 20px !important;
	/*@editable*/ line-height: 125% !important;
}
/* ======== Body Styles ======== */

				/**
				* @tab Mobile Styles
				* @section body image
				* @tip Make the main body image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
#bodyImage {
	height: auto !important;
	/*@editable*/ max-width: 560px !important;
	/*@editable*/ width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section body text
				* @tip Make the body content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
.bodyContent {
	/*@editable*/ font-size: 18px !important;
	/*@editable*/ line-height: 125% !important;
}
/* ======== Column Styles ======== */

.templateColumnContainer {
	display: block !important;
	width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section column image
				* @tip Make the column image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
.columnImage {
	height: auto !important;
	/*@editable*/ max-width: 260px !important;
	/*@editable*/ width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section left column text
				* @tip Make the left column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
.leftColumnContent {
	/*@editable*/ font-size: 16px !important;
	/*@editable*/ line-height: 125% !important;
}
/**
				* @tab Mobile Styles
				* @section right column text
				* @tip Make the right column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
.rightColumnContent {
	/*@editable*/ font-size: 16px !important;
	/*@editable*/ line-height: 125% !important;
}
/* ======== Footer Styles ======== */

				/**
				* @tab Mobile Styles
				* @section footer text
				* @tip Make the body content text larger in size for better readability on small screens.
				*/
.footerContent {
	/*@editable*/ font-size: 14px !important;
	/*@editable*/ line-height: 115% !important;
}
.footerContent a {
	display: block !important;
} /* Place footer social and utility links on their own lines, for easier access */
}
</style>
</head>
<body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0">
<center>
  <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
    <tr>
      <td align="center" valign="top" id="bodyCell"><!-- BEGIN TEMPLATE // -->
        
        <table border="0" cellpadding="0" cellspacing="0" id="templateContainer">
          <tr>
            <td align="center" valign="top"><!-- BEGIN PREHEADER // -->
              
              <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templatePreheader">
                <tr>
                  <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">This is an automated message, if you think you have received this message in error please contact customer service. </td>
                  <!-- *|IFNOT:ARCHIVE_PAGE|* --> <!-- *|END:IF|* --> 
                </tr>
              </table>
              
              <!-- // END PREHEADER --></td>
          </tr>
          <tr>
            <td align="center" valign="top"><!-- BEGIN HEADER // -->
              
              <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                <tr>
                  <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm.png" style="max-width:600px;" id="headerImage" /></td>
                </tr>
              </table>
              
              <!-- // END HEADER --></td>
          </tr>
          <tr>
            <td align="center" valign="top"><!-- BEGIN BODY // -->
              
              <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                <tr>
                  <td valign="top" class="bodyContent"><h1>Welcome to your new VIP Account</h1>
                    <h3>Let us show your around your new VIP Account</h3>
                    <p>Congratulations on your new VIP Account. Here are some highlights of what you will be able to do with your new VIP account. </p>
                    <ul>
                      <li>Submit invoices Online so you <em>get paid faster! </em></li>
                      <li>Setup ACH so you can save the hassle of dealing with paper checks.</li>
                      <li>If you are a Business Owner you can setup additional VIP accounts so your billing department or an assistant can access your account without seeing sensitive financial information (ACH Banking info). </li>
                      <li>Verify your services to help ensure accurate calls.</li>
                      <li>Renew contracts, setup multiple locations and more....<br />
                    <br />
                    </li>
                    </ul>
                    <h2>VIP Account Details</h2>
                    <p><strong>Username<br />
                    </strong> $user</p>
                    <p><strong>Account Representative<br />
                      </strong>${ContactFirstName} <br />
                      ${ContactLastName} <br />
                      ${Email} <br />
                      ${PhoneNumber} <br />
                    </p>
                    <br />
                    <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                      <tr>
                        <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/LogOn" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click here to Log In to your VIP Account</a></td>
                      </tr>
                    </table></td>
                </tr>
                <tr>
                  <td class="bodyContent" style="padding-top:0; padding-bottom:0;"><p><img src="http://gallery.mailchimp.com/27aac8a65e64c994c4416d6b8/images/body_placeholder_650px.png" style="max-width:560px;" id="bodyImage"  /></p>
                    <h4>VIP Dashboard Screenshot</h4></td>
                </tr>
                <tr>
                  <td align="center" valign="top"><!-- BEGIN COLUMNS // -->
                    
                    <table border="0" cellpadding="20" cellspacing="0" width="100%" id="templateColumns">
                      <tr>
                        <td align="left" valign="top" style="padding-bottom:0;"><table align="left" border="0" cellpadding="0" cellspacing="0" class="templateColumnContainer">
                            <tr>
                              <td class="leftColumnContent"><img src="http://gallery.mailchimp.com/27aac8a65e64c994c4416d6b8/images/header_placeholder_260px.png" style="max-width:260px;" class="columnImage" /></td>
                            </tr>
                            <tr>
                              <td valign="top" class="leftColumnContent" ><h3>Invoice Screenshot</h3>
                                <p>Entering invoices Online is easy and faster than ever before. </p>
                                <p>The new VIP system allows you to enter invoices and view invoice history. </p></td>
                            </tr>
                          </table>
                          <table align="right" border="0" cellpadding="0" cellspacing="0" class="templateColumnContainer">
                            <tr>
                              <td class="rightColumnContent"><img src="http://gallery.mailchimp.com/27aac8a65e64c994c4416d6b8/images/header_placeholder_260px.png" style="max-width:260px;" class="columnImage"  /></td>
                            </tr>
                            <tr>
                              <td valign="top" class="rightColumnContent" ><h3>Managing Services screenshot</h3>
                                <p>Have multiple locations? The new VIP has you covered. Easily setup multiple locations. </p>
                                <p>We have added Zip Code coverage for greater accuracy. Just list the Zip Codes each location services and the correct location will automatically show up in our ODIS Dispatch system. Better accuracy equals more dispatched calls to your business. </p></td>
                            </tr>
                          </table></td>
                      </tr>
                    </table>
                    
                    <!-- // END COLUMNS --></td>
                </tr>
                <tr>
                  <td valign="top" class="bodyContent" ><p><strong>For assistance please contact your VIP Vendor Representative , view the Online help located on your VIP Dashboard or call VIP Customer Service at (800) 863-6740. </strong></p>
                    <p>Regards,</p>
                    <p>VIP Customer Support</p></td>
                </tr>
              </table>
              
              <!-- // END BODY --></td>
          </tr>
          <tr>
            <td align="center" valign="top"><!-- BEGIN COLUMNS // --> 
              <!-- // END COLUMNS --></td>
          </tr>
          <tr>
            <td align="center" valign="top"><!-- BEGIN FOOTER // -->
              
              <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateFooter">
                <tr>
                  <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.gif" alt="VIP is a National Motor Club and Coach-Net Product" /></td>
                </tr>
                <tr>
                  <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                    <em>Copyright &copy; 2013 VIP, All rights reserved �<a href="http://nmc.com/" target="_blank">National Motor Club of America</a>�Inc. </em> <br />
                    <br />
                    <strong>Our mailing address is:</strong> <br />
                    130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                </tr>
                <tr>
                  <td valign="top" class="footerContent" style="padding-top:0;" ><a href="#">update subscription preferences</a>&nbsp; </td>
                </tr>
              </table>
              
              <!-- // END FOOTER --></td>
          </tr>
        </table>
        
        <!-- // END TEMPLATE --></td>
    </tr>
  </table>
</center>
</body>
</html>', 1, NULL, NULL, NULL, NULL)

     
INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('VendorPortal_TransitionRegistrationConfirmation', 'Welcome to your new VIP Account', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>
Welcome to Your New VIP Account</title>
<style type="text/css">
/* /\/\/\/\/\/\/\/\/ CLIENT-SPECIFIC STYLES /\/\/\/\/\/\/\/\/ */
#outlook a {
	padding: 0;
} /* Force Outlook to provide a view in browser message */
.ReadMsgBody {
	width: 100%;
}
.ExternalClass {
	width: 100%;
} /* Force Hotmail to display emails at full width */
.ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {
	line-height: 100%;
} /* Force Hotmail to display normal line spacing */
body, table, td, p, a, li, blockquote {
	-webkit-text-size-adjust: 100%;
	-ms-text-size-adjust: 100%;
} /* Prevent WebKit and Windows mobile changing default text sizes */
table, td {
	mso-table-lspace: 0pt;
	mso-table-rspace: 0pt;
} /* Remove spacing between tables in Outlook 2007 and up */
img {
	-ms-interpolation-mode: bicubic;
} /* Allow smoother rendering of resized image in Internet Explorer */
/* /\/\/\/\/\/\/\/\/ RESET STYLES /\/\/\/\/\/\/\/\/ */
body {
	margin: 0;
	padding: 0;
}
img {
	border: 0;
	height: auto;
	line-height: 100%;
	outline: none;
	text-decoration: none;
}
table {
	border-collapse: collapse !important;
}
body, #bodyTable, #bodyCell {
	height: 100% !important;
	margin: 0;
	padding: 0;
	width: 100% !important;
}
/* /\/\/\/\/\/\/\/\/ TEMPLATE STYLES /\/\/\/\/\/\/\/\/ */

			/* ========== Page Styles ========== */

#bodyCell {
	padding: 20px;
}
#templateContainer {
	width: 600px;
}
/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
body, #bodyTable {
	/*@editable*/ background-color: #DEE0E2;
}
/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
#bodyCell {
	/*@editable*/ border-top: 4px solid #BBBBBB;
}
/**
			* @tab Page
			* @section email border
			* @tip Set the border for your email.
			*/
#templateContainer {
	/*@editable*/ border: 1px solid #BBBBBB;
}
/**
			* @tab Page
			* @section heading 1
			* @tip Set the styling for all first-level headings in your emails. These should be the largest of your headings.
			* @style heading 1
			*/
h1 {
	/*@editable*/ color: #202020 !important;
	display: block;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 26px;
	/*@editable*/ font-style: normal;
	/*@editable*/ font-weight: bold;
	/*@editable*/ line-height: 100%;
	/*@editable*/ letter-spacing: normal;
	margin-top: 0;
	margin-right: 0;
	margin-bottom: 10px;
	margin-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Page
			* @section heading 2
			* @tip Set the styling for all second-level headings in your emails.
			* @style heading 2
			*/
h2 {
	/*@editable*/ color: #404040 !important;
	display: block;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 20px;
	/*@editable*/ font-style: normal;
	/*@editable*/ font-weight: bold;
	/*@editable*/ line-height: 100%;
	/*@editable*/ letter-spacing: normal;
	margin-top: 0;
	margin-right: 0;
	margin-bottom: 10px;
	margin-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Page
			* @section heading 3
			* @tip Set the styling for all third-level headings in your emails.
			* @style heading 3
			*/
h3 {
	/*@editable*/ color: #606060 !important;
	display: block;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 16px;
	/*@editable*/ font-style: italic;
	/*@editable*/ font-weight: normal;
	/*@editable*/ line-height: 100%;
	/*@editable*/ letter-spacing: normal;
	margin-top: 0;
	margin-right: 0;
	margin-bottom: 10px;
	margin-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Page
			* @section heading 4
			* @tip Set the styling for all fourth-level headings in your emails. These should be the smallest of your headings.
			* @style heading 4
			*/
h4 {
	/*@editable*/ color: #808080 !important;
	display: block;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 14px;
	/*@editable*/ font-style: italic;
	/*@editable*/ font-weight: normal;
	/*@editable*/ line-height: 100%;
	/*@editable*/ letter-spacing: normal;
	margin-top: 0;
	margin-right: 0;
	margin-bottom: 10px;
	margin-left: 0;
	/*@editable*/ text-align: left;
}
/* ========== Header Styles ========== */

			/**
			* @tab Header
			* @section preheader style
			* @tip Set the background color and bottom border for your emails preheader area.
			* @theme header
			*/
#templatePreheader {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-bottom: 1px solid #CCCCCC;
}
/**
			* @tab Header
			* @section preheader text
			* @tip Set the styling for your emails preheader text. Choose a size and color that is easy to read.
			*/
.preheaderContent {
	/*@editable*/ color: #808080;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 10px;
	/*@editable*/ line-height: 125%;
	/*@editable*/ text-align: left;
}
/**
			* @tab Header
			* @section preheader link
			* @tip Set the styling for your emails preheader links. Choose a color that helps them stand out from your text.
			*/
.preheaderContent a:link, .preheaderContent a:visited, /* Yahoo! Mail Override */ .preheaderContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #606060;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
/**
			* @tab Header
			* @section header style
			* @tip Set the background color and borders for your emails header area.
			* @theme header
			*/
#templateHeader {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-top: 1px solid #FFFFFF;
	/*@editable*/ border-bottom: 1px solid #CCCCCC;
}
/**
			* @tab Header
			* @section header text
			* @tip Set the styling for your emails header text. Choose a size and color that is easy to read.
			*/
.headerContent {
	/*@editable*/ color: #505050;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 20px;
	/*@editable*/ font-weight: bold;
	/*@editable*/ line-height: 100%;
	/*@editable*/ padding-top: 0;
	/*@editable*/ padding-right: 0;
	/*@editable*/ padding-bottom: 0;
	/*@editable*/ padding-left: 0;
	/*@editable*/ text-align: left;
	/*@editable*/ vertical-align: middle;
}
/**
			* @tab Header
			* @section header link
			* @tip Set the styling for your emails header links. Choose a color that helps them stand out from your text.
			*/
.headerContent a:link, .headerContent a:visited, /* Yahoo! Mail Override */ .headerContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #EB4102;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
#headerImage {
	height: auto;
	max-width: 600px;
}
/* ========== Body Styles ========== */

			/**
			* @tab Body
			* @section body style
			* @tip Set the background color and borders for your emails body area.
			*/
#templateBody {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-top: 1px solid #FFFFFF;
	/*@editable*/ border-bottom: 1px solid #CCCCCC;
}
/**
			* @tab Body
			* @section body text
			* @tip Set the styling for your emails main content text. Choose a size and color that is easy to read.
			* @theme main
			*/
.bodyContent {
	/*@editable*/ color: #505050;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 16px;
	/*@editable*/ line-height: 150%;
	padding-top: 20px;
	padding-right: 20px;
	padding-bottom: 20px;
	padding-left: 20px;
	/*@editable*/ text-align: left;
}
/**
			* @tab Body
			* @section body link
			* @tip Set the styling for your emails main content links. Choose a color that helps them stand out from your text.
			*/
.bodyContent a:link, .bodyContent a:visited, /* Yahoo! Mail Override */ .bodyContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #EB4102;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
.bodyContent img {
	display: inline;
	height: auto;
	max-width: 560px;
}
/* ========== Column Styles ========== */

.templateColumnContainer {
	display: inline;
	width: 260px;
}
/**
			* @tab Columns
			* @section column style
			* @tip Set the background color and borders for your emails column area.
			*/
#templateColumns {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-top: 1px solid #FFFFFF;
	/*@editable*/ border-bottom: 1px solid #CCCCCC;
}
/**
			* @tab Columns
			* @section left column text
			* @tip Set the styling for your emails left column content text. Choose a size and color that is easy to read.
			*/
.leftColumnContent {
	/*@editable*/ color: #505050;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 14px;
	/*@editable*/ line-height: 150%;
	padding-top: 0;
	padding-right: 0;
	padding-bottom: 20px;
	padding-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Columns
			* @section left column link
			* @tip Set the styling for your emails left column content links. Choose a color that helps them stand out from your text.
			*/
.leftColumnContent a:link, .leftColumnContent a:visited, /* Yahoo! Mail Override */ .leftColumnContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #EB4102;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
/**
			* @tab Columns
			* @section right column text
			* @tip Set the styling for your emails right column content text. Choose a size and color that is easy to read.
			*/
.rightColumnContent {
	/*@editable*/ color: #505050;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 14px;
	/*@editable*/ line-height: 150%;
	padding-top: 0;
	padding-right: 0;
	padding-bottom: 20px;
	padding-left: 0;
	/*@editable*/ text-align: left;
}
/**
			* @tab Columns
			* @section right column link
			* @tip Set the styling for your emails right column content links. Choose a color that helps them stand out from your text.
			*/
.rightColumnContent a:link, .rightColumnContent a:visited, /* Yahoo! Mail Override */ .rightColumnContent a .yshortcuts /* Yahoo! Mail Override */ {
	/*@editable*/ color: #EB4102;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}
.leftColumnContent img, .rightColumnContent img {
	display: inline;
	height: auto;
	max-width: 260px;
}
/* ========== Footer Styles ========== */

			/**
			* @tab Footer
			* @section footer style
			* @tip Set the background color and borders for your emails footer area.
			* @theme footer
			*/
#templateFooter {
	/*@editable*/ background-color: #F4F4F4;
	/*@editable*/ border-top: 1px solid #FFFFFF;
}
/**
			* @tab Footer
			* @section footer text
			* @tip Set the styling for your emails footer text. Choose a size and color that is easy to read.
			* @theme footer
			*/
.footerContent {
	/*@editable*/ color: #808080;
	/*@editable*/ font-family: Helvetica;
	/*@editable*/ font-size: 10px;
	/*@editable*/ line-height: 150%;
	padding-top: 20px;
	padding-right: 20px;
	padding-bottom: 20px;
	padding-left: 20px;
	/*@editable*/ text-align: left;
}
/**
			* @tab Footer
			* @section footer link
			* @tip Set the styling for your emails footer links. Choose a color that helps them stand out from your text.
			*/
.footerContent a:link, .footerContent a:visited, /* Yahoo! Mail Override */ .footerContent a .yshortcuts, .footerContent a span /* Yahoo! Mail Override */ {
	/*@editable*/ color: #606060;
	/*@editable*/ font-weight: normal;
	/*@editable*/ text-decoration: underline;
}

/* /\/\/\/\/\/\/\/\/ MOBILE STYLES /\/\/\/\/\/\/\/\/ */

@media only screen and (max-width: 480px) {
/* /\/\/\/\/\/\/ CLIENT-SPECIFIC MOBILE STYLES /\/\/\/\/\/\/ */
body, table, td, p, a, li, blockquote {
	-webkit-text-size-adjust: none !important;
} /* Prevent Webkit platforms from changing default text sizes */
body {
	width: 100% !important;
	min-width: 100% !important;
} /* Prevent iOS Mail from adding padding to the body */
/* /\/\/\/\/\/\/ MOBILE RESET STYLES /\/\/\/\/\/\/ */
#bodyCell {
	padding: 10px !important;
}
/* /\/\/\/\/\/\/ MOBILE TEMPLATE STYLES /\/\/\/\/\/\/ */

				/* ======== Page Styles ======== */

				/**
				* @tab Mobile Styles
				* @section template width
				* @tip Make the template fluid for portrait or landscape view adaptability. If a fluid layout doesnt work for you, set the width to 300px instead.
				*/
#templateContainer {
	max-width: 600px !important;
	/*@editable*/ width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section heading 1
				* @tip Make the first-level headings larger in size for better readability on small screens.
				*/
h1 {
	/*@editable*/ font-size: 24px !important;
	/*@editable*/ line-height: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section heading 2
				* @tip Make the second-level headings larger in size for better readability on small screens.
				*/
h2 {
	/*@editable*/ font-size: 20px !important;
	/*@editable*/ line-height: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section heading 3
				* @tip Make the third-level headings larger in size for better readability on small screens.
				*/
h3 {
	/*@editable*/ font-size: 18px !important;
	/*@editable*/ line-height: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section heading 4
				* @tip Make the fourth-level headings larger in size for better readability on small screens.
				*/
h4 {
	/*@editable*/ font-size: 16px !important;
	/*@editable*/ line-height: 100% !important;
}
/* ======== Header Styles ======== */

#templatePreheader {
	display: none !important;
} /* Hide the template preheader to save space */
/**
				* @tab Mobile Styles
				* @section header image
				* @tip Make the main header image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
#headerImage {
	height: auto !important;
	/*@editable*/ max-width: 600px !important;
	/*@editable*/ width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section header text
				* @tip Make the header content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
.headerContent {
	/*@editable*/ font-size: 20px !important;
	/*@editable*/ line-height: 125% !important;
}
/* ======== Body Styles ======== */

				/**
				* @tab Mobile Styles
				* @section body image
				* @tip Make the main body image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
#bodyImage {
	height: auto !important;
	/*@editable*/ max-width: 560px !important;
	/*@editable*/ width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section body text
				* @tip Make the body content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
.bodyContent {
	/*@editable*/ font-size: 18px !important;
	/*@editable*/ line-height: 125% !important;
}
/* ======== Column Styles ======== */

.templateColumnContainer {
	display: block !important;
	width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section column image
				* @tip Make the column image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
.columnImage {
	height: auto !important;
	/*@editable*/ max-width: 260px !important;
	/*@editable*/ width: 100% !important;
}
/**
				* @tab Mobile Styles
				* @section left column text
				* @tip Make the left column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
.leftColumnContent {
	/*@editable*/ font-size: 16px !important;
	/*@editable*/ line-height: 125% !important;
}
/**
				* @tab Mobile Styles
				* @section right column text
				* @tip Make the right column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
.rightColumnContent {
	/*@editable*/ font-size: 16px !important;
	/*@editable*/ line-height: 125% !important;
}
/* ======== Footer Styles ======== */

				/**
				* @tab Mobile Styles
				* @section footer text
				* @tip Make the body content text larger in size for better readability on small screens.
				*/
.footerContent {
	/*@editable*/ font-size: 14px !important;
	/*@editable*/ line-height: 115% !important;
}
.footerContent a {
	display: block !important;
} /* Place footer social and utility links on their own lines, for easier access */
}
</style>
</head>
<body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0">
<center>
  <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
    <tr>
      <td align="center" valign="top" id="bodyCell"><!-- BEGIN TEMPLATE // -->
        
        <table border="0" cellpadding="0" cellspacing="0" id="templateContainer">
          <tr>
            <td align="center" valign="top"><!-- BEGIN PREHEADER // -->
              
              <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templatePreheader">
                <tr>
                  <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">This is an automated message, if you think you have received this message in error please contact customer service. </td>
                  <!-- *|IFNOT:ARCHIVE_PAGE|* --> <!-- *|END:IF|* --> 
                </tr>
              </table>
              
              <!-- // END PREHEADER --></td>
          </tr>
          <tr>
            <td align="center" valign="top"><!-- BEGIN HEADER // -->
              
              <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                <tr>
                  <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm.png" style="max-width:600px;" id="headerImage" /></td>
                </tr>
              </table>
              
              <!-- // END HEADER --></td>
          </tr>
          <tr>
            <td align="center" valign="top"><!-- BEGIN BODY // -->
              
              <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                <tr>
                  <td valign="top" class="bodyContent"><h1>Welcome to your new VIP Account</h1>
                    <h3>Let us show your around your new VIP Account</h3>
                    <p>Congratulations on your new VIP Account. Here are some highlights of what you will be able to do with your new VIP account. </p>
                    <ul>
                      <li>Submit invoices Online so you <em>get paid faster! </em></li>
                      <li>Setup ACH so you can save the hassle of dealing with paper checks.</li>
                      <li>If you are a Business Owner you can setup additional VIP accounts so your billing department or an assistant can access your account without seeing sensitive financial information (ACH Banking info). </li>
                      <li>Verify your services to help ensure accurate calls.</li>
                      <li>Renew contracts, setup multiple locations and more....<br />
                    <br />
                    </li>
                    </ul>
                    <h2>VIP Account Details</h2>
                    <p><strong>Username<br />
                    </strong> $user</p>
                    <p><strong>Account Representative<br />
                      </strong>${ContactFirstName} <br />
                      ${ContactLastName} <br />
                      ${Email} <br />
                      ${PhoneNumber} <br />
                    </p>
                    <br />
                    <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                      <tr>
                        <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/ActivateVendor/?id=$activationToken" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click here to Log In to your VIP Account</a></td>
                      </tr>
                    </table></td>
                </tr>
                <tr>
                  <td class="bodyContent" style="padding-top:0; padding-bottom:0;"><p><img src="http://gallery.mailchimp.com/27aac8a65e64c994c4416d6b8/images/body_placeholder_650px.png" style="max-width:560px;" id="bodyImage"  /></p>
                    <h4>VIP Dashboard Screenshot</h4></td>
                </tr>
                <tr>
                  <td align="center" valign="top"><!-- BEGIN COLUMNS // -->
                    
                    <table border="0" cellpadding="20" cellspacing="0" width="100%" id="templateColumns">
                      <tr>
                        <td align="left" valign="top" style="padding-bottom:0;"><table align="left" border="0" cellpadding="0" cellspacing="0" class="templateColumnContainer">
                            <tr>
                              <td class="leftColumnContent"><img src="http://gallery.mailchimp.com/27aac8a65e64c994c4416d6b8/images/header_placeholder_260px.png" style="max-width:260px;" class="columnImage" /></td>
                            </tr>
                            <tr>
                              <td valign="top" class="leftColumnContent" ><h3>Invoice Screenshot</h3>
                                <p>Entering invoices Online is easy and faster than ever before. </p>
                                <p>The new VIP system allows you to enter invoices and view invoice history. </p></td>
                            </tr>
                          </table>
                          <table align="right" border="0" cellpadding="0" cellspacing="0" class="templateColumnContainer">
                            <tr>
                              <td class="rightColumnContent"><img src="http://gallery.mailchimp.com/27aac8a65e64c994c4416d6b8/images/header_placeholder_260px.png" style="max-width:260px;" class="columnImage"  /></td>
                            </tr>
                            <tr>
                              <td valign="top" class="rightColumnContent" ><h3>Managing Services screenshot</h3>
                                <p>Have multiple locations? The new VIP has you covered. Easily setup multiple locations. </p>
                                <p>We have added Zip Code coverage for greater accuracy. Just list the Zip Codes each location services and the correct location will automatically show up in our ODIS Dispatch system. Better accuracy equals more dispatched calls to your business. </p></td>
                            </tr>
                          </table></td>
                      </tr>
                    </table>
                    
                    <!-- // END COLUMNS --></td>
                </tr>
                <tr>
                  <td valign="top" class="bodyContent" ><p><strong>For assistance please contact your VIP Vendor Representative , view the Online help located on your VIP Dashboard or call VIP Customer Service at (800) 863-6740. </strong></p>
                    <p>Regards,</p>
                    <p>VIP Customer Support</p></td>
                </tr>
              </table>
              
              <!-- // END BODY --></td>
          </tr>
          <tr>
            <td align="center" valign="top"><!-- BEGIN COLUMNS // --> 
              <!-- // END COLUMNS --></td>
          </tr>
          <tr>
            <td align="center" valign="top"><!-- BEGIN FOOTER // -->
              
              <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateFooter">
                <tr>
                  <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.gif" alt="VIP is a National Motor Club and Coach-Net Product" /></td>
                </tr>
                <tr>
                  <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                    <em>Copyright &copy; 2013 VIP, All rights reserved �<a href="http://nmc.com/" target="_blank">National Motor Club of America</a>�Inc. </em> <br />
                    <br />
                    <strong>Our mailing address is:</strong> <br />
                    130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                </tr>
                <tr>
                  <td valign="top" class="footerContent" style="padding-top:0;" ><a href="#">update subscription preferences</a>&nbsp; </td>
                </tr>
              </table>
              
              <!-- // END FOOTER --></td>
          </tr>
        </table>
        
        <!-- // END TEMPLATE --></td>
    </tr>
  </table>
</center>
</body>
</html>', 1, NULL, NULL, NULL, NULL)
      

INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('VendorPortal_ChangePassword', 'Your VIP password has been updated', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Your VIP password has been updated. </title>
		<style type="text/css">
			/* /\/\/\/\/\/\/\/\/ CLIENT-SPECIFIC STYLES /\/\/\/\/\/\/\/\/ */
			#outlook a{padding:0;} /* Force Outlook to provide a view in browser message */
			.ReadMsgBody{width:100%;} .ExternalClass{width:100%;} /* Force Hotmail to display emails at full width */
			.ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {line-height: 100%;} /* Force Hotmail to display normal line spacing */
			body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;} /* Prevent WebKit and Windows mobile changing default text sizes */
			table, td{mso-table-lspace:0pt; mso-table-rspace:0pt;} /* Remove spacing between tables in Outlook 2007 and up */
			img{-ms-interpolation-mode:bicubic;} /* Allow smoother rendering of resized image in Internet Explorer */

			/* /\/\/\/\/\/\/\/\/ RESET STYLES /\/\/\/\/\/\/\/\/ */
			body{margin:0; padding:0;}
			img{border:0; height:auto; line-height:100%; outline:none; text-decoration:none;}
			table{border-collapse:collapse !important;}
			body, #bodyTable, #bodyCell{height:100% !important; margin:0; padding:0; width:100% !important;}

			/* /\/\/\/\/\/\/\/\/ TEMPLATE STYLES /\/\/\/\/\/\/\/\/ */

			/* ========== Page Styles ========== */

			#bodyCell{padding:20px;}
			#templateContainer{width:600px;}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			body, #bodyTable{
				/*@editable*/ background-color:#DEE0E2;
			}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			#bodyCell{
				/*@editable*/ border-top:4px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section email border
			* @tip Set the border for your email.
			*/
			#templateContainer{
				/*@editable*/ border:1px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section heading 1
			* @tip Set the styling for all first-level headings in your emails. These should be the largest of your headings.
			* @style heading 1
			*/
			h1{
				/*@editable*/ color:#202020 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:26px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 2
			* @tip Set the styling for all second-level headings in your emails.
			* @style heading 2
			*/
			h2{
				/*@editable*/ color:#404040 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 3
			* @tip Set the styling for all third-level headings in your emails.
			* @style heading 3
			*/
			h3{
				/*@editable*/ color:#606060 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 4
			* @tip Set the styling for all fourth-level headings in your emails. These should be the smallest of your headings.
			* @style heading 4
			*/
			h4{
				/*@editable*/ color:#808080 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/* ========== Header Styles ========== */

			/**
			* @tab Header
			* @section preheader style
			* @tip Set the background color and bottom border for your emails preheader area.
			* @theme header
			*/
			#templatePreheader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section preheader text
			* @tip Set the styling for your emails preheader text. Choose a size and color that is easy to read.
			*/
			.preheaderContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:125%;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Header
			* @section preheader link
			* @tip Set the styling for your emails preheader links. Choose a color that helps them stand out from your text.
			*/
			.preheaderContent a:link, .preheaderContent a:visited, /* Yahoo! Mail Override */ .preheaderContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Header
			* @section header style
			* @tip Set the background color and borders for your emails header area.
			* @theme header
			*/
			#templateHeader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section header text
			* @tip Set the styling for your emails header text. Choose a size and color that is easy to read.
			*/
			.headerContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ padding-top:0;
				/*@editable*/ padding-right:0;
				/*@editable*/ padding-bottom:0;
				/*@editable*/ padding-left:0;
				/*@editable*/ text-align:left;
				/*@editable*/ vertical-align:middle;
			}

			/**
			* @tab Header
			* @section header link
			* @tip Set the styling for your emails header links. Choose a color that helps them stand out from your text.
			*/
			.headerContent a:link, .headerContent a:visited, /* Yahoo! Mail Override */ .headerContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			#headerImage{
				height:auto;
				max-width:600px;
			}

			/* ========== Body Styles ========== */

			/**
			* @tab Body
			* @section body style
			* @tip Set the background color and borders for your emails body area.
			*/
			#templateBody{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Body
			* @section body text
			* @tip Set the styling for your emails main content text. Choose a size and color that is easy to read.
			* @theme main
			*/
			.bodyContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Body
			* @section body link
			* @tip Set the styling for your emails main content links. Choose a color that helps them stand out from your text.
			*/
			.bodyContent a:link, .bodyContent a:visited, /* Yahoo! Mail Override */ .bodyContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.bodyContent img{
				display:inline;
				height:auto;
				max-width:560px;
			}

			/* ========== Column Styles ========== */

			.templateColumnContainer{display:inline; width:260px;}

			/**
			* @tab Columns
			* @section column style
			* @tip Set the background color and borders for your emails column area.
			*/
			#templateColumns{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Columns
			* @section left column text
			* @tip Set the styling for your emails left column content text. Choose a size and color that is easy to read.
			*/
			.leftColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section left column link
			* @tip Set the styling for your emails left column content links. Choose a color that helps them stand out from your text.
			*/
			.leftColumnContent a:link, .leftColumnContent a:visited, /* Yahoo! Mail Override */ .leftColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Columns
			* @section right column text
			* @tip Set the styling for your emails right column content text. Choose a size and color that is easy to read.
			*/
			.rightColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section right column link
			* @tip Set the styling for your emails right column content links. Choose a color that helps them stand out from your text.
			*/
			.rightColumnContent a:link, .rightColumnContent a:visited, /* Yahoo! Mail Override */ .rightColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.leftColumnContent img, .rightColumnContent img{
				display:inline;
				height:auto;
				max-width:260px;
			}

			/* ========== Footer Styles ========== */

			/**
			* @tab Footer
			* @section footer style
			* @tip Set the background color and borders for your emails footer area.
			* @theme footer
			*/
			#templateFooter{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
			}

			/**
			* @tab Footer
			* @section footer text
			* @tip Set the styling for your emails footer text. Choose a size and color that is easy to read.
			* @theme footer
			*/
			.footerContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Footer
			* @section footer link
			* @tip Set the styling for your emails footer links. Choose a color that helps them stand out from your text.
			*/
			.footerContent a:link, .footerContent a:visited, /* Yahoo! Mail Override */ .footerContent a .yshortcuts, .footerContent a span /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/* /\/\/\/\/\/\/\/\/ MOBILE STYLES /\/\/\/\/\/\/\/\/ */

            @media only screen and (max-width: 480px){
				/* /\/\/\/\/\/\/ CLIENT-SPECIFIC MOBILE STYLES /\/\/\/\/\/\/ */
				body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:none !important;} /* Prevent Webkit platforms from changing default text sizes */
                body{width:100% !important; min-width:100% !important;} /* Prevent iOS Mail from adding padding to the body */

				/* /\/\/\/\/\/\/ MOBILE RESET STYLES /\/\/\/\/\/\/ */
				#bodyCell{padding:10px !important;}

				/* /\/\/\/\/\/\/ MOBILE TEMPLATE STYLES /\/\/\/\/\/\/ */

				/* ======== Page Styles ======== */

				/**
				* @tab Mobile Styles
				* @section template width
				* @tip Make the template fluid for portrait or landscape view adaptability. If a fluid layout doesnt work for you, set the width to 300px instead.
				*/
				#templateContainer{
					max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 1
				* @tip Make the first-level headings larger in size for better readability on small screens.
				*/
				h1{
					/*@editable*/ font-size:24px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 2
				* @tip Make the second-level headings larger in size for better readability on small screens.
				*/
				h2{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 3
				* @tip Make the third-level headings larger in size for better readability on small screens.
				*/
				h3{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 4
				* @tip Make the fourth-level headings larger in size for better readability on small screens.
				*/
				h4{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:100% !important;
				}

				/* ======== Header Styles ======== */

				#templatePreheader{display:none !important;} /* Hide the template preheader to save space */

				/**
				* @tab Mobile Styles
				* @section header image
				* @tip Make the main header image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#headerImage{
					height:auto !important;
					/*@editable*/ max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section header text
				* @tip Make the header content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.headerContent{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Body Styles ======== */

				/**
				* @tab Mobile Styles
				* @section body image
				* @tip Make the main body image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#bodyImage{
					height:auto !important;
					/*@editable*/ max-width:560px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section body text
				* @tip Make the body content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.bodyContent{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Column Styles ======== */

				.templateColumnContainer{display:block !important; width:100% !important;}

				/**
				* @tab Mobile Styles
				* @section column image
				* @tip Make the column image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				.columnImage{
					height:auto !important;
					/*@editable*/ max-width:260px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section left column text
				* @tip Make the left column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.leftColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/**
				* @tab Mobile Styles
				* @section right column text
				* @tip Make the right column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.rightColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Footer Styles ======== */

				/**
				* @tab Mobile Styles
				* @section footer text
				* @tip Make the body content text larger in size for better readability on small screens.
				*/
				.footerContent{
					/*@editable*/ font-size:14px !important;
					/*@editable*/ line-height:115% !important;
				}

				.footerContent a{display:block !important;} /* Place footer social and utility links on their own lines, for easier access */
			}
		</style>
		</head>
		<body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0">
        <center>
          <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
            <tr>
              <td align="center" valign="top" id="bodyCell"><!-- BEGIN TEMPLATE // -->
                
                <table border="0" cellpadding="0" cellspacing="0" id="templateContainer">
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN PREHEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templatePreheader">
                        <tr>
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">This is an automated message, if you think you have received this message in error please contact customer service. </td>
                          <!-- *|IFNOT:ARCHIVE_PAGE|* -->                          <!-- *|END:IF|* --> 
                        </tr>
                      </table>
                      
                      <!-- // END PREHEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN HEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                        <tr>
                          <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm.png" style="max-width:600px;" id="headerImage" /></td>
                        </tr>
                      </table>
                      
                      <!-- // END HEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN BODY // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                        <tr>
                          <td valign="top" class="bodyContent"><h1>Your VIP password has been updated. </h1>
                            <p><strong>The password for  for your VIP account has been updated.</strong> </p>
                          <p>If you have not requested the password change or believe this email is reaching you in error please contact VIP Customer Support at <strong>800-863-6740</strong>. Please be preprepared to verify your account information to request a password reset.                          </p>
                          <p>Regards,</p>
                          <p>VIP Customer Support</p></td>
                        </tr>
                      </table>
                      
                      <!-- // END BODY --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN COLUMNS // --> 
                      <!-- // END COLUMNS --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN FOOTER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateFooter">
                        <tr>
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.gif" alt="VIP is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Copyright &copy; 2013 VIP, All rights reserved �<a href="http://nmc.com/" target="_blank">National Motor Club of America</a>�Inc. </em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><a href="#">update subscription preferences</a>&nbsp; </td>
                        </tr>
                      </table>
                      
                      <!-- // END FOOTER --></td>
                  </tr>
                </table>
                
                <!-- // END TEMPLATE --></td>
            </tr>
          </table>
        </center>
</body>
</html>', 1, NULL, NULL, NULL, NULL)


INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('VendorPortal_ForgotPassword', 'Your VIP account password has been reset', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Your VIP account password has been reset</title>
		<style type="text/css">
			/* /\/\/\/\/\/\/\/\/ CLIENT-SPECIFIC STYLES /\/\/\/\/\/\/\/\/ */
			#outlook a{padding:0;} /* Force Outlook to provide a view in browser message */
			.ReadMsgBody{width:100%;} .ExternalClass{width:100%;} /* Force Hotmail to display emails at full width */
			.ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {line-height: 100%;} /* Force Hotmail to display normal line spacing */
			body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;} /* Prevent WebKit and Windows mobile changing default text sizes */
			table, td{mso-table-lspace:0pt; mso-table-rspace:0pt;} /* Remove spacing between tables in Outlook 2007 and up */
			img{-ms-interpolation-mode:bicubic;} /* Allow smoother rendering of resized image in Internet Explorer */

			/* /\/\/\/\/\/\/\/\/ RESET STYLES /\/\/\/\/\/\/\/\/ */
			body{margin:0; padding:0;}
			img{border:0; height:auto; line-height:100%; outline:none; text-decoration:none;}
			table{border-collapse:collapse !important;}
			body, #bodyTable, #bodyCell{height:100% !important; margin:0; padding:0; width:100% !important;}

			/* /\/\/\/\/\/\/\/\/ TEMPLATE STYLES /\/\/\/\/\/\/\/\/ */

			/* ========== Page Styles ========== */

			#bodyCell{padding:20px;}
			#templateContainer{width:600px;}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			body, #bodyTable{
				/*@editable*/ background-color:#DEE0E2;
			}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			#bodyCell{
				/*@editable*/ border-top:4px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section email border
			* @tip Set the border for your email.
			*/
			#templateContainer{
				/*@editable*/ border:1px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section heading 1
			* @tip Set the styling for all first-level headings in your emails. These should be the largest of your headings.
			* @style heading 1
			*/
			h1{
				/*@editable*/ color:#202020 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:26px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 2
			* @tip Set the styling for all second-level headings in your emails.
			* @style heading 2
			*/
			h2{
				/*@editable*/ color:#404040 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 3
			* @tip Set the styling for all third-level headings in your emails.
			* @style heading 3
			*/
			h3{
				/*@editable*/ color:#606060 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 4
			* @tip Set the styling for all fourth-level headings in your emails. These should be the smallest of your headings.
			* @style heading 4
			*/
			h4{
				/*@editable*/ color:#808080 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/* ========== Header Styles ========== */

			/**
			* @tab Header
			* @section preheader style
			* @tip Set the background color and bottom border for your emails preheader area.
			* @theme header
			*/
			#templatePreheader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section preheader text
			* @tip Set the styling for your emails preheader text. Choose a size and color that is easy to read.
			*/
			.preheaderContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:125%;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Header
			* @section preheader link
			* @tip Set the styling for your emails preheader links. Choose a color that helps them stand out from your text.
			*/
			.preheaderContent a:link, .preheaderContent a:visited, /* Yahoo! Mail Override */ .preheaderContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Header
			* @section header style
			* @tip Set the background color and borders for your emails header area.
			* @theme header
			*/
			#templateHeader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section header text
			* @tip Set the styling for your emails header text. Choose a size and color that is easy to read.
			*/
			.headerContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ padding-top:0;
				/*@editable*/ padding-right:0;
				/*@editable*/ padding-bottom:0;
				/*@editable*/ padding-left:0;
				/*@editable*/ text-align:left;
				/*@editable*/ vertical-align:middle;
			}

			/**
			* @tab Header
			* @section header link
			* @tip Set the styling for your emails header links. Choose a color that helps them stand out from your text.
			*/
			.headerContent a:link, .headerContent a:visited, /* Yahoo! Mail Override */ .headerContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			#headerImage{
				height:auto;
				max-width:600px;
			}

			/* ========== Body Styles ========== */

			/**
			* @tab Body
			* @section body style
			* @tip Set the background color and borders for your emails body area.
			*/
			#templateBody{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Body
			* @section body text
			* @tip Set the styling for your emails main content text. Choose a size and color that is easy to read.
			* @theme main
			*/
			.bodyContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Body
			* @section body link
			* @tip Set the styling for your emails main content links. Choose a color that helps them stand out from your text.
			*/
			.bodyContent a:link, .bodyContent a:visited, /* Yahoo! Mail Override */ .bodyContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.bodyContent img{
				display:inline;
				height:auto;
				max-width:560px;
			}

			/* ========== Column Styles ========== */

			.templateColumnContainer{display:inline; width:260px;}

			/**
			* @tab Columns
			* @section column style
			* @tip Set the background color and borders for your emails column area.
			*/
			#templateColumns{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Columns
			* @section left column text
			* @tip Set the styling for your emails left column content text. Choose a size and color that is easy to read.
			*/
			.leftColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section left column link
			* @tip Set the styling for your emails left column content links. Choose a color that helps them stand out from your text.
			*/
			.leftColumnContent a:link, .leftColumnContent a:visited, /* Yahoo! Mail Override */ .leftColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Columns
			* @section right column text
			* @tip Set the styling for your emails right column content text. Choose a size and color that is easy to read.
			*/
			.rightColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section right column link
			* @tip Set the styling for your emails right column content links. Choose a color that helps them stand out from your text.
			*/
			.rightColumnContent a:link, .rightColumnContent a:visited, /* Yahoo! Mail Override */ .rightColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.leftColumnContent img, .rightColumnContent img{
				display:inline;
				height:auto;
				max-width:260px;
			}

			/* ========== Footer Styles ========== */

			/**
			* @tab Footer
			* @section footer style
			* @tip Set the background color and borders for your emails footer area.
			* @theme footer
			*/
			#templateFooter{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
			}

			/**
			* @tab Footer
			* @section footer text
			* @tip Set the styling for your emails footer text. Choose a size and color that is easy to read.
			* @theme footer
			*/
			.footerContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Footer
			* @section footer link
			* @tip Set the styling for your emails footer links. Choose a color that helps them stand out from your text.
			*/
			.footerContent a:link, .footerContent a:visited, /* Yahoo! Mail Override */ .footerContent a .yshortcuts, .footerContent a span /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/* /\/\/\/\/\/\/\/\/ MOBILE STYLES /\/\/\/\/\/\/\/\/ */

            @media only screen and (max-width: 480px){
				/* /\/\/\/\/\/\/ CLIENT-SPECIFIC MOBILE STYLES /\/\/\/\/\/\/ */
				body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:none !important;} /* Prevent Webkit platforms from changing default text sizes */
                body{width:100% !important; min-width:100% !important;} /* Prevent iOS Mail from adding padding to the body */

				/* /\/\/\/\/\/\/ MOBILE RESET STYLES /\/\/\/\/\/\/ */
				#bodyCell{padding:10px !important;}

				/* /\/\/\/\/\/\/ MOBILE TEMPLATE STYLES /\/\/\/\/\/\/ */

				/* ======== Page Styles ======== */

				/**
				* @tab Mobile Styles
				* @section template width
				* @tip Make the template fluid for portrait or landscape view adaptability. If a fluid layout doesnt work for you, set the width to 300px instead.
				*/
				#templateContainer{
					max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 1
				* @tip Make the first-level headings larger in size for better readability on small screens.
				*/
				h1{
					/*@editable*/ font-size:24px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 2
				* @tip Make the second-level headings larger in size for better readability on small screens.
				*/
				h2{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 3
				* @tip Make the third-level headings larger in size for better readability on small screens.
				*/
				h3{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 4
				* @tip Make the fourth-level headings larger in size for better readability on small screens.
				*/
				h4{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:100% !important;
				}

				/* ======== Header Styles ======== */

				#templatePreheader{display:none !important;} /* Hide the template preheader to save space */

				/**
				* @tab Mobile Styles
				* @section header image
				* @tip Make the main header image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#headerImage{
					height:auto !important;
					/*@editable*/ max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section header text
				* @tip Make the header content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.headerContent{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Body Styles ======== */

				/**
				* @tab Mobile Styles
				* @section body image
				* @tip Make the main body image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#bodyImage{
					height:auto !important;
					/*@editable*/ max-width:560px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section body text
				* @tip Make the body content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.bodyContent{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Column Styles ======== */

				.templateColumnContainer{display:block !important; width:100% !important;}

				/**
				* @tab Mobile Styles
				* @section column image
				* @tip Make the column image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				.columnImage{
					height:auto !important;
					/*@editable*/ max-width:260px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section left column text
				* @tip Make the left column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.leftColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/**
				* @tab Mobile Styles
				* @section right column text
				* @tip Make the right column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.rightColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Footer Styles ======== */

				/**
				* @tab Mobile Styles
				* @section footer text
				* @tip Make the body content text larger in size for better readability on small screens.
				*/
				.footerContent{
					/*@editable*/ font-size:14px !important;
					/*@editable*/ line-height:115% !important;
				}

				.footerContent a{display:block !important;} /* Place footer social and utility links on their own lines, for easier access */
			}
		</style>
		</head>
		<body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0">
        <center>
          <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
            <tr>
              <td align="center" valign="top" id="bodyCell"><!-- BEGIN TEMPLATE // -->
                
                <table border="0" cellpadding="0" cellspacing="0" id="templateContainer">
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN PREHEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templatePreheader">
                        <tr>
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">This is an automated message, if you think you have received this message in error please contact customer service. </td>
                          <!-- *|IFNOT:ARCHIVE_PAGE|* -->                          <!-- *|END:IF|* --> 
                        </tr>
                      </table>
                      
                      <!-- // END PREHEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN HEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                        <tr>
                          <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm.png" style="max-width:600px;" id="headerImage" /></td>
                        </tr>
                      </table>
                      
                      <!-- // END HEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN BODY // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                        <tr>
                          <td valign="top" class="bodyContent"><h1>Your VIP account password has been reset</h1>
                            <h3>Forgot your password? No problem. </h3>
                          <p>The password for  for your VIP account has been reset. Please log in to the system with the temporary password: <strong>$password </strong></p>
                          <p>After you log in you will need to create your own password. Please keep your new password in a safe place. You will use your new password to access the VIP system.</p>
                          <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                            <tr>
                              <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/LogOn" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click to Log In to Complete Password Reset</a></td>
                            </tr>
                          </table></td>
                        </tr>
                        <tr>
                          <td valign="top" class="bodyContent" ><h2>Need help choosing a new password?</h2>
                            <h4>Helpful hints for a secure password.</h4>
                            <ul>
                              <li>Minimum of (7) letters, numbers and special characters. </li>
                              <li>The first letter of a phrase or song refrain. For example, if you wanted to use the famous Jackson 5 song &quot;I Want You Back&quot;, plus some memorable numbers and your base password might be &quot;IWUB687.&quot; Remembering the password is a matter of singing yourself the song.</li>
                              <li>Use your spouse''s initials and your anniversary, like &quot;TFB0602.&quot; This one guarantees you won''t forget an anniversary card, either.</li>
                              <li>For extra security, choose an easy to remember base, like your spouse''s initials, or the word &quot;cat&quot; and then shift your fingers up one row on the keyboard when you type it. In the case of &quot;cat,&quot; you''d get &quot;dq5.&quot;</li>
                            </ul>
                            <p><strong>If you need anymore help please contact VIP Customer Service or call 800-863-6740. </strong></p>
                            <p>Regards,</p>
                            <p>VIP Customer Support</p></td>
                        </tr>
                       
                      </table>
                      
                      <!-- // END BODY --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN COLUMNS // --> 
                      <!-- // END COLUMNS --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN FOOTER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateFooter">
                        <tr>
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.gif" alt="VIP is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Copyright &copy; 2013 VIP, All rights reserved �<a href="http://nmc.com/" target="_blank">National Motor Club of America</a>�Inc. </em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><a href="#">update subscription preferences</a>&nbsp; </td>
                        </tr>
                      </table>
                      
                      <!-- // END FOOTER --></td>
                  </tr>
                </table>
                
                <!-- // END TEMPLATE --></td>
            </tr>
          </table>
        </center>
</body>
</html>', 1, NULL, NULL, NULL, NULL)
           
           
INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('VendorPortal_RegistrationActivation', 'Complete Your VIP Account Registration', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Complete Your VIP Account Registration</title>
		<style type="text/css">
			/* /\/\/\/\/\/\/\/\/ CLIENT-SPECIFIC STYLES /\/\/\/\/\/\/\/\/ */
			#outlook a{padding:0;} /* Force Outlook to provide a view in browser message */
			.ReadMsgBody{width:100%;} .ExternalClass{width:100%;} /* Force Hotmail to display emails at full width */
			.ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {line-height: 100%;} /* Force Hotmail to display normal line spacing */
			body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;} /* Prevent WebKit and Windows mobile changing default text sizes */
			table, td{mso-table-lspace:0pt; mso-table-rspace:0pt;} /* Remove spacing between tables in Outlook 2007 and up */
			img{-ms-interpolation-mode:bicubic;} /* Allow smoother rendering of resized image in Internet Explorer */

			/* /\/\/\/\/\/\/\/\/ RESET STYLES /\/\/\/\/\/\/\/\/ */
			body{margin:0; padding:0;}
			img{border:0; height:auto; line-height:100%; outline:none; text-decoration:none;}
			table{border-collapse:collapse !important;}
			body, #bodyTable, #bodyCell{height:100% !important; margin:0; padding:0; width:100% !important;}

			/* /\/\/\/\/\/\/\/\/ TEMPLATE STYLES /\/\/\/\/\/\/\/\/ */

			/* ========== Page Styles ========== */

			#bodyCell{padding:20px;}
			#templateContainer{width:600px;}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			body, #bodyTable{
				/*@editable*/ background-color:#DEE0E2;
			}

			/**
			* @tab Page
			* @section background style
			* @tip Set the background color and top border for your email. You may want to choose colors that match your companys branding.
			* @theme page
			*/
			#bodyCell{
				/*@editable*/ border-top:4px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section email border
			* @tip Set the border for your email.
			*/
			#templateContainer{
				/*@editable*/ border:1px solid #BBBBBB;
			}

			/**
			* @tab Page
			* @section heading 1
			* @tip Set the styling for all first-level headings in your emails. These should be the largest of your headings.
			* @style heading 1
			*/
			h1{
				/*@editable*/ color:#202020 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:26px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 2
			* @tip Set the styling for all second-level headings in your emails.
			* @style heading 2
			*/
			h2{
				/*@editable*/ color:#404040 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-style:normal;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 3
			* @tip Set the styling for all third-level headings in your emails.
			* @style heading 3
			*/
			h3{
				/*@editable*/ color:#606060 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Page
			* @section heading 4
			* @tip Set the styling for all fourth-level headings in your emails. These should be the smallest of your headings.
			* @style heading 4
			*/
			h4{
				/*@editable*/ color:#808080 !important;
				display:block;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ font-style:italic;
				/*@editable*/ font-weight:normal;
				/*@editable*/ line-height:100%;
				/*@editable*/ letter-spacing:normal;
				margin-top:0;
				margin-right:0;
				margin-bottom:10px;
				margin-left:0;
				/*@editable*/ text-align:left;
			}

			/* ========== Header Styles ========== */

			/**
			* @tab Header
			* @section preheader style
			* @tip Set the background color and bottom border for your emails preheader area.
			* @theme header
			*/
			#templatePreheader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section preheader text
			* @tip Set the styling for your emails preheader text. Choose a size and color that is easy to read.
			*/
			.preheaderContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:125%;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Header
			* @section preheader link
			* @tip Set the styling for your emails preheader links. Choose a color that helps them stand out from your text.
			*/
			.preheaderContent a:link, .preheaderContent a:visited, /* Yahoo! Mail Override */ .preheaderContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Header
			* @section header style
			* @tip Set the background color and borders for your emails header area.
			* @theme header
			*/
			#templateHeader{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Header
			* @section header text
			* @tip Set the styling for your emails header text. Choose a size and color that is easy to read.
			*/
			.headerContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:20px;
				/*@editable*/ font-weight:bold;
				/*@editable*/ line-height:100%;
				/*@editable*/ padding-top:0;
				/*@editable*/ padding-right:0;
				/*@editable*/ padding-bottom:0;
				/*@editable*/ padding-left:0;
				/*@editable*/ text-align:left;
				/*@editable*/ vertical-align:middle;
			}

			/**
			* @tab Header
			* @section header link
			* @tip Set the styling for your emails header links. Choose a color that helps them stand out from your text.
			*/
			.headerContent a:link, .headerContent a:visited, /* Yahoo! Mail Override */ .headerContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			#headerImage{
				height:auto;
				max-width:600px;
			}

			/* ========== Body Styles ========== */

			/**
			* @tab Body
			* @section body style
			* @tip Set the background color and borders for your emails body area.
			*/
			#templateBody{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Body
			* @section body text
			* @tip Set the styling for your emails main content text. Choose a size and color that is easy to read.
			* @theme main
			*/
			.bodyContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:16px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Body
			* @section body link
			* @tip Set the styling for your emails main content links. Choose a color that helps them stand out from your text.
			*/
			.bodyContent a:link, .bodyContent a:visited, /* Yahoo! Mail Override */ .bodyContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.bodyContent img{
				display:inline;
				height:auto;
				max-width:560px;
			}

			/* ========== Column Styles ========== */

			.templateColumnContainer{display:inline; width:260px;}

			/**
			* @tab Columns
			* @section column style
			* @tip Set the background color and borders for your emails column area.
			*/
			#templateColumns{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
				/*@editable*/ border-bottom:1px solid #CCCCCC;
			}

			/**
			* @tab Columns
			* @section left column text
			* @tip Set the styling for your emails left column content text. Choose a size and color that is easy to read.
			*/
			.leftColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section left column link
			* @tip Set the styling for your emails left column content links. Choose a color that helps them stand out from your text.
			*/
			.leftColumnContent a:link, .leftColumnContent a:visited, /* Yahoo! Mail Override */ .leftColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/**
			* @tab Columns
			* @section right column text
			* @tip Set the styling for your emails right column content text. Choose a size and color that is easy to read.
			*/
			.rightColumnContent{
				/*@editable*/ color:#505050;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:14px;
				/*@editable*/ line-height:150%;
				padding-top:0;
				padding-right:0;
				padding-bottom:20px;
				padding-left:0;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Columns
			* @section right column link
			* @tip Set the styling for your emails right column content links. Choose a color that helps them stand out from your text.
			*/
			.rightColumnContent a:link, .rightColumnContent a:visited, /* Yahoo! Mail Override */ .rightColumnContent a .yshortcuts /* Yahoo! Mail Override */{
				/*@editable*/ color:#EB4102;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			.leftColumnContent img, .rightColumnContent img{
				display:inline;
				height:auto;
				max-width:260px;
			}

			/* ========== Footer Styles ========== */

			/**
			* @tab Footer
			* @section footer style
			* @tip Set the background color and borders for your emails footer area.
			* @theme footer
			*/
			#templateFooter{
				/*@editable*/ background-color:#F4F4F4;
				/*@editable*/ border-top:1px solid #FFFFFF;
			}

			/**
			* @tab Footer
			* @section footer text
			* @tip Set the styling for your emails footer text. Choose a size and color that is easy to read.
			* @theme footer
			*/
			.footerContent{
				/*@editable*/ color:#808080;
				/*@editable*/ font-family:Helvetica;
				/*@editable*/ font-size:10px;
				/*@editable*/ line-height:150%;
				padding-top:20px;
				padding-right:20px;
				padding-bottom:20px;
				padding-left:20px;
				/*@editable*/ text-align:left;
			}

			/**
			* @tab Footer
			* @section footer link
			* @tip Set the styling for your emails footer links. Choose a color that helps them stand out from your text.
			*/
			.footerContent a:link, .footerContent a:visited, /* Yahoo! Mail Override */ .footerContent a .yshortcuts, .footerContent a span /* Yahoo! Mail Override */{
				/*@editable*/ color:#606060;
				/*@editable*/ font-weight:normal;
				/*@editable*/ text-decoration:underline;
			}

			/* /\/\/\/\/\/\/\/\/ MOBILE STYLES /\/\/\/\/\/\/\/\/ */

            @media only screen and (max-width: 480px){
				/* /\/\/\/\/\/\/ CLIENT-SPECIFIC MOBILE STYLES /\/\/\/\/\/\/ */
				body, table, td, p, a, li, blockquote{-webkit-text-size-adjust:none !important;} /* Prevent Webkit platforms from changing default text sizes */
                body{width:100% !important; min-width:100% !important;} /* Prevent iOS Mail from adding padding to the body */

				/* /\/\/\/\/\/\/ MOBILE RESET STYLES /\/\/\/\/\/\/ */
				#bodyCell{padding:10px !important;}

				/* /\/\/\/\/\/\/ MOBILE TEMPLATE STYLES /\/\/\/\/\/\/ */

				/* ======== Page Styles ======== */

				/**
				* @tab Mobile Styles
				* @section template width
				* @tip Make the template fluid for portrait or landscape view adaptability. If a fluid layout doesnt work for you, set the width to 300px instead.
				*/
				#templateContainer{
					max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 1
				* @tip Make the first-level headings larger in size for better readability on small screens.
				*/
				h1{
					/*@editable*/ font-size:24px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 2
				* @tip Make the second-level headings larger in size for better readability on small screens.
				*/
				h2{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 3
				* @tip Make the third-level headings larger in size for better readability on small screens.
				*/
				h3{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section heading 4
				* @tip Make the fourth-level headings larger in size for better readability on small screens.
				*/
				h4{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:100% !important;
				}

				/* ======== Header Styles ======== */

				#templatePreheader{display:none !important;} /* Hide the template preheader to save space */

				/**
				* @tab Mobile Styles
				* @section header image
				* @tip Make the main header image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#headerImage{
					height:auto !important;
					/*@editable*/ max-width:600px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section header text
				* @tip Make the header content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.headerContent{
					/*@editable*/ font-size:20px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Body Styles ======== */

				/**
				* @tab Mobile Styles
				* @section body image
				* @tip Make the main body image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				#bodyImage{
					height:auto !important;
					/*@editable*/ max-width:560px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section body text
				* @tip Make the body content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.bodyContent{
					/*@editable*/ font-size:18px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Column Styles ======== */

				.templateColumnContainer{display:block !important; width:100% !important;}

				/**
				* @tab Mobile Styles
				* @section column image
				* @tip Make the column image fluid for portrait or landscape view adaptability, and set the images original width as the max-width. If a fluid setting doesnt work, set the image width to half its original size instead.
				*/
				.columnImage{
					height:auto !important;
					/*@editable*/ max-width:260px !important;
					/*@editable*/ width:100% !important;
				}

				/**
				* @tab Mobile Styles
				* @section left column text
				* @tip Make the left column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.leftColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/**
				* @tab Mobile Styles
				* @section right column text
				* @tip Make the right column content text larger in size for better readability on small screens. We recommend a font size of at least 16px.
				*/
				.rightColumnContent{
					/*@editable*/ font-size:16px !important;
					/*@editable*/ line-height:125% !important;
				}

				/* ======== Footer Styles ======== */

				/**
				* @tab Mobile Styles
				* @section footer text
				* @tip Make the body content text larger in size for better readability on small screens.
				*/
				.footerContent{
					/*@editable*/ font-size:14px !important;
					/*@editable*/ line-height:115% !important;
				}

				.footerContent a{display:block !important;} /* Place footer social and utility links on their own lines, for easier access */
			}
		</style>
		</head>
		<body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0">
        <center>
          <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
            <tr>
              <td align="center" valign="top" id="bodyCell"><!-- BEGIN TEMPLATE // -->
                
                <table border="0" cellpadding="0" cellspacing="0" id="templateContainer">
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN PREHEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templatePreheader">
                        <tr>
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">This is an automated message, if you think you have received this message in error please contact customer service. </td>
                          <!-- *|IFNOT:ARCHIVE_PAGE|* -->                          <!-- *|END:IF|* --> 
                        </tr>
                      </table>
                      
                      <!-- // END PREHEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN HEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                        <tr>
                          <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm.png" style="max-width:600px;" id="headerImage" /></td>
                        </tr>
                      </table>
                      
                      <!-- // END HEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN BODY // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                        <tr>
                          <td valign="top" class="bodyContent"><h1>Complete Your VIP Account Registration</h1>
                            <h3>Follow the instructions below to verify and activate your account. </h3>
                          <p>You are on your way to accessing your new VIP <strong></strong>account. Please click the link below to verify and activate your account. After you account is activated you will receive a confirmation email with your Username to keep for your records.                          </p>
                          <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                            <tr>
                              <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/ActivateVendor/$activationtoken" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click to Activate your VIP Account</a></td>
                            </tr>
                          </table></td>
                        </tr>
                        <tr>
                          <td valign="top" class="bodyContent" ><p><strong>If you need anymore help please contact VIP Customer Service or call 800-863-6740. </strong></p>
                            <p>Regards,</p>
                            <p>VIP Customer Support</p></td>
                        </tr>
                       
                      </table>
                      
                      <!-- // END BODY --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN COLUMNS // --> 
                      <!-- // END COLUMNS --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN FOOTER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateFooter">
                        <tr>
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.gif" alt="VIP is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Copyright &copy; 2013 VIP, All rights reserved �<a href="http://nmc.com/" target="_blank">National Motor Club of America</a>�Inc. </em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><a href="#">update subscription preferences</a>&nbsp; </td>
                        </tr>
                      </table>
                      
                      <!-- // END FOOTER --></td>
                  </tr>
                </table>
                
                <!-- // END TEMPLATE --></td>
            </tr>
          </table>
        </center>
</body>
</html>', 1, NULL, NULL, NULL, NULL)
           
           
INSERT INTO [Template]
           ([Name]
           ,[Subject]
           ,[Body]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ('VendorPortal_FeedbackConfirmation', 'Re: Your VIP Feedback', 'Thank you for your feedback. If your feedback requires a response someone will be contacting you.', 1, NULL, NULL, NULL, NULL)
           



UPDATE Member set SourceSystemID = (SELECT TOP 1 ID From SourceSystem WHERE Name = 'Backoffice')
WHERE SourceSystemID in(SELECT ID FROM SourceSystem WHERE Name in('VendorMaintenance','VendorManagement'))

UPDATE Membership set SourceSystemID = (SELECT TOP 1 ID From SourceSystem WHERE Name = 'Backoffice')
WHERE SourceSystemID in(SELECT ID FROM SourceSystem WHERE Name in('VendorMaintenance','VendorManagement'))

UPDATE Vendor set SourceSystemID = (SELECT TOP 1 ID From SourceSystem WHERE Name = 'Backoffice')
WHERE SourceSystemID in(SELECT ID FROM SourceSystem WHERE Name in('VendorMaintenance','VendorManagement'))

UPDATE VendorACH set SourceSystemID = (SELECT TOP 1 ID From SourceSystem WHERE Name = 'Backoffice')
WHERE SourceSystemID in(SELECT ID FROM SourceSystem WHERE Name in('VendorMaintenance','VendorManagement'))

UPDATE VendorInvoice set SourceSystemID = (SELECT TOP 1 ID From SourceSystem WHERE Name = 'Backoffice')
WHERE SourceSystemID in(SELECT ID FROM SourceSystem WHERE Name in('VendorMaintenance','VendorManagement'))

UPDATE Claim set SourceSystemID = (SELECT TOP 1 ID From SourceSystem WHERE Name = 'Backoffice')
WHERE SourceSystemID in(SELECT ID FROM SourceSystem WHERE Name in('VendorMaintenance','VendorManagement'))


UPDATE Contract set SourceSystemID = (SELECT TOP 1 ID From SourceSystem WHERE Name = 'Backoffice')
WHERE SourceSystemID in(SELECT ID FROM SourceSystem WHERE Name in('VendorMaintenance','VendorManagement'))

DELETE FROM SourceSystem WHERE Name IN ('VendorMaintenance','VendorManagement')