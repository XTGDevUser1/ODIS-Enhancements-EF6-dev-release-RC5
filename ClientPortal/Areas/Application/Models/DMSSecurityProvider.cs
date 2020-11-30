using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using log4net;
using Martex.DMS.DAL;
using System.Web.SessionState;
using ClientPortal.Common;
using Martex.DMS.DAL.DMSBaseException;

namespace ClientPortal.Areas.Application.Models
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
        public const string BUTTON_ADD_PAYMENT = "BUTTON_ADD_PAYMENT";
        public const string GRID_ACTION_USE_CARD = "GRID_ACTION_USE_CARD";
        public const string GRID_ACTION_CREDIT = "GRID_ACTION_CREDIT";
        public const string TEXT_DOLLAR_LIMIT = "TEXT_DOLLAR_LIMIT";


        #region Top Level Menus
        public const string MENU_TOP_DISPATCH = "MENU_TOP_DISPATCH";
        public const string MENU_TOP_VENDOR = "MENU_TOP_VENDOR";
        public const string MENU_TOP_CLIENT = "MENU_TOP_CLIENT";
        public const string MENU_TOP_QA = "MENU_TOP_QA";
        public const string MENU_TOP_ADMIN = "MENU_TOP_ADMIN";
        public const string MENU_TOP_REPORTS = "MENU_TOP_REPORTS";

        public const string MENU_SECOND_REPORTS_DEPARTMENT = "MENU_SECOND_REPORTS_DEPARTMENT";
        public const string MENU_SECOND_REPORTS_SYSTEM = "MENU_SECOND_REPORTS_SYSTEM";

        public const string MENU_THIRD_REPORTS_SYSTEM_TRANSACTION = "MENU_THIRD_REPORTS_SYSTEM_TRANSACTION";
        public const string MENU_THIRD_REPORTS_SYSTEM_EXPORT = "MENU_THIRD_REPORTS_SYSTEM_EXPORT";

        public const string MENU_THIRD_REPORTS_DEPARTMENT_VENDOR = "MENU_THIRD_REPORTS_DEPARTMENT_VENDOR";
        public const string MENU_THIRD_REPORTS_DEPARTMENT_CLIENT = "MENU_THIRD_REPORTS_DEPARTMENT_CLIENT";


        #endregion

        #region Left Side Menus

        public const string MENU_LEFT_DISPATCH_DASHBOARD = "MENU_LEFT_DISPATCH_DASHBOARD";
        public const string MENU_LEFT_DISPATCH_REQUEST = "MENU_LEFT_DISPATCH_REQUEST";
        public const string MENU_LEFT_DISPATCH_QUEUE = "MENU_LEFT_DISPATCH_QUEUE";
        public const string MENU_LEFT_DISPATCH_HISTORY = "MENU_LEFT_DISPATCH_HISTORY";

        public const string MENU_LEFT_VENDOR_DASHBOARD = "MENU_LEFT_VENDOR_DASHBOARD";
        public const string MENU_LEFT_VENDOR_VENDOR = "MENU_LEFT_VENDOR_VENDOR";
        public const string MENU_LEFT_VENDOR_INVOICES = "MENU_LEFT_VENDOR_INVOICES";
        public const string MENU_LEFT_VENDOR_MARKETANALYSIS = "MENU_LEFT_VENDOR_MARKETANALYSIS";
        public const string MENU_LEFT_VENDOR_TASKS = "MENU_LEFT_VENDOR_TASKS";


        public const string MENU_LEFT_CLIENT_DASHBOARD = "MENU_LEFT_CLIENT_DASHBOARD";
        public const string MENU_LEFT_CLIENT_CLIENT = "MENU_LEFT_CLIENT_CLIENT";
        public const string MENU_LEFT_CLIENT_BILLING = "MENU_LEFT_CLIENT_BILLING";
        public const string MENU_LEFT_CLIENT_INVOICEHISTORY = "MENU_LEFT_CLIENT_INVOICEHISTORY";
        public const string MENU_LEFT_CLIENT_CLAIMS = "MENU_LEFT_CLIENT_CLAIMS";
        public const string MENU_LEFT_CLIENT_MEMBERS = "MENU_LEFT_CLIENT_MEMBERS";
        public const string MENU_LEFT_CLIENT_TASKS = "MENU_LEFT_CLIENT_TASKS";


        public const string MENU_LEFT_QA_DASHBOARD = "MENU_LEFT_QA_DASHBOARD";
        public const string MENU_LEFT_QA_MEMBERS = "MENU_LEFT_QA_MEMBERS";
        public const string MENU_LEFT_QA_COMP = "MENU_LEFT_QA_COMP";
        public const string MENU_LEFT_QA_TASKS = "MENU_LEFT_QA_TASKS";


        public const string MENU_LEFT_REPORTS_SYSTEM_EXPORT_POEXPORT = "MENU_LEFT_REPORTS_SYSTEM_EXPORT_POEXPORT";
        public const string MENU_LEFT_REPORTS_SYSTEM_EXPORT_INVOICEEXPORT = "MENU_LEFT_REPORTS_SYSTEM_EXPORT_INVOICEEXPORT";
        public const string MENU_LEFT_REPORTS_SYSTEM_TRANSACTION_SRLIST = "MENU_LEFT_REPORTS_SYSTEM_TRANSACTION_SRLIST";
        public const string MENU_LEFT_REPORTS_SYSTEM_TRANSACTION_POLIST = "MENU_LEFT_REPORTS_SYSTEM_TRANSACTION_POLIST";
        public const string MENU_LEFT_REPORTS_DEPARTMENT_VENDOR_VENDORLIST = "MENU_LEFT_REPORTS_DEPARTMENT_VENDOR_VENDORLIST";
        public const string MENU_LEFT_REPORTS_DEPARTMENT_VENDOR_VENDORACTIVITY = "MENU_LEFT_REPORTS_DEPARTMENT_VENDOR_VENDORACTIVITY";


        #region Tabs
        //public const string TAB_DISPATCH_REQUEST_START = "TAB_DISPATCH_REQUEST_START";
        //public const string TAB_DISPATCH_REQUEST_EMERGENCY = "TAB_DISPATCH_REQUEST_EMERGENCY";
        //public const string TAB_DISPATCH_REQUEST_MEMBER = "TAB_DISPATCH_REQUEST_MEMBER";
        //public const string TAB_DISPATCH_REQUEST_VEHICLE = "TAB_DISPATCH_REQUEST_VEHICLE";
        //public const string TAB_DISPATCH_REQUEST_SERVICE = "TAB_DISPATCH_REQUEST_SERVICE";
        //public const string TAB_DISPATCH_REQUEST_MAP = "TAB_DISPATCH_REQUEST_MAP";
        //public const string TAB_DISPATCH_REQUEST_DISPATCH = "TAB_DISPATCH_REQUEST_DISPATCH";
        //public const string TAB_DISPATCH_REQUEST_PO = "TAB_DISPATCH_REQUEST_PO";
        //public const string TAB_DISPATCH_REQUEST_PAYMENT = "TAB_DISPATCH_REQUEST_PAYMENT";
        //public const string TAB_DISPATCH_REQUEST_ACTIVITY = "TAB_DISPATCH_REQUEST_ACTIVITY";
        //public const string TAB_DISPATCH_REQUEST_FINISH = "TAB_DISPATCH_REQUEST_FINISH";
        #endregion
        #endregion
    }
}