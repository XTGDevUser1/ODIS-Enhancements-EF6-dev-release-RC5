using MemberAPI.DAL;
using MemberAPI.Services.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using abo = Aptify.BusinessObjects;

namespace MemberAPI.Services
{
    public interface IMemberService
    {
        /// <summary>
        /// Validate if the credentials are correct.
        /// The method throws an exception when the validation fails.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="username">The username.</param>
        /// <param name="password">The password.</param>
        /// <returns>LoginResult containing username and member details.</returns>
        //LoginResult Login(int organizationID, string username, string password);

        /// <summary>
        /// Validate if the credentials are correct.
        /// The method throws an exception when the validation fails.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="username">The username.</param>
        /// <param name="password">The password.</param>
        /// <returns>LoginResult containing username and member details.</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        abo.MemberLogin Login(int organizationID, string username, string password);

        /// <summary>
        /// Verifies the registration.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="postalCode">The postal code.</param>
        /// <returns>Status of the registration verification</returns>
        //RegisterVerifyResult VerifyRegistration(int organizationID, string memberNumber, string lastName, string firstName);

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
        RegisterVerifyModel VerifyRegistration(int organizationID, string memberNumber, string lastName, string firstName);
        
        /// <summary>
        /// To register member with CNET Service
        /// </summary>
        /// <param name="organizationID">Origanization Id</param>
        /// <param name="memberNumber">Member Number</param>
        /// <param name="username">User Name</param>
        /// <param name="password">Password</param>
        /// <returns>Throw excpetion if register fail</returns>
        //bool Register(int organizationID, string memberNumber, string username, string password);

        /// <summary>
        /// Registers the specified organization identifier.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="objWebUser">The object web user.</param>
        /// <returns>True if registeration success else return exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        bool Register(int organizationID, string membershipNumber, MembershipService.WebUser objWebUser);

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
        bool ChangePassword(int organizationID, string membershipNumber, MembershipService.WebUser objWebUser, string oldPassword);

        /// <summary>
        /// Changes the password with token.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="passwordResetToken">The password reset token.</param>
        /// <param name="newPassword">The new password.</param>
        /// <returns>True if success else throws exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        bool ChangePasswordWithToken(int organizationID, Guid passwordResetToken, string newPassword);

        /// <summary>
        /// Joins a member to the system
        /// </summary>
        /// <param name="joinDetails">The join details.</param>
        /// <returns>Member number</returns>
        string Join(JoinModel joinDetails);

         /// <summary>
        /// Resets the password.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="email">The member email.</param>
        /// <returns>true if password reset successful else throw exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        bool ResetPassword(int organizationID, string email);

         /// <summary>
        /// Send User Name
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="postalCode">The postal code.</param>
        /// <returns>
        /// Status of the registration verification
        /// </returns>
        /// <exception cref="System.NotImplementedException"></exception>
        //void SendUserName(int organizationID, string memberNumber);

        /// <summary>
        /// Send User Name
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <exception cref="MemberException">Friendy Exception Message</exception>
        /// <exception cref="System.Exception">Full exception detail</exception>
        void SendUserName(int organizationID, string email);

        /// <summary>
        /// Get Member
        /// </summary>       
        /// <param name="memberNumber">The member number.</param>
        /// <returns>
        /// Get the Memberr by member number
        /// </returns>
        /// <exception cref="System.NotImplementedException"></exception>
        //GetMemberResult GetMember(int organizationID, string memberNumber);

        /// <summary>
        /// Gets the member.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>        
        /// <returns>Returns the List of Members</returns>
        /// <exception cref="MemberException">Friendy Exception Message</exception>        
        List<abo.Member> GetMember(int organizationID, string membershipNumber);

        /// <summary>
        /// Deletes the member.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <returns>Returns true if member deletes else return exception</returns>
        /// <exception cref="MemberException"></exception>        
        bool DeleteMember(int organizationID, string memberNumber);

        /// <summary>
        /// Gets the membership.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns>Membership details of the member</returns>
        /// <exception cref="MemberException"></exception>
        abo.Membership GetMembership(int organizationID, string membershipNumber);

        /// <summary>
        /// Updates the membership.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membership">The membership.</param>
        /// <returns>true if it success else it throw exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        bool UpdateMembership(int organizationID, MembershipService.Membership membership);

        /// <summary>
        /// Get Member Vechicle
        /// </summary>       
        /// <param name="memberNumber">The member number.</param>
        /// <returns>
        /// Get the Memberr by member number
        /// </returns>
        /// <exception cref="System.NotImplementedException"></exception>
        //List<GetVehicleResult> GetVehicle(int organizationID, string memberNumber);

        /// <summary>
        /// Gets the vehicle.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns>Returns the Vehicle information related to member</returns>
        /// <exception cref="MemberException"></exception>
        List<abo.VehicleInformation> GetVehicle(int organizationID, string membershipNumber);

        /// <summary>
        /// To Insert or Update the Member Vehicle
        /// </summary>
        /// <param name="membershipNumber">Membership Number</param>
        /// <param name="cnetVehicleInformation">Vechicle Information</param>
        /// <returns></returns>
        //bool AddEditMemberVehicle(int organizationID, string membershipNumber, MemberAPI.DAL.CNETService.VehicleInformation cnetVehicleInformation, bool isPostRequest);

        /// <summary>
        /// Adds the edit member vehicle.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="vehicles">The vehicles.</param>
        /// <returns>True after successfully inserts/updates else return exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        bool AddEditMemberVehicle(int organizationID, string membershipNumber, List<MembershipService.VehicleInformation> vehicles);

        /// <summary>
        /// Deletes the vehicle.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="vehicleId">The vehicle identifier.</param>
        /// <returns>true if vehicle deletes else throws exception</returns>
        /// <exception cref="MemberException"></exception>
        bool DeleteVehicle(int organizationID, long vehicleId);

        /// <summary>
        /// Gets the dependents.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        List<GetDependentsResult> GetDependents(int organizationID, string memberNumber);

        /// <summary>
        /// Processes the dependents.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="dependents">The dependents.</param>
        /// <param name="isPostRequest">if set to <c>true</c> [is post request].</param>
        /// <returns></returns>
        bool ProcessDependents(int organizationID, string membershipNumber, List<DAL.CNETService.MemberDependent> dependents, bool isPostRequest);

        /// <summary>
        /// Updates the membership.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="CNETMembership">The cnet membership.</param>
        /// <returns></returns>
        bool UpdateMembership(int organizationID, string membershipNumber, DAL.CNETService.Membership cnetMembership);

        /// <summary>
        /// Services the requests.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <param name="sourceSystem">The source system.</param>
        /// <returns>
        /// Member Service Requests Hisotry
        /// </returns>
        List<ODISAPISearchSRListModel> History(string memberNumber,string membershipNumber, int programID, string sourceSystem);

        /// <summary>
        /// Gets the active request.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        ODISAPISearchSRListModel GetActiveRequest(string memberNumber, string membershipNumber, int programID);

        /// <summary>
        /// Gets the service request.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        ODISAPISearchSRListModel GetServiceRequest(int serviceRequestID);

        /// <summary>
        /// Adds the edit member.
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="members">The members.</param>
        /// <returns>True if Member Inserts or Updates else returns exception</returns>
        /// <exception cref="MemberException"></exception>
        /// <exception cref="System.Exception"></exception>
        bool AddEditMember(int organizationID, string membershipNumber, List<MembershipService.Member> members);

        /// <summary>
        /// Gets the DMS vehicle chassis list.
        /// </summary>
        /// <returns>Vehicle chassis</returns>
        List<KeyValuePair<string, int>> GetDMSVehicleChassisList();

        /// <summary>
        /// Gets the DMS vehicle color list.
        /// </summary>
        /// <returns>Vehicle colors</returns>
        List<KeyValuePair<string, string>> GetDMSVehicleColorList();

        /// <summary>
        /// Gets the DMS vehicle engine list.
        /// </summary>
        /// <returns>Vehicle Engine</returns>
        List<KeyValuePair<string, int>> GetDMSVehicleEngineList();

        /// <summary>
        /// Gets the DMS vehicle make list.
        /// </summary>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <returns>Vehicle Make</returns>
        List<KeyValuePair<string, string>> GetDMSVehicleMakeList(long vehicleTypeID);

        /// <summary>
        /// Gets the DMS vehicle model list.
        /// </summary>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <param name="make">The make.</param>
        /// <returns>Vehilce Models</returns>
        List<KeyValuePair<string, string>> GetDMSVehicleModelList(long vehicleTypeID, string make);

        /// <summary>
        /// Gets the states for country.
        /// </summary>
        /// <param name="countryID">The country identifier.</param>
        /// <returns>States related to country</returns>
        List<KeyValuePair<string, string>> GetStatesForCountry(long countryID);

        /// <summary>
        /// Gets the DMS vehicle type list.
        /// </summary>
        /// <param name="programId">The program identifier.</param>
        /// <returns>Vehicle Types Dictionary Values</returns>
        List<KeyValuePair<string, int>> GetDMSVehicleTypeList(long programId);

        /// <summary>
        /// Gets the DMS vehicle transmission list.
        /// </summary>
        /// <returns>Vehicle Transmissions</returns>
        List<KeyValuePair<string, int>> GetDMSVehicleTransmissionList();

        /// <summary>
        /// Gets the countries.
        /// </summary>
        /// <returns>country names along with country code</returns>
        List<abo.Country> GetCountryCodes();

        /// <summary>
        /// Gets the application settings.
        /// </summary>
        /// <param name="OrganizationID">The organization identifier.</param>
        /// <returns></returns>
        List<KeyValuePair<string, string>> GetApplicationSettings(long OrganizationID);

        /// <summary>
        /// Gets the DMS make model data
        /// </summary>
        /// <returns></returns>
        DataTable GetDMSMakeModel();

        /// <summary>
        /// Send email to member
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="objWebUser">The object web user.</param>
        /// <param name="emailType">Type of the email.</param>
        /// <returns></returns>
        bool SendMemberEmail(long organizationID, MembershipService.WebUser objWebUser, MembershipService.enumMemberEmailType emailType);

        /// <summary>
        /// Gets the member by member number
        /// </summary>
        /// <param name="organizationID">The organization identifier.</param>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        abo.Member GetMemberByNumber(int organizationID, string memberNumber);
    }
}
