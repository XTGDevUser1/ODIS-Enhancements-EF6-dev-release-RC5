using MemberAPI.DAL;
using MemberAPI.Services.Aptify;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using abo = Aptify.BusinessObjects;
using System.Configuration;
using MemberAPI.Services.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using System.Data;
using log4net;
using Newtonsoft.Json;

namespace MemberAPI.Services
{
    public class PinnacleMemberService : IMemberService
    {
        protected IMemberRepository _memberRepository;
        protected IMessageRepository _messageRepository;
        protected readonly IODISAPIService _odisapiService = new ODISAPIService();
        protected static readonly ILog logger = LogManager.GetLogger(typeof(PinnacleMemberService));

        const string LOGIN_FAILED_MESSAGE = "MemberLoginFailed";
        const string REGISTER_MEMBER_NOT_FOUND_MESSAGE = "Register_MemberNotFound";
        const string REGISTER_ALREADY_REGISTERED_MESSAGE = "Register_AlreadyRegistered";
        const string MEMBER_NUMBER_NOT_FOUND_MESSAGE = "MemberNumberNotFound";
        const string MEMBER_NUMBER_NOT_REGISTERED_MESSAGE = "MemberNumberNotRegistered";
        const string NO_EMAIL_ADDRESS_MESSAGE = "NoEmailAddress";
        const string MEMBER_NOT_FOUND = "MemberNotFound";
        const string NO_VEHICLES_FOUND = "NoVehiclesFound";
        const string USERNAME_ALREADY_TAKEN = "UsernameAlreadyTaken";
        const string WEB_USER_CREATE_ACCOUNT_FAILURE = "WebUserCreateAccountFailure";
        const string FORGOT_PASSWORD_FAILED = "ForgotPassword_Failed";
        const string DEPENDENT_INSERT_FAILED = "DependentInsertFailed";
        const string DEPENDENT_UPDATE_FAILED = "DependentUpdateFailed";
        const string VEHICLE_INSERT_FAILED = "VehicleInsertFailed";
        const string VEHICLE_UPDATE_FAILED = "VehicleUpdateFailed";
        const string MEMBER_UPDATE_FAILED = "MemberUpdateFailed";
        const string EMAIL = "Email";
        const string UNHANDLED_EXCEPTION = "UnhandledException";

        #region App Settings
        const string APTIFY_SERVER = "AptifyServer";
        const string APTIFY_USER_ID = "AptifyUserID";
        const string APTIFY_PASSWORD = "AptifyPassword";
        const string APTIFY_USER_NAME = "AptifyUserName";
        const string PMC_DOMAIN = "PMC_DOMAIN";
        const string APTIFY_DB_CONN = "AptifyDBConn";
        #endregion

        public abo.AppContext GetAppContext()
        {
            abo.AppContext appContext = new abo.AppContext();
            appContext.ServerName = ConfigurationManager.AppSettings[APTIFY_SERVER];
            appContext.UserID = Convert.ToInt64(ConfigurationManager.AppSettings[APTIFY_USER_ID]);
            appContext.Password = ConfigurationManager.AppSettings[APTIFY_PASSWORD];
            appContext.UserName = ConfigurationManager.AppSettings[APTIFY_USER_NAME];
            appContext.Domain = ConfigurationManager.AppSettings[PMC_DOMAIN];
            return appContext;
        }

        public PinnacleMemberService()
        {
            _memberRepository = new AptifyMemberRepository();
            _messageRepository = new MessageRepository();
        }

        /// <summary>
        /// Validate if the credentials are correct.
        /// The method throws an exception when the validation fails.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="username">The username.</param>
        /// <param name="password">The password.</param>
        /// <returns>LoginResult containing username and member details.</returns>
        /// <exception cref="MemberException">Friendy Exception Message</exception>
        /// <exception cref="System.Exception">Full exception detail</exception>
        public abo.MemberLogin Login(int organizationID, string username, string password)
        {
            abo.NMCApiMessage friendlyErrorMessage = new abo.NMCApiMessage();
            string exceptionText = string.Empty;

            logger.DebugFormat("Attempting to retrieve functions from {0}", ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);

            logger.Info("Execute login on Aptify");
            var response = functions.ExecuteLogin(organizationID, username, password, ref exceptionText, ref friendlyErrorMessage);

            logger.InfoFormat("Got response from Aptify functions, Friendly message [ {0} ] and Exception [ {1} ]", friendlyErrorMessage != null, exceptionText);
            if (!string.IsNullOrEmpty(friendlyErrorMessage.Name))
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }

            return response;
        }

        /// <summary>
        /// Verifies the registration.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="firstName"></param>
        /// <returns>
        /// Status of the registration verification
        /// </returns>
        /// <exception cref="MemberException">Friendy Exception Message</exception>
        /// <exception cref="System.Exception">Full exception detail</exception>
        public RegisterVerifyModel VerifyRegistration(int organizationID, string memberNumber, string lastName, string firstName)
        {
            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            MembershipService.PhoneNumber cellPhone = new MembershipService.PhoneNumber();
            string email = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());
            //var result = functions.RegisterVerify(organizationID, memberNumber, firstName, lastName, ref cellPhone, ref email, ref exceptionText, ref friendlyErrorMessage);
            var result = client.RegisterVerify(organizationID, memberNumber, firstName, lastName, ref cellPhone, ref email, ref exceptionText, ref friendlyErrorMessage);

            if (result)
            {
                return new RegisterVerifyModel() { CellPhone = cellPhone, Email = email, FirstName = firstName, LastName = lastName };
            }
            else
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }
        }

        /// <summary>
        /// Registers the specified organization identifier.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="objWebUser">The object web user.</param>
        /// <returns>True if registeration success else return exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        public bool Register(int organizationID, string membershipNumber, MembershipService.WebUser objWebUser)
        {
            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            MembershipService.PhoneNumber cellPhone = new MembershipService.PhoneNumber();
            string email = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());
            //var result = functions.RegisterUser(organizationID, membershipNumber, objWebUser, ref exceptionText, ref friendlyErrorMessage);
            var result = client.RegisterUser(organizationID, membershipNumber, objWebUser, ref exceptionText, ref friendlyErrorMessage);

            if (result)
            {
                return true;
            }
            else
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }
        }

        /// <summary>
        /// Joins a member to the system
        /// </summary>
        /// <param name="joinDetails">The join details.</param>
        /// <returns>
        /// Member number
        /// </returns>
        public string Join(Models.JoinModel joinDetails)
        {
            CNETServiceClient cnetServiceClient = new CNETServiceClient();
            //TODO: Complete the implementation.
            return string.Empty;
        }

        /// <summary>
        /// Resets the password.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="email">The member email.</param>
        /// <returns>true if password reset successful else throw exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        public bool ResetPassword(int organizationID, string email)
        {
            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());

            //var result = functions.ResetPassword(organizationID, memberNumber, ref exceptionText, ref friendlyErrorMessage);
            var result = client.ResetPassword(organizationID, email, ref exceptionText, ref friendlyErrorMessage);

            logger.InfoFormat("result: {0}, exceptionText: {1}, friendlyErrorMessage: {2}", result, exceptionText, friendlyErrorMessage != null ? JsonConvert.SerializeObject(friendlyErrorMessage) : null);

            if (!result)
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }

            return result;
        }

        private void CreateResetPasswordCommunicationQueue(string email)
        {
            DMSEntities dbContext = new DMSEntities();

            //TODO: ContactMethod need to replace
            var cm = dbContext.ContactMethods.Where(c => c.Name == "ContactMethod" && c.IsActive == true).FirstOrDefault<ContactMethod>();

            if (cm == null)
            {
                throw new MemberException("Unable to retrieve contact method");
            }

            var template = dbContext.Templates.Where(t => t.Name == "Member" + cm.Name && t.IsActive == true).FirstOrDefault<Template>();

            if (template == null)
            {
                throw new MemberException("Unable to retrieve template PurchaseOrder" + cm.Name);
            }

            CommunicationQueue cQueue = new CommunicationQueue();
            cQueue.ContactLogID = null;
            cQueue.ContactMethodID = cm.ID;
            cQueue.TemplateID = template.ID;
            //TODO: Need to Fill this Message Data from Hash table
            cQueue.MessageData = null;
            cQueue.Subject = null;
            cQueue.MessageText = null;
            cQueue.Attempts = null;
            cQueue.ScheduledDate = null;
            cQueue.CreateDate = DateTime.Now;
            cQueue.CreateBy = "System";
            cQueue.EventLogID = null;
            cQueue.NotificationRecipient = email;

            CommunicationQueueRepository cqRepository = new CommunicationQueueRepository();
            cqRepository.Save(cQueue);
        }

        /// <summary>
        /// Send User Name
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <exception cref="MemberException">Friendy Exception Message</exception>
        /// <exception cref="System.Exception">Full exception detail</exception>
        public void SendUserName(int organizationID, string email)
        {
            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());

            //var result = functions.SendUserName(organizationID, memberNumber, ref exceptionText, ref friendlyErrorMessage);

            var result = client.SendUserName(organizationID, email, ref exceptionText, ref friendlyErrorMessage);

            if (!result)
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }
        }


        /// <summary>
        /// Changes the password.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="objWebUser">The object web user.</param>
        /// <param name="oldPassword">The old password.</param>
        /// <returns>True if change password success else return exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        public bool ChangePassword(int organizationID, string membershipNumber, MembershipService.WebUser objWebUser, string oldPassword)
        {
            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());

            //var result = functions.ChangePassword(organizationID, membershipNumber, objWebUser, oldPassword, ref exceptionText, ref friendlyErrorMessage);
            var result = client.ChangePassword(organizationID, membershipNumber, objWebUser, oldPassword, ref exceptionText, ref friendlyErrorMessage);

            if (!result)
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }

            return result;
        }

        private void CreateSendUserNameCommunicationQueue(string email)
        {
            DMSEntities dbContext = new DMSEntities();

            //TODO: ContactMethod need to replace
            var cm = dbContext.ContactMethods.Where(c => c.Name == "Email" && c.IsActive == true).FirstOrDefault<ContactMethod>();

            if (cm == null)
            {
                throw new MemberException("Unable to retrieve contact method");
            }

            var template = dbContext.Templates.Where(t => t.Name == "Member_ForgotUsername" && t.IsActive == true).FirstOrDefault<Template>();

            if (template == null)
            {
                throw new MemberException("Unable to retrieve template Member_ForgotUsername");
            }

            CommunicationQueue cQueue = new CommunicationQueue();
            cQueue.ContactLogID = null;
            cQueue.ContactMethodID = cm.ID;
            cQueue.TemplateID = template.ID;
            //TODO: Need to Fill this Message Data from Hash table
            cQueue.MessageData = null;
            cQueue.Subject = null;
            cQueue.MessageText = null;
            cQueue.Attempts = null;
            cQueue.ScheduledDate = null;
            cQueue.CreateDate = DateTime.Now;
            cQueue.CreateBy = "System";
            cQueue.EventLogID = null;
            cQueue.NotificationRecipient = email;

            CommunicationQueueRepository cqRepository = new CommunicationQueueRepository();
            cqRepository.Save(cQueue);
        }

        /// <summary>
        /// Changes the password with token.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="passwordResetToken">The password reset token.</param>
        /// <param name="newPassword">The new password.</param>
        /// <returns>True if success else throws exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        public bool ChangePasswordWithToken(int organizationID, Guid passwordResetToken, string newPassword)
        {
            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            var result = client.ChangePasswordWithToken(organizationID, passwordResetToken, newPassword, ref exceptionText, ref friendlyErrorMessage);

            if (!result)
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }

            return result;
        }

        /// <summary>
        /// Gets the member.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>        
        /// <returns>Returns the List of Members</returns>
        /// <exception cref="MemberException">Friendy Exception Message</exception>        
        public List<abo.Member> GetMember(int organizationID, string membershipNumber)
        {
            string exceptionText = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetMembersForMembership(organizationID, membershipNumber, ref exceptionText);

            if (!string.IsNullOrEmpty(exceptionText))
            {
                throw new MemberException(exceptionText);
            }

            return result;
        }

        /// <summary>
        /// Deletes the member.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <returns>
        /// Returns true if member deletes else return exception
        /// </returns>
        /// <exception cref="MemberException"></exception>
        public bool DeleteMember(int organizationID, string memberNumber)
        {
            var client = new MembershipService.MembershipProcessingClient();

            string exceptionText = string.Empty;

            var result = client.DeleteMember(organizationID, memberNumber, ref exceptionText);

            if (!string.IsNullOrEmpty(exceptionText))
            {
                logger.InfoFormat("DeleteMember Method Service Excpetion: {0}", exceptionText);

                string friendlyExceptionText = string.Empty;
                abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
                abo.NMCApiMessage exceptionMessage = functions.GetFriendlyErrorMessage(organizationID, UNHANDLED_EXCEPTION, ref friendlyExceptionText);

                if (exceptionMessage != null)
                {
                    throw new MemberInfoException(exceptionMessage.Message, new Exception(exceptionMessage.Message));
                }
                else
                {
                    throw new MemberInfoException(friendlyExceptionText, new Exception(friendlyExceptionText));
                }
            }

            return result;
        }

        /// <summary>
        /// Gets the membership.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns>Membership details of the member</returns>
        /// <exception cref="MemberException"></exception>
        public abo.Membership GetMembership(int organizationID, string membershipNumber)
        {
            string exceptionText = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetMembership(organizationID, membershipNumber, ref exceptionText);

            if (!string.IsNullOrEmpty(exceptionText))
            {
                throw new MemberException(exceptionText);
            }

            return result;
        }

        /// <summary>
        /// Updates the membership.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membership">The membership.</param>
        /// <returns>true if it success else it throw exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        public bool UpdateMembership(int organizationID, MembershipService.Membership membership)
        {

            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());

            //var result = functions.ProcessMembership(organizationID, membership, ref exceptionText, ref friendlyErrorMessage);
            var result = client.ProcessMembership(organizationID, membership, ref exceptionText, ref friendlyErrorMessage);
            if (!result)
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }

            return result;
        }

        /// <summary>
        /// Gets the vehicle.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns>Returns the Vehicle information related to member</returns>
        /// <exception cref="MemberException"></exception>
        public List<abo.VehicleInformation> GetVehicle(int organizationID, string membershipNumber)
        {
            string errorMessage = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetVehiclesForMembership(organizationID, membershipNumber, ref errorMessage);

            if (result.Count <= 0)
            {
                string exceptionText = string.Empty;
                abo.NMCApiMessage exceptionMessage = functions.GetFriendlyErrorMessage(organizationID, NO_VEHICLES_FOUND, ref exceptionText);

                if (exceptionMessage != null)
                {
                    logger.InfoFormat("GetVehicle - GetFriendlyErrorMessage Method: {0} - {1}", exceptionMessage.Name, exceptionMessage.Message);
                    throw new MemberInfoException(exceptionMessage.Message, new Exception(exceptionMessage.Message));
                }
                else
                {
                    logger.InfoFormat("GetVehicle - GetFriendlyErrorMessage Method: {0} - {1}", NO_VEHICLES_FOUND, exceptionText);
                    throw new MemberInfoException(exceptionText, new Exception(exceptionText));
                }
            }

            return result;
        }


        /// <summary>
        /// Adds the edit member vehicle.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="vehicles">The vehicles.</param>
        /// <returns>True after successfully inserts/updates else return exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        public bool AddEditMemberVehicle(int organizationID, string membershipNumber, List<MembershipService.VehicleInformation> vehicles)
        {
            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());

            //var result = functions.ProcessVehicles(organizationID, membershipNumber, vehicles, ref exceptionText, ref friendlyErrorMessage);
            var result = client.ProcessVehicles(organizationID, membershipNumber, vehicles.ToArray(), ref exceptionText, ref friendlyErrorMessage);

            if (!result)
            {
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }

            return result;
        }

        /// <summary>
        /// Deletes the vehicle.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="vehicleId">The vehicle identifier.</param>
        /// <returns>true if vehicle deletes else throws exception</returns>
        /// <exception cref="MemberException"></exception>
        public bool DeleteVehicle(int organizationID, long vehicleId)
        {
            var client = new MembershipService.MembershipProcessingClient();

            string exceptionText = string.Empty;

            var result = client.DeleteVehicle(organizationID, vehicleId, ref exceptionText);

            if (!string.IsNullOrEmpty(exceptionText))
            {
                logger.InfoFormat("DeleteVehicle Method Service Excpetion: {0}", exceptionText);

                string friendlyExceptionText = string.Empty;
                abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
                abo.NMCApiMessage exceptionMessage = functions.GetFriendlyErrorMessage(organizationID, UNHANDLED_EXCEPTION, ref friendlyExceptionText);

                if (exceptionMessage != null)
                {
                    throw new MemberInfoException(exceptionMessage.Message, new Exception(exceptionMessage.Message));
                }
                else
                {
                    throw new MemberInfoException(friendlyExceptionText, new Exception(friendlyExceptionText));
                }
            }

            return result;
        }

        /// <summary>
        /// Gets the dependents.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        public List<GetDependentsResult> GetDependents(int organizationID, string memberNumber)
        {
            return _memberRepository.GetDependents(organizationID, memberNumber);
        }

        /// <summary>
        /// Processes the dependents.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="dependents">The dependents.</param>
        /// <param name="isPostRequest">if set to <c>true</c> [is post request].</param>
        /// <returns></returns>
        /// <exception cref="MemberException">
        /// </exception>
        public bool ProcessDependents(int organizationID, string membershipNumber, List<DAL.CNETService.MemberDependent> dependents, bool isPostRequest)
        {
            var result = _memberRepository.ProcessDependents(membershipNumber, dependents);
            if (!result)
            {
                if (isPostRequest)
                {
                    var errorMessage = _messageRepository.GetErrorMessage(organizationID, DEPENDENT_INSERT_FAILED);
                    throw new MemberException(errorMessage);
                }
                else
                {
                    var errorMessage = _messageRepository.GetErrorMessage(organizationID, DEPENDENT_UPDATE_FAILED);
                    throw new MemberException(errorMessage);
                }
            }

            return result;
        }


        /// <summary>
        /// Updates the membership.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="CNETMembership">The cnet membership.</param>
        /// <returns></returns>
        /// <exception cref="MemberException"></exception>
        public bool UpdateMembership(int organizationID, string membershipNumber, DAL.CNETService.Membership cnetMembership)
        {
            var result = _memberRepository.UpdateMembership(membershipNumber, cnetMembership);
            if (!result)
            {
                var errorMessage = _messageRepository.GetErrorMessage(organizationID, MEMBER_UPDATE_FAILED);
                throw new MemberException(errorMessage);
            }
            return result;
        }

        /// <summary>
        /// Services the requests.
        /// </summary>
        /// <param name="accessToken">The access token.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns>Member Service Requests Hisotry</returns>
        public List<ODISAPISearchSRListModel> History(string memberNumber, string membershipNumber, int programID, string sourceSystem)
        {
            var accessToken = _odisapiService.Authenticate();
            if (!string.IsNullOrEmpty(accessToken))
            {
                return _odisapiService.ServiceRequests(accessToken, memberNumber, membershipNumber, programID, sourceSystem);
            }

            throw new MemberException("Authentication Failed for ODIS API");
        }

        /// <summary>
        /// Gets the active request.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        /// <exception cref="MemberException">Authentication Failed for ODIS API</exception>
        public ODISAPISearchSRListModel GetActiveRequest(string memberNumber, string membershipNumber, int programID)
        {
            var accessToken = _odisapiService.Authenticate();
            if (!string.IsNullOrEmpty(accessToken))
            {
                return _odisapiService.GetActiveRequest(accessToken, memberNumber, membershipNumber, programID);
            }

            throw new MemberException("Authentication Failed for ODIS API");
        }

        public ODISAPISearchSRListModel GetServiceRequest(int serviceRequestID)
        {
            return _odisapiService.GetServiceRequest(serviceRequestID);
        }

        /// <summary>
        /// Adds the edit member.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="members">The members.</param>
        /// <returns>True if Member Inserts or Updates else returns exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        public bool AddEditMember(int organizationID, string membershipNumber, List<MembershipService.Member> members)
        {
            var client = new MembershipService.MembershipProcessingClient();

            MembershipService.NMCApiMessage friendlyErrorMessage = new MembershipService.NMCApiMessage();
            string exceptionText = string.Empty;

            //BusinessFunctions functions = new BusinessFunctions(GetAppContext());

            //var result = functions.ProcessMembers(organizationID, membershipNumber, members, ref exceptionText, ref friendlyErrorMessage);
            var result = client.ProcessMembers(organizationID, membershipNumber, members.ToArray(), ref exceptionText, ref friendlyErrorMessage);

            if (!result)
            {
                if (friendlyErrorMessage != null)
                {
                    logger.InfoFormat("AddEditMember - ProcessMembers Exception Reulst: exceptionText - {0} friendlyErrorMessage - {1}", exceptionText,
                        JsonConvert.SerializeObject(friendlyErrorMessage, Formatting.Indented, new JsonSerializerSettings { PreserveReferencesHandling = PreserveReferencesHandling.Objects }));
                }
                else
                {
                    logger.InfoFormat("AddEditMember - ProcessMembers Exception Reulst: exceptionText - {0} friendlyErrorMessage - Object is Null", exceptionText);
                }
                throw new MemberException(friendlyErrorMessage.Message, new Exception(exceptionText));
            }

            return result;
        }

        /// <summary>
        /// Gets the DMS vehicle chassis list.
        /// </summary>
        /// <returns>Vehicle chassis</returns>
        public List<KeyValuePair<string, int>> GetDMSVehicleChassisList()
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetDMSVehicleChassisList();

            return result;
        }

        /// <summary>
        /// Gets the DMS vehicle color list.
        /// </summary>
        /// <returns>Vehicle colors</returns>
        public List<KeyValuePair<string, string>> GetDMSVehicleColorList()
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetDMSVehicleColorList();

            return result;
        }

        /// <summary>
        /// Gets the DMS vehicle engine list.
        /// </summary>
        /// <returns>Vehicle Engine</returns>
        public List<KeyValuePair<string, int>> GetDMSVehicleEngineList()
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetDMSVehicleEngineList();

            return result;
        }

        /// <summary>
        /// Gets the DMS vehicle make list.
        /// </summary>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <returns>Vehicle Make</returns>
        public List<KeyValuePair<string, string>> GetDMSVehicleMakeList(long vehicleTypeID)
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetDMSVehicleMakeList(vehicleTypeID);

            return result;
        }

        /// <summary>
        /// Gets the DMS vehicle model list.
        /// </summary>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <param name="make">The make.</param>
        /// <returns>Vehilce Models</returns>
        public List<KeyValuePair<string, string>> GetDMSVehicleModelList(long vehicleTypeID, string make)
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetDMSVehicleModelList(vehicleTypeID, make);

            return result;
        }

        /// <summary>
        /// Gets the states for country.
        /// </summary>
        /// <param name="countryID">The country identifier.</param>
        /// <returns>States related to country</returns>
        public List<KeyValuePair<string, string>> GetStatesForCountry(long countryID)
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetStatesForCountry(countryID);

            return result;
        }

        /// <summary>
        /// Gets the DMS vehicle type list.
        /// </summary>
        /// <param name="programId">The program identifier.</param>
        /// <returns>Vehicle Types Dictionary Values</returns>
        public List<KeyValuePair<string, int>> GetDMSVehicleTypeList(long programId)
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetDMSVehicleTypeList(programId);

            return result;
        }

        /// <summary>
        /// Gets the DMS vehicle transmission list.
        /// </summary>
        /// <returns>Vehicle Transmissions</returns>
        public List<KeyValuePair<string, int>> GetDMSVehicleTransmissionList()
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetDMSVehicleTransmissionList();

            return result;
        }

        /// <summary>
        /// Gets the countries.
        /// </summary>
        /// <returns>country names along with country code</returns>
        public List<abo.Country> GetCountryCodes()
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetCountryCodes();

            return result;
        }

        /// <summary>
        /// Gets the application settings.
        /// </summary>
        /// <param name="OrganizationID">The organization identifier.</param>
        /// <returns></returns>
        public List<KeyValuePair<string, string>> GetApplicationSettings(long OrganizationID)
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetApplicationSettings(OrganizationID);

            return result;
        }

        /// <summary>
        /// Gets the DMS make model data
        /// </summary>
        /// <returns></returns>
        public DataTable GetDMSMakeModel()
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            var result = functions.GetDMSMakeModel();

            return result;
        }

        /// <summary>
        /// Send email to member
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="objWebUser">The object web user.</param>
        /// <param name="emailType">Type of the email.</param>
        /// <returns></returns>
        public bool SendMemberEmail(long organizationID, MemberAPI.Services.MembershipService.WebUser objWebUser, MembershipService.enumMemberEmailType emailType)
        {
            var client = new MembershipService.MembershipProcessingClient();

            string exceptionText = string.Empty;

            var result = client.SendMemberEmail(organizationID, objWebUser, emailType, ref exceptionText);

            logger.InfoFormat("SendMemberEmail Input Params: emailType - {0} webUser - {1}", emailType,
                        JsonConvert.SerializeObject(objWebUser, Formatting.Indented, new JsonSerializerSettings { PreserveReferencesHandling = PreserveReferencesHandling.Objects }));

            if (!result)
            {
                logger.InfoFormat("SendMemberEmail Result: exceptionText - {0}", exceptionText);

                throw new MemberException(exceptionText, new Exception(exceptionText));
            }

            return result;
        }

        /// <summary>
        /// Get the member details
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        public abo.Member GetMemberByNumber(int organizationID, string memberNumber)
        {
            abo.Queries functions = new abo.Queries(ConfigurationManager.AppSettings[APTIFY_DB_CONN]);
            string exceptionText = string.Empty;

            var result = functions.GetMemberStatus(organizationID, memberNumber, ref exceptionText);
            logger.InfoFormat("IsMemberActive Input Params: organization ID - {0} member number - {1}", organizationID, memberNumber);
            
            return result;
        }
    }
}
