using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities
{
    public static class HttpMethods
    {
        public static string POST = "POST";
        public static string GET = "GET";
        public static string DELETE = "DELETE";
        public static string PUT = "PUT";

    }
    public static class OperationStatus
    {
        public static string SUCCESS = "Success";
        public static string ERROR = "Error";
        public static string INFO = "Info";

    }
    public static class ApplicationSettings
    {
        public static string BENEFIT_GUIDE_VIRTUAL_DIRECTORY_PATH = "BenefitGuideVirtualDirectoryPath";
        public static string MEMBER_SERVICES = "MemberServices";
        public static string PASSWORD_RESET_VALIDITY_IN_HOURS = "PasswordResetValidityInHours";
        public static string PRIVACY = "Privacy";
        public static string PRODUCT_IMAGE_VIRTUAL_DIRECTORY_PATH = "ProductImageVirtualDirectoryPath";
        public static string RESET_PASSWORD_LINK = "ResetPasswordLink";
        public static string TERMS = "Terms";
        public static string HELP = "Help";
    }
    public static class RestAPI
    {
        private static string URL_BASE = "https://api.pinnaclememberships.com/";
        //private static string URL_BASE = "http://192.168.0.15:907/";
        //private static string URL_BASE = "http://testapi.pinnaclememberships.com/";
        public static string URL_MEMBER = URL_BASE + "api/v1/Members";
        public static string URL_MEMBER_MEMBERSHIP = URL_BASE + "api/v1/Members/Membership";
        public static string URL_LOGIN = URL_BASE + "Members/Login";
        public static string URL_JOIN = URL_BASE + "api/v1/Members/Join";
        public static string URL_REGISTER_VERIFY = URL_BASE + "api/v1/Members/RegisterVerify";
        public static string URL_REGISTER = URL_BASE + "api/v1/Members/Register";
        public static string URL_RESET_PASSWORD = URL_BASE + "api/v1/Members/ResetPassword";
        public static string URL_SEND_USER_NAME = URL_BASE + "api/v1/Members/SendUserName";
        public static string URL_CHANGE_PASSWORD = URL_BASE + "api/v1/Members/ChangePassword";
        public static string URL_MEMBER_STATUS = URL_BASE + "api/v1/Members/{0}";
        public static string URL_MEMBER_VEHICLES = URL_BASE + "api/v1/Members/Vehicles";
        public static string URL_MEMBER_VEHICLE_DELETE = URL_BASE + "api/v1/Members/Vehicle";
        public static string URL_MEMBER_ASSOCIATES = URL_BASE + "api/v1/Members/Dependents";
        public static string URL_MEMBER_ACTIVE_REQUEST = URL_BASE + "api/v1/Members/History/ActiveRequest";
        public static string URL_MEMBER_HISTORY = URL_BASE + "api/v1/Members/History";
        public static string URL_MEMBER_SUBMIT_REQUEST = URL_BASE + "api/v1/Members/SubmitRequest";
        public static string URL_MEMBER_SUBMIT_REQUEST_CLOSELOOP = URL_BASE + "api/v1/Members/ServiceRequest/CloseLoop";

        public static string URL_MEMBER_ROADSIDE_VEHICLE_SERVICES = URL_BASE + "api/v1/RoadsideServices";
        public static string URL_MEMBER_ROADSIDE_VEHICLE_SERVICES_QUESTIONS = URL_BASE + "api/v1/RoadsideServices/Questions";

        public static string URL_MEMBER_VEHICLE_CHASSIS_LIST = URL_BASE + "api/v1/Members/DMSVehicleChassisList";
        public static string URL_MEMBER_VEHICLE_COLOR_LIST = URL_BASE + "api/v1/Members/DMSVehicleColorList";
        public static string URL_MEMBER_VEHICLE_ENGINE_LIST = URL_BASE + "api/v1/Members/DMSVehicleEngineList";
        public static string URL_MEMBER_VEHICLE_MAKE_LIST = URL_BASE + "api/v1/Members/DMSVehicleMakeList";
        public static string URL_MEMBER_VEHICLE_MODEL_LIST = URL_BASE + "api/v1/Members/DMSVehicleModelList";
        public static string URL_MEMBER_VEHICLE_TRANSMISSION_LIST = URL_BASE + "api/v1/Members/DMSVehicleTransmissionList";
        public static string URL_MEMBER_VEHICLE_TYPE_LIST = URL_BASE + "api/v1/Members/DMSVehicleTypeList";

        public static string URL_MEMBER_STATES_FOR_COUNTRY = URL_BASE + "api/v1/Members/StatesForCountry";
        public static string URL_MEMBER_COUNTRY_CODE = URL_BASE + "api/v1/Members/GetCountryCodes";
        public static string URL_MEMBER_COUNTRY = URL_BASE + "api/v1/Members/GetCountries";
        public static string URL_DEVICE_REGISTER = URL_BASE + "api/v1/Members/DeviceRegister";
        public static string URL_CONFIRM_ESTIMATE = URL_BASE + "api/v1/Members/ConfirmEstimate";
        public static string URL_CANCEL_ESTIMATE = URL_BASE + "api/v1/Members/CancelEstimate";
        public static string URL_DMS_MAKE_MODEL = URL_BASE + "api/v1/Members/GetDMSMakeModel";
        public static string URL_SEND_MEMBER_EMAIL = URL_BASE+"api/v1/Members/SendMemberEmail";

        public static string URL_MEMBER_APPLICATION_SETTINGS = URL_BASE + "api/v1/Members/GetApplicationSettings";
        public static string URL_MOBILE_STATIC_DATA_VERSIONS = URL_BASE + "api/v1/Members/MobileStaticDataVersions";
        //public static string URL_MOBILE_WORD_PRESS_POSTS = "https://www.pinnaclemotorclub.com/pmcmobile/wp-json/wp/v2/posts/?category_name=pmcapp";
        public static string URL_MOBILE_WORD_PRESS_POSTS = URL_BASE + "api/v1/Members/GetFeeds";

    }
    public static class Constants
    {
        public static bool IS_CONNECTED = true;
        public static string ORGANIZATION_ID = "7";
        public static string ORGANIZATION_NAME = "Pinnacle Motor Club";

        public static string ACCESS_TOKEN = string.Empty;
        public static string MEMBER_NUMBER = string.Empty;
        public static string MASTER_MEMBER_NUMBER = string.Empty;
        public static string MEMBER_FULL_NAME = string.Empty;
        public static string MEMBER_PLAN_NAME = string.Empty;
        public static string SOURCE_SYSTEM = "MemberMobile";
        public static bool IS_LOGGING_ENABLED = false;
        public static string X_API_KEY = "3c649fbbed000642181b173b8c43b814";

        public static string BING_API_KEY = "Ag37nsHBx8BxsIiXtl5qxfYNY7tt6s-aKky73p8iYA3vdZ8NDx3YCC7L1WWAgCEK";
        public static int ToastTimeSpan = 5;
        public static string DateFormat = "MM/dd/yyyy";

        public static string DateFormatForCard = "g";
        public static string DefaultAptifyDate = "1/1/1900";

        public static string APPLICATION_INSIGHT_ANDROID_KEY = "11951f38-09f1-46eb-a842-67bd2afa4b84";
        public static string APPLICATION_INSIGHT_iOS_KEY = "4869580e-badf-4fa8-9491-c63049f72bc3";
        public static string MEMBER_PROGRAM_ID = null;
        public static string MEMBER_FIRST_NAME = null;
        public static string MEMBER_LAST_NAME = null;
        public static string MEMBER_SERVICE_PHONE_NUMBER = null;
        public static string MEMBER_MEMBERSHIP_NUMBER = null;
        public static string MEMBER_SUBSCRIPTION_START_DATE = null;
        public static bool IS_ACTIVE = false;
        public static string BENEFIT_GUIDE_PDF = null;
        public static string DISPATCH_PHONE_NUMBER = null;
        public static string USER_NAME = null;
        public static bool IS_MASTER_MEMBER = false;
        public static bool IS_SHOW_MEMBER_LIST = false;
        public static bool IS_SHOW_ADD_MEMBER = false;
        public static long PersonID = 0;

        public static string PRODUCT_IMAGE = string.Empty;

        public static int FFIMAGE_VEHICLE_HEIGHT = 80;
        public static int FFIMAGE_VEHICLE_WIDTH = 80;

        public static double DEFAULT_LATITUDE = 39.023407;
        public static double DEFAULT_LONGITUDE = -104.784104;

        public enum LogType
        {
            INFO,
            ERROR,
            DEBUG
        }
        public enum EnumCreditCardAuthorizationType
        {
            Auth = 0,
            Capture = 2,
        }
        public enum enumCreditCardType
        {
            AmericanExpress = 0,
            Visa = 1,
            MasterCard = 2,
            Discover = 3,
        }
        public enum EnumPaymentTransactionType
        {
            CreditCard = 0,
            Check = 1,
        }
        public enum CreditCardCardType
        {
            NONE = 0,
            MC = 1,
            VS = 2,
            AE = 3,
            DS = 4,
        }
        public enum enumPersonRelationship
        {
            Associate = 0,
            Master = 1,
            Child = 2,
            Spouse = 3,
        }
        public enum enumAddressType
        {
            Primary = 0,
            Secondary = 1,
        }
        public enum enumPhoneType
        {
            Primary = 0,
            Home = 1,
            Cell = 2,
            Fax = 3,
            Pager = 4
        }
        public enum accountProfileMenu
        {
            Membership = 1,
            Members = 2,
            ChangePassword = 3,
            Other = 4
        }
        public enum DynamicFieldsControlType
        {
            Textbox,
            Dropdown,
            Combobox,
            Phone,
            Textarea,
            Datepicker,//TODO: Review and remove this.
            DatePicker,
            TirePicker,
            Checkbox,
            Radio
        }
        public enum DynamicFieldsDataType
        {
            Numeric, Text, Date, Email, Phone
        }

        public enum MemberType
        {
            MasterMember = 0,
            Dependent = 1,
        }
        public enum enumMemberEmailType 
        {
            
            ForgotUserName = 0,
            ForgotPassword = 1,
            WebAccountSetupConfirmation = 2,
            InvitationToRegister = 3
        }

        #region Push Notification Constants
        public const string GOOGLE_API_PROJECT_NUMBER = "514405748734";
        public const string AZURE_NOTIFICATION_LISTEN_CONNECTION_STRING = @"Endpoint=sb://membermobilenamespace.servicebus.windows.net/;SharedAccessKeyName=DefaultListenSharedAccessSignature;SharedAccessKey=Tv3AUn/+a4bEvMHTYkIYP95Eeq1F9ukKRBbM7R+z/Cc=";
        public const string AZURE_NOTIFICATION_HUB_NAME = @"membermobilehub";
        #endregion

        #region Registration Tags
        public static string TAG_MEMBER_NUMBER = "MemberNumber:";
        public static string TAG_MEMBERSHIP_NUMBER = "MembershipNumber:";
        #endregion

        #region Static Data Files
        public static string JSON_VEHICLE_COLOR_LIST = "ODISMember.StaticData.VehicleColorList.json";
        public static string JSON_VEHICLE_CHASSIS_LIST = "ODISMember.StaticData.VehicleChassisList.json";
        public static string JSON_VEHICLE_ENGINE_LIST = "ODISMember.StaticData.VehicleEngineList.json";
        public static string JSON_VEHICLE_TRANSMISSION_LIST = "ODISMember.StaticData.VehicleTransmissionList.json";
        public static string JSON_VEHICLE_COUNTRIES_LIST = "ODISMember.StaticData.CountriesList.json";

        public static string JSON_MOBILE_STATIC_DATA_VERSION_LIST = "ODISMember.StaticData.MobileStaticDataVersion.json";
        public static string JSON_APPLICATION_SETTINGS_LIST = string.Format("ODISMember.StaticData.ApplicationSettings{0}.json",Constants.ORGANIZATION_ID);

        public static string JSON_MAKE_MODEL_LIST = "ODISMember.StaticData.MakeModelList.json";
        #endregion
    }

    public static class PageNames
    {
        public static string LOGIN = "Login";
        public static string REGISTER_VERIFY = "Register Verify";
        public static string REGISTER = "Register";
        public static string FORGOT_USER_NAME = "Forgot User Name";
        public static string FORGOT_PASSWORD = "Forgot Password";

        public static string HOME = "Home";
        public static string MY_CARD = "My Card";
        public static string GET_HELP = "Get Help";
        public static string BENEFITS = "Benefits";

        public static string ACCOUNT = "Account";
        public static string ACCOUNT_MEMBERSHIP_DETAILS = "Account Membership Details";
        public static string ACCOUNT_MEMBERSHIP_EDIT = "Account Membership Edit";
        public static string ACCOUNT_MEMBERS = "Account Members";
        public static string ACCOUNT_MEMBER_DETAILS = "Account Member DETAILS";
        public static string ACCOUNT_MEMBER_ADD_EDIT = "Account Member ADD EDIT";
        public static string ACCOUNT_CHANGE_PASSWORD = "Account Change Password";

        public static string VEHICLES = "Vehicles";
        public static string VEHICLES_ADD = "Vehicles Add";
        public static string VEHICLE_DETAILS = "Vehicle Details";
        public static string VEHICLES_ADD_EDIT = "Vehicles Add/Edit";
    }
}
