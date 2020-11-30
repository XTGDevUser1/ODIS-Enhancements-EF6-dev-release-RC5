using ODISMember.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ODISMember.Entities.Model;

namespace ODISMember.Services.Contract
{
    public interface IMemberService
    {
        /// <summary>
        /// Logins with the specified username and password
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <param name="password">The password. 
        /// Note:Password should follow the specified rules</param>
        /// <returns>Member details</returns>
        Task<AccessResult> Login(string userName, string password);

        /// <summary>
        /// To Join the Member
        /// </summary>
        /// <param name="memberModel">The member model.</param>
        /// <returns></returns>
        Task<OperationResult> Join(MemberModel memberModel);

        /// <summary>
        /// Verify the member register details
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="firstName">The first name.</param>
        /// <returns>returns Success in Status property on successful verification, returns ErrorMessage on verification fails </returns>
        Task<OperationResult> RegisterVerify(string memberNumber, string lastName, string firstName);

        /// <summary>
        /// Registers member by using membership details
        /// </summary>
        /// <param name="registerSendModel">The register send model.</param>
        /// <returns>returns Success in Status property on successful registeration, returns ErrorMessage on registration fails</returns>
        Task<OperationResult> Register(RegisterSendModel registerSendModel);

        /// <summary>
        /// Resets the member password.
        /// </summary>
        /// <param name="email">Member registered email.</param>
        /// <returns>returns Success in Status property on successful reset of password, returns ErrorMessage on reset password fails</returns>
        Task<OperationResult> ResetPassword(string email);

        /// <summary>
        /// Sends mail to member registered email
        /// </summary>
        /// <param name="email">Member registered email.</param>
        /// <returns>returns Success in Status property on successful reset of password, returns ErrorMessage on reset password fails</returns>
        Task<OperationResult> SendUserName(string email);

        /// <summary>
        /// Changes the member password.
        /// </summary>
        /// <param name="changePasswordSendModel">The change password send model.</param>
        /// <returns>returns Success in Status property on successful change password, returns ErrorMessage on change password fails</returns>
        Task<OperationResult> ChangePassword(RegisterSendModel changePasswordSendModel);

        Task<OperationResult> AddVehicles(List<VehicleModel> vehicle);

        /// <summary>
        /// Gets the membership.
        /// </summary>
        /// <returns>Get the membership details</returns>
        Task<OperationResult> GetMembership();

        /// <summary>
        /// Gets the members.
        /// </summary>
        /// <returns>Get the members</returns>
        Task<OperationResult> GetMembers();

        Task<OperationResult> GetActiveRequest(string membershipNumber);

        /// <summary>
        /// Gets the member hisotry.
        /// </summary>        
        /// <returns>Membership History</returns>
        Task<OperationResult> GetMemberHistory();

        /// <summary>
        /// Submits the service request.
        /// </summary>
        /// <param name="serviceRequestModel">The service request model.</param>
        /// <returns>if request submit success Tracking UID returns</returns>
        Task<OperationResult> SubmitServiceRequest(ServiceRequestModel serviceRequestModel);
    }
}
