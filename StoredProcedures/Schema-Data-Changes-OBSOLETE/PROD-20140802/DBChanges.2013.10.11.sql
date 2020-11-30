--Message table related
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MessageType](
 [ID] [int] IDENTITY(1,1) NOT NULL,
 [Name] [nvarchar](50) NULL,
 [Description] [nvarchar](255) NULL,
 [Sequence] [int] NULL,
 [IsActive] [int] NULL,
 CONSTRAINT [PK_MessageType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

INSERT INTO [MessageType]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('News','News',1,1)
INSERT INTO [MessageType]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Tips','Tips',2,1)

INSERT INTO [MessageType]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Event','Event',3,1)
 
GO
/****** Object:  Table [dbo].[Message]    Script Date: 10/10/2013 23:32:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Message](
 [ID] [int] IDENTITY(1,1) NOT NULL,
 [MessageTypeID] [int] NULL,
 [MessageScope] [nvarchar](50) NULL,
 [Subject] [nvarchar](255) NULL,
 [MessageText] [nvarchar](max) NULL,
 [StartDate] [datetime] NULL,
 [EndDate] [datetime] NULL,
 [Sequence] [int] NULL,
 [IsActive] [bit] NULL,
 [CreateBy] [nvarchar](50) NULL,
 [CreateDate] [datetime] NULL,
 [ModifyBy] [nvarchar](50) NULL,
 [ModifyDate] [datetime] NULL,
CONSTRAINT [PK_Message] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[Message]  WITH CHECK ADD  CONSTRAINT [FK_Message_MessageType] FOREIGN KEY([MessageTypeID])
REFERENCES [dbo].[MessageType] ([ID])
GO

ALTER TABLE [dbo].[Message] CHECK CONSTRAINT [FK_Message_MessageType]
GO

DECLARE @MsgType INT = (SELECT ID FROM MessageType WHERE Name = 'News')
INSERT INTO [Message]
           ([MessageTypeID]
           ,[MessageScope]
           ,[Subject]
           ,[MessageText]
           ,[StartDate]
           ,[EndDate]
           ,[Sequence]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate]
           ,[ModifyBy]
           ,[ModifyDate])
     VALUES
           (@MsgType, 'VendorPortal', 'Welcome', 'Welcome to the new Coach-Net Vendor Portal.  Please take a minute to look around at all the new features!', '10/10/2013 00:00:00.000',NULL, 1, 1, NULL,NULL,NULL,NULL )
INSERT INTO [Message]
           ([MessageTypeID]
           ,[MessageScope]
           ,[Subject]
           ,[MessageText]
           ,[StartDate]
           ,[EndDate]
           ,[Sequence]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate]
           ,[ModifyBy]
           ,[ModifyDate])
     VALUES
           (@MsgType, 'VendorPortal', 'Path to Preferred', 'Checkout your status on becoming a preferred provider.  The steps are shown above and we indicate how your are doing.  Preferred provides receive priority when dispatching roadside services.', '10/10/2013 00:00:00.000',NULL, 1, 1, NULL,NULL,NULL,NULL )
GO

--App config vendor service office and fax numbers
DECLARE @AppConfigType int
SET @AppConfigType = (SELECT ID FROM ApplicationConfigurationType WHERE Name = 'System')
DECLARE @AppConfigCat int
SET @AppConfigType = (SELECT ID FROM ApplicationConfigurationCategory WHERE Name = 'Email')

IF NOT EXISTS(SELECT * FROM ApplicationConfiguration WHERE Name = 'VendorServicesPhoneNumber')
BEGIN  

INSERT INTO [ApplicationConfiguration]
([ApplicationConfigurationTypeID]
,[ApplicationConfigurationCategoryID]
,[ControlTypeID]
,[DataTypeID]
,[Name]
,[Value]
,[CreateDate]
,[CreateBy]
,[ModifyDate]
,[ModifyBy])
VALUES
(@AppConfigType, @AppConfigCat, NULL, NULL, 'VendorServicesPhoneNumber', '800-285-4977', NULL, NULL, NULL, NULL)

END

IF NOT EXISTS(SELECT * FROM ApplicationConfiguration WHERE Name = 'VendorServicesFaxNumber')
BEGIN  

INSERT INTO [ApplicationConfiguration]
([ApplicationConfigurationTypeID]
,[ApplicationConfigurationCategoryID]
,[ControlTypeID]
,[DataTypeID]
,[Name]
,[Value]
,[CreateDate]
,[CreateBy]
,[ModifyDate]
,[ModifyBy])
VALUES
(@AppConfigType, @AppConfigCat, NULL, NULL, 'VendorServicesFaxNumber', '800-331-1145', NULL, NULL, NULL, NULL)

END
GO

--Template related changes
update Template set Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Welcome to Coach-Net Vendor Network</title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
                          <!-- *|IFNOT:ARCHIVE_PAGE|* -->                          <!-- *|END:IF|* --> 
                        </tr>
                      </table>
                      
                      <!-- // END PREHEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN HEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                        <tr>
                          <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm-network.png" style="max-width:600px;" id="headerImage" /></td>
                        </tr>
                      </table>
                      
                      <!-- // END HEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN BODY // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                        <tr>
                          <td valign="top" class="bodyContent"><h1>Welcome to the Coach-Net Vendor  Network</h1>
                            <h3>Get Paid Faster! Register your account and gain access full Coach-Net Vendor Portal access.</h3>
                          <p>Dear ${UserFirst} ${UserLast}, </p>
                          <p>Welcome to the Coach-Net Vendor Network. You are now part of our network of over 20,000 service providers in North America who are working with Coach-Net to help take their business to the next level.</p>
                          <p>Your new Coach-Net Vendor Number: ${user}</p>
                          <p>As part of our network you have access to our 24/7/365 Coach-Net Network Vendor Portal. This website provides you with access to tools and information that make doing business with Coach-Net a breeze, with features like:</p>
                          <ul>
                            <li> View and update your account information</li>
                            <li>Submit invoices online to get paid faster</li>
                            <li>Sign up for Direct Deposit for your invoice payments </li>
                            <li>Easy access to your Coach-Net Vendor Representative</li>
                            <li>And so much more!</li>
                            </ul>
                          <p>Please register today! Go to vendor.coach-net.com. Click on Register and follow the instructions. You will need your Coach-Net Vendor Number provided in this letter and your Federal Tax ID.                          </p>
                          <p>Setup is quick and easy and you will gain instant access to all of the Coach-Net Vendor Portal features. So what are you waiting for? Register today!</p>
                          <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                            <tr>
                              <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Register/Index" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click to Register your Coach-Net Vendor Portal Account</a></td>
                            </tr>
                          </table></td>
                        </tr>
                        <tr>
                          <td valign="top" class="bodyContent" ><p><strong>If you need anymore help please do not hesitate to contact me for assistance. </strong></p>
                            <p>Regards,</p>
                            <p>${ContactFirstName} ${ContactLastName}<br />
                            ${RegionName}</p>
                            <p> <br />
                              ${Email} <br />
                              dir: ${PhoneNumber}<br />
                              ofc: ${Office}<br />
                              fax: ${fax}
                          </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Version: 1.0 Oct. 2013<br />
                          © 2013 National Motor Club-RV Inc. All rights reserved.</em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>'
WHERE Name = 'Vendor_WelcomeToNetwork'

update Template set Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Your application has been received. </title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message of interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
                          <!-- *|IFNOT:ARCHIVE_PAGE|* -->                          <!-- *|END:IF|* --> 
                        </tr>
                      </table>
                      
                      <!-- // END PREHEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN HEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                        <tr>
                          <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm-network.png" style="max-width:600px;" id="headerImage" /></td>
                        </tr>
                      </table>
                      
                      <!-- // END HEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN BODY // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                        <tr>
                          <td valign="top" class="bodyContent"><h1>Your Coach-Net Service Provider Application has been received. </h1>
                            <p>Dear ${UserFirst} ${UserLast}, </p>
                            <p>Thank you for your interest in becoming part of the Coach-Net Vendor Network. We are currently looking to develop relationships with quality Service Providers to better serve members seeking road service.  </p>
<p>Your application has been submitted for review and a Coach-Net Vendor Network Representative will contact you via email or phone soon. We look forward to working with you. </p>
<p>After your application has been successfully processed you will receive further instructions on how to set up your Coach-Net Vendor Portal account access.</p>
<p><strong><em>Some of the benefits that you will enjoy as one of our service providers.</em></strong></p>
<ul>
  <li>Our Dispatchers are well trained, professional and courteous, providing you with all the correct information necessary for the service event. </li>
  <li>Easy access to Regional Specialists ensure your needs are heard and addressed.  Specialists are just a phone call away, no need to go through an automated answering system to reach them. </li>
  <li>We accept your invoice – there are never any special forms to fill out, and no hassle!  *Invoices must be received by Coach-Net (or submitted online) within 90 days of date of service.</li>
  <li>Our quickest payment method allows you to get paid every week when you use online billing and direct deposit.</li>
</ul>
<p>&nbsp;</p>
<p><strong>If you need anymore help please do not hesitate to contact me for assistance. </strong></p>
<p>Regards,</p>
<p>${ContactFirstName} ${ContactLastName}<br />
  ${RegionName}</p>
<p> <br />
  ${Email} <br />
  dir: ${PhoneNumber}<br />
  ofc: ${Office}<br />
  fax: ${fax} </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                            Version: 1.0 Oct. 2013<br />
                            &copy; 2013 <a href="http://www.coach-net.com/" target="_blank">National Motor Club-RV Inc. All rights reserved.</a><br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>'
WHERE Name = 'VendorPortal_ApplicationConfirmation'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Your password has been updated. </title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
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
                          <td valign="top" class="bodyContent"><h1>Your Coach-Net Vendor Portal password has been updated. </h1>
                            <p><strong>The password for  for your Coach-Net Vendor Portal account has been updated.</strong> </p>
                          <p>If you have not requested the password change or believe this email is reaching you in error please contact Coach-Net Vendor Portal Customer Support.</p>
                          <p>Regards,</p>
                          <p>Coach-Net Vendor Portal<br />
                          ${Office} </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Version: 1.0 Oct. 2013<br />
                          © 2013 National Motor Club-RV Inc. All rights reserved.</em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>'
WHERE Name = 'VendorPortal_ChangePassword'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Re: Your Coach-Net Feedback</title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
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
                          <td valign="top" class="bodyContent"><h1>Feedback Title</h1>
                            <p>Feedback Message                          </p></td>
                        </tr>
                        <tr>
                          <td valign="top" class="bodyContent" ><p><strong>If you need anymore help please do not hesitate to contact me for assistance. </strong></p>
                            <p>Regards,</p>
                            <p>${ContactFirstName} ${ContactLastName}<br />
                              ${RegionName}</p>
                            <p> <br />
                              ${Email} <br />
                              dir: ${PhoneNumber}<br />
                              ofc: ${Office}<br />
                          fax: ${fax} </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Version: 1.0 Oct. 2013<br />
                          © 2013 National Motor Club-RV Inc. All rights reserved.</em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>'
WHERE Name = 'VendorPortal_FeedbackConfirmation'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Your account password has been reset.</title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
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
                          <td valign="top" class="bodyContent"><h1>Your Coach-Net Vendor Portal account password has been reset</h1>
                            <h3>Forgot your password? No problem. </h3>
                          <p>The password for  for your Coach-Net Vendor Portal account has been reset. Please log in to the system with the temporary password: <strong>${password}</strong></p>
                          <p>After you log in you will need to create your own password. Please keep your new password in a safe place. You will use your new password to access the Coach-Net Vendor Portal system.</p>
                          <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                            <tr>
                              <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/Login" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click to Log In to Complete Password Reset</a></td>
                            </tr>
                          </table></td>
                        </tr>
                        <tr>
                          <td valign="top" class="bodyContent" ><h2>Need help choosing a new password?</h2>
                            <h4>Helpful hints for a secure password.</h4>
                            <ul>
                              <li>Your password should be a minimum of (7) letters, numbers and special characters. </li>
                            </ul>
                            <p>Regards,</p>
                            <p>Coach-Net Vendor Portal<br />
                            ${Office} </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Version: 1.0 Oct. 2013<br />
                          © 2013 National Motor Club-RV Inc. All rights reserved.</em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>' 
WHERE Name='VendorPortal_ForgotPassword'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Complete Your Account Registration</title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
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
                          <td valign="top" class="bodyContent"><h1>Complete Your Coach-Net Vendor Portal Account Registration</h1>
                            <h3>Follow the instructions below to verify and activate your account. </h3>
                          <p>You are on your way to accessing your new Coach-Net Vendor Portal <strong></strong>account. Please click the link below to verify and activate your account. After you account is activated you will receive a confirmation email with your Username to keep for your records.                          </p>
                          <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                            <tr>
                              <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/ActivateVendor/${activationToken}" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click to Activate your Coach-Net Vendor Portal Account</a></td>
                            </tr>
                          </table></td>
                        </tr>
                        <tr>
                          <td valign="top" class="bodyContent" ><p><strong>If you need anymore help please do not hesitate to contact me for assistance. </strong></p>
                            <p>Regards,</p>
                            <p>${ContactFirstName} ${ContactLastName}<br />
                              ${RegionName}</p>
                            <p> <br />
                              ${Email} <br />
                              dir: ${PhoneNumber}<br />
                              ofc: ${Office}<br />
                          fax: ${fax} </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Version: 1.0 Oct. 2013<br />
                          © 2013 National Motor Club-RV Inc. All rights reserved.</em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>'
WHERE Name = 'VendorPortal_RegistrationActivation'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>
Welcome to your NEW Account!</title>
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
                  <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
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
                  <td valign="top" class="bodyContent"><h1>Welcome to your new Coach-Net Vendor Portal Account</h1>
                    <h3>Let us show your around your new Coach-Net Vendor Portal Account</h3>
                    <p>Congratulations on your new Coach-Net Vendor Portal Account. Here are some highlights of what you will be able to do with your new Coach-Net Vendor Portal account. </p>
                    <ul>
                      <li>Submit invoices Online so you <em>get paid faster! </em></li>
                      <li>Setup ACH so you can save the hassle of dealing with paper checks.</li>
                      <li>If you are a Business Owner you can setup additional Coach-Net Vendor Portal accounts so your billing department or an assistant can access your account without seeing sensitive financial information (ACH Banking info). </li>
                      <li>Verify your services to help ensure accurate calls.</li>
                      <li>Renew contracts, setup multiple locations and more....<br />
                    <br />
                    </li>
                    </ul>
                    <h2>Coach-Net Vendor Portal Account Details</h2>
                    <p><strong>Username<br />
                    </strong> $user</p>
                    <p><strong>Primary Contact Information<br />
                    </strong>${ContactFirstName} ${ContactLastName}<br />
${RegionName}<br />
${Email} <br />
dir: ${PhoneNumber}<br />
ofc: ${Office}<br />
fax: ${fax} <br />
                    </p>
                    <br />
                    <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                      <tr>
                        <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/Login" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click here to Log In to your Coach-Net Vendor Portal Account</a></td>
                      </tr>
                    </table></td>
                </tr>
                <tr>
                  <td align="center" valign="top"><!-- BEGIN COLUMNS // -->
                    
                    <!-- // END COLUMNS --></td>
                </tr>
                <tr>
                  <td valign="top" class="bodyContent" ><p><strong>If you need anymore help please do not hesitate to contact me for assistance. </strong></p>
                    <p>Regards,</p>
                  <p>${Office} </p></td>
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
                  <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                </tr>
                <tr>
                  <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                    <em>Version: 1.0 Oct. 2013<br />
                    © 2013 National Motor Club-RV Inc. All rights reserved.</em> <br />
                    <br />
                    <strong>Our mailing address is:</strong> <br />
                    130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>'
WHERE Name = 'VendorPortal_TransitionRegistrationConfirmation'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>
Welcome to your NEW Account!</title>
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
                  <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
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
                  <td valign="top" class="bodyContent"><h1>Welcome to your new Coach-Net Vendor Portal Account</h1>
                    <h3>Let us show your around your new Coach-Net Vendor Portal Account</h3>
                    <p>Congratulations on your new Coach-Net Vendor Portal Account. Here are some highlights of what you will be able to do with your new Coach-Net Vendor Portal account. </p>
                    <ul>
                      <li>Submit invoices Online so you <em>get paid faster! </em></li>
                      <li>Setup Direct Deposit so you can save the hassle of dealing with paper checks.</li>
                      <li>If you are a Business Owner you can setup additional Coach-Net Vendor Portal accounts so your billing department or an assistant can access your account without seeing sensitive financial information (Direct Deposit Banking info). </li>
                      <li>Verify your services to help ensure accurate calls.</li>
                      <li>Renew contracts, setup multiple locations and more....<br />
                    <br />
                    </li>
                    </ul>
                    <h2>Coach-Net Vendor Portal Account Details</h2>
                    <p><strong>Username<br />
                    </strong> $user</p>
                    <p><strong>Primary Contact Information<br />
                      </strong>${ContactFirstName} ${ContactLastName}<br />
${RegionName}<br />
${Email} <br />
                      dir: ${PhoneNumber}<br />
                      ofc: ${Office}<br />
                    fax: ${fax} </p>
                    <p><br />
                    </p>
                    <br />
                    <table border="0" align="center" cellpadding="0" cellspacing="0" class="emailButton" style="border-radius: 3px; background-color: #BF1E2C;">
                      <tr>
                        <td align="center" valign="middle" class="emailButtonContent" style="padding-top:15px; padding-right:30px; padding-bottom:15px; padding-left:30px;"><a href="$url/Account/Login" target="_blank" style="color:#FFFFFF; font-family:Helvetica, Arial, sans-serif; font-size:16px; font-weight:bold; text-decoration:none;">Click here to Log In to your Coach-Net Vendor Portal Account</a></td>
                      </tr>
                    </table></td>
                </tr>
                <tr>
                  <td align="center" valign="top"><!-- BEGIN COLUMNS // -->
                    
                    <!-- // END COLUMNS --></td>
                </tr>
                <tr>
                  <td valign="top" class="bodyContent" ><p><strong>If you need anymore help please do not hesitate to contact me for assistance. </strong></p>
                    <p>Regards,</p>
                  <p>${Office} </p></td>
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
                  <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                </tr>
                <tr>
                  <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                    <em>Version: 1.0 Oct. 2013<br />
                    © 2013 National Motor Club-RV Inc. All rights reserved.</em> <br />
                    <br />
                    <strong>Our mailing address is:</strong> <br />
                    130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>'
WHERE Name = 'VendorPortal_RegistrationConfirmation'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Direct Deposit has been stop </title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
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
                          <td valign="top" class="bodyContent"><h1>Direct Deposit has been stopped. </h1>
                            <p><strong>The Direct Deposit for your Coach-Net Vendor Portal account has been stopped. </strong></p>
                          <p>If you have not requested the  change or believe this email is reaching you in error please log in to your Coach-Net Vendor Portal account and click on the Direct Deposit icon to view your settings.</p>
                          <p>Regards,</p>
                          <p>Coach-Net Vendor Portal<br />
${Office} <br />
                          </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Version 1.0 Oct. 2013 <br />
                          Copyright &copy; 2013 National Motor Club-RV Inc, All rights reserved  <a href="http://nmc.com/" target="_blank">National Motor Club of America</a> Inc. </em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                        </tr>
                      </table>
                      
                      <!-- // END FOOTER --></td>
                  </tr>
                </table>
                
                <!-- // END TEMPLATE --></td>
            </tr>
          </table>
          jjjj
        47
        </center>
</body>
</html>'
WHERE Name = 'VendorPortal_ACH_Stopped'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Direct Deposit has been started</title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
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
                          <td valign="top" class="bodyContent"><h1>Direct Deposit has been started. </h1>
                            <p><strong>The Direct Deposit for your Coach-Net Vendor Portal account has been started. </strong></p>
                          <p>If you have not requested the  change or believe this email is reaching you in error please log in to your Coach-Net Vendor Portal account and click on the Direct Deposit icon to view your settings.</p>
                          <p>Regards,</p>
                          <p>Coach-Net Vendor Portal<br />
                            ${Office} </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>Version 1.0 Oct. 2013<br />
                          Copyright &copy; 2013 National Motor Club-RV Inc, All rights reserved  <a href="http://nmc.com/" target="_blank">National Motor Club of America</a> Inc. </em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
                        </tr>
                      </table>
                      
                      <!-- // END FOOTER --></td>
                  </tr>
                </table>
                
                <!-- // END TEMPLATE --></td>
            </tr>
          </table>
          jjjj
        47
        </center>
</body>
</html>'
WHERE Name = 'VendorPortal_ACH_Started'

UPDATE Template SET Body = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>Rate Schedule Agreement</title>
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
                          <td valign="top" class="preheaderContent" style="padding-top:10px; padding-right:20px; padding-bottom:10px; padding-left:20px;">You are receiving this message because of an interaction with the Coach-Net Vendor Portal. If you think you have received this message in error please contact customer service. </td>
                          <!-- *|IFNOT:ARCHIVE_PAGE|* -->                          <!-- *|END:IF|* --> 
                        </tr>
                      </table>
                      
                      <!-- // END PREHEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN HEADER // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateHeader">
                        <tr>
                          <td valign="top" class="headerContent"><img src="https://dl.dropboxusercontent.com/u/6761860/600xHeader_sm-network.png" style="max-width:600px;" id="headerImage" /></td>
                        </tr>
                      </table>
                      
                      <!-- // END HEADER --></td>
                  </tr>
                  <tr>
                    <td align="center" valign="top"><!-- BEGIN BODY // -->
                      
                      <table border="0" cellpadding="0" cellspacing="0" width="100%" id="templateBody">
                        <tr>
                          <td valign="top" class="bodyContent"><h1>Rate Schedule</h1>
                          <p>Dear ${UserFirst} ${UserLast}, </p>
                          <p>We have reviewed your application and you are steps away from joining a network of over 20,000 service providers in North America. We have researched your area and have a personalized Rate Schedule for the services you offer.</p>
                          <p>Review, sign and return the attached Rate Schedule and gain the benefits of becoming a contracted Service Provider. Contracted Service Providers filter to the top of search results for dispatch calls. What does that mean for you? More business and that means more money in your pocket. </p>
                          <p><strong>Mail</strong><br />
                          Coach-Net Vendor Network<br />
                          Attn: ${ContactFirstName} ${ContactLastName} <br />
                          130 E. John Carpenter Fwy<br />
                          Irving, TX 75062-2708</p>
                          <p><strong>Fax</strong><br />
                            ${fax}</p>
                          <p><strong>Email</strong><br />
                          ${Email} </p></td>
                        </tr>
                        <tr>
                          <td valign="top" class="bodyContent" ><p><strong>If you need anymore help please do not hesitate to contact me for assistance. </strong></p>
                            <p>Regards,</p>
                            <p>${ContactFirstName} ${ContactLastName}<br />
                              ${RegionName}</p>
                            <p> <br />
                              ${Email} <br />
                              dir: ${PhoneNumber}<br />
                              ofc: ${Office}<br />
                          fax: ${fax} </p></td>
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
                          <td valign="top" class="headerContent" ><img src="https://dl.dropboxusercontent.com/u/6761860/600xFooter.png" alt="Coach-Net Vendor Portal is a National Motor Club and Coach-Net Product" /></td>
                        </tr>
                        <tr>
                          <td valign="top" class="footerContent" style="padding-top:0;" ><br />
                          <em>© 2013 National Motor Club-RV Inc. All rights reserved.</em> <br />
                            <br />
                            <strong>Our mailing address is:</strong> <br />
                            130 E John Carpenter Fwy, Irving, TX 75062-2708 </td>
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
</html>'
WHERE Name = 'Vendor_SendRateSchedule'