using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.Common
{
    /// <summary>
    /// Role Constants
    /// </summary>
    public class RoleConstants
    {
        public const string Agent = "Agent";
        public const string RVTech = "RVTech";
        public const string ClientAdmin = "ClientAdmin";
        public const string Manager = "Manager";
        public const string QA = "QA";
        public const string Dispatcher = "Dispatcher";
        public const string ClientAgent = "ClientAgent";
        public const string SysAdmin = "SysAdmin";
    }

    /// <summary>
    /// String Constants
    /// </summary>
    public static class StringConstants
    {
        public const string AmazonConnectID = "AmazonConnectID";
        public const string LastVendorContactLogID = "LastVendorContactLogID";
        public const string ConnectCallData = "ConnectCallData";
        public const string INBOUND_CALL_ID = "INBOUND_CALL_ID";
        public const string LOGGED_IN_USER = "LOGGED_IN_USER";
        public const string START_CALL_DATA = "StartCallData";
        public const string CASE_ID = "CaseID";
        public const string SERVICE_REQUEST_ID = "ServiceRequestID";
        public const string MEMBERSHIP_ID = "MembershipID";
        public const string MEMBER_ID = "MemberID";
        public const string MEMBER_EMAIL = "MemberEMAIL";
        public const string MEMBER_HOME_ADDRESS_COUNTRY_CODE = "MEMBER_HOME_ADDRESS_COUNTRY_CODE";

        public const string MEMBER_PROGRAM_ID = "MemberProgramID";
        public const string MEMBER_STATUS = "MemberStatus";
        public const string PROGRAM_ID = "ProgramID";
        public const string PROGRAM_NAME = "ProgramName";
        public const string PROGRAM_PARENT_NAME = "ProgramParentName";
        public const string IS_MOBILE_ENABLED = "IsMobileEnabled";
        public const string ALLOW_PAYMENT_PROCESSING = "AllowPaymentProcessing";
        public const string ALLOW_ESTIMATE_PROCESSING = "AllowEstimateProcessing";
        public const string SERVICE_ESTIMATE_FEE = "ServiceEstimateFee";
        public const string SHOW_DATE_OF_PURCHASE = "ShowDateOfPurchase";
        public const string SHOW_FIRST_OWNER = "ShowFirstOwner";

        public const string MOBILE_CALL_FOR_SERVICE_RECORD = "MobileCallForServiceRecord";
        public const string CONTACT_PHONE_TYPE_ID = "ContactPhoneTypeID";
        public const string LAST_UPDATED_VEHICLE_TYPE = "LastUpdatedVehicleType";
        public const string VEHICLE_YEAR = "VehicleYear";
        public const string CALLBACK_NUMBER = "CallbackNumber";
        public const string STARTING_POINT = "StartingPoint";
        public const string START = "Start";
        public const string QUEUE = "Queue";
        public const string CONTACT_CATEGORY_ID = "ContactCategoryID ";
        public const string PAYMENT_ID = "PaymentID";
        public const string VEHICLE_MAKE = "VehicleMake";
        public const string VENDOR_LOCATION_ID = "VendorLocationID";
        public const string IS_PRIMARY_SERVICE_COVERED = "IsPrimaryServiceCovered";
        public const string MEMBER_PAYMENT_TYPE_ID = "MemberPaymentTypeID";

        public const string CONTACT_FIRST_NAME = "ContactFirstName";
        public const string CONTACT_LAST_NAME = "ContactLastName";
        public const string CONTACT_EMAIL = "ContactEmail";
        public const string SOURCE_SYSTEM_FROM_CASE = "SourceSystemFromCase";

        public const string IS_DELIVERY_DRIVER = "IsDeliveryDriver";

        public const string SERVICE_LOCATION_LATITUDE = "ServiceLocationLatitude";
        public const string SERVICE_LOCATION_LONGITUDE = "ServiceLocationLongitude";

        public const string DESTINATION_LATITUDE = "DestinationLatitude";
        public const string DESTINATION_LONGITUDE = "DestinationLongitude";

        public const string VEHICLE_TYPE_ID = "VehicleTypeID";
        public const string VEHICLE_CATEGORY_ID = "VehicleCategoryID";
        public const string PRIMARY_PRODUCT_ID = "PrimaryProductID";
        public const string SECONDARY_PRODUCT_ID = "SecondaryProductID";
        public const string PRODUCT_CATEGORY_ID = "ProductCategoryID";
        public const string PRODUCT_CATEGORY_NAME = "ProductCategoryName";
        public const string REQUIRED_FIELDS_FOR_DISPATCH = "RequiredFieldsForDispatch";
        public const string REQUIRED_FIELDS_FOR_ESTIMATE = "RequiredFieldsForEstimate";
        public const string ISP_LIST = "ISPList";
        public const string REJECTED_VENDORS = "RejectedVendors";
        public const string CURRENT_PURCHASE_ORDER = "CurrentPurchaseOrder";
        public const string CURRENT_PO_DETAILS = "CurrentPODetails";
        public const string VENDOR_INDEX_IN_LIST = "VendorIndexInList";
        public const string DEALER_ID_NUMBER = "DealerIDNumber";
        public const string IS_POSSIBLE_TOW = "IsPossibleTow";
        public const string IS_SMS_AVAILABLE = "IsSMSAvailable";
        public const string IS_DISPATCH_THRESHOLD_REACHED = "IsDispatchThresholdReached";
        public const string IS_CALL_MADE_TO_VENDOR = "IsCallMadeToVendor";
        public const string VENDOR_PHONE_NUMBER = "VendorPhoneNumber";
        public const string VENDOR_PHONE_TYPE = "VendorPhoneType";

        public const string SHOW_OPTIONS = "ShowOptions";
        public const string PRODUCT_OPTIONS = "ProductOptions";
        public const string ENABLE_ADD_VENDOR = "EnableAddVendor";

        public const string CALLS_MADE_SO_FAR = "CallsMadeSoFar";
        public const string IS_ALLOWED_TO_SEE_ISP_NOTCALLED = "IsAllowedToSeeISPNotCalled";
        public const string REJECT_VENDOR_ON_DISPATCH = "RejectVendorOnDispatch";

        public const string SERVICE_TECH_MODEL = "ServiceTechModel";
        public const string CLIENT_NAME = "ClientName";
        public const string CONTACT_LOG_ID = "ContactLogID";
        public const string TALKED_TO = "TalkedTo";
        public const string COMPANY = "Company";
        public const string OLD_DISPATCH_SEARCH_FILTERS = "OldDispatchSearchFilters";
        public const string ORGINAL_ISPS = "OrginalISPs";

        public const string HAGERTY_VEHICLES = "HagertyVehicles";

        public const string SERVICE_MILES = "ServiceMiles";
        public const string SERVICE_TIME_IN_MINUTES = "ServiceTimeInMinutes";
        public const string CLICK_TO_CALL_DEVICE_NAME = "ClickToCallDeviceName";
        public const string IS_CLICK_TO_CALL_ENABLED = "IsClickToCallEnabled";

        public const string SERVICE_TECH_COMMENT = "ServiceTechComment";
        public const string FULL_DISPATCH_ENABLED = "FullDispatchEnabled";


        public const string Is_Show_Add_Payment = "IsShowAddPayment";

        public const string SESSION_ACCESS_LIST = "LOGGED_IN_USER_ACCESS_LIST";

        public const string IS_FROM_HISTORY_LIST = "IsFromHistoryList";
        public const string Is_FROM_HISTORY_LIST_PO_ID = "IsFromHistoryListPOID";

        public const string HAGERTY_CHILD_PROGRAMS = "HAGERTY_CHILD_PROGRAMS";
        public const string ACES_CLIENT_FORD = "Ford";

        public const string DOCUMENT_CATEGORY_VENDOR = "VendorInvoice";
        public const string DOCUMENT_CATEGORY_CLAIM = "Claim";
        public const string CURRENT_HISTORY_PO_DETAILS = "CurrentHistoryPODetails";

        public const string PROGRAM_DETAILS = "ProgramDetails";  //Lakshmi - Hagerty Integration
        public const string IsAHagertyCallAfterPhoneSearch = "IsAHagertyCallAfterPhoneSearch";  //Lakshmi - Hagerty Integration

        public const string TAB_VALIDATION_STATUS = "TAB_VALIDATION_STATUS";
        public const string SERVICE_REQUEST_EXCEPTIONS = "SERVICE_REQUEST_EXCEPTIONS";

        public const string ACTIVE_REQUEST_LOCKED = "ActiveRequestLocked";
        public const string ACTIVE_SERVICE_REQUEST_ID = "ActiveServiceRequestId";
        public const string ACTIVE_REQUEST_LOCKED_BY_USER = "ActiveRequestLockedUser";


        public const string SET_VENDOR_IN_CONTEXT = "SetVendorInContext";
        public const string REQUEST_OPENED_TIME = "REQUEST_OPENED_TIME";
        public const string PRODUCT_PROVIDER_ID = "PRODUCT_PROVIDER_ID";
        public const string IS_CAPTURE_CLAIM_NUMBER = "IS_CAPTURE_CLAIM_NUMBER";
        public const string HAGERTY_MEMBERSHIP_NUMBER = "HAGERTY_MEMBERSHIP_NUMBER";
        public const string HAGERTY_MEMBER_SEARCH_CRITERIA = "HAGERTY_MEMBER_SEARCH_CRITERIA";

        public const string SR_AGENT_TIME = "SR_AGENT_TIME";

        public const string MEMBER_MOBILE = "MemberMobile";
        public const string NEXT_ACTION = "NextAction";
    }
}
