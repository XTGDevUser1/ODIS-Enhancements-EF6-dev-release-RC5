using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using log4net;
using Martex.DMS.DAL;
using System.Web.SessionState;
using Martex.DMS.Common;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.Areas.Application.Models
{
    /// <summary>
    /// DMS Security Provider
    /// </summary>
    public static class DMSSecurityProvider
    {
        #region Static Members
        /// <summary>
        /// The logger
        /// </summary>
        static ILog logger = LogManager.GetLogger(typeof(DMSSecurityProvider));
        #endregion

        #region Public Members
        /// <summary>
        /// Gets the type of the access.
        /// </summary>
        /// <param name="friendlyName">Name of the friendly.</param>
        /// <param name="securityContext">The security context.</param>
        /// <returns></returns>
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

        /// <summary>
        /// Gets the session.
        /// </summary>
        /// <value>
        /// The session.
        /// </value>
        private static HttpSessionState Session
        {
            get
            {
                return HttpContext.Current.Session;
            }
        }

        /// <summary>
        /// Gets or sets the access control list.
        /// </summary>
        /// <value>
        /// The access control list.
        /// </value>
        public static List<AccessControlList_Result> AccessControlList
        {
            get { return Session[StringConstants.SESSION_ACCESS_LIST] as List<AccessControlList_Result>; }
            set { Session[StringConstants.SESSION_ACCESS_LIST] = value; }
        }
        #endregion
    }

    /// <summary>
    /// AccessType
    /// </summary>
    public enum AccessType
    {
        Denied = 1,
        ReadOnly = 2,
        ReadWrite = 3
    }

    /// <summary>
    /// DMS Security Provider Friendly Name
    /// </summary>
    public static class DMSSecurityProviderFriendlyName
    {
        public const string BUTTON_ADD_PAYMENT = "BUTTON_ADD_PAYMENT";
        public const string GRID_ACTION_USE_CARD = "GRID_ACTION_USE_CARD";
        public const string GRID_ACTION_CREDIT = "GRID_ACTION_CREDIT";
        public const string TEXT_DOLLAR_LIMIT = "TEXT_DOLLAR_LIMIT";

        public const string VENDOR_BUTTON_PAY_INVOICES = "VENDOR_BUTTON_PAY_INVOICES";
        public const string CLAIMS_ACES_GRID_ACTION_DELETE = "CLAIMS_ACES_GRID_ACTION_DELETE";
        public const string CLAIMS_ACES_BUTTON_ADDPAYMENT = "CLAIMS_ACES_BUTTON_ADDPAYMENT";
        public const string CLAIMS_BUTTON_TAGREADYFORPAYMENT = "CLAIMS_BUTTON_TAGREADYFORPAYMENT";
        public const string CLAIMS_BUTTON_PAY_CLAIMS = "CLAIMS_BUTTON_PAY_CLAIMS";
        public const string PO_BUTTON_REISSUECC = "PO_BUTTON_REISSUECC";
        public const string PO_BUTTON_EDIT_CCNUMBER = "BUTTON_EDIT_CCNUMBER";
        public const string BUTTON_POST_INVOICES = "BUTTON_POST_INVOICES";
        public const string CLIENT_BUTTON_CLOSEPERIOD = "CLIENT_BUTTON_CLOSEPERIOD";
        public const string CLIENT_BUTTON_OPENPERIOD = "CLIENT_BUTTON_OPENPERIOD";
        public const string PO_BUTTON_PO_SERVICECOVERED_EDIT = "BUTTON_PO_SERVICECOVERED_EDIT";

        public const string BUTTON_ADD_VENDOR = "BUTTON_ADD_VENDOR";
        public const string GRID_ACTION_VENDOR_SUMMARY = "GRID_ACTION_VENDOR_SUMMARY";
        public const string GRID_ACTION_VENDOR_EDIT = "GRID_ACTION_VENDOR_EDIT";
        public const string GRID_ACTION_VENDOR_MERGE = "GRID_ACTION_VENDOR_MERGE";
        public const string BUTTON_IMPORT_CCFILE = "BUTTON_IMPORT_CCFILE";
        public const string BUTTON_TEMPCC_MATCH = "BUTTON_TEMPCC_MATCH";
        public const string BUTTON_TEMPCC_POST = "BUTTON_TEMPCC_POST";

        public const string BUTTON_VENDOR_ACTIVITY_ADD_COMMENT = "BUTTON_VENDOR_ACTIVITY_ADD_COMMENT";
        public const string BUTTON_VENDOR_ACTIVITY_ADD_CONTACT = "BUTTON_VENDOR_ACTIVITY_ADD_CONTACT";
        public const string TEXT_PO_VENDOR_TAX_ID = "TEXT_PO_VENDOR_TAX_ID";

        public const string BUTTON_MEMBER_EDIT_EXPIRATION = "BUTTON_MEMBER_EDIT_EXPIRATION";
        public const string BUTTON_MEMBER_EDIT_NAME = "BUTTON_MEMBER_EDIT_NAME";
        public const string BUTTON_MEMBER_EDIT_PROGRAM = "BUTTON_MEMBER_EDIT_PROGRAM";

        public const string BUTTON_ADD_CX_CUSTOMERFEEDBACK = "BUTTON_ADD_CX_CUSTOMERFEEDBACK";
        public const string GRID_ACTION_CX_CUSTOMERFEEDBACK_SUMMARY = "GRID_ACTION_CX_CUSTOMERFEEDBACK_SUMMARY";
        public const string GRID_ACTION_CX_CUSTOMERFEEDBACK_EDIT = "GRID_ACTION_CX_CUSTOMERFEEDBACK_EDIT";
        public const string GRID_ACTION_CX_CUSTOMERFEEDBACK_MERGE = "GRID_ACTION_CX_CUSTOMERFEEDBACK_MERGE";
        public const string ALLOW_UNLOCK_AND_OPEN_CUSTOMER_FEEDBACK = "ALLOW_UNLOCK_AND_OPEN_CUSTOMER_FEEDBACK";

        #region Top Level Menus
        public const string MENU_TOP_DISPATCH = "MENU_TOP_DISPATCH";
        public const string MENU_TOP_VENDOR = "MENU_TOP_VENDOR";
        public const string MENU_TOP_CLIENT = "MENU_TOP_CLIENT";
        public const string MENU_TOP_CX = "MENU_TOP_CX";
        public const string MENU_TOP_ADMIN = "MENU_TOP_ADMIN";
        public const string MENU_TOP_REPORTS = "MENU_TOP_REPORTS";
        public const string MENU_TOP_CLAIMS = "MENU_TOP_CLAIMS";
        public const string MENU_TOP_MEMBER = "MENU_TOP_MEMBER";
        public const string MENU_TOP_DIGITAL_DISPATCH = "MENU_TOP_DIGITAL_DISPATCH";

        public const string MENU_SECOND_REPORTS_DEPARTMENT = "MENU_SECOND_REPORTS_DEPARTMENT";
        public const string MENU_SECOND_REPORTS_SYSTEM = "MENU_SECOND_REPORTS_SYSTEM";

        public const string MENU_THIRD_REPORTS_SYSTEM_TRANSACTION = "MENU_THIRD_REPORTS_SYSTEM_TRANSACTION";
        public const string MENU_THIRD_REPORTS_SYSTEM_EXPORT = "MENU_THIRD_REPORTS_SYSTEM_EXPORT";

        public const string MENU_THIRD_REPORTS_DEPARTMENT_VENDOR = "MENU_THIRD_REPORTS_DEPARTMENT_VENDOR";
        public const string MENU_THIRD_REPORTS_DEPARTMENT_CLIENT = "MENU_THIRD_REPORTS_DEPARTMENT_CLIENT";


        #endregion

        #region Left Side Menus

        public const string MENU_LEFT_DISPATCH_REQUEST = "MENU_LEFT_DISPATCH_REQUEST";
        public const string MENU_LEFT_DISPATCH_QUEUE = "MENU_LEFT_DISPATCH_QUEUE";
        public const string MENU_LEFT_DISPATCH_HISTORY = "MENU_LEFT_DISPATCH_HISTORY";
        public const string MENU_LEFT_DISPATCH_ADMIN = "MENU_LEFT_DISPATCH_ADMIN";


        public const string MENU_LEFT_VENDOR_VENDOR = "MENU_LEFT_VENDOR_VENDOR";
        public const string MENU_LEFT_VENDOR_INVOICES = "MENU_LEFT_VENDOR_INVOICES";
        public const string MENU_LEFT_VENDOR_MARKETANALYSIS = "MENU_LEFT_VENDOR_MARKETANALYSIS";
        public const string MENU_LEFT_VENDOR_TASKS = "MENU_LEFT_VENDOR_TASKS";
        public const string MENU_LEFT_VENDOR_MERGE = "MENU_LEFT_VENDOR_MERGE";
        public const string MENU_LEFT_VENDOR_PAYHISTORY = "MENU_LEFT_VENDOR_PAYHISTORY";

        public const string MENU_LEFT_TEMPORARY_CC_PROCESSING = "MENU_LEFT_TEMPORARY_CC_PROCESSING";
        public const string MENU_LEFT_TEMPORARY_CC_HISTORY = "MENU_LEFT_TEMPORARY_CC_HISTORY";
        public const string MENU_LEFT_VENDOR_LOCATION_GEOGRAPHY = "MENU_LEFT_VENDOR_LOCATION_GEOGRAPHY";

        public const string MENU_LEFT_MEMBER_MAINTENANCE = "MENU_LEFT_MEMBER_MAINTENANCE";
        public const string MENU_LEFT_MEMBER_MERGE = "MENU_LEFT_MEMBER_MERGE";

        public const string MENU_LEFT_CLAIMS_CLAIMS = "MENU_LEFT_CLAIMS_CLAIMS";
        public const string MENU_LEFT_CLAIMS_ACESPAYMENTS = "MENU_LEFT_CLAIMS_ACESPAYMENTS";
        public const string MENU_LEFT_CLAIMS_PAYHISTORY = "MENU_LEFT_CLAIMS_PAYHISTORY";

        public const string MENU_LEFT_CLIENT_CLIENT = "MENU_LEFT_CLIENT_CLIENT";
        public const string MENU_LEFT_CLIENT_BILLING = "MENU_LEFT_CLIENT_BILLING";
        public const string MENU_LEFT_BILLING_INVOICEHISTORY = "MENU_LEFT_BILLING_INVOICEHISTORY";
        public const string MENU_LEFT_CLIENT_INVOICEPROCESSING = "MENU_LEFT_CLIENT_INVOICEPROCESSING";
        public const string MENU_LEFT_CLIENT_INVOICEBATCHES = "MENU_LEFT_CLIENT_INVOICEBATCHES";
        public const string MENU_LEFT_BILLING_BILLINGHISTORY = "MENU_LEFT_BILLING_BILLINGHISTORY";
        public const string MENU_LEFT_CLIENT_CLIENTREP_MAINTENANCE = "MENU_LEFT_CLIENT_CLIENTREP_MAINTENANCE";



        public const string MENU_LEFT_ADMIN_MAINTENANCE = "MENU_LEFT_ADMIN_MAINTENANCE";
        public const string MENU_LEFT_ADMIN_PROGRAM_MANAGEMENT = "MENU_LEFT_ADMIN_PROGRAM_MANAGEMENT";
        public const string MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT = "MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT";
        // TO BE USED IN FUTURE.
        //public const string MENU_LEFT_CLIENT_CLAIMS = "MENU_LEFT_CLIENT_CLAIMS";
        //public const string MENU_LEFT_CLIENT_MEMBERS = "MENU_LEFT_CLIENT_MEMBERS";
        //public const string MENU_LEFT_CLIENT_TASKS = "MENU_LEFT_CLIENT_TASKS";


        public const string MENU_LEFT_CX_DASHBOARD = "MENU_LEFT_CX_DASHBOARD";
        public const string MENU_LEFT_QA_MEMBERS = "MENU_LEFT_QA_MEMBERS";
        public const string MENU_LEFT_QA_COMP = "MENU_LEFT_QA_COMP";
        public const string MENU_LEFT_QA_TASKS = "MENU_LEFT_QA_TASKS";


        public const string MENU_LEFT_CX_COACHING_CONCERN = "MENU_LEFT_CX_COACHING_CONCERN";
        public const string MENU_LEFT_CX_CONCERN_MAINTAINENCE = "MENU_LEFT_CX_CONCERN_MAINTAINENCE";
        public const string MENU_LEFT_CX_CONCERN_TYPE_MAINTAINENCE = "MENU_LEFT_CX_CONCERN_TYPE_MAINTAINENCE";
        public const string MENU_LEFT_CX_CUSTOMER_FEEDBACK = "MENU_LEFT_CX_CUSTOMER_FEEDBACK";
        public const string MENU_LEFT_CX_SURVEY = "MENU_LEFT_CX_SURVEY";



        public const string MENU_LEFT_REPORTS_SYSTEM_EXPORT_POEXPORT = "MENU_LEFT_REPORTS_SYSTEM_EXPORT_POEXPORT";
        public const string MENU_LEFT_REPORTS_SYSTEM_EXPORT_INVOICEEXPORT = "MENU_LEFT_REPORTS_SYSTEM_EXPORT_INVOICEEXPORT";
        public const string MENU_LEFT_REPORTS_SYSTEM_TRANSACTION_SRLIST = "MENU_LEFT_REPORTS_SYSTEM_TRANSACTION_SRLIST";
        public const string MENU_LEFT_REPORTS_SYSTEM_TRANSACTION_POLIST = "MENU_LEFT_REPORTS_SYSTEM_TRANSACTION_POLIST";
        public const string MENU_LEFT_REPORTS_DEPARTMENT_VENDOR_VENDORLIST = "MENU_LEFT_REPORTS_DEPARTMENT_VENDOR_VENDORLIST";
        public const string MENU_LEFT_REPORTS_DEPARTMENT_VENDOR_VENDORACTIVITY = "MENU_LEFT_REPORTS_DEPARTMENT_VENDOR_VENDORACTIVITY";

        public const string SPINNER_NOTIFICATION_AUTOCLOSE = "SPINNER_NOTIFICATION_AUTOCLOSE";

        public const string TEXT_USER_PIN = "TEXT_USER_PIN";


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

        #region Drop Down Values
        public const string CLAIMS_STATUS_READYFORPAYMENT = "CLAIMS_STATUS_READYFORPAYMENT";
        #endregion

        public const string BUTTON_ADD_NOTIFICATION = "BUTTON_ADD_NOTIFICATION";
    }
}
