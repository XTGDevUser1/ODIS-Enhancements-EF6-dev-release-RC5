using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Common;

using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using System.Text;
using System.Web.Security;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.ActionFilters
{
    /// <summary>
    /// Static Data enumeration - to hold constants for reference data
    /// </summary>
    public enum StaticData
    {
        FeedbackTypes,
        Priorities,
        Organizations,
        UserRoles,
        DataGroups,
        Clients,
        Province,
        AddressProvince,
        Address1Province,
        IvrScript,
        InBoundPhoneCompany,
        SkillSet,
        Programs,
        Country,
        VehicleType,
        VehicleModelYear,
        VehicleMake,
        VehicleModel,
        QueueFilterItems,
        ContactActions,
        ContactReasons,
        ContactSources,
        CountryCode,
        Suffix,
        Prefix,
        ProgramsForMember,
        ProgramsForClient,
        EmergencyAssistanceReason,
        CallType,
        Language,
        Colors,
        Users,
        POSearchTimeFilter,
        PhoneType,
        TrailerType,
        HitchType,
        Axles,
        BallSize,
        VehicleCategory,
        RVType,
        ContactCategory,
        ServiceRequestStatus,
        NextAction,
        FinishUsers,
        ClosedLoopStatus,
        CreditCardExpirationYear,
        CreditCardExpirationMonths,
        PaymentType,
        CurrencyType,
        PaymentReason,
        ServiceMemberPayMode,
        SendType,
        SendRecieptType,
        PODetailsProduct,
        POCancelReason,
        ETA,
        MemberPayType,
        CodeTypes,
        PrimaryCodes,
        ProvinceAbbreviation,
        MileageUOM,
        ServiceType,
        PODetailsUOM,
        POCopyProduct,
        GOAReason,
        HistorySearchCriteriaIDSectionType,
        HistorySearchCriteriaNameSectionType,
        HistorySearchCriteriaNameSectionUser,
        HistorySearchCriteriaNameFilterType,
        HistorySearchCriteriaDatePreset,
        HistorySearchCriteriaVehicleType,
        VendorSearchCriteriaNameFilterType,
        VendorStatus,
        VendorLocationStatus,
        VendorChangeReason,
        AddressTypes,
        LocationList,
        ACHAccountType,
        ACHStatus,
        RecieptMethodForACH,
        CommentType,
        ContractStatus,
        VendorTermAgreements,
        VendorInfoTaxClassification,
        VendorContractRateScheduleStatus,
        VendorRatesExistingContract,
        MemberManagementMembers,
        AllActiveClients,
        InvoiceTypes,
        ContactMethod,
        VendorInvoiceStatus,
        BatchStatus,
        ClaimIDFilterTypes,
        TemprorayCCIDFilterTypes,
        ClaimNameFilterTypes,
        SearchFilterTypes,
        ClaimType,
        PayeeType,
        ClaimStatus,
        ClaimStatusUsingRole,
        ClaimCategory,
        ContactMethodForVendor,
        ContactMethodForClaim,
        ClaimRejectReason,
        MemberShipMembers,
        ExportBatchesForInvoice,
        ClientPaymentCreatedBy,
        DocumentCategories,
        DocumentType,
        ExportBatchesForClaim,
        VendorInvoicePaymentDifferenceReasonCode,
        BillingEvent,
        BillingScheduleType,
        BillingDefinitionInvoice,
        PurchaseOrderPayStatusCode,
        RegenerateBillingEventsClientList,
        BillingInvoiceDetailStatus,
        BillingAdjustmentReason,
        POProductsForClientInvoice,
        BillingExcludeReason,
        BillingDispositionStatus,
        BillingInvoiceLineStatus,
        ACESClaimStatus,
        AllStateProvince,
        PostingBatch,
        ImportCCFileTypes,
        BillingInvoiceDetailDisposition,
        BillingInvoiceDetailStatusPendingReady,
        DeclinedReasons,                         // Lakshmi - Email on Map Tab,
        ConfigurationType,
        ConfigurationCategory,
        ControlType,
        DataType,
        ProductCategory,
        NotificationRecipientType,
        WarrantyPeriodUOM,
        Product,
        ProductCategoryForRules,
        MessageScope,
        MessageType,
        EventCategory,
        EventTypes,
        Events,
        ApplicationNames,
        ConcernTypes,
        ConcernType,
        Concern,
        UsersAgentTech,
        UserManagers,
        UserAgents,
        CoachingConcernNameType,
        ClientRep,
        ClientType,
        DispatchSoftwareProduct,
        //DriverSoftwareProduct,
        DispatchGPSNetwork,
        ServiceRequestDeclineReason,
        //CustomFeedbacktype,
        CustomerFeedbackIDFilterTypes,
        CustomerFeedbackSearchCriteriaNameFilterType,
        CustomerFeedbackClient,
        CustomerFeedbackProgram,
        CustomerFeedbackNextaction,
        CustomerFeedbackSearchCriteriaValueFilterType,
        CustomerFeedbackStatus,
        CustomerFeedbackSource,
        CustomerFeedbackPriority,
        CustomerFeedbackRequestBy,
        CustomerFeedbackAssignedTo,
        AllActiveUsers,
        CustomerFeedbackType,
        CustomerFeedbackCategory,
        CustomerFeedbackSubCategory,
        WorkedByUsers,
        CustomerFeedbackInvalidReasons,
        CustomerFeedbackSearchCriteriaValueMemberType,
        CustomerFeedbackSearchCriteriaNamesurveyFilterType
    }

    /// <summary>
    /// ActionFilter to make all the static data required by the target view available via ViewData.
    /// </summary>
    [AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
    public class ReferenceDataFilterAttribute : ActionFilterAttribute
    {
        protected StaticData _key;
        protected bool addDefaultValue = true;

        /// <summary>
        /// Initializes a new instance of the <see cref="ReferenceDataFilterAttribute"/> class.
        /// </summary>
        /// <param name="key">The key for the static data which is used as a key by the ViewDataDictionary and the value is a list of IEnumerable&lt;SelectListItem&gt;</param>
        public ReferenceDataFilterAttribute(StaticData key, bool addDefaultValue = true)
        {
            _key = key;
            this.addDefaultValue = addDefaultValue;
        }


        /// <summary>
        /// Utility method to get the user ID of the currently logged in user.
        /// </summary>
        /// <param name="filterContext">The filter context.</param>
        /// <returns></returns>
        private Guid GetUserID(ResultExecutingContext filterContext)
        {
            string username = filterContext.HttpContext.User.Identity.Name;
            Guid userId = (Guid)System.Web.Security.Membership.FindUsersByName(username)[username].ProviderUserKey;
            return userId;
        }


        /// <summary>
        /// Called by the ASP.NET MVC framework before the action result executes.
        /// </summary>
        /// <param name="filterContext">The filter context.</param>
        public override void OnResultExecuting(ResultExecutingContext filterContext)
        {
            ViewDataDictionary viewData = filterContext.Controller.ViewData;

            switch (_key)
            {
                case StaticData.FeedbackTypes:
                    viewData[StaticData.FeedbackTypes.ToString()] = ReferenceDataRepository.GetFeedbackTypes().Where(a => a.IsShownOnODIS == true).ToSelectListItem<FeedbackType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.Priorities:
                    viewData[StaticData.Priorities.ToString()] = ReferenceDataRepository.GetPriorities().ToSelectListItem<ServiceRequestPriority>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;

                case StaticData.Organizations:
                    viewData[StaticData.Organizations.ToString()] = ReferenceDataRepository.GetOrganizations(GetUserID(filterContext)).ToSelectListItem<dms_users_organizations_List>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;

                case StaticData.Clients:
                    viewData[StaticData.Clients.ToString()] = ReferenceDataRepository.GetClients(GetUserID(filterContext)).ToSelectListItem<Clients_Result>(x => x.ClientID.ToString(), y => y.ClientName, addDefaultValue);
                    break;
                case StaticData.Province:
                    //viewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), addDefaultValue);
                    viewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, addDefaultValue);
                    break;
                case StaticData.AllStateProvince:
                    viewData[StaticData.AllStateProvince.ToString()] = ReferenceDataRepository.GetAllStateProvinces().ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, addDefaultValue);
                    break;
                case StaticData.ProvinceAbbreviation:
                    viewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), addDefaultValue);
                    // viewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, addDefaultValue);
                    break;
                case StaticData.IvrScript:
                    viewData[StaticData.IvrScript.ToString()] = ReferenceDataRepository.GetIvrScripts().ToSelectListItem<IVRScript>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.InBoundPhoneCompany:
                    viewData[StaticData.InBoundPhoneCompany.ToString()] = ReferenceDataRepository.GetInBoundPhoneCompany().ToSelectListItem<PhoneCompany>(x => x.ID.ToString(), y => y.Type, addDefaultValue);
                    break;
                case StaticData.SkillSet:
                    viewData[StaticData.SkillSet.ToString()] = ReferenceDataRepository.GetSkillSets().ToSelectListItem<Skillset>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.Programs:
                    viewData[StaticData.Programs.ToString()] = ReferenceDataRepository.GetProgram().ToSelectListItem<Program>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.Country:
                    viewData[StaticData.Country.ToString()] = ReferenceDataRepository.GetCountry().ToSelectListItem<Country>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.CountryCode:
                    viewData[StaticData.CountryCode.ToString()] = ReferenceDataRepository.GetCountryTelephoneCode().ToSelectListItem<Country>(x => x.ISOCode, y => "+" + y.TelephoneCode.Trim() + " " + y.Name, addDefaultValue);
                    break;

                case StaticData.VehicleType:
                    viewData[StaticData.VehicleType.ToString()] = ReferenceDataRepository.GetVehicleType().ToSelectListItem<VehicleType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;

                case StaticData.VehicleModelYear:
                    GenericIEqualityComparer<VehicleMakeModel> yearDistinct = new GenericIEqualityComparer<VehicleMakeModel>(
                        (x, y) =>
                        {
                            return x.Year.GetValueOrDefault().Equals(y.Year.GetValueOrDefault());
                        },
                        (a) =>
                        {
                            return a.Year.GetValueOrDefault().GetHashCode();
                        }
                        );

                    viewData[StaticData.VehicleModelYear.ToString()] = ReferenceDataRepository.GetVehicleYears().ToSelectListItem<VehicleYears_Result>(x => x.Year.Value.ToString(), y => y.Year.Value.ToString(), addDefaultValue);
                    break;
                case StaticData.QueueFilterItems:
                    viewData[StaticData.QueueFilterItems.ToString()] = ReferenceDataRepository.GetQueueFilterItems().ToSelectListItem(x => x.Key, y => y.Value, addDefaultValue);
                    break;

                case StaticData.Suffix:
                    viewData[StaticData.Suffix.ToString()] = ReferenceDataRepository.GetSuffix().ToSelectListItem<Suffix>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.Prefix:
                    viewData[StaticData.Prefix.ToString()] = ReferenceDataRepository.GetPrefix().ToSelectListItem<Prefix>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.EmergencyAssistanceReason:
                    viewData[StaticData.EmergencyAssistanceReason.ToString()] = ReferenceDataRepository.GetEmergencyAssistanceReason().ToSelectListItem<EmergencyAssistanceReason>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.CallType:
                    viewData[StaticData.CallType.ToString()] = ReferenceDataRepository.GetCallTypes().ToSelectListItem<CallType>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.Language:
                    viewData[StaticData.Language.ToString()] = ReferenceDataRepository.GetLanguage().ToSelectListItem<Language>(x => x.ID.ToString(), y => y.Name, "1");
                    break;

                case StaticData.Users:
                    viewData[StaticData.Users.ToString()] = ReferenceDataRepository.GetUsers().ToSelectListItem<aspnet_Users>(x => x.UserName, y => y.UserName, addDefaultValue);
                    break;
                case StaticData.UsersAgentTech:
                    List<string> users = new List<string>();
                    List<aspnet_Users> aspNetUsers = ReferenceDataRepository.GetUsers("DMS");
                    aspNetUsers.ForEach(x =>
                    {
                        if (Roles.IsUserInRole(x.UserName, "Agent") || Roles.IsUserInRole(x.UserName, "RVTech"))
                        {
                            users.Add(x.UserName);
                        }
                    });
                    viewData[StaticData.UsersAgentTech.ToString()] = users.ToSelectListItem<string>(x => x.ToString(), y => y.ToString(), addDefaultValue);
                    break;
                case StaticData.UserManagers:
                    List<string> managers = new List<string>();
                    managers.AddRange(Roles.GetUsersInRole("Manager"));
                    viewData[StaticData.UserManagers.ToString()] = managers.ToSelectListItem<string>(x => x.ToString(), y => y.ToString(), addDefaultValue);
                    break;
                case StaticData.UserAgents:
                    List<string> agents = new List<string>();
                    agents.AddRange(Roles.GetUsersInRole("Agent"));
                    viewData[StaticData.UserAgents.ToString()] = agents.ToSelectListItem<string>(x => x.ToString(), y => y.ToString(), addDefaultValue);
                    break;
                case StaticData.Colors:
                    viewData[StaticData.Colors.ToString()] = ReferenceDataRepository.GetColors().ToSelectListItem<VehicleColor>(x => x.Name, y => y.Value, addDefaultValue);
                    break;
                case StaticData.POSearchTimeFilter:
                    viewData[StaticData.POSearchTimeFilter.ToString()] = ReferenceDataRepository.GetPOTimeFilterValues().ToSelectListItem(x => x.Key, y => y.Value, true);
                    break;
                case StaticData.HitchType:
                    viewData[StaticData.HitchType.ToString()] = ReferenceDataRepository.GetHitchType().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.TrailerType:
                    viewData[StaticData.TrailerType.ToString()] = ReferenceDataRepository.GetTrailerType().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.Axles:
                    viewData[StaticData.Axles.ToString()] = ReferenceDataRepository.GetAxles().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.BallSize:
                    viewData[StaticData.BallSize.ToString()] = ReferenceDataRepository.GetBallSize().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.ContactCategory:
                    viewData[StaticData.ContactCategory.ToString()] = ReferenceDataRepository.GetContactCategory().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ServiceRequestStatus:
                    viewData[StaticData.ServiceRequestStatus.ToString()] = ReferenceDataRepository.ServiceRequestStatus().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.NextAction:
                    viewData[StaticData.NextAction.ToString()] = ReferenceDataRepository.NextActions().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.FinishUsers:
                case StaticData.CustomerFeedbackAssignedTo:
                    viewData[_key.ToString()] = ReferenceDataRepository.GetAssignedTo().OrderBy(x => x.FirstName).ToSelectListItem(x => x.ID.ToString(), y => (y.FirstName + " " + y.LastName), addDefaultValue);
                    break;
                case StaticData.ClosedLoopStatus:
                    viewData[StaticData.ClosedLoopStatus.ToString()] = ReferenceDataRepository.GetClosedLoopStuses().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.PaymentType:
                    viewData[StaticData.PaymentType.ToString()] = ReferenceDataRepository.GetPaymentTypes().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.CurrencyType:
                    viewData[StaticData.CurrencyType.ToString()] = ReferenceDataRepository.GetCurrencyTypes().ToSelectListItem(x => x.ID.ToString(), y => y.Abbreviation, addDefaultValue);
                    break;
                case StaticData.PaymentReason:
                    viewData[StaticData.PaymentReason.ToString()] = ReferenceDataRepository.GetPaymentReasons(1).ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ServiceMemberPayMode:
                    viewData[StaticData.ServiceMemberPayMode.ToString()] = ReferenceDataRepository.GetServiceMemberPayMode().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;

                case StaticData.VehicleCategory:
                    viewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.SendType:
                    viewData[StaticData.SendType.ToString()] = ReferenceDataRepository.GetContactMethod().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.SendRecieptType:
                    viewData[StaticData.SendRecieptType.ToString()] = ReferenceDataRepository.GetContactMethodForSendReciept().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.PODetailsProduct:
                    viewData[StaticData.PODetailsProduct.ToString()] = ReferenceDataRepository.GetPODetailsProducts().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.POCancelReason:
                    viewData[StaticData.POCancelReason.ToString()] = ReferenceDataRepository.GetPOCancelReason().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ETA:
                    viewData[StaticData.ETA.ToString()] = ReferenceDataRepository.GetETA().ToSelectListItem(x => x.Key, y => y.Value, true);
                    break;
                case StaticData.MemberPayType:
                    viewData[StaticData.MemberPayType.ToString()] = ReferenceDataRepository.GetMemberPayTypes().ToSelectListItem(x => x.ID.ToString(), y => y.Name);
                    break;

                case StaticData.MileageUOM:
                    viewData[StaticData.MileageUOM.ToString()] = ReferenceDataRepository.GetMileageUOM().ToSelectListItem(x => x.Key, y => y.Value);
                    break;
                case StaticData.ServiceType:
                    viewData[StaticData.ServiceType.ToString()] = ReferenceDataRepository.GetProductCategories().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.PODetailsUOM:
                    viewData[StaticData.PODetailsUOM.ToString()] = ReferenceDataRepository.GetUnitOfMeasure().ToSelectListItem(x => x.UnitOfMeasure, y => y.UnitOfMeasure, addDefaultValue);
                    break;
                case StaticData.GOAReason:
                    viewData[StaticData.GOAReason.ToString()] = ReferenceDataRepository.GetGOAReason().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.HistorySearchCriteriaIDSectionType:
                    viewData[StaticData.HistorySearchCriteriaIDSectionType.ToString()] = ReferenceDataRepository.GetHistorySearchCriteriaIDSectionType().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.HistorySearchCriteriaNameSectionType:
                    viewData[StaticData.HistorySearchCriteriaNameSectionType.ToString()] = ReferenceDataRepository.GetHistorySearchCriteriaNameSectionType().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.HistorySearchCriteriaNameSectionUser:
                    viewData[StaticData.HistorySearchCriteriaNameSectionUser.ToString()] = ReferenceDataRepository.GetHistorySearchCriteriaNameSectionUsers().ToSelectListItem(x => x.UserName.ToString(), y => y.UserName, addDefaultValue);
                    break;
                case StaticData.HistorySearchCriteriaNameFilterType:
                    viewData[StaticData.HistorySearchCriteriaNameFilterType.ToString()] = ReferenceDataRepository.GetHistorySearchCriteriaNameFilterType().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.VendorSearchCriteriaNameFilterType:
                    viewData[StaticData.VendorSearchCriteriaNameFilterType.ToString()] = ReferenceDataRepository.GetVendorSearchCriteriaNameFilterType().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.HistorySearchCriteriaDatePreset:
                    viewData[StaticData.HistorySearchCriteriaDatePreset.ToString()] = ReferenceDataRepository.GetHistorySearchCriteriaDatePreset().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.HistorySearchCriteriaVehicleType:
                    viewData[StaticData.HistorySearchCriteriaVehicleType.ToString()] = ReferenceDataRepository.GetVehicleType(true).ToSelectListItem<VehicleType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.VendorStatus:
                    viewData[StaticData.VendorStatus.ToString()] = ReferenceDataRepository.GetVendorStatus().ToSelectListItem<VendorStatu>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.VendorLocationStatus:
                    viewData[StaticData.VendorLocationStatus.ToString()] = ReferenceDataRepository.GetVendorLocationStatus().ToSelectListItem<VendorLocationStatu>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.VendorChangeReason:
                    viewData[StaticData.VendorChangeReason.ToString()] = ReferenceDataRepository.GetVendorStatusChangeReason().ToSelectListItem<VendorStatusReason>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.CommentType:
                    viewData[StaticData.CommentType.ToString()] = ReferenceDataRepository.GetCommentsTypes().ToSelectListItem<CommentType>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.ACHAccountType:
                    viewData[StaticData.ACHAccountType.ToString()] = ReferenceDataRepository.GetACHAccountTypes().ToSelectListItem<DropDownEntityForString>(x => x.Value, y => y.Text, addDefaultValue);
                    break;
                case StaticData.ACHStatus:
                    viewData[StaticData.ACHStatus.ToString()] = ReferenceDataRepository.GetACHStatus().ToSelectListItem<ACHStatu>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.RecieptMethodForACH:
                    viewData[StaticData.RecieptMethodForACH.ToString()] = ReferenceDataRepository.GetACHRecieptMethod().ToSelectListItem<ContactMethod>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ContractStatus:
                    viewData[StaticData.ContractStatus.ToString()] = ReferenceDataRepository.GetVendorContractStatus().ToSelectListItem<ContractStatu>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.VendorContractRateScheduleStatus:
                    viewData[StaticData.VendorContractRateScheduleStatus.ToString()] = ReferenceDataRepository.GetVendorContractRateScheduleStatus().ToSelectListItem<ContractRateScheduleStatu>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.VendorTermAgreements:
                    viewData[StaticData.VendorTermAgreements.ToString()] = ReferenceDataRepository.GetVendorTermAgreements().ToSelectListItem<VendorTermsAgreement>(x => x.ID.ToString(), y => y.EffectiveDate.ToString(), addDefaultValue);
                    break;
                case StaticData.VendorInfoTaxClassification:
                    viewData[StaticData.VendorInfoTaxClassification.ToString()] = ReferenceDataRepository.GetVendorInfoTaxClassifications().ToSelectListItem<DropDownEntityForString>(x => x.Value, y => y.Text, addDefaultValue);
                    break;
                case StaticData.AllActiveClients:
                    viewData[StaticData.AllActiveClients.ToString()] = ReferenceDataRepository.GetAllClients().ToSelectListItem<Client>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.InvoiceTypes:
                    viewData[StaticData.InvoiceTypes.ToString()] = ReferenceDataRepository.GetVendorInvoiceTypes().ToSelectListItem<DropDownEntityForString>(x => x.Value, y => y.Text, addDefaultValue);
                    break;
                case StaticData.ContactMethod:
                    viewData[StaticData.ContactMethod.ToString()] = ReferenceDataRepository.GetContactMethods().ToSelectListItem<ContactMethod>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.VendorInvoiceStatus:
                    viewData[StaticData.VendorInvoiceStatus.ToString()] = ReferenceDataRepository.GetInvoiceStatuses().ToSelectListItem<VendorInvoiceStatu>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.BatchStatus:
                    viewData[StaticData.BatchStatus.ToString()] = ReferenceDataRepository.GetBatchStatuses().ToSelectListItem<BatchStatu>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.ClaimIDFilterTypes:
                    viewData[StaticData.ClaimIDFilterTypes.ToString()] = ReferenceDataRepository.GetClaimIDFilterTypes().ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;
                case StaticData.TemprorayCCIDFilterTypes:
                    viewData[StaticData.TemprorayCCIDFilterTypes.ToString()] = ReferenceDataRepository.GetTemporaryCCIDFilterTypes().ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;
                case StaticData.ClaimNameFilterTypes:
                    viewData[StaticData.ClaimNameFilterTypes.ToString()] = ReferenceDataRepository.GetClaimNameFilterTypes().ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;
                case StaticData.SearchFilterTypes:
                    viewData[StaticData.SearchFilterTypes.ToString()] = ReferenceDataRepository.GetSearchFilterType().ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;
                case StaticData.ClaimType:
                    viewData[StaticData.ClaimType.ToString()] = ReferenceDataRepository.GetClaimTypes().ToSelectListItem<ClaimType>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.PayeeType:
                    viewData[StaticData.PayeeType.ToString()] = ReferenceDataRepository.GetPayeeTypes().ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;
                case StaticData.ClaimStatus:
                    viewData[StaticData.ClaimStatus.ToString()] = ReferenceDataRepository.GetClaimStatus().ToSelectListItem<ClaimStatu>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ClaimStatusUsingRole:
                    Guid loggedInUserId = (Guid)System.Web.Security.Membership.GetUser(true).ProviderUserKey;
                    viewData[StaticData.ClaimStatusUsingRole.ToString()] = ReferenceDataRepository.GetClaimStatus(loggedInUserId).ToSelectListItem<ClaimStatu>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ClaimCategory:
                    viewData[StaticData.ClaimCategory.ToString()] = ReferenceDataRepository.GetClaimCategories().ToSelectListItem<ClaimCategory>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ContactMethodForVendor:
                    viewData[StaticData.ContactMethodForVendor.ToString()] = ReferenceDataRepository.GetContactMethodsForVendor().ToSelectListItem<ContactMethod>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ContactMethodForClaim:
                    viewData[StaticData.ContactMethodForClaim.ToString()] = ReferenceDataRepository.GetContactMethodsForClaim().ToSelectListItem<ContactMethod>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ClaimRejectReason:
                    viewData[StaticData.ClaimRejectReason.ToString()] = ReferenceDataRepository.GetClaimRejectReason().ToSelectListItem<ClaimRejectReason>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.MemberShipMembers:
                    viewData[StaticData.MemberShipMembers.ToString()] = ReferenceDataRepository.GetMembersByMembershipNumber(string.Empty).ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.ExportBatchesForInvoice:
                    viewData[StaticData.ExportBatchesForInvoice.ToString()] = ReferenceDataRepository.GetExportBatchesForInvoice().ToSelectListItem(x => x.ID.ToString(), y => string.Format("{0}-{1}", y.ID, y.CreateDate.Value.ToString("MM/dd/yyyy")), addDefaultValue);
                    break;
                case StaticData.ClientPaymentCreatedBy:
                    viewData[StaticData.ClientPaymentCreatedBy.ToString()] = ReferenceDataRepository.GetClientPaymentCreatedBy().ToSelectListItem(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;
                case StaticData.ExportBatchesForClaim:
                    viewData[StaticData.ExportBatchesForClaim.ToString()] = ReferenceDataRepository.GetExportBatchesForClaim().ToSelectListItem(x => x.ID.ToString(), y => string.Format("{0}-{1}", y.ID, y.CreateDate.Value.ToString("MM/dd/yyyy")), addDefaultValue);
                    break;
                case StaticData.VendorInvoicePaymentDifferenceReasonCode:
                    viewData[StaticData.VendorInvoicePaymentDifferenceReasonCode.ToString()] = ReferenceDataRepository.GetVendorInvoicePaymentDifferenceReasonCodes().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.BillingEvent:
                    viewData[StaticData.BillingEvent.ToString()] = ReferenceDataRepository.GetBillingEvents(string.Empty).ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.BillingScheduleType:
                    viewData[StaticData.BillingScheduleType.ToString()] = ReferenceDataRepository.GetBillingScheduleType().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.BillingDefinitionInvoice:
                    viewData[StaticData.BillingDefinitionInvoice.ToString()] = ReferenceDataRepository.GetBillingDefinitionInvoice().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;

                case StaticData.PurchaseOrderPayStatusCode:
                    viewData[StaticData.PurchaseOrderPayStatusCode.ToString()] = ReferenceDataRepository.GetPurchaseOrderPayStatusCodes().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.RegenerateBillingEventsClientList:
                    viewData[StaticData.RegenerateBillingEventsClientList.ToString()] = ReferenceDataRepository.GetRegenerateBillingEventsClients().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.BillingInvoiceDetailStatus:
                    viewData[StaticData.BillingInvoiceDetailStatus.ToString()] = ReferenceDataRepository.GetBillingInvoiceDetailStatus().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.BillingInvoiceDetailDisposition:
                    viewData[StaticData.BillingInvoiceDetailDisposition.ToString()] = ReferenceDataRepository.GetBillingInvoiceDetailDisposition().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.BillingInvoiceDetailStatusPendingReady:
                    viewData[StaticData.BillingInvoiceDetailStatusPendingReady.ToString()] = ReferenceDataRepository.GetBillingInvoiceDetailStatusPendingReady().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.BillingAdjustmentReason:
                    viewData[StaticData.BillingAdjustmentReason.ToString()] = ReferenceDataRepository.GetBillingAdjustmentReason().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.POProductsForClientInvoice:
                    viewData[StaticData.POProductsForClientInvoice.ToString()] = ReferenceDataRepository.GetPOProductsForClientInvoice().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.Product:
                    viewData[StaticData.Product.ToString()] = ReferenceDataRepository.GetPOProductsList().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.BillingExcludeReason:
                    viewData[StaticData.BillingExcludeReason.ToString()] = ReferenceDataRepository.GetBillingExcludeReason().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.BillingDispositionStatus:
                    viewData[StaticData.BillingDispositionStatus.ToString()] = ReferenceDataRepository.GetBillingInvoiceDetailDisposition().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.BillingInvoiceLineStatus:
                    viewData[StaticData.BillingInvoiceLineStatus.ToString()] = ReferenceDataRepository.GetBillingInvoiceLineStatus().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.ACESClaimStatus:
                    viewData[StaticData.ACESClaimStatus.ToString()] = ReferenceDataRepository.GetAcesClaimStatus().ToSelectListItem<ACESClaimStatu>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.PostingBatch:
                    viewData[StaticData.PostingBatch.ToString()] = ReferenceDataRepository.GetPostingBatch().ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.ImportCCFileTypes:
                    viewData[StaticData.ImportCCFileTypes.ToString()] = ReferenceDataRepository.GetImportCCFileTypes().ToSelectListItem<DropDownEntityForString>(x => x.Text.ToString(), y => y.Value, addDefaultValue);
                    break;

                case StaticData.DeclinedReasons:
                    viewData[StaticData.DeclinedReasons.ToString()] = ReferenceDataRepository.GetDeclineReasons().ToSelectListItem<ContactEmailDeclineReason>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;

                case StaticData.ConfigurationType:
                    viewData[StaticData.ConfigurationType.ToString()] = ReferenceDataRepository.GetConfigurationTypes().ToSelectListItem<ConfigurationType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;

                case StaticData.ConfigurationCategory:
                    viewData[StaticData.ConfigurationCategory.ToString()] = ReferenceDataRepository.GetConfigurationCategories().ToSelectListItem<ConfigurationCategory>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;

                case StaticData.ControlType:
                    viewData[StaticData.ControlType.ToString()] = ReferenceDataRepository.GetControlTypes().ToSelectListItem<ControlType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;

                case StaticData.DataType:
                    viewData[StaticData.DataType.ToString()] = ReferenceDataRepository.GetDataTypes().ToSelectListItem<DataType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ProductCategory:
                    viewData[StaticData.ProductCategory.ToString()] = ReferenceDataRepository.GetProductCategories().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.ProductCategoryForRules:
                    viewData[StaticData.ProductCategoryForRules.ToString()] = ReferenceDataRepository.GetProductCategoriesForRules().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.NotificationRecipientType:
                    viewData[StaticData.NotificationRecipientType.ToString()] = ReferenceDataRepository.GetNotificationRecipientType().ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.WarrantyPeriodUOM:
                    viewData[StaticData.WarrantyPeriodUOM.ToString()] = ReferenceDataRepository.GetWarrantyPeriodUOM().ToSelectListItem(x => x.Key, y => y.Value, addDefaultValue);
                    break;
                case StaticData.MessageScope:
                    viewData[StaticData.MessageScope.ToString()] = ReferenceDataRepository.GetMessageScope().ToSelectListItem<DropDownEntityForString>(x => x.Value, y => y.Text, addDefaultValue);
                    break;
                case StaticData.MessageType:
                    viewData[StaticData.MessageType.ToString()] = ReferenceDataRepository.GetMessageType().ToSelectListItem<MessageType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.EventCategory:
                    viewData[StaticData.EventCategory.ToString()] = ReferenceDataRepository.GetEventCategories().ToSelectListItem<EventCategory>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.EventTypes:
                    viewData[StaticData.EventTypes.ToString()] = ReferenceDataRepository.GetEventTypes().ToSelectListItem<EventType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.Events:
                    viewData[StaticData.Events.ToString()] = ReferenceDataRepository.GetEvents().ToSelectListItem<Event>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ApplicationNames:
                    viewData[StaticData.ApplicationNames.ToString()] = ReferenceDataRepository.GetApplicationNames().ToSelectListItem<aspnet_Applications>(x => x.ApplicationName.ToString(), y => y.ApplicationName, addDefaultValue);
                    break;
                case StaticData.ConcernTypes:
                    viewData[StaticData.ConcernTypes.ToString()] = ReferenceDataRepository.GetConcernTypes().ToSelectListItem<ConcernType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ConcernType:
                    viewData[StaticData.ConcernType.ToString()] = ReferenceDataRepository.GetConcernType().ToSelectListItem<ConcernType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.CoachingConcernNameType:
                    List<SelectListItem> coachingConcernName = new List<SelectListItem>();
                    coachingConcernName.Add(new SelectListItem() { Text = "Manager", Value = "Manager" });
                    coachingConcernName.Add(new SelectListItem() { Text = "User", Value = "User" });
                    viewData[StaticData.CoachingConcernNameType.ToString()] = coachingConcernName.ToSelectListItem<SelectListItem>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;
                case StaticData.ClientRep:
                    viewData[StaticData.ClientRep.ToString()] = ReferenceDataRepository.GetClientReps().ToSelectListItem<ClientRep>(x => x.ID.ToString(), y => y.FirstName + " " + y.LastName, addDefaultValue);
                    break;
                case StaticData.ClientType:
                    viewData[StaticData.ClientType.ToString()] = ReferenceDataRepository.GetClientTypes().ToSelectListItem<ClientType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.DispatchSoftwareProduct:
                    viewData[StaticData.DispatchSoftwareProduct.ToString()] = ReferenceDataRepository.GetDispatchSoftwareProduct(false).ToSelectListItem<DispatchSoftwareProduct>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                //case StaticData.DriverSoftwareProduct:
                //    viewData[StaticData.DriverSoftwareProduct.ToString()] = ReferenceDataRepository.GetDispatchSoftwareProduct().ToSelectListItem<DispatchSoftwareProduct>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                //    break;
                case StaticData.DispatchGPSNetwork:
                    viewData[StaticData.DispatchGPSNetwork.ToString()] = ReferenceDataRepository.GetDispatchGPSNetwork().ToSelectListItem<DispatchGPSNetwork>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.ServiceRequestDeclineReason:
                    viewData[StaticData.ServiceRequestDeclineReason.ToString()] = ReferenceDataRepository.GetServiceRequestDeclineReason().ToSelectListItem<ServiceRequestDeclineReason>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;

                case StaticData.CustomerFeedbackSearchCriteriaNameFilterType:
                    viewData[StaticData.CustomerFeedbackSearchCriteriaNameFilterType.ToString()] = ReferenceDataRepository.GetCustomerFeedbackSearchCriteriaNameFilterType().ToSelectListItem(y => y.Value, x => x.Text.ToString(), addDefaultValue);
                    break;
                //case StaticData.CustomerFeedbackIDFilterTypes:
                //    viewData[StaticData.CustomerFeedbackIDFilterTypes.ToString()] = ReferenceDataRepository.GetCustomerFeedbackIDFilterTypes().ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                //    break;
                case StaticData.CustomerFeedbackClient:
                    viewData[StaticData.CustomerFeedbackClient.ToString()] = ReferenceDataRepository.GetCustomerFeedbackClients().ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.CustomerFeedbackProgram:
                    viewData[StaticData.CustomerFeedbackProgram.ToString()] = ReferenceDataRepository.GetCustomerFeedbackProgram(0).ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.CustomerFeedbackNextaction:
                    viewData[StaticData.CustomerFeedbackNextaction.ToString()] = ReferenceDataRepository.NextActions(EntityNames.CUSTOMER_FEEDBACK).OrderBy(a => a.Sequence).ToSelectListItem(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;

                case StaticData.CustomerFeedbackSearchCriteriaValueFilterType:
                    viewData[StaticData.CustomerFeedbackSearchCriteriaValueFilterType.ToString()] = ReferenceDataRepository.GetCustomerFeedbackFilterValueTypes().ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;

                case StaticData.CustomerFeedbackStatus:
                    viewData[StaticData.CustomerFeedbackStatus.ToString()] = ReferenceDataRepository.GetCustomerFeedbackStatus_List().ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.CustomerFeedbackSource:
                    viewData[StaticData.CustomerFeedbackSource.ToString()] = ReferenceDataRepository.GetCustomerFeedbackSource_List().ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.CustomerFeedbackPriority:
                    viewData[StaticData.CustomerFeedbackPriority.ToString()] = ReferenceDataRepository.GetCustomerFeedbackPriority_List().ToSelectListItem<CustomerFeedbackPriority>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                    break;
                case StaticData.CustomerFeedbackRequestBy:
                    viewData[StaticData.CustomerFeedbackRequestBy.ToString()] = ReferenceDataRepository.GetFeedbackRequestBy_List().ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text, addDefaultValue);
                    break;
                case StaticData.AllActiveUsers:
                    viewData[StaticData.AllActiveUsers.ToString()] = ReferenceDataRepository.GetUsersList().ToSelectListItem<User>(x => x.ID.ToString(), y => y.FirstName + " " + y.LastName, addDefaultValue);
                    break;
                case StaticData.CustomerFeedbackType:
                    viewData[StaticData.CustomerFeedbackType.ToString()] = ReferenceDataRepository.GetCustomerFeedbackTypes().ToSelectListItem<CustomerFeedbackType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;
                case StaticData.CustomerFeedbackInvalidReasons:
                    viewData[StaticData.CustomerFeedbackInvalidReasons.ToString()] = ReferenceDataRepository.GetCustomerFeedbackInvalidReasons().ToSelectListItem<CustomerFeedbackInvalidReason>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                    break;                
                case StaticData.CustomerFeedbackSearchCriteriaValueMemberType:
                    viewData[StaticData.CustomerFeedbackSearchCriteriaValueMemberType.ToString()] = ReferenceDataRepository.GetCustomerFeedbackSearchCriteriaValueMemberType().ToSelectListItem(y => y.Value, x => x.Text.ToString(), addDefaultValue);
                    break;

                case StaticData.CustomerFeedbackSearchCriteriaNamesurveyFilterType:
                    viewData[StaticData.CustomerFeedbackSearchCriteriaNamesurveyFilterType.ToString()] = ReferenceDataRepository.GetCustomerFeedbackSearchCriteriaNamesurveyFilterType().ToSelectListItem(y => y.Value, x => x.Text.ToString(), addDefaultValue);
                    break;

            }

        }
    }
}
