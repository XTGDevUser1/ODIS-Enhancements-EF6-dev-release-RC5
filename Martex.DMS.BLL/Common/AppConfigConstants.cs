using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.BLL.Common
{
    public static class AppConfigConstants
    {
        // Twilio configuration
        public const string FAX_FILE_PDF_PATH = "FaxFilePDFPath";
        public const string TwilioAccountSid = "TwilioAccountSid";
        public const string TwilioAuthToken = "TwilioAuthToken";
        public const string TwilioFromNumber = "TwilioFromNumber";
        public const string TwilioMediaHostURL = "TwilioMediaHostURL";

        // OutboundCall - AmazonConnect
        public const string ClosedLoopApiKey = "ClosedLoopApiKey";
        public const string OutboundCallApiKey = "OutboundCallApiKey";
        public const string OutboundCallAPIHost = "OutboundCallAPIHost";
        public const string OutboundCallAPIEndpoint = "OutboundCallAPIEndpoint";
        public const string OutboundCallQueueID = "OutboundCallQueueID";
        public const string OutboundCallContactFlowID = "OutboundCallContactFlowID";

        public const string CLOSED_LOOP_SERVICE_CATEGORY = "ClosedLoopPhoneService";

        public const string BODY_FILE_PATH = "BodyFilePath";
        public const string LOCAL_BODY_FILE_PATH = "LocalBodyFilePath";
        public const string XML_API_PATH = "XMLAPIPath";
        public const string COVER_PAGE = "CoverPage";
        public const string GFI_SENDER_EMAIL = "GFISenderEmail";
        public const string FEEDBACK_ATTACHMENT_PATH = "FeedbackAttachmentPath";
        public const string FAX_PRINT_QUEUE = "FaxPrintQueue";
        public const string QUEUE_REFRESH_SECONDS = "QueueRefreshSeconds";
        public const string QUEUE_DISPLAY_HOURS = "QueueDisplayHours";
        public const string COMMUNICATION_QUEUE_ATTEMPTS = "CommunicationQueueAttempts";
        public const string SMS_SERVICE_GUID = "SMSServiceGUID";
        public const string SMS_SERVICE_URI = "SMSServiceURI";
        public const string GET_LOCATION_RESULT_SERVICE_URI = "GetLocationResultServiceURI";
        public const string GET_LOCATION_RESULT_SERVICE_GUID = "GetLocationResultServiceGUID";
        public const string Hagerty_Service_UserName = "HagertyServiceUserName";
        public const string Hagerty_Service_Password = "HagertyServicePassword";
        public const string Hagerty_Service_URI = "HagertyServiceURI";
        public const string PSAP_Lookup_US_URI = "PSAPLookupUSURI";
        public const string PSAP_Nearest_US_URI = "PSAPNearestUSURI";
        public const string PSAP_Username = "PSAPUsername";
        public const string PSAP_Password = "PSAPPassword";
        public const string APPLICATION_VERSION = "ApplicationVersion";
        public const string SERVICE_LOCATION_SEARCH_RADIUS_MILES = "ServiceLocationSearchRadius";
        public const string SEARCH_RADIUS_MILES = "InitialISPSearchRadiusMiles";
        public const string ADMIN_WEIGHT = "DefaultAdminWeighting";
        public const string PERFORMANCE_WEIGHT = "DefaultPerformanceWeighting";
        public const string COST_WEIGHT = "DefaultCostWeighting";
        public const string CC_SERVICE_URL = "CCServiceURI";
        public const string CC_LocalService_Password = "CCLocalServicePassword";
        public const string CC_LocalService_UserName = "CCLocalServiceUserName";


        public const string SUCCESS = "SUCCESS";
        public const string PENDING = "PENDING";
        public const string FAIL = "FAIL";

        public const string ROLES_THAT_SHOW_ADD_NEW_PAYMENT = "RolesThatCanProcessPayments";
        public const string THRESHOLD_NUMBER_OF_CALLS = "ThreshholdNumberOfCalls";
        public const string THRESHOLD_ENROUTE_MILES = "ThresholdEnrouteMiles";
        public const string ROLES_THAT_SHOW_ISP_NOTCALLED = "RolesWithFullDispatchEnabled";// "RolesThatShowISPNotCalled";
        public const string ROLES_THAT_ALLOW_PO_PAYMENT_EDIT = "RolesThatAllowPOPaymentEdit";
        public const string Event_Notification_Service_Sleep_Interval = "EventNotificationServiceSleepInterval";
        public const string AGING_CLOSE_LOOP_MINUTES_Service_Sleep_Interval = "AgingClosedLoopMinutes";
        public const string AGING_SERVICE_REQUEST_HOURS_Service_Sleep_Interval = "AgingServiceRequestHours";
        public const string AGING_READY_FOR_EXPORT_MINUTES_Service_Seleep_Interval = "AgingReadyForExportMinutes";

        public const string APPLICATION_CONFIGURATION_CAT_FAX_SERVICE = "FaxService";
        public const string APPLICATION_CONFIGURATION_TYPE_COM_QUEUE = "CommunicationQueue";

        public const string TEMPLATE_FAX_HEADER_XML_FILE = "FaxHeaderXMLFile";
        public const string FAX_SERVER_USERNAME = "FaxServerUserName";
        public const string FAX_SERVER_PASSWORD = "FaxServerPassword";
        public const string PHONE_HTTP_TRIGGER = "PhoneHTTPTrigger";
        public const string SERVICE_ACCOUNT_USERNAME = "ServiceAccountUserName";
        public const string SERVICE_ACCOUNT_PASSWORD = "ServiceAccountPassword";
        public const string SERVICE_ACCOUNT_DOMAIN = "ServiceAccountDomain";
        public const string PHONE_HTTP_REQUEST_TIMEOUT = "PhoneHTTPRequestTimeout";

        // Click to call config settings
        public const string CLICK_TO_CALL_ENABLED = "ClickToCallEnabled";
        public const string DEVICE_NAME_REGISTRY_PATH = "DeviceNameRegistryPath";
        public const string WEB_DIALER_URI = "WebDialerURI";
        public const string PHONE_NUMBER_PREFIX = "PhoneNumberPrefix";

        public const string BING_API_KEY = "BING_API_KEY";

        public const string INSURANCE_CERTIFICATE_PATH = "InsuranceCertificatePath";

        public const string PO_INVOICE_DIFFERENCE_THRESHOLD = "POInvoiceDifferenceThreshold";
        public const string MAXIMUM_INVOICE_AMOUNT_THRESHOLD = "MaximumInvoiceAmountThreshold";

        public const string VENDOR_ADMIN_RATING_DEFAULT = "VendorAdminRatingDefault";

        public const string DEFAULT_VENDOR_INVOICE_LIST_DAYS = "DefaultVendorInvoiceListDays";
        public const string DEFAULT_ACES_PAYMENT_LIST_DAYS = "DefaultACESPaymentListDays";

        public const string MANUAL_INVOICE_WAIT_IN_DAYS = "ManualInvoiceWaitInDays";

        public const string VENDOR_PORTAL_ACH_VOIDED_CHECK_PATH = "VendorPortalACHVoidedCheckPath";
        public const string APPLICAITON_CONFIGURAITON_VENDOR_FEEDBACK_DEFAULT_EMAIL = "VendorPortalDefaultFeedbackEmail";
        public const string DOCUMENT_NETWORK_BASE_PATH = "ODISVendorDocumentBasePath";
        public const string DOCUMENT_CATEGORY_VENDOR = "VendorInvoice";
        public const string NO_REPLY_FROM_EMAIL_ADDRESS = "SMTPNoReplyFromAddress";
        public const string GLOBAL_FROM_DISPLAY_NAME_COACH_VENDOR = "Pinnacle Partner Portal";
        public const string DOCUMENT_BACK_OFFICE = "BackOffice";
        public const string EMAIL_BCC = "EmailTemplateBCC";
        public const string EMAIL_BCC_INCULDE = "EmailTemplateBCCInclude";
        public const string EMAIL_BCC_INCULDE_ON = "on";
        public const string EMAIL_BCC_INCULDE_OFF = "off";
        public const string APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER = "VendorServicesPhoneNumber";
        public const string APPCONFIG_VENDOR_SERVICE_FAX_NUMBER = "VendorServicesFaxNumber";
        public const string APPCONFIG_FEEDBACK_MAIL_SUBJECT = "FeedbackEmailSubject";
        public const string APPCONFIG_FEEDBACK_ROLE_SETTING_NAME = "RolesForCustomerFeedbackWorkedBy";
        public const string ROLES_THAT_CAN_REQUEST_GIFT_CARD = "RolesThatCanRequestGiftCard";


        public const string VENDOR_DOCUMENTS_USERNAME = "VendorDocumentsUserName";
		public const string VENDOR_DOCUMENTS_PASSWORD = "VendorDocumentsPassword";
			
		public const string EXPORTFILES_FOLDER_USERNAME = "ExportFilesFolderUserName";
        public const string EXPORTFILES_FOLDER_PASSWORD = "ExportFilesFolderPassword";

        //Lakshmi - Hagerty Integration
        public const string HagertyPlus_Service_UserName = "HagertyPlusServiceUserName";
        public const string HagertyPlus_Service_Password = "HagertyPlusServicePassword";
        public const string HagertyPlus_Service_URI = "HagertyPlusServiceURI";


        public const string INSURANCE_ADMIN_USER = "InsuranceAdminUser";

        public const string STATUS_PAGE_AUTOREFRESH_INTERVAL_IN_MILLIS = "StatusPageAutoRefreshIntervalInMillis";

        public const string SERVICE_TEAM_NAME = "ServiceTeamName";
        public const string SERVICE_TEAM_NUMBER = "ServiceTeamNumber";
        public const string SURVEY_LINK = "SurveyLink";
    }
}
