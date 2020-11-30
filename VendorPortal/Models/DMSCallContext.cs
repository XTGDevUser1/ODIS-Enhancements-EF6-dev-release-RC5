using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.SessionState;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using System.Text;
using log4net;
using VendorPortal.Common;

namespace VendorPortal.Models
{
    public static class DMSCallContext
    {
        static ILog logger = LogManager.GetLogger(typeof(DMSCallContext));
        private static HttpSessionState Session
        {
            get
            {
                return HttpContext.Current.Session;
            }
        }
        public static CallInformation StartCallData
        {
            get { return Session[StringConstants.START_CALL_DATA] as CallInformation; }
            set { Session[StringConstants.START_CALL_DATA] = value; }
        }

        public static string ContactFirstName
        {
            get { return Session[StringConstants.CONTACT_FIRST_NAME] as string; }
            set { Session[StringConstants.CONTACT_FIRST_NAME] = value; }
        }

        

        public static string ContactLastName
        {
            get { return Session[StringConstants.CONTACT_LAST_NAME] as string; }
            set { Session[StringConstants.CONTACT_LAST_NAME] = value; }
        }

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

        public static string MemberStatus
        {
            get { return Session[StringConstants.MEMBER_STATUS] as string; }
            set { Session[StringConstants.MEMBER_STATUS] = value; }
        }

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

        public static string VehicleMake
        {
            get { return Session[StringConstants.VEHICLE_MAKE] as string; }
            set { Session[StringConstants.VEHICLE_MAKE] = value; }
        }

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

        public static decimal? ServiceMiles
        {
            get { return Session[StringConstants.SERVICE_MILES] as decimal?; }
            set { Session[StringConstants.SERVICE_MILES] = value; }
        }

        public static decimal? ServiceTimeInMinutes
        {
            get { return Session[StringConstants.SERVICE_TIME_IN_MINUTES] as decimal?; }
            set { Session[StringConstants.SERVICE_TIME_IN_MINUTES] = value; }
        }

        
        public static decimal? ServiceLocationLatitude
        {
            get { return Session[StringConstants.SERVICE_LOCATION_LATITUDE] as decimal?; }
            set { Session[StringConstants.SERVICE_LOCATION_LATITUDE] = value; }
        }

        public static decimal? ServiceLocationLongitude
        {
            get { return Session[StringConstants.SERVICE_LOCATION_LONGITUDE] as decimal?; }
            set { Session[StringConstants.SERVICE_LOCATION_LONGITUDE] = value; }
        }

        public static decimal? DestinationLatitude
        {
            get { return Session[StringConstants.DESTINATION_LATITUDE] as decimal?; }
            set { Session[StringConstants.DESTINATION_LATITUDE] = value; }
        }

        public static decimal? DestinationLongitude
        {
            get { return Session[StringConstants.DESTINATION_LONGITUDE] as decimal?; }
            set { Session[StringConstants.DESTINATION_LONGITUDE] = value; }
        }

        public static int? VehicleTypeID
        {
            get {  return Session[StringConstants.VEHICLE_TYPE_ID] as int?;  }
            set { Session[StringConstants.VEHICLE_TYPE_ID] = value; }
        }

        public static int? VehicleCategoryID
        {
            get { return Session[StringConstants.VEHICLE_CATEGORY_ID] as int?; }
            set { Session[StringConstants.VEHICLE_CATEGORY_ID] = value; }
        }

        public static int? PrimaryProductID
        {
            get { return Session[StringConstants.PRIMARY_PRODUCT_ID] as int?; }
            set { Session[StringConstants.PRIMARY_PRODUCT_ID] = value; }
        }
        public static int? SecondaryProductID
        {
            get { return Session[StringConstants.SECONDARY_PRODUCT_ID] as int?; }
            set { Session[StringConstants.SECONDARY_PRODUCT_ID] = value; }
        }

        public static int? ProductCategoryID
        {
            get { return Session[StringConstants.PRODUCT_CATEGORY_ID] as int?; }
            set { Session[StringConstants.PRODUCT_CATEGORY_ID] = value; }
        }

        public static string ProductCategoryName
        {
            get { return Session[StringConstants.PRODUCT_CATEGORY_NAME] as string; }
            set { Session[StringConstants.PRODUCT_CATEGORY_NAME] = value; }
        }

        public static List<ISPs_Result> ISPs
        {
            get { return Session[StringConstants.ISP_LIST] as List<ISPs_Result>; }
            set { Session[StringConstants.ISP_LIST] = value; }
        }

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

        public static string DealerIDNumber
        {
            get {
                return (string)Session[StringConstants.DEALER_ID_NUMBER];
            }
            set { Session[StringConstants.DEALER_ID_NUMBER] = value; }
        }

        public static string ServiceTechComments
        {
            get
            {
                return (string)Session[StringConstants.SERVICE_TECH_COMMENT];
            }
            set { Session[StringConstants.SERVICE_TECH_COMMENT] = value; }
        }

       
        public static void Reset()
        {
            AllowPaymentProcessing = false;
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
            //IsFromHistoryList = false;

            HagertyChildPrograms = null;

        }

        public static int VendorIndexInList
        {
            get { return Session[StringConstants.VENDOR_INDEX_IN_LIST] == null ? -1 : (int)Session[StringConstants.VENDOR_INDEX_IN_LIST]; }
            set { Session[StringConstants.VENDOR_INDEX_IN_LIST] = value; }
        }

        public static int CallsMadeSoFar
        {
            get { return Session[StringConstants.CALLS_MADE_SO_FAR] == null ? 0 : (int)Session[StringConstants.CALLS_MADE_SO_FAR]; }
            set { Session[StringConstants.CALLS_MADE_SO_FAR] = value; }
        }

        public static bool IsAllowedToSeeISPNotCalled
        {
            get { return Session[StringConstants.IS_ALLOWED_TO_SEE_ISP_NOTCALLED] == null ? false : (bool)Session[StringConstants.IS_ALLOWED_TO_SEE_ISP_NOTCALLED]; }
            set { Session[StringConstants.IS_ALLOWED_TO_SEE_ISP_NOTCALLED] = value; }
        }

        public static bool IsShowAddPayment
        {
            get { return Session[StringConstants.Is_Show_Add_Payment] == null ? false : (bool)Session[StringConstants.Is_Show_Add_Payment]; }
            set { Session[StringConstants.Is_Show_Add_Payment] = value; }
        }

        public static bool RejectVendorOnDispatch
        {
            get { return Session[StringConstants.REJECT_VENDOR_ON_DISPATCH] == null ? false : (bool)Session[StringConstants.REJECT_VENDOR_ON_DISPATCH]; }
            set { Session[StringConstants.REJECT_VENDOR_ON_DISPATCH] = value; }
        }

        public static bool IsPossibleTow
        {
            get { return Session[StringConstants.IS_POSSIBLE_TOW] == null ? false : (bool)Session[StringConstants.IS_POSSIBLE_TOW]; }
            set { Session[StringConstants.IS_POSSIBLE_TOW] = value; }
        }

        public static bool IsSMSAvailable
        {
            get { return Session[StringConstants.IS_SMS_AVAILABLE] == null ? false : (bool)Session[StringConstants.IS_SMS_AVAILABLE]; }
            set { Session[StringConstants.IS_SMS_AVAILABLE] = value; }
        }

        public static bool IsCallMadeToVendor
        {
            get { return Session[StringConstants.IS_CALL_MADE_TO_VENDOR] == null ? false : (bool)Session[StringConstants.IS_CALL_MADE_TO_VENDOR]; }
            set { Session[StringConstants.IS_CALL_MADE_TO_VENDOR] = value; }
        }

        public static string VendorPhoneNumber
        {
            get { return Session[StringConstants.VENDOR_PHONE_NUMBER] as string; }
            set { Session[StringConstants.VENDOR_PHONE_NUMBER] = value; }
        }

        public static string VendorPhoneType
        {
            get { return Session[StringConstants.VENDOR_PHONE_TYPE] as string; }
            set { Session[StringConstants.VENDOR_PHONE_TYPE] = value; }
        }

        public static string ClientName
        {
            get { return Session[StringConstants.CLIENT_NAME] as string; }
            set { Session[StringConstants.CLIENT_NAME] = value; }
        }

        public static int? ContactLogID
        {
            get { return Session[StringConstants.CONTACT_LOG_ID] as int?; }
            set { Session[StringConstants.CONTACT_LOG_ID] = value; }
        }

        public static string TalkedTo
        {
            get { return Session[StringConstants.TALKED_TO] as string; }
            set { Session[StringConstants.TALKED_TO] = value; }
        }

        public static string Company
        {
            get { return Session[StringConstants.COMPANY] as string; }
            set { Session[StringConstants.COMPANY] = value; }
        }

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

        public static List<ISPs_Result> OrginalISPs
        {
            get { return Session[StringConstants.ORGINAL_ISPS] as List<ISPs_Result>; }
            set { Session[StringConstants.ORGINAL_ISPS] = value; }
        }
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


        public static string ClickToCallDeviceName
        {
            get { return Session[StringConstants.CLICK_TO_CALL_DEVICE_NAME] as string; }
            set { Session[StringConstants.CLICK_TO_CALL_DEVICE_NAME] = value; }
        }

        public static bool IsClickToCallEnabled
        {
            get { return Session[StringConstants.IS_CLICK_TO_CALL_ENABLED] == null ? false : (bool)Session[StringConstants.IS_CLICK_TO_CALL_ENABLED]; }
            set { Session[StringConstants.IS_CLICK_TO_CALL_ENABLED] = value; }
        }

        public static List<Vehicles_Result> HagertyVehicles
        {
            get { return Session[StringConstants.HAGERTY_VEHICLES] as List<Vehicles_Result>; }
            set { Session[StringConstants.HAGERTY_VEHICLES] = value; }
        }

        public static List<ChildrenPrograms_Result> HagertyChildPrograms
        {
            get { return Session[StringConstants.HAGERTY_CHILD_PROGRAMS] as List<ChildrenPrograms_Result>; }
            set { Session[StringConstants.HAGERTY_CHILD_PROGRAMS] = value; }
        }

        public static bool IsAHagertyProgram
        {
            get
            {
                var list = HagertyChildPrograms;                
                if(HagertyChildPrograms != null && HagertyChildPrograms.Count > 0)
                {
                    int count = HagertyChildPrograms.Where(x => x.ProgramID == DMSCallContext.ProgramID).Count();
                    return count > 0;
                }
                return false;
            }
        }

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

        internal static void UpdateItemInOriginalISPList(ISPs_Result item)
        {
            var originalISPs = DMSCallContext.OrginalISPs;
            if (originalISPs != null && originalISPs.Count > 0)
            {
                ISPs_Result  matchedItem = null;
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
    }
}
