using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.SessionState;
using Martex.DMS.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using System.Text;
using log4net;
using System.Configuration;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.Areas.Application.Models
{
    /// <summary>
    /// DMS Call Context
    /// </summary>
    public static class DMSCallContext
    {
        #region Static Methods
        /// <summary>
        /// The logger
        /// </summary>
        static ILog logger = LogManager.GetLogger(typeof(DMSCallContext));
        #endregion

        #region Private Members
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
        #endregion

        #region Public Members
        /// <summary>
        /// Gets or sets the start call data.
        /// </summary>
        /// <value>
        /// The start call data.
        /// </value>
        ///

        public static string AmazonConnectID
        {
            get { return Session[StringConstants.AmazonConnectID] as string; }
            set { Session[StringConstants.AmazonConnectID] = value; }
        }

        public static int? LastVendorContactLogID
        {
            get { return Session[StringConstants.LastVendorContactLogID] as int?; }
            set { Session[StringConstants.LastVendorContactLogID] = value; }
        }
        public static string ConnectCallData
        {
            get { return Session[StringConstants.ConnectCallData] as string; }
            set { Session[StringConstants.ConnectCallData] = value; }
        }
        public static CallInformation StartCallData
        {
            get { return Session[StringConstants.START_CALL_DATA] as CallInformation; }
            set { Session[StringConstants.START_CALL_DATA] = value; }
        }

        public static string NextAction
        {
            get
            { return Session[StringConstants.NEXT_ACTION] as string; }
            set { Session[StringConstants.NEXT_ACTION] = value; }

        }
        public static string SourceSystemFromCase
        {
            get
            {
                var sourceSystem = Session[StringConstants.SOURCE_SYSTEM_FROM_CASE] as string;
                if (string.IsNullOrEmpty(sourceSystem))
                {
                    return SourceSystemName.DISPATCH;
                }
                return sourceSystem;
            }
            set { Session[StringConstants.SOURCE_SYSTEM_FROM_CASE] = value; }
        }

        /// <summary>
        /// Gets or sets the first name of the contact.
        /// </summary>
        /// <value>
        /// The first name of the contact.
        /// </value>
        public static string ContactFirstName
        {
            get { return Session[StringConstants.CONTACT_FIRST_NAME] as string; }
            set { Session[StringConstants.CONTACT_FIRST_NAME] = value; }
        }

        /// <summary>
        /// Gets or sets the last name of the contact.
        /// </summary>
        /// <value>
        /// The last name of the contact.
        /// </value>
        public static string ContactLastName
        {
            get { return Session[StringConstants.CONTACT_LAST_NAME] as string; }
            set { Session[StringConstants.CONTACT_LAST_NAME] = value; }
        }

        public static string ContactEmail
        {
            get { return Session[StringConstants.CONTACT_EMAIL] as string; }
            set { Session[StringConstants.CONTACT_EMAIL] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is delivery driver.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is delivery driver; otherwise, <c>false</c>.
        /// </value>
        public static bool IsDeliveryDriver
        {
            get
            {
                if (Session[StringConstants.IS_DELIVERY_DRIVER] != null)
                {
                    return (bool)Session[StringConstants.IS_DELIVERY_DRIVER];
                }
                return false;
            }

            set { Session[StringConstants.IS_DELIVERY_DRIVER] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether [allow payment processing].
        /// </summary>
        /// <value>
        /// <c>true</c> if [allow payment processing]; otherwise, <c>false</c>.
        /// </value>
        public static bool AllowPaymentProcessing
        {
            get
            {
                if (Session[StringConstants.ALLOW_PAYMENT_PROCESSING] != null)
                {
                    return (bool)Session[StringConstants.ALLOW_PAYMENT_PROCESSING];
                }
                return false;
            }

            set { Session[StringConstants.ALLOW_PAYMENT_PROCESSING] = value; }
        }

        public static bool AllowEstimateProcessing
        {
            get
            {
                if (Session[StringConstants.ALLOW_ESTIMATE_PROCESSING] != null)
                {
                    return (bool)Session[StringConstants.ALLOW_ESTIMATE_PROCESSING];
                }
                return false;
            }

            set { Session[StringConstants.ALLOW_ESTIMATE_PROCESSING] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether [show date of purchase].
        /// </summary>
        /// <value>
        ///   <c>true</c> if [show date of purchase]; otherwise, <c>false</c>.
        /// </value>
        public static bool ShowDateOfPurchase
        {
            get
            {
                if (Session[StringConstants.SHOW_DATE_OF_PURCHASE] != null)
                {
                    return (bool)Session[StringConstants.SHOW_DATE_OF_PURCHASE];
                }
                return false;
            }

            set { Session[StringConstants.SHOW_DATE_OF_PURCHASE] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether [show first owner].
        /// </summary>
        /// <value>
        ///   <c>true</c> if [show first owner]; otherwise, <c>false</c>.
        /// </value>
        public static bool ShowFirstOwner
        {
            get
            {
                if (Session[StringConstants.SHOW_FIRST_OWNER] != null)
                {
                    return (bool)Session[StringConstants.SHOW_FIRST_OWNER];
                }
                return false;
            }

            set { Session[StringConstants.SHOW_FIRST_OWNER] = value; }
        }

        /// <summary>
        /// Gets or sets the inbound call ID.
        /// </summary>
        /// <value>
        /// The inbound call ID.
        /// </value>
        public static int InboundCallID
        {
            get
            {
                if (Session[StringConstants.INBOUND_CALL_ID] != null)
                {
                    return (int)Session[StringConstants.INBOUND_CALL_ID];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.INBOUND_CALL_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets the case ID.
        /// </summary>
        /// <value>
        /// The case ID.
        /// </value>
        public static int CaseID
        {
            get
            {
                if (Session[StringConstants.CASE_ID] != null)
                {
                    return (int)Session[StringConstants.CASE_ID];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.CASE_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is from history list.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is from history list; otherwise, <c>false</c>.
        /// </value>
        public static bool IsFromHistoryList
        {
            get
            {
                if (Session[StringConstants.IS_FROM_HISTORY_LIST] != null)
                {
                    return (bool)Session[StringConstants.IS_FROM_HISTORY_LIST];
                }
                return false;
            }
            set
            {
                Session[StringConstants.IS_FROM_HISTORY_LIST] = value;
            }
        }

        /// <summary>
        /// Gets or sets the is from history list POID.
        /// </summary>
        /// <value>
        /// The is from history list POID.
        /// </value>
        public static int IsFromHistoryListPOID
        {
            get
            {
                if (Session[StringConstants.Is_FROM_HISTORY_LIST_PO_ID] != null)
                {
                    return (int)Session[StringConstants.Is_FROM_HISTORY_LIST_PO_ID];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.Is_FROM_HISTORY_LIST_PO_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets the service request ID.
        /// </summary>
        /// <value>
        /// The service request ID.
        /// </value>
        public static int ServiceRequestID
        {
            get
            {
                if (Session[StringConstants.SERVICE_REQUEST_ID] != null)
                {
                    return (int)Session[StringConstants.SERVICE_REQUEST_ID];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.SERVICE_REQUEST_ID] = value;
            }
        }


        public static decimal? ServiceEstimateFee
        {
            get
            {
                if (Session[StringConstants.SERVICE_ESTIMATE_FEE] != null)
                {
                    return (decimal?)Session[StringConstants.SERVICE_ESTIMATE_FEE];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.SERVICE_ESTIMATE_FEE] = value;
            }
        }

        /// <summary>
        /// Gets or sets the member ID.
        /// </summary>
        /// <value>
        /// The member ID.
        /// </value>
        public static int MemberID
        {
            get
            {
                if (Session[StringConstants.MEMBER_ID] != null)
                {
                    return (int)Session[StringConstants.MEMBER_ID];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.MEMBER_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets the member email.
        /// </summary>
        /// <value>
        /// The member email.
        /// </value>
        public static string MemberEmail
        {
            get
            {
                if (Session[StringConstants.MEMBER_EMAIL] != null)
                {
                    return Session[StringConstants.MEMBER_EMAIL].ToString();
                }
                return string.Empty;
            }
            set
            {
                Session[StringConstants.MEMBER_EMAIL] = value;
            }
        }


        /// <summary>
        /// Gets or sets the member home address country code.
        /// </summary>
        /// <value>
        /// The member home address country code.
        /// </value>
        public static string MemberHomeAddressCountryCode
        {
            get
            {
                if (Session[StringConstants.MEMBER_HOME_ADDRESS_COUNTRY_CODE] != null)
                {
                    return Session[StringConstants.MEMBER_HOME_ADDRESS_COUNTRY_CODE].ToString();
                }
                return string.Empty;
            }
            set
            {
                Session[StringConstants.MEMBER_HOME_ADDRESS_COUNTRY_CODE] = value;
            }
        }

        /// <summary>
        /// Gets or sets the membership ID.
        /// </summary>
        /// <value>
        /// The membership ID.
        /// </value>
        public static int MembershipID
        {
            get
            {
                if (Session[StringConstants.MEMBERSHIP_ID] != null)
                {
                    return (int)Session[StringConstants.MEMBERSHIP_ID];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.MEMBERSHIP_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets the member program ID.
        /// </summary>
        /// <value>
        /// The member program ID.
        /// </value>
        public static int MemberProgramID
        {
            get
            {
                if (Session[StringConstants.MEMBER_PROGRAM_ID] != null)
                {
                    return (int)Session[StringConstants.MEMBER_PROGRAM_ID];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.MEMBER_PROGRAM_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets the member status.
        /// </summary>
        /// <value>
        /// The member status.
        /// </value>
        public static string MemberStatus
        {
            get { return Session[StringConstants.MEMBER_STATUS] as string; }
            set { Session[StringConstants.MEMBER_STATUS] = value; }
        }

        /// <summary>
        /// Gets or sets the program ID.
        /// </summary>
        /// <value>
        /// The program ID.
        /// </value>
        public static int ProgramID
        {
            get
            {
                if (Session[StringConstants.PROGRAM_ID] != null)
                {
                    return (int)Session[StringConstants.PROGRAM_ID];
                }
                return 0;
            }
            set
            {
                Session[StringConstants.PROGRAM_ID] = value;
            }
        }

        public static string ProgramName
        {
            get
            {
                if (Session[StringConstants.PROGRAM_NAME] != null)
                {
                    return Session[StringConstants.PROGRAM_NAME].ToString();
                }
                return "";
            }
            set
            {
                Session[StringConstants.PROGRAM_NAME] = value;
            }
        }

        public static string ProgramParentName
        {
            get
            {
                if (Session[StringConstants.PROGRAM_PARENT_NAME] != null)
                {
                    return Session[StringConstants.PROGRAM_PARENT_NAME].ToString();
                }
                return "";
            }
            set
            {
                Session[StringConstants.PROGRAM_PARENT_NAME] = value;
            }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is mobile enabled.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is mobile enabled; otherwise, <c>false</c>.
        /// </value>
        public static bool IsMobileEnabled
        {
            get
            {
                if (Session[StringConstants.IS_MOBILE_ENABLED] != null)
                {
                    return (bool)Session[StringConstants.IS_MOBILE_ENABLED];
                }
                return false;
            }
            set { Session[StringConstants.IS_MOBILE_ENABLED] = value; }
        }

        /// <summary>
        /// Gets or sets the mobile call for service record.
        /// </summary>
        /// <value>
        /// The mobile call for service record.
        /// </value>
        public static MobileCallData_Result MobileCallForServiceRecord
        {
            get
            {
                return Session[StringConstants.MOBILE_CALL_FOR_SERVICE_RECORD] as MobileCallData_Result;
            }
            set
            {
                Session[StringConstants.MOBILE_CALL_FOR_SERVICE_RECORD] = value;
            }
        }

        /// <summary>
        /// Gets or sets the contact phone type ID.
        /// </summary>
        /// <value>
        /// The contact phone type ID.
        /// </value>
        public static int? ContactPhoneTypeID
        {
            get
            {
                return Session[StringConstants.CONTACT_PHONE_TYPE_ID] as int?;
            }
            set
            {
                Session[StringConstants.CONTACT_PHONE_TYPE_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets the last type of the updated vehicle.
        /// </summary>
        /// <value>
        /// The last type of the updated vehicle.
        /// </value>
        public static string LastUpdatedVehicleType
        {
            get
            {
                return Session[StringConstants.LAST_UPDATED_VEHICLE_TYPE] as string;
            }
            set
            {
                Session[StringConstants.LAST_UPDATED_VEHICLE_TYPE] = value;
            }
        }

        /// <summary>
        /// Gets or sets the vehicle year.
        /// </summary>
        /// <value>
        /// The vehicle year.
        /// </value>
        public static string VehicleYear
        {
            get
            {
                return Session[StringConstants.VEHICLE_YEAR] as string;
            }
            set
            {
                Session[StringConstants.VEHICLE_YEAR] = value;
            }
        }

        /// <summary>
        /// Gets or sets the callback number.
        /// </summary>
        /// <value>
        /// The callback number.
        /// </value>
        public static string CallbackNumber
        {
            get
            {
                return Session[StringConstants.CALLBACK_NUMBER] as string;
            }
            set
            {
                Session[StringConstants.CALLBACK_NUMBER] = value;
            }
        }

        /// <summary>
        /// Gets or sets the starting point.
        /// </summary>
        /// <value>
        /// The starting point.
        /// </value>
        public static string StartingPoint
        {
            get
            {
                return Session[StringConstants.STARTING_POINT] as string;
            }

            set
            {
                Session[StringConstants.STARTING_POINT] = value;
            }
        }

        /// <summary>
        /// Gets or sets the contact category ID.
        /// </summary>
        /// <value>
        /// The contact category ID.
        /// </value>
        public static int ContactCategoryID
        {
            get
            {
                if (Session[StringConstants.CONTACT_CATEGORY_ID] != null)
                {
                    return (int)Session[StringConstants.CONTACT_CATEGORY_ID];
                }
                return 0;

            }

            set
            {
                Session[StringConstants.CONTACT_CATEGORY_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets the payment ID.
        /// </summary>
        /// <value>
        /// The payment ID.
        /// </value>
        public static int PaymentID
        {
            get
            {
                if (Session[StringConstants.PAYMENT_ID] != null)
                {
                    return (int)Session[StringConstants.PAYMENT_ID];
                }
                return 0;

            }

            set
            {
                Session[StringConstants.PAYMENT_ID] = value;
            }
        }

        /// <summary>
        /// Gets or sets the vehicle make.
        /// </summary>
        /// <value>
        /// The vehicle make.
        /// </value>
        public static string VehicleMake
        {
            get { return Session[StringConstants.VEHICLE_MAKE] as string; }
            set { Session[StringConstants.VEHICLE_MAKE] = value; }
        }

        /// <summary>
        /// Gets or sets the vendor location ID.
        /// </summary>
        /// <value>
        /// The vendor location ID.
        /// </value>
        public static int VendorLocationID
        {
            get
            {
                if (Session[StringConstants.VENDOR_LOCATION_ID] != null)
                {
                    return (int)Session[StringConstants.VENDOR_LOCATION_ID];
                }
                return 0;
            }
            set { Session[StringConstants.VENDOR_LOCATION_ID] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is primary service covered.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is primary service covered; otherwise, <c>false</c>.
        /// </value>
        public static bool IsPrimaryServiceCovered
        {
            get
            {
                if (Session[StringConstants.IS_DISPATCH_THRESHOLD_REACHED] != null)
                {
                    return (bool)Session[StringConstants.IS_DISPATCH_THRESHOLD_REACHED];
                }
                return false;
            }
            set { Session[StringConstants.IS_DISPATCH_THRESHOLD_REACHED] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is dispatch threshold reached.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is dispatch threshold reached; otherwise, <c>false</c>.
        /// </value>
        public static bool IsDispatchThresholdReached
        {
            get
            {
                if (Session[StringConstants.IS_PRIMARY_SERVICE_COVERED] != null)
                {
                    return (bool)Session[StringConstants.IS_PRIMARY_SERVICE_COVERED];
                }
                return false;
            }
            set { Session[StringConstants.IS_PRIMARY_SERVICE_COVERED] = value; }
        }

        /// <summary>
        /// Gets or sets the member payment type ID.
        /// </summary>
        /// <value>
        /// The member payment type ID.
        /// </value>
        public static int? MemberPaymentTypeID
        {
            get
            {
                if (Session[StringConstants.MEMBER_PAYMENT_TYPE_ID] != null)
                {
                    return (int)Session[StringConstants.MEMBER_PAYMENT_TYPE_ID];
                }
                return null;
            }
            set { Session[StringConstants.MEMBER_PAYMENT_TYPE_ID] = value; }
        }

        /// <summary>
        /// Gets or sets the service miles.
        /// </summary>
        /// <value>
        /// The service miles.
        /// </value>
        public static decimal? ServiceMiles
        {
            get { return Session[StringConstants.SERVICE_MILES] as decimal?; }
            set { Session[StringConstants.SERVICE_MILES] = value; }
        }

        /// <summary>
        /// Gets or sets the service time in minutes.
        /// </summary>
        /// <value>
        /// The service time in minutes.
        /// </value>
        public static decimal? ServiceTimeInMinutes
        {
            get { return Session[StringConstants.SERVICE_TIME_IN_MINUTES] as decimal?; }
            set { Session[StringConstants.SERVICE_TIME_IN_MINUTES] = value; }
        }


        /// <summary>
        /// Gets or sets the service location latitude.
        /// </summary>
        /// <value>
        /// The service location latitude.
        /// </value>
        public static decimal? ServiceLocationLatitude
        {
            get { return Session[StringConstants.SERVICE_LOCATION_LATITUDE] as decimal?; }
            set { Session[StringConstants.SERVICE_LOCATION_LATITUDE] = value; }
        }

        /// <summary>
        /// Gets or sets the service location longitude.
        /// </summary>
        /// <value>
        /// The service location longitude.
        /// </value>
        public static decimal? ServiceLocationLongitude
        {
            get { return Session[StringConstants.SERVICE_LOCATION_LONGITUDE] as decimal?; }
            set { Session[StringConstants.SERVICE_LOCATION_LONGITUDE] = value; }
        }

        /// <summary>
        /// Gets or sets the destination latitude.
        /// </summary>
        /// <value>
        /// The destination latitude.
        /// </value>
        public static decimal? DestinationLatitude
        {
            get { return Session[StringConstants.DESTINATION_LATITUDE] as decimal?; }
            set { Session[StringConstants.DESTINATION_LATITUDE] = value; }
        }

        /// <summary>
        /// Gets or sets the destination longitude.
        /// </summary>
        /// <value>
        /// The destination longitude.
        /// </value>
        public static decimal? DestinationLongitude
        {
            get { return Session[StringConstants.DESTINATION_LONGITUDE] as decimal?; }
            set { Session[StringConstants.DESTINATION_LONGITUDE] = value; }
        }

        /// <summary>
        /// Gets or sets the vehicle type ID.
        /// </summary>
        /// <value>
        /// The vehicle type ID.
        /// </value>
        public static int? VehicleTypeID
        {
            get { return Session[StringConstants.VEHICLE_TYPE_ID] as int?; }
            set { Session[StringConstants.VEHICLE_TYPE_ID] = value; }
        }

        /// <summary>
        /// Gets or sets the vehicle category ID.
        /// </summary>
        /// <value>
        /// The vehicle category ID.
        /// </value>
        public static int? VehicleCategoryID
        {
            get { return Session[StringConstants.VEHICLE_CATEGORY_ID] as int?; }
            set { Session[StringConstants.VEHICLE_CATEGORY_ID] = value; }
        }

        /// <summary>
        /// Gets or sets the primary product ID.
        /// </summary>
        /// <value>
        /// The primary product ID.
        /// </value>
        public static int? PrimaryProductID
        {
            get { return Session[StringConstants.PRIMARY_PRODUCT_ID] as int?; }
            set { Session[StringConstants.PRIMARY_PRODUCT_ID] = value; }
        }

        /// <summary>
        /// Gets or sets the secondary product ID.
        /// </summary>
        /// <value>
        /// The secondary product ID.
        /// </value>
        public static int? SecondaryProductID
        {
            get { return Session[StringConstants.SECONDARY_PRODUCT_ID] as int?; }
            set { Session[StringConstants.SECONDARY_PRODUCT_ID] = value; }
        }

        /// <summary>
        /// Gets or sets the product category ID.
        /// </summary>
        /// <value>
        /// The product category ID.
        /// </value>
        public static int? ProductCategoryID
        {
            get { return Session[StringConstants.PRODUCT_CATEGORY_ID] as int?; }
            set { Session[StringConstants.PRODUCT_CATEGORY_ID] = value; }
        }

        /// <summary>
        /// Gets or sets the name of the product category.
        /// </summary>
        /// <value>
        /// The name of the product category.
        /// </value>
        public static string ProductCategoryName
        {
            get { return Session[StringConstants.PRODUCT_CATEGORY_NAME] as string; }
            set { Session[StringConstants.PRODUCT_CATEGORY_NAME] = value; }
        }

        /// <summary>
        /// Gets or sets the IS ps.
        /// </summary>
        /// <value>
        /// The IS ps.
        /// </value>
        public static List<ISPs_Result> ISPs
        {
            get { return Session[StringConstants.ISP_LIST] as List<ISPs_Result>; }
            set { Session[StringConstants.ISP_LIST] = value; }
        }

        /// <summary>
        /// Gets or sets the current purchase order.
        /// </summary>
        /// <value>
        /// The current purchase order.
        /// </value>
        public static PurchaseOrder CurrentPurchaseOrder
        {
            get
            {
                if (Session[StringConstants.CURRENT_PURCHASE_ORDER] != null)
                {
                    return (PurchaseOrder)Session[StringConstants.CURRENT_PURCHASE_ORDER];
                }
                return null;
            }
            set
            {
                Session[StringConstants.CURRENT_PURCHASE_ORDER] = value;
            }

        }

        /// <summary>
        /// Gets or sets the current PO details.
        /// </summary>
        /// <value>
        /// The current PO details.
        /// </value>
        public static List<PurchaseOrderDetailsModel> CurrentPODetails
        {
            get
            {
                if (Session[StringConstants.CURRENT_PO_DETAILS] != null)
                {
                    return (List<PurchaseOrderDetailsModel>)Session[StringConstants.CURRENT_PO_DETAILS];
                }
                return new List<PurchaseOrderDetailsModel>();
            }
            set
            {
                Session[StringConstants.CURRENT_PO_DETAILS] = value;
            }
        }

        public static Dictionary<int, List<PurchaseOrderDetailsModel>> CurrentHistoryPODetails
        {
            get
            {
                if (Session[StringConstants.CURRENT_HISTORY_PO_DETAILS] != null)
                {
                    return (Dictionary<int, List<PurchaseOrderDetailsModel>>)Session[StringConstants.CURRENT_HISTORY_PO_DETAILS];
                }
                return new Dictionary<int, List<PurchaseOrderDetailsModel>>();
            }
            set
            {
                Session[StringConstants.CURRENT_HISTORY_PO_DETAILS] = value;
            }
        }
        /// <summary>
        /// Gets or sets the dealer ID number.
        /// </summary>
        /// <value>
        /// The dealer ID number.
        /// </value>
        public static string DealerIDNumber
        {
            get
            {
                return (string)Session[StringConstants.DEALER_ID_NUMBER];
            }
            set { Session[StringConstants.DEALER_ID_NUMBER] = value; }
        }

        /// <summary>
        /// Gets or sets the service tech comments.
        /// </summary>
        /// <value>
        /// The service tech comments.
        /// </value>
        public static string ServiceTechComments
        {
            get
            {
                return (string)Session[StringConstants.SERVICE_TECH_COMMENT];
            }
            set { Session[StringConstants.SERVICE_TECH_COMMENT] = value; }
        }

        public static bool ActiveRequestLocked
        {
            get
            {
                if (Session[StringConstants.ACTIVE_REQUEST_LOCKED] != null)
                {
                    return (bool)Session[StringConstants.ACTIVE_REQUEST_LOCKED];
                }
                return false;
            }
            set { Session[StringConstants.ACTIVE_REQUEST_LOCKED] = value; }
        }

        public static int? ActiveServiceRequestId
        {
            get { return Session[StringConstants.ACTIVE_SERVICE_REQUEST_ID] as int?; }
            set { Session[StringConstants.ACTIVE_SERVICE_REQUEST_ID] = value; }
        }

        public static int? ActiveRequestLockedByUser
        {
            get { return Session[StringConstants.ACTIVE_REQUEST_LOCKED_BY_USER] as int?; }
            set { Session[StringConstants.ACTIVE_REQUEST_LOCKED_BY_USER] = value; }
        }


        /// <summary>
        /// Resets this instance.
        /// </summary>
        public static void Reset()
        {
            #region Reset values
            AllowPaymentProcessing = false;
            AllowEstimateProcessing = false;
            CallbackNumber = null;
            CallsMadeSoFar = 0;
            CaseID = 0;
            ClientName = null;
            Company = null;
            ContactCategoryID = 0;
            ContactFirstName = null;
            ContactLastName = null;
            ContactLogID = null;
            ContactPhoneTypeID = null;
            CurrentPODetails = null;
            CurrentPurchaseOrder = null;
            DealerIDNumber = null;
            DestinationLatitude = null;
            DestinationLongitude = null;
            InboundCallID = 0;
            IsAllowedToSeeISPNotCalled = false;
            IsDeliveryDriver = false;
            IsMobileEnabled = false;
            IsPossibleTow = false;
            IsPrimaryServiceCovered = false;
            ISPs = null;
            OrginalISPs = null;

            LastUpdatedVehicleType = null;
            VehicleYear = null;
            MemberID = 0;
            MemberPaymentTypeID = null;
            MemberStatus = null;
            MembershipID = 0;
            MobileCallForServiceRecord = null;
            PaymentID = 0;
            PrimaryProductID = null;
            ProductCategoryID = null;
            ProductCategoryName = null;
            ProgramID = 0;
            RejectVendorOnDispatch = false;
            SecondaryProductID = null;
            ServiceLocationLatitude = null;
            ServiceLocationLongitude = null;
            ServiceRequestID = 0;
            ServiceEstimateFee = null;
            StartCallData = null;
            StartingPoint = null;
            TalkedTo = null;
            VehicleCategoryID = null;
            VehicleMake = null;
            VehicleTypeID = null;
            VendorIndexInList = 0;
            ServiceMiles = null;
            ServiceTimeInMinutes = null;
            IsDispatchThresholdReached = false;

            IsCallMadeToVendor = false;
            VendorIndexInList = -1;
            VendorPhoneNumber = null;
            VendorPhoneType = null;
            MemberEmail = string.Empty;
            IsFromHistoryListPOID = 0;

            HagertyChildPrograms = null;

            HagertyCallAfterPhoneSearch = false;   //Lakshmi - Hagerty Integration
            GetProgramDetails = null;               //Lakshmi - Hagerty Integration
            HagertyMemberSearchCriteria = string.Empty;    //Lakshmi - Hagerty Integration
            HagertyMembershipNo = string.Empty; //Lakshmi - Hagerty Integration

            ActiveRequestLocked = false;
            ActiveServiceRequestId = null;
            ActiveRequestLockedByUser = null;
            IsCaptureClaimNumber = false;
            ProductProviderID = null;
            RequestOpenedTime = null;
            SetVendorInContext = false;

            SRAgentTime = null;
            SourceSystemFromCase = null;
            NextAction = null;

            #endregion
        }

        /// <summary>
        /// Gets or sets the vendor index in list.
        /// </summary>
        /// <value>
        /// The vendor index in list.
        /// </value>
        public static int VendorIndexInList
        {
            get { return Session[StringConstants.VENDOR_INDEX_IN_LIST] == null ? -1 : (int)Session[StringConstants.VENDOR_INDEX_IN_LIST]; }
            set { Session[StringConstants.VENDOR_INDEX_IN_LIST] = value; }
        }

        /// <summary>
        /// Gets or sets the calls made so far.
        /// </summary>
        /// <value>
        /// The calls made so far.
        /// </value>
        public static int CallsMadeSoFar
        {
            get { return Session[StringConstants.CALLS_MADE_SO_FAR] == null ? 0 : (int)Session[StringConstants.CALLS_MADE_SO_FAR]; }
            set { Session[StringConstants.CALLS_MADE_SO_FAR] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is allowed to see ISP not called.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is allowed to see ISP not called; otherwise, <c>false</c>.
        /// </value>
        public static bool IsAllowedToSeeISPNotCalled
        {
            get { return Session[StringConstants.IS_ALLOWED_TO_SEE_ISP_NOTCALLED] == null ? false : (bool)Session[StringConstants.IS_ALLOWED_TO_SEE_ISP_NOTCALLED]; }
            set { Session[StringConstants.IS_ALLOWED_TO_SEE_ISP_NOTCALLED] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is show add payment.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is show add payment; otherwise, <c>false</c>.
        /// </value>
        public static bool IsShowAddPayment
        {
            get { return Session[StringConstants.Is_Show_Add_Payment] == null ? false : (bool)Session[StringConstants.Is_Show_Add_Payment]; }
            set { Session[StringConstants.Is_Show_Add_Payment] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether [reject vendor on dispatch].
        /// </summary>
        /// <value>
        /// <c>true</c> if [reject vendor on dispatch]; otherwise, <c>false</c>.
        /// </value>
        public static bool RejectVendorOnDispatch
        {
            get { return Session[StringConstants.REJECT_VENDOR_ON_DISPATCH] == null ? false : (bool)Session[StringConstants.REJECT_VENDOR_ON_DISPATCH]; }
            set { Session[StringConstants.REJECT_VENDOR_ON_DISPATCH] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is possible tow.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is possible tow; otherwise, <c>false</c>.
        /// </value>
        public static bool IsPossibleTow
        {
            get { return Session[StringConstants.IS_POSSIBLE_TOW] == null ? false : (bool)Session[StringConstants.IS_POSSIBLE_TOW]; }
            set { Session[StringConstants.IS_POSSIBLE_TOW] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is SMS available.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is SMS available; otherwise, <c>false</c>.
        /// </value>
        public static bool IsSMSAvailable
        {
            get { return Session[StringConstants.IS_SMS_AVAILABLE] == null ? false : (bool)Session[StringConstants.IS_SMS_AVAILABLE]; }
            set { Session[StringConstants.IS_SMS_AVAILABLE] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is call made to vendor.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is call made to vendor; otherwise, <c>false</c>.
        /// </value>
        public static bool IsCallMadeToVendor
        {
            get { return Session[StringConstants.IS_CALL_MADE_TO_VENDOR] == null ? false : (bool)Session[StringConstants.IS_CALL_MADE_TO_VENDOR]; }
            set { Session[StringConstants.IS_CALL_MADE_TO_VENDOR] = value; }
        }

        /// <summary>
        /// Gets or sets the vendor phone number.
        /// </summary>
        /// <value>
        /// The vendor phone number.
        /// </value>
        public static string VendorPhoneNumber
        {
            get { return Session[StringConstants.VENDOR_PHONE_NUMBER] as string; }
            set { Session[StringConstants.VENDOR_PHONE_NUMBER] = value; }
        }

        /// <summary>
        /// Gets or sets the type of the vendor phone.
        /// </summary>
        /// <value>
        /// The type of the vendor phone.
        /// </value>
        public static string VendorPhoneType
        {
            get { return Session[StringConstants.VENDOR_PHONE_TYPE] as string; }
            set { Session[StringConstants.VENDOR_PHONE_TYPE] = value; }
        }

        /// <summary>
        /// Gets or sets the name of the client.
        /// </summary>
        /// <value>
        /// The name of the client.
        /// </value>
        public static string ClientName
        {
            get { return Session[StringConstants.CLIENT_NAME] as string; }
            set { Session[StringConstants.CLIENT_NAME] = value; }
        }

        /// <summary>
        /// Gets or sets the contact log ID.
        /// </summary>
        /// <value>
        /// The contact log ID.
        /// </value>
        public static int? ContactLogID
        {
            get { return Session[StringConstants.CONTACT_LOG_ID] as int?; }
            set { Session[StringConstants.CONTACT_LOG_ID] = value; }
        }

        /// <summary>
        /// Gets or sets the talked to.
        /// </summary>
        /// <value>
        /// The talked to.
        /// </value>
        public static string TalkedTo
        {
            get { return Session[StringConstants.TALKED_TO] as string; }
            set { Session[StringConstants.TALKED_TO] = value; }
        }

        /// <summary>
        /// Gets or sets the company.
        /// </summary>
        /// <value>
        /// The company.
        /// </value>
        public static string Company
        {
            get { return Session[StringConstants.COMPANY] as string; }
            set { Session[StringConstants.COMPANY] = value; }
        }

        /// <summary>
        /// Gets or sets the old dispatch search filters.
        /// </summary>
        /// <value>
        /// The old dispatch search filters.
        /// </value>
        public static VendorSearchFilters OldDispatchSearchFilters
        {
            get
            {
                if (Session[StringConstants.OLD_DISPATCH_SEARCH_FILTERS] != null)
                {
                    return Session[StringConstants.OLD_DISPATCH_SEARCH_FILTERS] as VendorSearchFilters;
                }
                return new VendorSearchFilters();
            }

            set { Session[StringConstants.OLD_DISPATCH_SEARCH_FILTERS] = value; }
        }

        /// <summary>
        /// Gets or sets the original IS ps.
        /// </summary>
        /// <value>
        /// The original IS ps.
        /// </value>
        public static List<ISPs_Result> OrginalISPs
        {
            get { return Session[StringConstants.ORGINAL_ISPS] as List<ISPs_Result>; }
            set { Session[StringConstants.ORGINAL_ISPS] = value; }
        }

        /// <summary>
        /// Gets or sets the rejected vendors.
        /// </summary>
        /// <value>
        /// The rejected vendors.
        /// </value>
        public static List<ISPs_Result> RejectedVendors
        {
            get
            {
                if (Session[StringConstants.REJECTED_VENDORS] == null)
                {
                    Session[StringConstants.REJECTED_VENDORS] = new List<ISPs_Result>();
                }
                return Session[StringConstants.REJECTED_VENDORS] as List<ISPs_Result>;
            }
            set { Session[StringConstants.REJECTED_VENDORS] = value; }
        }


        /// <summary>
        /// Gets or sets the name of the click to call device.
        /// </summary>
        /// <value>
        /// The name of the click to call device.
        /// </value>
        public static string ClickToCallDeviceName
        {
            get { return Session[StringConstants.CLICK_TO_CALL_DEVICE_NAME] as string; }
            set { Session[StringConstants.CLICK_TO_CALL_DEVICE_NAME] = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is click to call enabled.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is click to call enabled; otherwise, <c>false</c>.
        /// </value>
        public static bool IsClickToCallEnabled
        {
            get { return Session[StringConstants.IS_CLICK_TO_CALL_ENABLED] == null ? false : (bool)Session[StringConstants.IS_CLICK_TO_CALL_ENABLED]; }
            set { Session[StringConstants.IS_CLICK_TO_CALL_ENABLED] = value; }
        }

        /// <summary>
        /// Gets or sets the hagerty vehicles.
        /// </summary>
        /// <value>
        /// The hagerty vehicles.
        /// </value>
        public static List<Vehicles_Result> HagertyVehicles
        {
            get { return Session[StringConstants.HAGERTY_VEHICLES] as List<Vehicles_Result>; }
            set { Session[StringConstants.HAGERTY_VEHICLES] = value; }
        }

        /// <summary>
        /// Gets or sets the hagerty child programs.
        /// </summary>
        /// <value>
        /// The hagerty child programs.
        /// </value>
        public static List<ChildrenPrograms_Result> HagertyChildPrograms
        {
            get { return Session[StringConstants.HAGERTY_CHILD_PROGRAMS] as List<ChildrenPrograms_Result>; }
            set { Session[StringConstants.HAGERTY_CHILD_PROGRAMS] = value; }
        }

        /// <summary>
        /// Gets a value indicating whether this instance is A hagerty program.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is A hagerty program; otherwise, <c>false</c>.
        /// </value>
        public static bool IsAHagertyProgram
        {
            get
            {
                var list = HagertyChildPrograms;
                if (HagertyChildPrograms != null && HagertyChildPrograms.Count > 0)
                {
                    int count = HagertyChildPrograms.Where(x => x.ProgramID == DMSCallContext.ProgramID).Count();
                    return count > 0;
                }
                return false;
            }
        }

        //Lakshmi - Hagerty Integeration
        //Not used.
        /// <summary>
        /// Gets or sets program info.
        /// </summary>
        public static Program GetProgramDetails
        {
            get { return Session[StringConstants.PROGRAM_DETAILS] as Program; }
            set { Session[StringConstants.PROGRAM_DETAILS] = value; }
        }

        //Lakshmi - Hagerty Integeration
        /// <summary>
        /// Gets a value indicating whether this instance is A hagerty Parent program.
        /// </summary>
        ///   <value>
        /// <c>true</c> if this instance is A hagerty parent program; otherwise, <c>false</c>.
        /// </value>
        public static bool IsAHagertyParentProgram
        {
            get
            {
                System.Configuration.Configuration rootWebConfig =
                System.Web.Configuration.WebConfigurationManager.OpenWebConfiguration("/Web.config");
                if (rootWebConfig.AppSettings.Settings.Count > 0)
                {
                    System.Configuration.KeyValueConfigurationElement hagertyParentPgmID =
                        rootWebConfig.AppSettings.Settings["HagertyParentProgramID"];
                    if (hagertyParentPgmID != null)
                    {
                        if (Convert.ToInt32(hagertyParentPgmID.Value) == DMSCallContext.ProgramID)
                        {
                            return true;
                        }
                        else
                        {
                            return false;
                        }
                    }
                    else
                    {
                        return false;
                    }
                }
                return false;
            }
        }

        public static bool CheckIfHagertyParentProgram(int ProgramID)
        {

            System.Configuration.Configuration rootWebConfig =
            System.Web.Configuration.WebConfigurationManager.OpenWebConfiguration("/Web.config");
            if (rootWebConfig.AppSettings.Settings.Count > 0)
            {
                System.Configuration.KeyValueConfigurationElement hagertyParentPgmID =
                    rootWebConfig.AppSettings.Settings["HagertyParentProgramID"];
                if (hagertyParentPgmID != null)
                {
                    if (Convert.ToInt32(hagertyParentPgmID.Value) == ProgramID)
                    {
                        return true;
                    }
                    else
                    {
                        return false;
                    }
                }
                else
                {
                    return false;
                }
            }
            return false;

        }

        //Lakshmi - Hagerty Integeration
        public static string GetHagertyParentProgramID
        {
            get
            {
                System.Configuration.Configuration rootWebConfig =
                System.Web.Configuration.WebConfigurationManager.OpenWebConfiguration("/Web.config");
                if (rootWebConfig.AppSettings.Settings.Count > 0)
                {
                    System.Configuration.KeyValueConfigurationElement hagertyParentPgmID =
                        rootWebConfig.AppSettings.Settings["HagertyParentProgramID"];
                    if (hagertyParentPgmID != null)
                    {
                        return hagertyParentPgmID.Value;
                    }
                    else
                    {
                        return string.Empty;
                    }
                }
                return string.Empty;
            }
        }

        //Lakshmi - Hagerty Integeration
        /// <summary>
        /// Gets or sets a value indicating whether this instance call is after Hagerty Member phone search.
        /// </summary>
        ///   <value>
        /// <c>true</c> if this instance call is after Hagerty Member phone search; otherwise, <c>false</c>.
        /// </value>
        public static bool HagertyCallAfterPhoneSearch
        {
            get
            {
                if (Session[StringConstants.IsAHagertyCallAfterPhoneSearch] != null)
                {
                    return (bool)Session[StringConstants.IsAHagertyCallAfterPhoneSearch];
                }
                return false;
            }

            set { Session[StringConstants.IsAHagertyCallAfterPhoneSearch] = value; }
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets or sets the values of Hagerty Member Search.
        /// </summary>
        /// <value>
        /// The values of Hagerty Member Search.
        /// </value>
        public static string HagertyMemberSearchCriteria
        {
            get { return Session[StringConstants.HAGERTY_MEMBER_SEARCH_CRITERIA] as string; }
            set { Session[StringConstants.HAGERTY_MEMBER_SEARCH_CRITERIA] = value; }
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets or sets the search value of Hagerty Membership Number.
        /// </summary>
        /// <value>
        /// The value of Hagerty Membership Number.
        /// </value>
        public static string HagertyMembershipNo
        {
            get { return Session[StringConstants.HAGERTY_MEMBERSHIP_NUMBER] as string; }
            set { Session[StringConstants.HAGERTY_MEMBERSHIP_NUMBER] = value; }
        }

        //Lakshmi - Hagerty Integration
        public static bool HagertyIntegrationConfigFlag
        {
            get
            {
                System.Configuration.Configuration rootWebConfig =
                System.Web.Configuration.WebConfigurationManager.OpenWebConfiguration("/Web.config");
                if (rootWebConfig.AppSettings.Settings.Count > 0)
                {
                    System.Configuration.KeyValueConfigurationElement hagertyServiceFlag =
                        rootWebConfig.AppSettings.Settings["HagertyIntegration"];
                    if (hagertyServiceFlag != null)
                    {
                        return Convert.ToBoolean(hagertyServiceFlag.Value);
                    }
                    else
                    {
                        return false;
                    }
                }
                return false;
            }
        }

        public static bool IsCaptureClaimNumber
        {
            get
            {
                if (Session[StringConstants.IS_CAPTURE_CLAIM_NUMBER] != null)
                {
                    return (bool)Session[StringConstants.IS_CAPTURE_CLAIM_NUMBER];
                }
                return false;
            }

            set { Session[StringConstants.IS_CAPTURE_CLAIM_NUMBER] = value; }
        }

        public static bool SetVendorInContext
        {
            get
            {
                if (Session[StringConstants.SET_VENDOR_IN_CONTEXT] != null)
                {
                    return (bool)Session[StringConstants.SET_VENDOR_IN_CONTEXT];
                }
                return false;
            }

            set { Session[StringConstants.SET_VENDOR_IN_CONTEXT] = value; }
        }

        public static int? ProductProviderID
        {
            get { return Session[StringConstants.PRODUCT_PROVIDER_ID] as int?; }
            set { Session[StringConstants.PRODUCT_PROVIDER_ID] = value; }
        }

        public static DateTime? RequestOpenedTime
        {
            get { return Session[StringConstants.REQUEST_OPENED_TIME] as DateTime?; }
            set { Session[StringConstants.REQUEST_OPENED_TIME] = value; }
        }

        public static ServiceRequestAgentTime SRAgentTime
        {
            get { return Session[StringConstants.SR_AGENT_TIME] as ServiceRequestAgentTime; }
            set { Session[StringConstants.SR_AGENT_TIME] = value; }
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Logs the call context.
        /// </summary>
        public static void LogCallContext()
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("Service Request ID : {0}", ServiceRequestID).AppendLine();
            sb.AppendFormat("Case ID : {0}", CaseID).AppendLine();
            sb.AppendFormat("Program ID : {0}", ProgramID).AppendLine();
            sb.AppendFormat("Vehicle Type ID : {0}", VehicleTypeID).AppendLine();
            sb.AppendFormat("Vehicle Category ID : {0}", VehicleCategoryID).AppendLine();

            logger.Info(" ==== BEGIN : DMS call context =====");
            logger.Info(sb.ToString());
            logger.Info(" ==== END : DMS call context =====");
        }
        #endregion

        #region Intrernal Methods
        /// <summary>
        /// Updates the item in original ISP list.
        /// </summary>
        /// <param name="item">The item.</param>
        internal static void UpdateItemInOriginalISPList(ISPs_Result item)
        {
            var originalISPs = DMSCallContext.OrginalISPs;
            if (originalISPs != null && originalISPs.Count > 0)
            {
                ISPs_Result matchedItem = null;
                for (int i = 0, l = originalISPs.Count; i < l; i++)
                {
                    var currentItem = originalISPs[i];
                    if (currentItem.VendorID == item.VendorID && currentItem.VendorLocationID == item.VendorLocationID)
                    {
                        matchedItem = currentItem;
                        break;
                    }
                }
                if (matchedItem != null)
                {
                    matchedItem.CallStatus = item.CallStatus;
                    matchedItem.RejectReason = item.RejectReason;
                    matchedItem.RejectComment = item.RejectComment;
                    matchedItem.Comment = item.Comment;
                    matchedItem.IsPossibleCallback = item.IsPossibleCallback;
                }
            }
        }
        #endregion
    }
}
