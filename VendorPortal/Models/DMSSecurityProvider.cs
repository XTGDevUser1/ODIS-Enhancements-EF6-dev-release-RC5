using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using log4net;
using Martex.DMS.DAL;
using System.Web.SessionState;
using VendorPortal.Common;
using Martex.DMS.DAL.DMSBaseException;

namespace VendorPortal.Models
{
    public static class DMSSecurityProvider
    {
        static ILog logger = LogManager.GetLogger(typeof(DMSSecurityProvider));

        public static AccessType GetAccessType(string friendlyName, string securityContext = null)
        {
            AccessType value = AccessType.Denied;
            if (AccessControlList != null)
            {
                List<AccessControlList_Result> list = AccessControlList;
                var result = list.Where(u => u.FriendlyName.Equals(friendlyName) && (string.IsNullOrEmpty(securityContext) || u.SecurityContext == securityContext)).FirstOrDefault();
                if (result != null)
                {
                    value = (AccessType)result.AccessTypeID.Value;
                }
            }

            return value;
        }

        private static HttpSessionState Session
        {
            get
            {
                return HttpContext.Current.Session;
            }
        }
        public static List<AccessControlList_Result> AccessControlList
        {
            get { return Session[StringConstants.SESSION_ACCESS_LIST] as List<AccessControlList_Result>; }
            set { Session[StringConstants.SESSION_ACCESS_LIST] = value; }
        }
    }

    public enum AccessType
    {
        Denied = 1,
        ReadOnly = 2,
        ReadWrite = 3
    }

    public static class DMSSecurityProviderFriendlyName
    {

        #region Top Level Menus

        public const string MENU_TOP_VENDOR_ADMIN = "MENU_TOP_VENDOR_ADMIN";
        public const string MENU_TOP_ISP = "MENU_TOP_ISP";

        #endregion

        #region Left Side Menus


        public const string MENU_LEFT_ISP_ACCOUNT = "MENU_LEFT_ISP_ACCOUNT";
        public const string MENU_LEFT_ISP_SUBMITINVOICE = "MENU_LEFT_ISP_SUBMITINVOICE";
        public const string MENU_LEFT_ISP_INVOICEHISTORY = "MENU_LEFT_ISP_INVOICEHISTORY";
        public const string MENU_LEFT_ISP_MYPROFILE = "MENU_LEFT_ISP_MYPROFILE";
        public const string MENU_LEFT_ISP_ACH = "MENU_LEFT_ISP_ACH";
        public const string MENU_LEFT_ISP_USERMAINTENANCE = "MENU_LEFT_ISP_USERMAINTENANCE";
        public const string MENU_LEFT_ISP_SERVICERATINGS = "MENU_LEFT_ISP_SERVICERATINGS";
        public const string MENU_LEFT_ISP_IMPERSONATE = "MENU_LEFT_ISP_IMPERSONATE";

        #region Tabs

        #endregion
        #endregion
    }
}