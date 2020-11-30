using Newtonsoft.Json;
using ODISMember.Common;
using ODISMember.Data;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Entities.Table;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Services.Service;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember
{
    public class MemberHelper
    {
        public MemberService memberService;
        public DBRepository dbRepository;
        private LoggerHelper logger = new LoggerHelper();

        public MemberHelper()
        {
            memberService = new MemberService();
            dbRepository = new DBRepository();
        }

        #region Service Method Calls

        public async Task<AccessResult> Login(string userName, string password)
        {
            logger.Trace("MemberHelper: Login Starts at:" + DateTime.Now.ToString());
            AccessResult registrationResult = await memberService.Login(userName, password);

            if (!string.IsNullOrEmpty(registrationResult.access_token))
            {
                //Assigning login detail values to Global Static variables to access through out application
                Constants.ACCESS_TOKEN = registrationResult.access_token;
                Constants.MEMBER_NUMBER = registrationResult.MemberNumber;
                Constants.MASTER_MEMBER_NUMBER = registrationResult.MasterMemberNumber;
                Constants.MEMBER_FULL_NAME = registrationResult.FirstName + " " + registrationResult.LastName;
                Constants.MEMBER_PLAN_NAME = registrationResult.PlanName;
                Constants.MEMBER_PROGRAM_ID = registrationResult.ProgramID;
                Constants.MEMBER_FIRST_NAME = registrationResult.FirstName;
                Constants.MEMBER_LAST_NAME = registrationResult.LastName;
                Constants.MEMBER_SERVICE_PHONE_NUMBER = registrationResult.MemberServicePhoneNumber;
                Constants.MEMBER_MEMBERSHIP_NUMBER = registrationResult.MembershipNumber;
                Constants.IS_ACTIVE = registrationResult.IsActive;
                Constants.BENEFIT_GUIDE_PDF = registrationResult.BenefitGuidePDF;
                Constants.DISPATCH_PHONE_NUMBER = registrationResult.DispatchPhoneNumber;

                Constants.IS_MASTER_MEMBER = registrationResult.IsMasterMember;
                Constants.IS_SHOW_MEMBER_LIST = registrationResult.IsShowMemberList;
                Constants.IS_SHOW_ADD_MEMBER = registrationResult.IsShowAddMember;
                Constants.PRODUCT_IMAGE = registrationResult.ProductImage;
                Constants.USER_NAME = userName;
                Constants.MEMBER_SUBSCRIPTION_START_DATE = registrationResult.CurrentSubscriptionStartDate.HasValue ? registrationResult.CurrentSubscriptionStartDate.Value.ToString(Constants.DateFormat) : string.Empty;
                Constants.PersonID = registrationResult.PersonID;

                Member member = new Member();
                member.AccessToken = registrationResult.access_token;
                member.TokenType = registrationResult.token_type;
                member.ExpiresIn = registrationResult.expires_in;
                member.MemberNumber = registrationResult.MemberNumber;
                member.FirstName = registrationResult.FirstName;
                member.LastName = registrationResult.LastName;
                member.PersonID = registrationResult.PersonID;
                member.UserName = userName;
                member.Password = password;
                member.MembershipStatus = registrationResult.MembershipStatus;
                member.MemberSinceDate = registrationResult.MemberSinceDate;
                member.CurrentSubscriptionExpirationDate = registrationResult.CurrentSubscriptionExpirationDate;
                member.CurrentSubscriptionStartDate = registrationResult.CurrentSubscriptionStartDate;
                member.MembershipNumber = registrationResult.MembershipNumber;
                member.PlanName = registrationResult.PlanName;
                member.PlanID = registrationResult.PlanID;
                member.ProductCode = registrationResult.ProductCode;
                member.IsActive = registrationResult.IsActive;
                member.MasterPersonID = registrationResult.MasterPersonID;
                member.MasterMemberNumber = registrationResult.MasterMemberNumber;
                member.ProgramID = registrationResult.ProgramID;
                member.IsMasterMember = registrationResult.IsMasterMember;
                member.IsShowMemberList = registrationResult.IsShowMemberList;
                member.IsShowAddMember = registrationResult.IsShowAddMember;

                member.ContactMethod = registrationResult.ContactMethod;
                member.CreatedOn = DateTime.Now;
                member.MemberServicePhoneNumber = registrationResult.MemberServicePhoneNumber;
                member.BenefitGuidePDF = registrationResult.BenefitGuidePDF;
                member.DispatchPhoneNumber = registrationResult.DispatchPhoneNumber;
                member.ProductImage = registrationResult.ProductImage;

                //inserting login details into database
                dbRepository.DeleteAllRecords<Member>();
                dbRepository.InsertRecord(member);
            }
            logger.Trace("MemberHelper: Login Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> Join(MemberModel memberModel)
        {
            OperationResult registrationResult = await memberService.Join(memberModel);
            return registrationResult;
        }

        public async Task<OperationResult> RegisterVerify(string memberNumber, string lastName, string firstName)
        {
            logger.Trace("MemberHelper: RegisterVerify Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.RegisterVerify(memberNumber, lastName, firstName);
            logger.Trace("MemberHelper: RegisterVerify Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> Register(RegisterSendModel registerSendModel)
        {
            logger.Trace("MemberHelper: Register Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.Register(registerSendModel);
            logger.Trace("MemberHelper: Register Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> ResetPassword(string email)
        {
            logger.Trace("MemberHelper: ResetPassword Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.ResetPassword(email);
            logger.Trace("MemberHelper: ResetPassword Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> SendUserName(string email)
        {
            logger.Trace("MemberHelper: SendUserName Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.SendUserName(email);
            logger.Trace("MemberHelper: SendUserName Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> ChangePassword(RegisterSendModel changePasswordSendModel)
        {
            logger.Trace("MemberHelper: ChangePassword Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.ChangePassword(changePasswordSendModel);
            logger.Trace("MemberHelper: ChangePassword Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        #endregion Service Method Calls

        public async Task<OperationResult> GetMemberStatus(string memberNumber)
        {
            logger.Trace("MemberHelper: GetMemberStatus Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetMemberStatus(memberNumber);
            logger.Trace("MemberHelper: GetMemberStatus Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetMembership()
        {
            logger.Trace("MemberHelper: GetMembership Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetMembership();

            if (registrationResult != null && registrationResult.Status == OperationStatus.SUCCESS && registrationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.Membership>();
                    ODISMember.Entities.Table.Membership membership = new ODISMember.Entities.Table.Membership();
                    membership.MembershipInfo = registrationResult.Data.ToString();
                    dbRepository.InsertRecord(membership);
                    Device.BeginInvokeOnMainThread(() =>
                   {
                       EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.MEMBERSHIP_DATA_UPDATED_LOCALLY));
                   });
                });
            }
            logger.Trace("MemberHelper: GetMembership Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetMembers()
        {
            logger.Trace("MemberHelper: GetMembers Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetMembers();
            if (registrationResult != null && registrationResult.Status == OperationStatus.SUCCESS && registrationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.MemberAssociate>();
                    ODISMember.Entities.Table.MemberAssociate memberAssociate = new ODISMember.Entities.Table.MemberAssociate();
                    memberAssociate.MemberAssociateInfo = registrationResult.Data.ToString();
                    dbRepository.InsertRecord(memberAssociate);
                    Device.BeginInvokeOnMainThread(() =>
                    {
                        EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.MEMBER_DATA_UPDATED_LOCALLY));
                    });
                });
            }
            logger.Trace("MemberHelper: GetMembers Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetMemberAssociates(string memberNumber)
        {
            logger.Trace("MemberHelper: GetMemberAssociates Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetMemberAssociates(memberNumber);
            logger.Trace("MemberHelper: GetMemberAssociates Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> AddEditMember(List<Associate> associates)
        {
            logger.Trace("MemberHelper: AddEditMember Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.AddEditMember(associates);
            logger.Trace("MemberHelper: AddEditMember Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> UpdateMemberhip(AccountModel accountModel)
        {
            logger.Trace("MemberHelper: UpdateMemberhip Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.UpdateMemberhip(accountModel);
            logger.Trace("MemberHelper: UpdateMemberhip Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> DeleteMember(string memberNumber)
        {
            logger.Trace("MemberHelper: DeleteMember Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.DeleteMember(memberNumber);
            logger.Trace("MemberHelper: DeleteMember Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicles(bool isVehiclePhotoRequired = true)
        {
            logger.Trace("MemberHelper: GetVehicles Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicles(isVehiclePhotoRequired);
            logger.Trace("MemberHelper: GetVehicles Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        /// <summary>
        /// Register the device to process notifications
        /// </summary>
        /// <returns></returns>
        public async Task<OperationResult> DeviceRegister()
        {
            logger.Trace("MemberHelper: DeviceRegister Starts at:" + DateTime.Now.ToString());
            DeviceRegisterModel registerModel = new DeviceRegisterModel();
            registerModel.DeviceOS = Xamarin.Forms.Device.OS.ToString();

            registerModel.Tags = new List<string>();
            registerModel.Tags.Add(Constants.TAG_MEMBERSHIP_NUMBER + Constants.MEMBER_MEMBERSHIP_NUMBER);
            registerModel.Tags.Add(Constants.TAG_MEMBER_NUMBER + Constants.MEMBER_NUMBER);

            OperationResult registrationResult = await memberService.DeviceRegister(registerModel);
            logger.Trace("MemberHelper: DeviceRegister Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> ConfirmEstimate(string serviceRequestId)
        {
            logger.Trace("MemberHelper: ConfirmEstimate Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.ConfirmEstimate(serviceRequestId);
            logger.Trace("MemberHelper: ConfirmEstimate Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> CancelEstimate(string serviceRequestId)
        {
            logger.Trace("MemberHelper: CancelEstimate Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.CancelEstimate(serviceRequestId);
            logger.Trace("MemberHelper: CancelEstimate Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> EmailSetupInstructions(MemberEmailModel memberEmailModel)
        {
            logger.Trace("MemberHelper: EmailSetupInstructions Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.EmailSetupInstructions(memberEmailModel);
            logger.Trace("MemberHelper: EmailSetupInstructions Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        #region Vehicle

        public async Task<OperationResult> AddVehicles(List<VehicleModel> vehicles)
        {
            logger.Trace("MemberHelper: AddVehicles Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.AddVehicles(vehicles);
            logger.Trace("MemberHelper: AddVehicles Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> UpdateVehicles(List<VehicleModel> vehicles)
        {
            logger.Trace("MemberHelper: UpdateVehicles Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.UpdateVehicles(vehicles);
            logger.Trace("MemberHelper: UpdateVehicles Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> DeleteVehicles(long vehicleId)
        {
            logger.Trace("MemberHelper: DeleteVehicles Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.DeleteVehicles(vehicleId);
            logger.Trace("MemberHelper: DeleteVehicles Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicleServices()
        {
            logger.Trace("MemberHelper: GetVehicleServices Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleServices();
            logger.Trace("MemberHelper: GetVehicleServices Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicleServiceQuestions(string productCategory, string vehicleCategory, string vehicleType)
        {
            logger.Trace("MemberHelper: GetVehicleServiceQuestions Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleServiceQuestions(productCategory, vehicleCategory, vehicleType);
            logger.Trace("MemberHelper: GetVehicleServiceQuestions Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        #endregion Vehicle

        #region Dropdowns

        public async Task<OperationResult> GetVehicleTypes(string programId)
        {
            logger.Trace("MemberHelper: GetVehicleTypes Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleTypes(programId);
            logger.Trace("MemberHelper: GetVehicleTypes Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicleChassis()
        {
            logger.Trace("MemberHelper: GetVehicleChassis Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleChassis();
            if (registrationResult != null && registrationResult.Status == OperationStatus.SUCCESS && registrationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.VehicleChassis>();
                    List<ODISMember.Entities.Table.VehicleChassis> items = JsonConvert.DeserializeObject<List<ODISMember.Entities.Table.VehicleChassis>>(registrationResult.Data.ToString());
                    dbRepository.InsertAllRecords<ODISMember.Entities.Table.VehicleChassis>(items);
                });
            }
            logger.Trace("MemberHelper: GetVehicleChassis Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicleColors()
        {
            logger.Trace("MemberHelper: GetVehicleColors Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleColors();
            if (registrationResult != null && registrationResult.Status == OperationStatus.SUCCESS && registrationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.VehicleColor>();
                    List<ODISMember.Entities.Table.VehicleColor> items = JsonConvert.DeserializeObject<List<ODISMember.Entities.Table.VehicleColor>>(registrationResult.Data.ToString());
                    dbRepository.InsertAllRecords<ODISMember.Entities.Table.VehicleColor>(items);
                });
            }
            logger.Trace("MemberHelper: GetVehicleColors Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicleEngines()
        {
            logger.Trace("MemberHelper: GetVehicleEngines Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleEngines();
            if (registrationResult != null && registrationResult.Status == OperationStatus.SUCCESS && registrationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.VehicleEngine>();
                    List<ODISMember.Entities.Table.VehicleEngine> items = JsonConvert.DeserializeObject<List<ODISMember.Entities.Table.VehicleEngine>>(registrationResult.Data.ToString());
                    dbRepository.InsertAllRecords<ODISMember.Entities.Table.VehicleEngine>(items);
                });
            }
            logger.Trace("MemberHelper: GetVehicleEngines Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicleMakes(string vehicleTypeId)
        {
            logger.Trace("MemberHelper: GetVehicleMakes Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleMakes(vehicleTypeId);
            logger.Trace("MemberHelper: GetVehicleMakes Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicleModels(string vehicleTypeId, string makeId)
        {
            logger.Trace("MemberHelper: GetVehicleModels Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleModels(vehicleTypeId, makeId);
            logger.Trace("MemberHelper: GetVehicleModels Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetStatesForCountry(string countryId)
        {
            logger.Trace("MemberHelper: GetStatesForCountry Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetStatesForCountry(countryId);
            logger.Trace("MemberHelper: GetStatesForCountry Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetMakeModels()
        {
            logger.Trace("MemberHelper: GetMakeModels Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetMakeModels();

            if (registrationResult != null && registrationResult.Status == OperationStatus.SUCCESS && registrationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.MakeModel>();
                    List<ODISMember.Entities.Table.MakeModel> items = JsonConvert.DeserializeObject<List<ODISMember.Entities.Table.MakeModel>>(registrationResult.Data.ToString());
                    dbRepository.InsertAllRecords<ODISMember.Entities.Table.MakeModel>(items);
                });
            }

            logger.Trace("MemberHelper: GetMakeModels Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetVehicleTransmissions()
        {
            logger.Trace("MemberHelper: GetVehicleTransmissions Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetVehicleTransmissions();
            if (registrationResult != null && registrationResult.Status == OperationStatus.SUCCESS && registrationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.VehicleTransmission>();
                    List<VehicleTransmission> items = JsonConvert.DeserializeObject<List<VehicleTransmission>>(registrationResult.Data.ToString());
                    dbRepository.InsertAllRecords<VehicleTransmission>(items);
                });
            }
            logger.Trace("MemberHelper: GetVehicleTransmissions Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetCountryCodes()
        {
            logger.Trace("MemberHelper: GetCountryCodes Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = await memberService.GetCountryCodes();
            if (registrationResult != null && registrationResult.Status == OperationStatus.SUCCESS && registrationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.Countries>();
                    List<Countries> items = JsonConvert.DeserializeObject<List<Countries>>(registrationResult.Data.ToString());
                    dbRepository.InsertAllRecords<Countries>(items);
                });
            }
            logger.Trace("MemberHelper: GetCountryCodes Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        #endregion Dropdowns

        /// <summary>
        /// Gets the member data.
        /// Returns Member if exists in the local database, else returns null
        /// </summary>
        public Member GetLocalMember()
        {
            List<Member> listMember = null;
            logger.Trace("MemberHelper: GetLocalMember Starts at:" + DateTime.Now.ToString());
            try
            {
                listMember = dbRepository.GetAllRecords<Member>();
            }
            catch (Exception ex)
            {
                throw ex;
            }
            logger.Trace("MemberHelper: GetLocalMember Ends at:" + DateTime.Now.ToString());
            if (listMember.Count > 0)
            {
                return listMember[0];
            }
            else
            {
                return null;
            }
        }

        public async Task<OperationResult> GetActiveRequest(string membershipNumber)
        {
            logger.Trace("MemberHelper: GetActiveRequest Starts at:" + DateTime.Now.ToString());
            var result = await memberService.GetActiveRequest(membershipNumber);
            logger.Trace("MemberHelper: GetActiveRequest Ends at:" + DateTime.Now.ToString());
            return result;
        }

        /// <summary>
        /// Gets the member history.
        /// </summary>
        /// <returns>Membership History</returns>
        public async Task<OperationResult> GetMemberHistory()
        {
            logger.Trace("MemberHelper: GetMemberHisotry Starts at:" + DateTime.Now.ToString());
            var result = await memberService.GetMemberHistory();
            logger.Trace("MemberHelper: GetMemberHisotry Ends at:" + DateTime.Now.ToString());
            return result;
        }

        /// <summary>
        /// Submits the service request.
        /// </summary>
        /// <param name="serviceRequestModel">The service request model.</param>
        /// <returns>if request submit success Tracking UID returns</returns>
        public async Task<OperationResult> SubmitServiceRequest(ServiceRequestModel serviceRequestModel)
        {
            logger.Trace("MemberHelper: SubmitServiceRequest Starts at:" + DateTime.Now.ToString());
            var result = await memberService.SubmitServiceRequest(serviceRequestModel);
            logger.Trace("MemberHelper: SubmitServiceRequest Ends at:" + DateTime.Now.ToString());
            return result;
        }

        public async Task<BingAddressRoot> GetBingAddress(string lat, string lang)
        {
            logger.Trace("MemberHelper: GetBingAddress Starts at:" + DateTime.Now.ToString());
            var result = await memberService.GetBingAddress(lat, lang);
            logger.Trace("MemberHelper: GetBingAddress Ends at:" + DateTime.Now.ToString());
            return result;
        }

        public async Task<BingAddressRoot> GetBingPoints(string address)
        {
            logger.Trace("MemberHelper: GetBingPoints Starts at:" + DateTime.Now.ToString());
            var result = await memberService.GetBingPoints(address);
            logger.Trace("MemberHelper: GetBingPoints Ends at:" + DateTime.Now.ToString());
            return result;
        }

        public async Task<OperationResult> GetApplicationSettings()
        {
            logger.Trace("MemberHelper: GetApplicationSettings Starts at:" + DateTime.Now.ToString());
            OperationResult result = await memberService.GetApplicationSettings();
            if (result != null && result.Status == OperationStatus.SUCCESS && result.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.DeleteAllRecords<ODISMember.Entities.Table.ApplicationSettingsTable>();
                    List<ApplicationSettingsTable> settings = new List<ApplicationSettingsTable>();
                    settings = JsonConvert.DeserializeObject<List<ApplicationSettingsTable>>(result.Data.ToString());
                    dbRepository.InsertAllRecords<ApplicationSettingsTable>(settings);
                    EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.APPLICATION_SETTINGS_DATA_UPDATED_LOCALLY));
                });
            }
            logger.Trace("MemberHelper: GetApplicationSettings Ends at:" + DateTime.Now.ToString());
            return result;
        }

        public async Task<OperationResult> GetStaticDataVersions()
        {
            logger.Trace("MemberHelper: GetStaticDataVersions Starts at:" + DateTime.Now.ToString());
            OperationResult result = await memberService.GetStaticDataVersions();
            logger.Trace("MemberHelper: GetStaticDataVersions Ends at:" + DateTime.Now.ToString());
            return result;
        }

        #region Local database operations

        private void AddSettingsRecord(SettingsTable item)
        {
            logger.Trace("MemberHelper: AddSettingsRecord Starts at:" + DateTime.Now.ToString());
            ODISBackgroundService.GetInstance().Enqueue(() =>
            {
                dbRepository.InsertRecord(item);
            });
            logger.Trace("MemberHelper: AddSettingsRecord Ends at:" + DateTime.Now.ToString());
        }

        public void UpdateSettingsLocation(bool isLocationAllowed)
        {
            logger.Trace("MemberHelper: UpdateSettingsLocation Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            if (settings.Count > 0)
            {
                settings[0].IsLocationAllowed = isLocationAllowed;
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.UpdateRecord(settings[0]);
                });
            }
            else
            {
                SettingsTable setting = new SettingsTable();
                setting.MemberNumber = Constants.MEMBER_NUMBER;
                setting.IsLocationAllowed = isLocationAllowed;
                setting.IsNotificationEnabled = false;
                setting.IsLoggingEnabled = false;
                setting.IsCameraPermissionAsked = false;
                setting.IsGalleryPermissionAsked = false;
                setting.IsLocationPermissionAsked = false;
                AddSettingsRecord(setting);
            }
            logger.Trace("MemberHelper: UpdateSettingsLocation Ends at:" + DateTime.Now.ToString());
        }

        public void UpdateSettingsNotification(bool isNotificaitonEnalbed)
        {
            logger.Trace("MemberHelper: UpdateSettingsNotification Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            if (settings.Count > 0)
            {
                settings[0].IsNotificationEnabled = isNotificaitonEnalbed;
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.UpdateRecord(settings[0]);
                });
            }
            else
            {
                SettingsTable setting = new SettingsTable();
                setting.MemberNumber = Constants.MEMBER_NUMBER;
                setting.IsLocationAllowed = false;
                setting.IsLoggingEnabled = false;
                setting.IsNotificationEnabled = isNotificaitonEnalbed;
                setting.IsCameraPermissionAsked = false;
                setting.IsGalleryPermissionAsked = false;
                setting.IsLocationPermissionAsked = false;
                AddSettingsRecord(setting);
            }
            logger.Trace("MemberHelper: UpdateSettingsNotification Ends at:" + DateTime.Now.ToString());
        }

        public void UpdateSettingsLogging(bool isLoggingEnalbed)
        {
            logger.Trace("MemberHelper: UpdateSettingsLogging Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            if (settings.Count > 0)
            {
                settings[0].IsLoggingEnabled = isLoggingEnalbed;
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.UpdateRecord(settings[0]);
                });
            }
            else
            {
                SettingsTable setting = new SettingsTable();
                setting.MemberNumber = Constants.MEMBER_NUMBER;
                setting.IsLocationAllowed = false;
                setting.IsLoggingEnabled = isLoggingEnalbed;
                setting.IsNotificationEnabled = false;
                setting.IsCameraPermissionAsked = false;
                setting.IsGalleryPermissionAsked = false;
                setting.IsLocationPermissionAsked = false;
                AddSettingsRecord(setting);
            }
            logger.Trace("MemberHelper: UpdateSettingsLogging Ends at:" + DateTime.Now.ToString());
        }

        public void UpdateSettingsAskCameraPermission(bool IsPermissionItem)
        {
            logger.Trace("MemberHelper: CheckIsAskPermission Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            logger.Trace("MemberHelper: CheckIsAskPermission Ends at:" + DateTime.Now.ToString());
            if (settings.Count > 0)
            {
                settings[0].IsCameraPermissionAsked = IsPermissionItem;
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.UpdateRecord(settings[0]);
                });
            }
            else
            {
                SettingsTable setting = new SettingsTable();
                setting.MemberNumber = Constants.MEMBER_NUMBER;
                setting.IsLocationAllowed = false;
                setting.IsLoggingEnabled = false;
                setting.IsNotificationEnabled = false;
                setting.IsCameraPermissionAsked = IsPermissionItem;
                setting.IsGalleryPermissionAsked = false;
                setting.IsLocationPermissionAsked = false;

                AddSettingsRecord(setting);
            }
        }

        public void UpdateSettingsAskLocationPermission(bool IsPermissionItem)
        {
            logger.Trace("MemberHelper: CheckIsAskPermission Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            logger.Trace("MemberHelper: CheckIsAskPermission Ends at:" + DateTime.Now.ToString());
            if (settings.Count > 0)
            {
                settings[0].IsLocationPermissionAsked = IsPermissionItem;
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.UpdateRecord(settings[0]);
                });
            }
            else
            {
                SettingsTable setting = new SettingsTable();
                setting.MemberNumber = Constants.MEMBER_NUMBER;
                setting.IsLocationAllowed = false;
                setting.IsLoggingEnabled = false;
                setting.IsNotificationEnabled = false;
                setting.IsCameraPermissionAsked = false;
                setting.IsGalleryPermissionAsked = false;
                setting.IsLocationPermissionAsked = IsPermissionItem;
                AddSettingsRecord(setting);
            }
        }

        public void UpdateSettingsWalkthroughDisable(bool IsWalkthroughShown)
        {
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            if (settings.Count > 0)
            {
                settings[0].IsWalkthroughShown = IsWalkthroughShown;
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.UpdateRecord(settings[0]);
                });
            }
            else
            {
                SettingsTable setting = new SettingsTable();
                setting.MemberNumber = Constants.MEMBER_NUMBER;
                setting.IsLocationAllowed = false;
                setting.IsLoggingEnabled = false;
                setting.IsNotificationEnabled = false;
                setting.IsCameraPermissionAsked = false;
                setting.IsGalleryPermissionAsked = false;
                setting.IsLocationPermissionAsked = false;
                setting.IsWalkthroughShown = IsWalkthroughShown;
                AddSettingsRecord(setting);
            }
        }

        public bool CheckIsLocationAllowed()
        {
            logger.Trace("MemberHelper: CheckIsLocationAllowed Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            logger.Trace("MemberHelper: CheckIsLocationAllowed Ends at:" + DateTime.Now.ToString());
            if (settings.Count > 0)
            {
                return settings[0].IsLocationAllowed;
            }
            return false;
        }

        public bool CheckIsLoggingEnabled()
        {
            logger.Trace("MemberHelper: CheckIsLoggingEnabled Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>();
            logger.Trace("MemberHelper: CheckIsLoggingEnabled Ends at:" + DateTime.Now.ToString());
            if (settings.Count > 0)
            {
                return settings[0].IsLoggingEnabled;
            }
            return false;
        }

        public SettingsTable GetSettings()
        {
            logger.Trace("MemberHelper: CheckIsAskPermission Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            logger.Trace("MemberHelper: CheckIsAskPermission Ends at:" + DateTime.Now.ToString());
            if (settings.Count > 0)
            {
                return settings[0];
            }
            else
            {
                SettingsTable setting = new SettingsTable();
                setting.MemberNumber = Constants.MEMBER_NUMBER;
                setting.IsLocationAllowed = false;
                setting.IsLoggingEnabled = false;
                setting.IsNotificationEnabled = false;
                setting.IsCameraPermissionAsked = false;
                setting.IsGalleryPermissionAsked = false;
                setting.IsLocationPermissionAsked = false;
                setting.IsWalkthroughShown = false;
                return setting;
            }
        }

        public SettingsTable GetMemberSettings()
        {
            logger.Trace("MemberHelper: GetMemberSettings Starts at:" + DateTime.Now.ToString());
            List<SettingsTable> settings = dbRepository.GetAllRecords<SettingsTable>(string.Format("where MemberNumber={0}", Constants.MEMBER_NUMBER));
            logger.Trace("MemberHelper: GetMemberSettings Ends at:" + DateTime.Now.ToString());
            if (settings.Count > 0)
            {
                return settings[0];
            }
            return new SettingsTable();
        }

        /// <summary>
        /// Deletes the currently logged in user cached details.
        /// NOTE: This method statements not run on background service. Caller need to run this method inside background service if require
        /// </summary>
        public void ClearMemberData()
        {
            dbRepository.DeleteAllRecords<Member>();
            dbRepository.DeleteAllRecords<MemberAssociate>();
            dbRepository.DeleteAllRecords<ODISMember.Entities.Table.Membership>();
        }

        public ODISMember.Entities.Table.Membership GetMembershipLocal()
        {
            logger.Trace("MemberHelper: GetMembershipLocal Starts at:" + DateTime.Now.ToString());
            List<ODISMember.Entities.Table.Membership> memberships = new List<Entities.Table.Membership>();
            memberships = dbRepository.GetAllRecords<ODISMember.Entities.Table.Membership>();
            logger.Trace("MemberHelper: GetMembershipLocal Ends at:" + DateTime.Now.ToString());
            if (memberships.Count > 0)
            {
                return memberships[0];
            }
            else
            {
                return null;
            }
        }

        public ODISMember.Entities.Table.MemberAssociate GetLocalMembers()
        {
            logger.Trace("MemberHelper: GetLocalMembers Starts at:" + DateTime.Now.ToString());
            List<ODISMember.Entities.Table.MemberAssociate> memberAssociates = new List<Entities.Table.MemberAssociate>();
            memberAssociates = dbRepository.GetAllRecords<ODISMember.Entities.Table.MemberAssociate>();
            logger.Trace("MemberHelper: GetLocalMembers Ends at:" + DateTime.Now.ToString());
            if (memberAssociates.Count > 0)
            {
                return memberAssociates[0];
            }
            else
            {
                return null;
            }
        }

        public List<ODISMember.Entities.Table.ApplicationSettingsTable> GetLocalApplicationSettings()
        {
            logger.Trace("MemberHelper: GetLocalApplicationSettings Starts at:" + DateTime.Now.ToString());
            List<ODISMember.Entities.Table.ApplicationSettingsTable> listSettings = dbRepository.GetAllRecords<ODISMember.Entities.Table.ApplicationSettingsTable>();
            logger.Trace("MemberHelper: GetLocalApplicationSettings Ends at:" + DateTime.Now.ToString());
            return listSettings;
        }

        public async Task<OperationResult> GetLocalVehicleChassis()
        {
            logger.Trace("MemberHelper: GetLocalVehicleChassis Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = new OperationResult();
            List<VehicleChassis> items = dbRepository.GetAllRecords<VehicleChassis>();
            registrationResult.Status = OperationStatus.SUCCESS;
            registrationResult.Data = JsonConvert.SerializeObject(items);
            logger.Trace("MemberHelper: GetLocalVehicleChassis Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetLocalVehicleColors()
        {
            logger.Trace("MemberHelper: GetLocalVehicleColors Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = new OperationResult();

            List<VehicleColor> items = dbRepository.GetAllRecords<VehicleColor>();
            registrationResult.Status = OperationStatus.SUCCESS;
            registrationResult.Data = JsonConvert.SerializeObject(items);
            logger.Trace("MemberHelper: GetLocalVehicleColors Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetLocalVehicleEngines()
        {
            logger.Trace("MemberHelper: GetLocalVehicleEngines Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = new OperationResult();
            List<VehicleEngine> items = dbRepository.GetAllRecords<VehicleEngine>();
            registrationResult.Status = OperationStatus.SUCCESS;
            registrationResult.Data = JsonConvert.SerializeObject(items);
            logger.Trace("MemberHelper: GetLocalVehicleEngines Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetLocalVehicleTransmissions()
        {
            logger.Trace("MemberHelper: GetLocalVehicleTransmissions Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = new OperationResult();
            List<VehicleTransmission> items = dbRepository.GetAllRecords<VehicleTransmission>();
            registrationResult.Status = OperationStatus.SUCCESS;
            registrationResult.Data = JsonConvert.SerializeObject(items);
            logger.Trace("MemberHelper: GetLocalVehicleTransmissions Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public async Task<OperationResult> GetLocalCountryCodes()
        {
            logger.Trace("MemberHelper: GetLocalCountryCodes Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = new OperationResult();
            List<Countries> items = dbRepository.GetAllRecords<Countries>();
            registrationResult.Status = OperationStatus.SUCCESS;
            registrationResult.Data = JsonConvert.SerializeObject(items);
            logger.Trace("MemberHelper: GetLocalCountryCodes Ends at:" + DateTime.Now.ToString());
            return registrationResult;
        }

        public List<MakeModel> GetLocalMakeModels()
        {
            logger.Trace("MemberHelper: GetMakeModels Starts at:" + DateTime.Now.ToString());
            OperationResult registrationResult = new OperationResult();
            List<MakeModel> items = dbRepository.GetAllRecords<MakeModel>();
            logger.Trace("MemberHelper: GetMakeModels Ends at:" + DateTime.Now.ToString());
            return items;
        }

        public int? GetTelephoneCodeByCountryCode(string countryCode)
        {
            logger.Trace("MemberHelper: GetTelephoneCodeByCountryCode Starts at:" + DateTime.Now.ToString());
            var countries = dbRepository.GetAllRecords<Countries>(string.Format("WHERE ISOCode=='{0}'", countryCode));
            logger.Trace("MemberHelper: GetTelephoneCodeByCountryCode Ends at:" + DateTime.Now.ToString());
            if (countries.Count > 0)
            {
                int telephoneCode = 0;
                var isParsed = int.TryParse(countries[0].TelephoneCode.Trim(), out telephoneCode);
                if (isParsed)
                {
                    return telephoneCode;
                }
            }

            return null;
        }

        #endregion Local database operations

        #region WordPress Methods

        public async Task<List<WordPressFeedResult>> GetWordPressPosts()
        {
            var posts = new List<WordPressFeedResult>();
            /*Facing issue in iOS to call the Wordpress posts directly using end point. Exposed API to get the result from the server itself.*/
            logger.Trace("MemberHelper: GetWordPressPosts Starts at:" + DateTime.Now.ToString());
            var result = await memberService.GetWordPressPosts();
            if (result != null && result.Status == OperationStatus.SUCCESS && result.Data != null)
            {
                posts = JsonConvert.DeserializeObject<List<WordPressFeedResult>>(result.Data.ToString());
            }
            logger.Trace("MemberHelper: GetWordPressPosts Ends at:" + DateTime.Now.ToString());
            return posts;
        }

        #endregion WordPress Methods
    }
}