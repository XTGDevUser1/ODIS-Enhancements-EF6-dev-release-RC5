using MemberAPI.DAL.CNETService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.DAL
{
    public interface IMemberRepository
    {
        /// <summary>
        /// Validate if the credentials are correct.
        /// The method throws an exception when the validation fails.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="username">The username.</param>
        /// <param name="password">The password.</param>
        /// <returns></returns>
        LoginResult Login(int organizationID, string username, string password);

        /// <summary>
        /// Verifies the registration.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="postalCode">The postal code.</param>
        /// <returns></returns>
        RegisterVerifyResult VerifyRegistration(int organizationID, string memberNumber, string lastName, string firstName);

        /// <summary>
        /// Determines whether given username is already in use.
        /// Returns true if the username is not in use, false otherwise.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="username">The username.</param>
        /// <returns></returns>
        bool IsUsernameAvailable(int organizationID, string username);

        /// <summary>
        /// Determines weather member is available or not.
        /// Returns member details if available ortherwise null.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The MemberNumber.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        CheckMemberNumberResult VerifyMemberNumber(int organizationID, string memberNumber);

        /// <summary>
        /// Get Member by number
        /// </summary>
        /// <param name="organizationId">The organization identifier</param>
        /// <param name="memberNumber">The member number</param>
        /// <returns></returns>
        GetMemberResult GetMember(int organizationId, string memberNumber);

        /// <summary>
        /// Get Vehicles related to member
        /// </summary>
        /// <param name="organizationId">The organization identifier</param>
        /// <param name="memberNumber">The MemberNumber.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        List<GetVehicleResult> GetVechicle(int organizationId, string memberNumber);

        /// <summary>
        /// Register the Member
        /// </summary>
        /// <param name="memberNumber">The MemberNumber</param>
        /// <param name="username">Username</param>
        /// <param name="password">Password</param>
        /// <param name="source">Source</param>
        /// <returns></returns>
        bool Register(string memberNumber, string username, string password, string source);

        /// <summary>
        /// To update the web user
        /// </summary>
        /// <param name="memberNumber">Member Number</param>
        /// <param name="password">Password</param>
        /// <param name="organizationID">OrganizationId</param>
        /// <returns></returns>
        bool UpdateWebUser(string memberNumber, string password, int organizationID);

        /// <summary>
        /// To Insert or Update the Member Vehicle
        /// </summary>
        /// <param name="membershipNumber">Membership Number</param>
        /// <param name="cnetVehicleInformation">Vechicle Information</param>
        /// <returns></returns>
        bool AddEditMemberVehicle(string membershipNumber, CNETService.VehicleInformation cnetVehicleInformation);

        /// <summary>
        /// Gets the dependents.
        /// </summary>
        /// <param name="organizationId">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        List<GetDependentsResult> GetDependents(int organizationID, string memberNumber);

        /// <summary>
        /// Processes the dependents.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="dependents">The dependents.</param>
        /// <returns></returns>
        bool ProcessDependents(string membershipNumber, List<MemberDependent> dependents);

        /// <summary>
        /// Updates the membership.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="CNETMembership">The cnet membership.</param>
        /// <returns></returns>
        bool UpdateMembership(string membershipNumber, Membership cnetMembership);
    }
}
