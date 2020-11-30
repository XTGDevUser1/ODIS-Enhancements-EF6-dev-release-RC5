using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using ms = System.Web.Security;
using System.Web.Security;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;
using log4net;


namespace Martex.DMS.BLL.Facade
{
    public class VendorUserFacade
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorUserFacade));

        /// <summary>
        /// Adds the user.
        /// </summary>
        /// <param name="aspNetUser">The aspnet user.</param>
        /// <param name="vendorUser">The vendor user.</param>
        public MembershipUser AddUser(aspnet_Users aspNetUser, VendorUser vendorUser, string user)
        {
            MembershipCreateStatus mcreationStatus = MembershipCreateStatus.Success;
            try
            {
                MembershipUser membershipUser = ms.Membership.CreateUser(aspNetUser.UserName,
                                                          aspNetUser.aspnet_Membership.Password,
                                                          aspNetUser.aspnet_Membership.Email,
                                                          null,
                                                          null,
                                                          aspNetUser.aspnet_Membership.IsApproved,
                                                          out mcreationStatus);
                switch (mcreationStatus)
                {
                    case MembershipCreateStatus.Success:
                        Roles.AddUserToRoles(aspNetUser.UserName, aspNetUser.aspnet_Roles.Select(c => c.RoleName).ToArray());                        
                        using (TransactionScope tran = new TransactionScope())
                        {
                            VendorRepository vendorRepository = new VendorRepository();
                            vendorUser.aspnet_UserID = (Guid)membershipUser.ProviderUserKey;
                            // 1. Write to VendorUser table.
                            logger.Info("Adding a record to VendorUser");
                            vendorRepository.AddVendorUser(vendorUser, user,true);

                            //2. Event Logs.
                            //EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                            //logger.Info("Logging an event to EventLog table");
                            //eventLogFacade.LogEvent(eventSource, EventNames.WEB_REGISTRATION, eventDetails, user, sessionID);

                            tran.Complete();
                        }
                        //TODO: Event logs.
                        return membershipUser;

                    case MembershipCreateStatus.DuplicateUserName:
                        throw new DMSException("That User name already exists");

                    case MembershipCreateStatus.InvalidPassword:
                        throw new DMSException("Password is not in proper format");

                    case MembershipCreateStatus.DuplicateEmail:
                        throw new DMSException("This email is already in use.  Please try another email address.");
                    case MembershipCreateStatus.InvalidUserName:
                    case MembershipCreateStatus.InvalidEmail:
                    case MembershipCreateStatus.UserRejected:
                        throw new DMSException(mcreationStatus.ToString());

                    default:
                        throw new DMSException("User Creation Error");

                }
            }
            catch (Exception ex)
            {
                if (mcreationStatus == MembershipCreateStatus.Success)
                    ms.Membership.DeleteUser(aspNetUser.UserName, true);
                throw ex;
            }

        }

        /// <summary>
        /// Gets the specified id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public aspnet_Users Get(Guid id)
        {
            IRepository<aspnet_Users> userRepository = new UserRepository();
            return userRepository.Get<Guid>(id);
        }

        /// <summary>
        /// Updates the user.
        /// </summary>
        /// <param name="aspnetUser">The aspnet user.</param>
        /// <param name="vendorUser">The vendor user.</param>
        public void UpdateUser(aspnet_Users aspNetUser, VendorUser vendorUser)
        {
            // Call Membership.UpdateUser
            MembershipUserCollection users = ms.Membership.FindUsersByName(aspNetUser.UserName);
            MembershipUserCollection usersWithEmail = ms.Membership.FindUsersByEmail(aspNetUser.aspnet_Membership.Email);

            if (users.Count > 0)
            {

                MembershipUser u = users[aspNetUser.UserName];

                if (u.Email != aspNetUser.aspnet_Membership.Email && usersWithEmail.Count > 0)
                {
                    throw new DMSException("This email is already in use.  Please try another email address.");
                }
                u.Email = aspNetUser.aspnet_Membership.Email;
                u.IsApproved = aspNetUser.aspnet_Membership.IsApproved;
                ms.Membership.UpdateUser(u);
                u.UnlockUser();
            }

            //Check if password is blank no need to reset or update
            if (!string.IsNullOrEmpty(aspNetUser.aspnet_Membership.Password))
            {
                if (!ms.Membership.GetUser(aspNetUser.UserName).ChangePassword(ms.Membership.GetUser(aspNetUser.UserName).ResetPassword(), aspNetUser.aspnet_Membership.Password))
                {
                    throw new DMSException("Error while updating the password");
                }
            }
            //Delete Roles First
            string[] roleList = Roles.GetRolesForUser(aspNetUser.UserName);
            if (roleList.Count() > 0)
            {
                Roles.RemoveUserFromRoles(aspNetUser.UserName, roleList);
            }
            Roles.AddUserToRoles(aspNetUser.UserName, aspNetUser.aspnet_Roles.Select(c => c.RoleName).ToArray());


            // Vendor user.
            VendorUserRepository vurRepository = new VendorUserRepository();
            vurRepository.UpdateUser(vendorUser);
        }

        /// <summary>
        /// Deletes the user.
        /// </summary>
        /// <param name="aspnetUser">The aspnet user.</param>
        /// <param name="vendorUser">The vendor user.</param>
        public void DeleteUser(Guid aspnetUserID)
        {
            VendorUserRepository repository = new VendorUserRepository();
            repository.DeleteUser(aspnetUserID);
        }

        /// <summary>
        /// Return List of users for Vendor Portal
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<UsersForVendorPortal_Result> GetUsersForVendorPortal(Guid? userID, PageCriteria pageCriteria)
        {
            VendorUserRepository repository = new VendorUserRepository();
            return repository.GetUsersForVendorPortal(userID, pageCriteria);
        }

        /// <summary>
        /// Gets the roles.
        /// </summary>
        /// <returns></returns>
        public List<aspnet_Roles> GetRoles()
        {
            return ReferenceDataRepository.GetRoles(ms.Membership.ApplicationName);
        }

        public VendorUserProfile_Result GetVendorUserProfile(string loggedInUserName)
        {
            VendorUserRepository repository = new VendorUserRepository();
            return repository.GetVendorUserProfile(loggedInUserName);
        }

    }
}
