using MemberAPI.DAL.CNETService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.DAL
{
    public class AptifyMemberRepository : IMemberRepository
    {
        /// <summary>
        /// Validate if the credentials are correct.
        /// The method throws an exception when the validation fails.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="username">The username.</param>
        /// <param name="password">The password.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public LoginResult Login(int organizationID, string username, string password)
        {
            using (APTIFYEntities dbContext = new APTIFYEntities())
            {
                return dbContext.spNMCAPI_Login(organizationID, username, password).ToList<LoginResult>().FirstOrDefault();
            }
        }

        /// <summary>
        /// Verifies the registration.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="postalCode">The postal code.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public RegisterVerifyResult VerifyRegistration(int organizationID, string memberNumber, string lastName, string firstName)
        {
            using (APTIFYEntities dbContext = new APTIFYEntities())
            {
                return dbContext.spNMCAPI_RegisterVerify(organizationID, memberNumber,lastName,firstName).ToList<RegisterVerifyResult>().FirstOrDefault();
            }
        }

        /// <summary>
        /// Determines whether given username is already in use.
        /// Returns true if the username is not in use, false otherwise.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="username">The username.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public bool IsUsernameAvailable(int organizationID, string username)
        {
            using (APTIFYEntities dbContext = new APTIFYEntities())
            {
                var retVal = dbContext.spNMCAPI_CheckUsername(organizationID, username).Single<int?>();
                return (retVal == null || retVal == 0);
            }
        }
               
        public bool Register(string memberNumber, string username, string password, string source)
        {
            string exceptionText = string.Empty;

            CNETService.CNETServiceClient client = new CNETService.CNETServiceClient ();            
            bool result = client.ProcessInsertWebUserAccount(memberNumber, username, password, source, ref exceptionText);

            return result;
        }

        /// <summary>
        /// Determines weather member is available or not.
        /// Returns member details if available ortherwise null.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The MemberNumber.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public CheckMemberNumberResult VerifyMemberNumber(int organizationID, string memberNumber)
        {
            using (APTIFYEntities dbContext = new APTIFYEntities())
            {
                return dbContext.spNMCAPI_CheckMemberNumber(organizationID, memberNumber).ToList<CheckMemberNumberResult>().FirstOrDefault();                
            }
        }

        public bool UpdateWebUser(string memberNumber, string password, int organizationID)
        {
            string exceptionText = string.Empty;            
            //TODO: Genereate Security Token
            string securityToken = null;

            CNETService.CNETServiceClient client = new CNETService.CNETServiceClient();
            var result = client.ProcessUpdateWebUserAccount(memberNumber, password, securityToken, organizationID, ref exceptionText);

            return result;
        }

        /// <summary>
        /// To Insert or Update the Member Vehicle
        /// </summary>
        /// <param name="membershipNumber">Membership Number</param>
        /// <param name="cnetVehicleInformation">Vechicle Information</param>
        /// <returns></returns>
        public bool AddEditMemberVehicle(string membershipNumber, CNETService.VehicleInformation cnetVehicleInformation)
        {
            string exceptionText = string.Empty;            

            CNETService.CNETServiceClient client = new CNETService.CNETServiceClient();
            var result = client.ProcessVehicle(membershipNumber, cnetVehicleInformation, ref exceptionText);

            return result;
        }

        /// <summary>
        /// Get Member
        /// </summary>
        /// <param name="memberNumber">The MemberNumber.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public GetMemberResult GetMember(int organizationId, string memberNumber)
        {
            using (APTIFYEntities dbContext = new APTIFYEntities())
            {
                return dbContext.spNMCAPI_GetMember(organizationId, memberNumber).ToList<GetMemberResult>().FirstOrDefault();
            }
        }

        /// <summary>
        /// Get Vehicle related to member
        /// </summary>
        /// <param name="memberNumber">The MemberNumber.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public List<GetVehicleResult> GetVechicle(int organizationID, string memberNumber)
        {
            using (APTIFYEntities dbContext = new APTIFYEntities())
            {
                return dbContext.spNMCAPI_GetVehicle(organizationID, memberNumber).ToList<GetVehicleResult>();
            }
        }

        /// <summary>
        /// Gets the dependents.
        /// </summary>
        /// <param name="organizationId">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        public List<GetDependentsResult> GetDependents(int organizationID, string memberNumber)
        {
            using (APTIFYEntities dbContext = new APTIFYEntities())
            {
                return dbContext.spNMCAPI_GetDependents(organizationID, memberNumber).ToList<GetDependentsResult>();
            }
        }

        /// <summary>
        /// Processes the dependents.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="dependents">The dependents.</param>
        /// <returns></returns>
        public bool ProcessDependents(string membershipNumber, List<MemberDependent> dependents)
        {
            string exceptionText = string.Empty;

            CNETService.CNETServiceClient client = new CNETService.CNETServiceClient();
            var result = client.ProcessDependents(membershipNumber, dependents.ToArray(), ref exceptionText);

            return result;
        }

        /// <summary>
        /// Updates the membership.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="CNETMembership">The cnet membership.</param>
        /// <returns></returns>
        public bool UpdateMembership(string membershipNumber, Membership cnetMembership)
        {
            string exceptionText = string.Empty;

            CNETService.CNETServiceClient client = new CNETService.CNETServiceClient();
            var result = client.UpdateMembership(membershipNumber, cnetMembership, ref exceptionText);

            return result;
        }
    }
}