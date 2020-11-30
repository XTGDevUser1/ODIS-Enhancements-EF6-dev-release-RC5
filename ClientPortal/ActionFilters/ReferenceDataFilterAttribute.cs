using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using ClientPortal.Common;

using Martex.DMS.DAL.Entities;
using ClientPortal.Models;
using System.Text;


namespace ClientPortal.ActionFilters
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
        HistorySearchCriteriaVehicleType
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
                    viewData[StaticData.FeedbackTypes.ToString()] = ReferenceDataRepository.GetFeedbackTypes().ToSelectListItem<FeedbackType>(x => x.ID.ToString(), y => y.Name, addDefaultValue);
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
                    viewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y =>  y.Abbreviation.Trim() + "-" + y.Name, addDefaultValue);
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
                    viewData[StaticData.CountryCode.ToString()] = ReferenceDataRepository.GetCountryTelephoneCode().ToSelectListItem<Country>(x => x.ISOCode, y => y.ISOCode.Trim(), addDefaultValue);
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
                    viewData[StaticData.Language.ToString()] = ReferenceDataRepository.GetLanguage().ToSelectListItem<Language>(x => x.ID.ToString(), y => y.Name,"1");
                    break;

                case StaticData.Users:
                    viewData[StaticData.Users.ToString()] = ReferenceDataRepository.GetUsers().ToSelectListItem<aspnet_Users>(x => x.UserName, y => y.UserName, addDefaultValue);
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
                    viewData[StaticData.FinishUsers.ToString()] = ReferenceDataRepository.GetAssignedTo().ToSelectListItem(x => x.ID.ToString(), y => (y.FirstName+" "+y.LastName), addDefaultValue);
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
                    viewData[StaticData.MemberPayType.ToString()] = ReferenceDataRepository.GetMemberPayTypes().ToSelectListItem(x=>x.ID.ToString(), y=>y.Name);
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
                case StaticData.HistorySearchCriteriaDatePreset:
                 viewData[StaticData.HistorySearchCriteriaDatePreset.ToString()] = ReferenceDataRepository.GetHistorySearchCriteriaDatePreset().ToSelectListItem(x => x.ID.ToString(), y => y.Name, addDefaultValue);
                 break;
                case StaticData.HistorySearchCriteriaVehicleType:
                 viewData[StaticData.HistorySearchCriteriaVehicleType.ToString()] = ReferenceDataRepository.GetVehicleType(true).ToSelectListItem<VehicleType>(x => x.ID.ToString(), y => y.Description, addDefaultValue);
                 break;
            }

        }
    }
}
