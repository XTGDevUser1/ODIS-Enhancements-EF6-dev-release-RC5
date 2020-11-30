using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Common
{
    /// <summary>
    /// 
    /// </summary>
    public static class EventTypes
    {
        public const string LOGIN = "Login";
        public const string SERVICE_REQUEST = "ServiceRequest";
    }

    /// <summary>
    /// 
    /// </summary>
    public static class EventCategories
    {
        public const string SYSTEM = "System";
        public const string USER = "User";
        public const string PAYMENT = "Payment";
        public const string VENDOR_PORTAL = "VendorPortal";
    }

    public static class RateTypeNames
    {
        public const string Service = "Service";
        public const string ServiceFree = "ServiceFree";
        public const string Base = "Base";
        public const string Enroute = "Enroute";
        public const string EnrouteFree = "EnrouteFree";
        public const string Hourly = "Hourly";
        public const string GoneOnArrival = "GoneOnArrival";

        public const string Manual = "Manual";


    }

    public static class ServiceRequestStatusNames
    {
        public const string SUBMITTED = "Submitted";
        public const string COMPLETE = "Complete";
        public const string ENTRY = "Entry";
        public const string DISPATCHED = "Dispatched";
        public const string CANCELLED = "Cancelled";
    }
    /// <summary>
    /// 
    /// </summary>
    public static class EventNames
    {
        public const string BING_MAP_SERVICE_DOWN = "BingMapDown";
        public const string LOGIN_SUCCESS = "LoginSuccess";
        public const string LOGIN_FAILURE = "LoginFailure";
        public const string FORGOT_PASSWORD = "ForgotPassword";
        public const string LOGOUT = "Logout";
        public const string FEEDBACK_SEND = "FeedbackSend";
        public const string FEEDBACK_SUCCESS = "FeedbackSuccess";
        public const string FEEDBACK_FAILURE = "FeedbackFailure";
        public const string EMERGENCY_ASSISTANCE = "EmergencyAssistance";
        public const string SUBMITTED_FOR_DISPATCH = "SubmittedForDispatch";

        public const string DISPATCH_IN_PROCESS = "DispatchInProcess";
        public const string SERVICE_ARRIVED = "ServiceArrived";
        public const string SERVICE_COMPLETED = "ServiceCompleted";
        public const string SERVICE_CANCELLED = "ServiceCancelled";

        public const string ENTER_START_TAB = "EnterStartTab";
        public const string LEAVE_START_TAB = "LeaveStartTab";
        public const string StartCase = "StartCase";
        public const string MANAGER_OVERRIDE_OPEN_CASE = "ManagerOverrideOpenCase";
        public const string OPENED_LOCKED_REQUEST_BECAUSE_NOT_ONLINE = "OpenedLockedRequestBecauseNotOnline";
        public const string REGISTER_MEMBER = "RegisterMember";
        public const string EFG_REGISTER_MEMBER = "EFGRegisterMember";

        public const string START_CALL = "StartCall";
        public const string MEMBER_SEARCH = "MemberSearch";
        public const string PO_SEARCH = "POSearch";
        public const string CLOSED_LOOP_SEARCH = "ClosedLoopSearch";
        public const string START_CASE = "StartCase";
        public const string START_SERVICE_REQUEST = "StartServiceRequest";
        public const string OPEN_SERVICE_REQUEST = "OpenServiceRequest";
        public const string OPEN_ACTIVE_REQUEST = "OpenActiveRequest";
        public const string LEAVE_MEMBER_TAB = "LeaveMemberTab";
        public const string SAVE_MEMBER_TAB = "SaveMemberTab";
        public const string ENTER_EMERGENCY_TAB = "EnterEmergencyTab";
        public const string EMERGENCY_HELP_PROVIDED = "EmergencyHelpProvided";
        public const string LEAVE_EMERGENCY_TAB = "LeaveEmergencyTab";
        public const string ENTER_MEMBER_TAB = "EnterMemberTab";
        public const string ENTER_VEHICLE_TAB = "EnterVehicleTab";
        public const string ADD_VEHICLE = "AddVehicle";
        public const string UPDATE_VEHICLE = "UpdateVehicle";
        public const string RETRIEVE_HAGERTY_VEHICLE = "RetrieveHagertyVehicle";
        public const string LEAVE_VEHICLE_TAB = "LeaveVehicleTab";
        public const string SAVE_VEHICLE_TAB = "SaveVehicleTab";
        public const string ENTER_SERVICE_TAB = "EnterServiceTab";
        public const string LEAVE_SERVICE_TAB = "LeaveServiceTab";
        public const string ENTER_ESTIMATE_TAB = "EnterEstimateTab";
        public const string LEAVE_ESTIMATE_TAB = "LeaveEstimateTab";
        public const string ENTER_MAP_TAB = "EnterMapTab";
        public const string SEARCH_MAP = "SearchMap";
        public const string SET_LOCATION = "SetLocation";
        public const string SET_DESTINATION = "SetDestination";
        public const string LEAVE_MAP_TAB = "LeaveMapTab";
        public const string ENTER_DISPATCH_TAB = "EnterDispatchTab";
        public const string LEAVE_DISPATCH_TAB = "LeaveDispatchTab";
        public const string ENTER_PO_TAB = "EnterPOTab";
        public const string SEND_PO_TO_VENDOR = "SendPOToVendor";
        public const string LEAVE_PO_TAB = "LeavePOTab";
        public const string ENTER_PAYMENT_TAB = "EnterPaymentTab";
        public const string LEAVE_PAYMENT_TAB = "LeavePaymentTab";
        public const string ENTER_ACTIVITY_TAB = "EnterActivityTab";
        public const string LEAVE_ACTIVITY_TAB = "LeaveActivityTab";
        public const string ENTER_FINISH_TAB = "EnterFinishTab";
        public const string LOG_CALL = "Log Call";
        public const string LEAVE_FINISH_TAB = "LeaveFinishTab";
        public const string SAVE_FINISH_TAB = "SaveFinishTab";
        public const string SUBMIT_FOR_DISPATCH = "SubmitForDispatch";
        public const string START_DISPATCH = "StartDispatch";
        public const string CALLED_ISP = "CalledISP";
        public const string DISPATCHED = "Dispatched";
        public const string REQUEST_CLOSEDLOOP = "RequestClosedLoop";
        public const string SEND_CLOSEDLOOP = "SendClosedLoop";
        public const string RECEIVE_CLOSEDLOOP = "ReceiveClosedLoop";
        public const string ACCEPT_CREATE_PO = "AcceptCreatePO";
        public const string COPY_PO = "CopyPO";

        public const string CREATE_TEMPORARY_VENDOR = "CreateTemporaryVendor";

        public const string SEND_PO = "SendPO";
        public const string CREATE_PO = "CreatePO";
        public const string UPDATE_PO = "UpdatePO";
        public const string CANCEL_PO = "CancelPO";
        public const string CREATE_GOA = "Create GOA";
        public const string CREATE_CASE_FOR_INFO_CALL = "CreateCaseForInfoCall";
        public const string CREATE_SERVICE_REQUEST_FOR_INFO_CALL = "CreateServiceRequestForInfoCall";

        public const string HAGERTY_VIP_ISSUED_PO = "HagertyVIPIssuedPO";
        public const string HAGERTY_PCS_ISSUED_PO = "HagertyPCSIssuedPO";
        public const string HAGERTY_SPECIAL_ISSUED_PO = "HagertySpecialIssuedPO";
        public const string NOVUM_ISSUED_PO = "NovumIssuedPO";

        public const string EFG_PATTERSON_ISSUED_PO = "EFGPattersonIssuedPO";
        public const string EFG_SERVICE_CONTRACT_ISSUED_PO = "EFGServiceContractIssuedPO";

        public const string DEVICE_INFO_READ_BY_APPLET = "DeviceInfoReadByApplet";
        public const string CLICK_TO_CALL = "ClickToCall";
        public const string APPLY_CREDIT_FAILED = "ApplyCreditFailed";
        public const string APPLY_CREDIT_APPROVED = "ApplyCreditApproved";
        public const string CHARGE_CARD = "ChargeCard";

        public const string SEND_PAYMENT_RECEIPT = "SendPaymentReceipt";
        public const string SEND_PAYMENT_RECEIPT_COPY_TO_CLIENT = "SendPaymentReceiptCopyToClient";

        public const string EMERGENCY_USEPSAP = "UsePSAP";

        public const string REJECT_EXISTING_VENDOR = "RejectExistingVendor";
        public const string USE_EXISTING_VENDOR = "UseExistingVendor";

        public const string ADD_VENDOR = "AddVendor";
        public const string ADD_VENDOR_APPLICATION = "AddVendorApplication";

        public const string ADD_VENDOR_LOCATION = "AddVendorLocation";

        // Vendor mangament        
        public const string WEB_REGISTRATION = "WebRegistration";
        public const string SUBMITTED_WEB_APPLICATION = "SubmittedWebApplication";
        public const string WEB_AUTHENTICATION = "WebAuthentication";
        public const string UPDATE_PASSWORD = "UpdatePassword";
        public const string UPDATE_INFORMATION = "UpdateInformation";
        public const string OVER_RIDE_SERVICE_RATING = "OverrideServiceRating";
        public const string USE_SELLER_DEALER_LOCATION = "UseSellerDealerLocation";
        // Vendor Contract
        public const string ADD_CONTRACT = "Add Contract";
        public const string ADD_CONTRACT_RATE_SCHEDULE = "AddContractRateSchedule";

        //Member
        public const string UPDATE_MEMBER = "UpdateMember";
        public const string UPDATE_MEMBER_SHIP = "UpdateMembership";
        public const string OPENED_MEMBERSHIP_NOTE = "OpenedMembershipNote";

        public const string ADD_MEMBER = "AddMember";

        //Vendor Portal
        public const string SEARCH_INVOICE_HISTORY = "SearchInvoiceHistory";
        public const string VENDOR_PORTAL_SUBMIT_FEEDBACK = "VendorPortalSubmitFeedback";
        public const string INSURANCE_PROMPT = "InsurancePrompt";

        //Vendor Invoice
        public const string ADD_VENDOR_INVOICE = "AddVendorInvoice";
        public const string INITIAL_LOGIN_VERIFY_DATA = "InitialLoginVerifyData";
        public const string UPDATE_VENDOR_INVOICE = "UpdateVendorInvoice";
        public const string VERIFY_INVOICES = "VerifyInvoices";

        public const string SEARCH_TEMP_CC_HISTORY = "SearchTempCCHistory";
        // Vendor Transitions
        public const string TRANSITION_REGISTRATION = "TransitionRegistration";

        //Vendor Levy
        public const string START_LEVY = "StartLevy";
        public const string END_LEVY = "EndLevy";

        public const string MERGE_VENDOR = "MergeVendor";

        public const string PAY_INVOICES = "PayInvoices";

        public const string MERGE_MEMBER = "MergeMember";

        public const string UPDATE_CLAIM = "UpdateClaim";
        public const string SUBMIT_CLAIM = "SubmitClaim";
        public const string ADD_CLIENT_PAYMENT = "AddClientPayment";
        public const string UPDATE_CLIENT_PAYMENT = "UpdateClientPayment";
        public const string APPLY_CLIENT_PAYMENTS = "ApplyClientPayments";


        // For Vendor Portal ACH
        public const string ACH_SIGNUP_CLICKED = "ACHSignUpClicked";
        public const string ACH_INSERT_RECORD = "InsertACH";
        public const string ACH_TURN_ON = "TurnOnACH";
        public const string ACH_TURN_OFF = "TurnOffACH";
        public const string ACH_UPDATE_RECORD = "UpdateACH";

        //Document
        public const string EVENT_ADD_DOCUMENT = "UploadDocument";
        public const string EVENT_DELETE_DOCUMENT = "DeleteDocument";

        //Claims
        public const string TAG_CLAIM_READY_FOR_PAYMENT = "TagClaimReadyForPayment";
        public const string PAY_CLAIM = "PayClaim";

        public const string REISSUED_TEMPORARY_CC = "Re-Issued Temporary CC";
        public const string EVENT_OVERRIDEPOSERVICECOVERED = "OverridePOServiceCovered";

        //Client Billable Event Processing
        public const string UPDATE_BILLING_INVOICE_DETAIL = "UpdateBillingInvoiceDetail";
        public const string ADD_INVOICE_LINE = "AddInvoiceLine";
        public const string DELETE_INVOICE_LINE = "DeleteInvoiceLine";
        public const string REFRESH_INVOICE_DETAILS = "RefreshInvoiceDetails";
        public const string POST_INVOICE = "PostInvoice";
        public const string REFRESH_ALL_INVOICE_DETAILS = "RefreshAllInvoiceDetails";
        public const string POST_ALL_INVOICES = "PostAllInvoices";

        public const string RETRIEVE_HAGERTY_MEMBER = "RetrieveHagertyMember";  //Lakshmi - Hagerty Integration 
        public const string INSERT_UPDATE_HAGERTY_MEMBER = "InsertOrUpdateHagertyMember";  //Lakshmi - Hagerty Integration 

        //vendor temporary credit card
        public const string MATCH_TEMP_CC = "MatchTempCC";
        public const string IMPORT_TEMP_CC_FILE = "ImportTempCCFile";

        // Client Open Close Periods
        public const string CLOSE_PERIOD = "ClosePeriod";


        //Client Invoice Processing

        public const string UPDATE_BILLING_EVENT_STATUS = "UpdateBillingEventStatus";
        public const string UPDATE_BILLING_EVENT_DISPOSITION = "UpdateBillingEventDisposition";

        public const string LOCKED_REQUEST_COMMENT = "LockedRequestComment";

        public const string UPDATE_MEMBER_EXPIRATION = "UpdateMemberExpiration";

        public const string UPDATE_CASE = "UpdateMemberInfoInCase";  //Lakshmi - Update Orphaned Service Request

        public const string EDIT_CC_NUMBER_ON_PO = "EditCCNumberOnPO";
        public const string EVENT_PO_CHANGE_SERVICE = "POChangeService";

        //For Coaching Concern
        public const string ADD_COACHING_CONCERN = "AddCoachingConcern";
        public const string UPDATE_COACHING_CONCERN = "UpdateCoachingConcern";

        public const string ENTERED_PROVIDER_CLAIM_NUMBER = "EnteredProviderClaimNumber";

        public const string CHANGE_MEMBER_NAME = "ChangeMemberName";

        public const string CHANGE_MEMBER_PROGRAM = "ChangeMemberProgram";

        public const string NEXT_ACTION_SET = "NextActionSet";
        public const string NEXT_ACTION_CLEARED = "NextActionCleared";
        public const string NEXT_ACTION_STARTED = "NextActionStarted";


        // Client API Event Names
        public const string API_POST_MEMBER_BEGIN = "API_POST_MEMBER_BEGIN";
        public const string API_POST_MEMBER_END = "API_POST_MEMBER_END";
        public const string API_PUT_MEMBER_BEGIN = "API_PUT_MEMBER_BEGIN";
        public const string API_PUT_MEMBER_END = "API_PUT_MEMBER_END";
        public const string API_DELETE_MEMBER_BEGIN = "API_DELETE_MEMBER_BEGIN";
        public const string API_DELETE_MEMBER_END = "API_DELETE_MEMBER_END";
        public const string API_GET_MEMBER_BEGIN = "API_GET_MEMBER_BEGIN";
        public const string API_GET_MEMBER_END = "API_GET_MEMBER_END";
        public const string API_POST_SERVICEREQUEST_BEGIN = "API_POST_SERVICEREQUEST_BEGIN";
        public const string API_POST_SERVICEREQUEST_END = "API_POST_SERVICEREQUEST_END";
        public const string API_GET_SERVICEREQUEST_BEGIN = "API_GET_SERVICEREQUEST_BEGIN";
        public const string API_GET_SERVICEREQUEST_END = "API_GET_SERVICEREQUEST_END";

        public const string API_GET_ROADSIDE_SERVICES_BEGIN = "API_GET_ROADSIDE_SERVICES_BEGIN";
        public const string API_GET_ROADSIDE_SERVICES_END = "API_GET_ROADSIDE_SERVICES_END";

        public const string API_GET_ROADSIDE_SERVICES_QUESTIONS_END = "API_GET_ROADSIDE_SERVICES_QUESTIONS_END";
        public const string API_GET_ACTIVE_REQUEST_BEGIN = "API_GET_ACTIVE_REQUEST_BEGIN";
        public const string API_GET_ACTIVE_REQUEST_END = "API_GET_ACTIVE_REQUEST_END";
        public const string API_GET_ROADSIDE_SERVICES_QUESTIONS_BEGIN = "API_GET_ROADSIDE_SERVICES_QUESTIONS_BEGIN";

        public const string API_POST_DEVICE_BEGIN = "API_POST_DEVICE_BEGIN";
        public const string API_POST_DEVICE_END = "API_POST_DEVICE_END";

        public const string API_GET_CONFIRM_ESTIMATE_BEGIN = "API_GET_CONFIRM_ESTIMATE_BEGIN";
        public const string API_GET_CONFIRM_ESTIMATE_END = "API_GET_CONFIRM_ESTIMATE_END";

        public const string API_GET_CANCEL_ESTIMATE_BEGIN = "API_GET_CANCEL_ESTIMATE_BEGIN";
        public const string API_GET_CANCEL_ESTIMATE_END = "API_GET_CANCEL_ESTIMATE_END";

        public const string API_POST_CLOSELOOP_BEGIN = "API_POST_CLOSELOOP_BEGIN";
        public const string API_POST_CLOSELOOP_END = "API_POST_CLOSELOOP_END";

        //Client Rep
        public const string CREATE_CLIENT_REP = "CreateClientRep";
        public const string UPDATE_CLIENT_REP = "UpdateClientRep";


        public const string SIGNED_PINNACLE_CONTRACT = "SignedPinnacleContract";
        public const string SOFTWARE_ZIP_CODES_PROMPT = "SoftwareZipCodesPrompt";

        //Estimate
        public const string CAPTURE_ESTIMATE = "CaptureEstimate";
        public const string UPDATE_SERVICEREQUEST_ESTIMATE = "UpdateServiceRequestEstimate";


        public const string PO_THRESHOLD_APPROVED = "POThresholdApproved";
        public const string PO_THRESHOLD_REJECTED = "POThresholdRejected";

        public const string INSERT_CUSTOMER_FEEDBACK = "InsertCustomerFeedback";
        public const string UPDATE_CUSTOMER_FEEDBACK = "UpdateCustomerFeedback";
        public const string CLOSE_CUSTOMER_FEEDBACK = "CloseCustomerFeedback";

        public const string ADD_CUSTOMER_FEEDBACK_GIFT_CARD = "AddCustomerFeedbackGiftCard";
        public const string UPDATE_CUSTOMER_FEEDBACK_GIFT_CARD = "UpdateCustomerFeedbackGiftCard";
        public const string DELEET_CUSTOMER_FEEDBACK_GIFT_CARD = "DeleteCustomerFeedbackGiftCard";

        public const string SEND_SURVEY = "SendSurvey";
    }


    /// <summary>
    /// 
    /// </summary>
    public static class PhoneTypeNames
    {
        public const string BANK = "Bank";
        public const string Home = "Home";
        public const string Work = "Work";
        public const string Cell = "Cell";
        public const string Fax = "Fax";
        public const string Dispatch = "Dispatch";
        public const string AlternateDispatch = "AlternateDispatch";
        public const string Office = "Office";
        public const string Other = "Other";
        public const string Insurance = "Insurance";
    }

    public static class VendorLocationTypeNames
    {
        public const string Physical = "Physical";
    }


    /// <summary>
    /// 
    /// </summary>
    public static class AddressTypeNames
    {
        public const string BANK = "Bank";
        public const string HOME = "Home";
        public const string BILLING = "Billing";
        public const string Insurance = "Insurance";
        public const string Business = "Business";
        public const string LEVY = "Levy";
        public const string DISPATCH = "Dispatch";
    }
    /// <summary>
    /// 
    /// </summary>
    public static class EntityNames
    {
        public const string ADDRESS = "Address";
        public const string CASE = "Case";
        public const string CLIENT = "Client";
        public const string CLIENT_REP = "ClientRep";
        public const string CONTRACT = "Contract";
        public const string MEMBER = "Member";
        public const string MEMBERSHIP = "Membership";
        public const string ORGANIZATION = "Organization";
        public const string PAYMENT = "Payment";
        public const string PAYMENT_AUTHORIZATION = "PaymentAuthorization";
        public const string PHONE = "Phone";
        public const string PURCHASE_ORDER = "PurchaseOrder";
        public const string PURCHASE_ORDER_DETAIL = "PurchaseOrderDetail";
        public const string SERVICE_REQUEST = "ServiceRequest";
        public const string SERVICE_REQUEST_DETAIL = "ServiceRequestDetail";
        public const string USER = "User";
        public const string VEHICLE = "Vehicle";
        public const string VENDOR = "Vendor";
        public const string VENDOR_LOCATION = "VendorLocation";
        public const string VENDOR_PAYMENT = "VendorPayment";
        public const string VENDOR_APPLICATION = "VendorApplication";
        public const string EMERGENCY_ASSISTANCE = "EmergencyAssistance";
        public const string INBOUND_CALL = "InboundCall";
        public const string CONTACT_LOG = "ContactLog";
        public const string VENDOR_LOCATION_VIRTUAL = "VendorLocationVirtual";
        public const string VENDOR_INVOICE = "VendorInvoice";
        public const string CLAIM_PAYMENT = "ClientPayment";

        public const string CLAIM = "Claim";
        public const string CLIENT_PAYMENT = "ClientPayment";

        public const string FEEDBACK = "Feedback";
        public const string INVOICE = "Invoice";
        public const string BILLING_INVOICE = "BillingInvoice";
        public const string BILLING_SCHEDULE = "BillingSchedule";
        public const string BILLING_INVOICE_DETAIL = "BillingInvoiceDetail";

        public const string COACHING_CONCERN = "CoachingConcern";
        public const string DOCUMENT = "Document";

        public const string NEXT_ACTION = "NextAction";
        public const string PROGRAM = "Program";
        public const string CUSTOMER_FEEDBACK = "CustomerFeedback";
    }

    public static class DocumentCategoryNames
    {
        public const string VENDOR_INVOICE = "VendorInvoice";
    }

    public static class Products
    {
        public const string COACHNET_DEALER_PARTNER = "CoachNet Dealer Partner";
    }

    public static class ProgramDataItemNames
    {
        public const string CLAIM_NUMBER = "ClaimNumber";

    }

    /// <summary>
    /// 
    /// </summary>
    public static class ContactMethodNames
    {
        public const string PHONE = "Phone";
        public const string TEXT = "Text";
        public const string EMAIL = "Email";
        public const string FAX = "Fax";
        public const string IVR = "IVR";
        public const string VERBALLY = "VERBALLY";
        public const string MAIL = "Mail";
        public const string DESKTOP_NOTIFICATION = "DesktopNotification";
        public const string MOBILE_NOTIFICATION = "MobileNotification";

    }

    public static class ContactSourceNames
    {
        public const string VENDOR_DATA = "VendorData";
    }

    /// <summary>
    /// 
    /// </summary>
    public static class ContactActionName
    {
        public const string SENT = "Sent";
        public const string SEND_FAILURE = "SendFailure";
        public const string SEND_WELCOME_LETTER = "SendWelcomeLetter";
        public const string SEND_RATE_SCHEDULE = "SendRateSchedule";
        public const string NOTIFY_VENDOR_REP_FOR_UPLOAD_DOCUMENT = "NotifyVendorRepForUploadDocument";
    }

    public static class ContactReasonName
    {
        public const string SUBMIT_CLAIM = "SubmitClaim";
        public const string RECEIVED_CLAIM = "ReceivedClaim";
        public const string UPDATE_CLAIM = "UpdateClaim";
        public const string NEW_VENDOR = "NewVendor";
        public const string UPLOAD_DOCUMENT = "UploadDocument";
    }

    /// <summary>
    /// 
    /// </summary>
    public static class ClosedLoopStatusName
    {
        public const string PENDING = "Pending";
        public const string SENT = "Sent";
        public const string SEND_FAILURE = "SendFailure";
        public const string SERVICE_ARRIVED = "ServiceArrived";
        public const string SERVICE_NOT_ARRIVED = "ServiceNotArrived";
        public const string UNKNOWN = "Unknown";

    }
    /// <summary>
    /// 
    /// </summary>
    public static class ContactCategoryNames
    {
        public const string EMERGENCY_ASSISTANCE = "EmergencyAssistance";
        public const string CLOSED_LOOP = "ClosedLoop";
        public const string CONTACT_VENDOR = "ContactVendor";
        public const string VENDOR_PORTAL = "VendorPortal";
    }

    /// <summary>
    /// 
    /// </summary>
    public static class ContactTypeNames
    {
        public const string SYSTEM = "System";
    }

    /// <summary>
    /// 
    /// </summary>
    public enum TabConstants : int
    {
        StartTab = 1,
        ActivityTab,
        VehicleTab,
        EmergencyTab,
        MemberTab,
        ServiceTab,
        PaymentTab,
        MapTab,
        DispatchTab,
        POTab,
        FinishTab,
        EstimateTab
    }

    public static class RateTypes
    {
        public const string BASE = "Base";
        public const string ENROUTE = "Enroute";
        public const string ENROUTE_FREE = "EnrouteFree";
        public const string GONE_ON_ARRIVAL = "GoneOnArrival";
        public const string HOURLY = "Hourly";
        public const string SERVICE = "Service";
        public const string SERVICE_FREE = "ServiceFree";
    }

    public static class ApplicationConfigurationTypes
    {
        public const string SYSTEM = "System";
        public const string VENDOR_INVOICE = "VendorInvoice";
    }
    public static class ApplicationConfigurationCategories
    {
        public const string EMAIL = "Email";
    }

    public static class TemplateNames
    {
        public const string VENDOR_PORTAL_REGISTRATION_ACTIVATION = "VendorPortal_RegistrationActivation";
        public const string VENDOR_PORTAL_FORGOT_PASSWORD = "VendorPortal_ForgotPassword";

        public const string VENDOR_PORTAL_FEEDBACK_CONFIRMATION = "VendorPortal_FeedbackConfirmation";
        public const string VENDOR_PORTAL_CHANGE_PASSWORD = "VendorPortal_ChangePassword";
        public const string VENDOR_PORTAL_TRANSITION_REGISTRATION_CONFIRMATION = "VendorPortal_TransitionRegistrationConfirmation";

        public const string VENDOR_PORTAL_APPLICATION_CONFIRMATION = "VendorPortal_ApplicationConfirmation";

        public const string VENDOR_PORTAL_REGISTRATION_CONFIRMATION = "VendorPortal_RegistrationConfirmation";

        public const string VENDOR_WELCOME = "Vendor_WelcomeToNetwork";

        public const string PAYMENT_RECEIPT_EMAIL = "PaymentReceiptEmail";

        public const string VENDOR_PORTAL_STOP_ACH = "VendorPortal_ACH_Stopped";

        public const string VENDOR_SEND_RATE_SCHEDULE = "Vendor_SendRateSchedule";

        public const string VENDOR_PORTAL_UPLOAD_DOCUMENT = "VendorPortal_UploadDocument";

        public const string HAS_SERVICE_ARRIVED = "StatusPage_HasServiceArrived";
        public const string HAS_SERVICE_ARRIVED_NO = "StatusPage_HasServiceArrivedNo";
        public const string SERVICE_NOT_ARRIVED_NO_CALL = "StatusPage_ServiceNotArrivedNoCall";

    }

    public static class SourceSystemName
    {
        public const string BACK_OFFICE = "BackOffice";
        public const string VENDOR_PORTAL = "VendorPortal";
        public const string DISPATCH = "Dispatch";
        public const string WEB_SERVICE = "WebService";
        public const string CLIENT_PORTAL = "ClientPortal";
        public const string MEMBER_MOBILE = "MemberMobile";
        public const string CUSTOMER_FEEDBACK = "CustomerFeedback";
    }
    public static class PaymentTypeName
    {
        public const string CHECK = "Check";
        public const string TEMPORARY_CC = "TemporaryCC";
    }

    public static class PayeeTypeName
    {
        public const string MEMBER = "Member";
        public const string VENDOR = "Vendor";
    }

    public static class ClaimTypeName
    {
        public const string WARRANTY = "Warranty Repair";
        public const string ROADSIDE = "Roadside Reimbursement";
        public const string DAMAGE = "Damage Reimbursement";
        public const string FORDQFC = "Ford QFC";
        public const string MOTOR_HOME_REIMBURSEMENT = "MotorhomeReimbursement";
    }

    public static class CompanyNames
    {
        public const string FORD = "Ford";
    }

    public static class MessageScopeNames
    {
        public const string VENDOR_PORTAL = "VendorPortal";
        public const string DISPATCH = "Dispatch";
    }

    public static class PurchaseOrderPayStatusCodeNames
    {
        public const string PAY_BY_CC = "PaidByCC";
        public const string PAID_BY_MEMBER = "PaidByMember";
        public const string PAY_TO_VENDOR = "PayToVendor";
        public const string ON_HOLD = "OnHold";
        public const string AGED = "Aged";
    }

    public static class CommentTypeNames
    {
        public const string CLAIM = "Claim";
        public const string MEMBER = "Member";
        public const string SERVICE_REQUEST = "ServiceRequest";
        public const string LOCKED_REQUEST = "LockedRequest";
    }

    public static class VehicleTypeNames
    {
        public const string AUTO = "Auto";
        public const string RV = "RV";
        public const string MOTORCYCLE = "Motorcycle";
        public const string TRAILER = "Trailer";
    }

    public static class VehicleCategoryNames
    {
        public const string LIGHT_DUTY = "LightDuty";
        public const string MEDIUM_DUTY = "MediumDuty";
        public const string HEAVY_DUTY = "HeavyDuty";
    }

    public static class LanguageNames
    {
        public const string ENGLISH = "English";
        public const string SPANISH = "Spanish";
        public const string FRENCH = "French";
        public const string VIETNAMESE = "Vietnamese";
    }

    public static class CallTypeNames
    {
        public const string NEW_CALL = "NewCall";
        public const string CUSTOMER_CALLBACK = "CustomerCallback";
        public const string VENDOR_CALLBACK = "VendorCallback";
        public const string CLOSED_LOOP = "ClosedLoop";
        public const string WEB_SERVICE = "WebService";
    }

    public static class ContractStatusNames
    {
        public const string ACTIVE = "Active";
    }

    public static class PostLoginPromptNames
    {
        public const string SOFTWARE_ZIP_CODES = "SoftwareZipCodes";
        public const string SIGN_NEW_CONTRACTS = "SignNewContracts";
        public const string INSURANCE_EXPIRING = "InsuranceExpiring";
        public const string UPDATE_PASS = "UpdatePass";
        public const string INITIAL_LOGIN_VERIFY_DATA = "InitialLoginVerifyData";
    }

    public static class ProgramNames
    {
        public const string EFG_PATTERSON = "EFG Patterson";
        public const string EFG_SERVICE_CONTRACT = "Service Contract - EFG";
    }

    public static class ClientNames
    {
        public const string EFG_COMPANIES = "EFG Companies";
    }

    public static class TimeTypes
    {
        public const string FRONTEND = "FrontEnd";
        public const string BACKEND = "BackEnd";
        public const string TECH = "Tech";
        public const string QA = "QA";
        public const string BACKOFFICE = "BackOffice";
    }

    public static class ServiceEligibilityMessages
    {
        public const string ASSIST_ONLY = "ASSIST_ONLY";
        public const string ASSIST_REIMBURSEMENT = "ASSIST_REIMBURSEMENT";
        public const string BEST_VALUE = "BEST_VALUE";
        public const string BEST_VALUE_MILEAGE_LIMIT = "BEST_VALUE_MILEAGE_LIMIT";
        public const string BEST_VALUE_REIMBURSEMENT_ONLY = "BEST_VALUE_REIMBURSEMENT_ONLY";
        public const string BEST_VALUE_REIMBURSEMENT_ONLY_MILEAGE_LIMIT = "BEST_VALUE_REIMBURSEMENT_ONLY_MILEAGE_LIMIT";
        public const string COVERAGE_LIMIT = "COVERAGE_LIMIT";
        public const string COVERAGE_LIMIT_EXCEEDED = "COVERAGE_LIMIT_EXCEEDED";
        public const string COVERAGE_LIMIT_MILEAGE_LIMIT = "COVERAGE_LIMIT_MILEAGE_LIMIT";
        public const string COVERAGE_LIMIT_REIMBURSEMENT_ONLY = "COVERAGE_LIMIT_REIMBURSEMENT_ONLY";
        public const string COVERAGE_LIMIT_REIMBURSEMENT_ONLY_MILEAGE_LIMIT = "COVERAGE_LIMIT_REIMBURSEMENT_ONLY_MILEAGE_LIMIT";
        public const string MEMBER_INACTIVE = "MEMBER_INACTIVE";
        public const string MEMBER_PAY = "MEMBER_PAY";
        public const string PROGRAM_SPECIFIC_ADDENDUM = "PROGRAM_SPECIFIC_ADDENDUM";
        public const string UNDETERMINED = "UNDETERMINED";
        public const string VEHICLE_OUT_OF_WARRANTY = "VEHICLE_OUT_OF_WARRANTY";

    }

    /// <summary>
    /// Vehicle Types
    /// </summary>
    public enum VehicleTypes
    {
        /// <summary>
        /// The auto
        /// </summary>
        Auto = 1,

        /// <summary>
        /// The RV
        /// </summary>
        RV,

        /// <summary>
        /// The motorcycle
        /// </summary>
        Motorcycle,

        /// <summary>
        /// The trailer
        /// </summary>
        Trailer
    }

    public static class CustomerFeedbackStatusNames
    {
        public const string OPEN = "Open";
        public const string CLOSED = "Closed";
        public const string RESEARCH_COMPLETED = "ResearchCompleted";
        public const string IN_PROGRESS = "InProgress";
        public const string PENDING = "Pending";        
    }


    public static class CustomerFeedbackSourceNames
    {
        public const string CLIENT_COMPLAINT = "ClientComplaint";
        public const string FLOOR = "Floor";
        public const string SURVEY = "Survey";

    }

    public static class CustomerFeedbackTypeNames
    {
        public const string COMPLAINT_NON_DAMAGE = "ComplaintNonDamage";
        public const string COMPLAINT_DAMAGE = "ComplaintDamage";
        public const string COMPLIMENT = "Compliment";

    }

    public static class NumberTypeConstants
    {
        public const string SERVICE_REQUEST = "ServiceRequest";
        public const string PURCHASE_ORDER = "PurchaseOrder";
            
    }

    public static class CallFrom
    {
        public const string FEEDBACK = "Feedback";
        public const string SURVEY = "Survey";

    }
}
