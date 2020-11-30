DECLARE @ParentID INT
SELECT  @ParentID = ID FROM Securable WHERE FriendlyName LIKE 'MENU_LEFT_VENDOR_DASHBOARD'

INSERT INTO Securable VALUES('VENDOR_DASHBOARD_PORTLET_TOP_VENDORS',@ParentID,NULL)
INSERT INTO Securable VALUES('VENDOR_DASHBOARD_PORTLET_VENDORS_ISSUES',@ParentID,NULL)
INSERT INTO Securable VALUES('VENDOR_DASHBOARD_PORTLET_NEXT_EVENTS',@ParentID,NULL)
INSERT INTO Securable VALUES('VENDOR_DASHBOARD_PORTLET_NEWS',@ParentID,NULL)
INSERT INTO Securable VALUES('VENDOR_DASHBOARD_PORTLET_RATINGS',@ParentID,NULL)
INSERT INTO Securable VALUES('VENDOR_DASHBOARD_PORTLET_FEEDBACK',@ParentID,NULL)


INSERT INTO PortletColumns VALUES('six-columns',1,1)
INSERT INTO PortletColumns VALUES('six-columns',1,2)

INSERT INTO PortletColumns VALUES('six-columns',2,1)
INSERT INTO PortletColumns VALUES('six-columns',2,2)

INSERT INTO PortletColumns VALUES('six-columns',3,1)
INSERT INTO PortletColumns VALUES('six-columns',3,2)

-- SELECT * FROM Portlet
DECLARE @ScreenID INT
SELECT  @ScreenID = ID FROM PortletScreen where Name = 'Vendor'
INSERT INTO Portlet VALUES(@ScreenID,(SELECT ID FROM Securable WHERE FriendlyName ='VENDOR_DASHBOARD_PORTLET_TOP_VENDORS'),'TOP_VENDORS','VendorDashboard','VendorManagement',0,0,'TopVendors','Top Vendors',0,1,NULL)
INSERT INTO Portlet VALUES(@ScreenID,(SELECT ID FROM Securable WHERE FriendlyName ='VENDOR_DASHBOARD_PORTLET_VENDORS_ISSUES'),'VENDORS_ISSUES','VendorDashboard','VendorManagement',1,0,'VendorIssues','Vendor Issues',0,1,NULL)

INSERT INTO Portlet VALUES(@ScreenID,(SELECT ID FROM Securable WHERE FriendlyName ='VENDOR_DASHBOARD_PORTLET_NEXT_EVENTS'),'NEXT_EVENTS','VendorDashboard','VendorManagement',0,0,'Events','Events',0,2,NULL)
INSERT INTO Portlet VALUES(@ScreenID,(SELECT ID FROM Securable WHERE FriendlyName ='VENDOR_DASHBOARD_PORTLET_NEWS'),'NEWS','VendorDashboard','VendorManagement',1,0,'News','News',0,2,NULL)

INSERT INTO Portlet VALUES(@ScreenID,(SELECT ID FROM Securable WHERE FriendlyName ='VENDOR_DASHBOARD_PORTLET_RATINGS'),'RATINGS','VendorDashboard','VendorManagement',0,0,'Ratings','Ratings',0,3,NULL)
INSERT INTO Portlet VALUES(@ScreenID,(SELECT ID FROM Securable WHERE FriendlyName ='VENDOR_DASHBOARD_PORTLET_FEEDBACK'),'FEEDBACK','VendorDashboard','VendorManagement',1,0,'Feedback','Feedback',0,3,NULL)

