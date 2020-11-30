using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using log4net;
using membershipProvider = System.Web.Security;
using System.Web.Security;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Manage Users
    /// </summary>
    public class UsersFacade
    {
        #region Public Methods
        /// <summary>
        /// Lists the specified user ID.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<SearchUsersResult> List(Guid? userID, PageCriteria pageCriteria)
        {
            UserRepository repository = new UserRepository();
            var list = repository.Search(userID, pageCriteria);
            return list;
        }

        /// <summary>
        /// Lists the client portal.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<SearchUsersListClientPortal_Result> ListClientPortal(Guid? userID, PageCriteria pageCriteria)
        {
            UserRepository repository = new UserRepository();
            var list = repository.SearchClientProfile(userID, pageCriteria);
            return list;
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
        /// Gets the by id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public User GetById(int id)
        {
            UserRepository repository = new UserRepository();
            return repository.GetUserById(id);
        }



        public MembershipUser GetMembershipUser(string userName)
        {
            MembershipUserCollection users = membershipProvider.Membership.FindUsersByName(userName);

            if (users.Count > 0)
            {
                MembershipUser u = users[userName];
                return u;
            }
            else
            {
                throw new DMSException("No user found with the name " + userName);
            }
        }

        /// <summary>
        /// Gets the user name by pin.
        /// </summary>
        /// <param name="pin">The pin.</param>
        /// <returns></returns>
        public List<UserNameByPIN_Result> GetUserNameByPin(int? pin)
        {
            UserRepository repository = new UserRepository();
            return repository.GetUserNameByPin(pin).ToList();

        }

        /// <summary>
        /// Updates the specified ASP net user.
        /// </summary>
        /// <param name="aspNetUser">The ASP net user.</param>
        /// <exception cref="DMSException">Error while updating the password</exception>
        public void Update(aspnet_Users aspNetUser)
        {
            // Call Membership.UpdateUser
            MembershipUserCollection users = membershipProvider.Membership.FindUsersByName(aspNetUser.UserName);
            if (users.Count > 0)
            {
                MembershipUser u = users[aspNetUser.UserName];
                u.Email = aspNetUser.aspnet_Membership.Email;
                u.IsApproved = aspNetUser.aspnet_Membership.IsApproved;
                //u.IsLockedOut = aspNetUser.aspnet_Membership.IsLockedOut;
                membershipProvider.Membership.UpdateUser(u);
                if (!aspNetUser.aspnet_Membership.IsLockedOut)
                {
                    u.UnlockUser();
                }
            }
            IRepository<aspnet_Users> userRepository = new UserRepository();
            aspNetUser.Users.FirstOrDefault().aspnet_UserID = (Guid)membershipProvider.Membership.GetUser(aspNetUser.UserName).ProviderUserKey;
            //Check if password is blank no need to reset or update
            if (!string.IsNullOrEmpty(aspNetUser.aspnet_Membership.Password))
            {
                if (!membershipProvider.Membership.GetUser(aspNetUser.UserName).ChangePassword(membershipProvider.Membership.GetUser(aspNetUser.UserName).ResetPassword(), aspNetUser.aspnet_Membership.Password))
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
            userRepository.Update(aspNetUser);
        }

        /// <summary>
        /// Adds the specified ASP net user.
        /// </summary>
        /// <param name="aspNetUser">The ASP net user.</param>
        /// <exception cref="DMSException">
        /// That User name already exists
        /// or
        /// Password is not in proper format
        /// or
        /// or
        /// User Creation Error
        /// </exception>
        public void Add(aspnet_Users aspNetUser)
        {
            MembershipCreateStatus mcreationStatus = MembershipCreateStatus.Success;
            IRepository<aspnet_Users> userRepository = new UserRepository();
            try
            {
                membershipProvider.Membership.CreateUser(aspNetUser.UserName,
                                                          aspNetUser.aspnet_Membership.Password,
                                                          aspNetUser.aspnet_Membership.Email,
                                                          "Martex",
                                                          "Martex",
                                                          aspNetUser.aspnet_Membership.IsApproved,
                                                          out mcreationStatus);
                switch (mcreationStatus)
                {
                    case MembershipCreateStatus.Success:
                        Roles.AddUserToRoles(aspNetUser.UserName, aspNetUser.aspnet_Roles.Select(c => c.RoleName).ToArray());
                        userRepository.Add(aspNetUser);
                        break;

                    case MembershipCreateStatus.DuplicateUserName:
                        throw new DMSException("That User name already exists");

                    case MembershipCreateStatus.InvalidPassword:
                        throw new DMSException("Password is not in proper format");

                    case MembershipCreateStatus.DuplicateEmail:
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
                    membershipProvider.Membership.DeleteUser(aspNetUser.UserName, true);
                throw ex;
            }
        }

        /// <summary>
        /// Deletes the specified user ID.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        public void Delete(Guid userID)
        {
            IRepository<aspnet_Users> user = new UserRepository();
            user.Delete<Guid>(userID);
        }

        /// <summary>
        /// Gets the drop down data group.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <returns></returns>
        public List<DropDownDataGroup> GetDropDownDataGroup(int organizationId)
        {
            return ReferenceDataRepository.GetDataGroups(organizationId);
        }

        /// <summary>
        /// Gets the access control list.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <returns></returns>
        public List<AccessControlList_Result> GetAccessControlList(Guid userID)
        {
            UserRepository userRepository = new UserRepository();
            return userRepository.GetAccessControlList(userID);
        }

        public aspnet_Users GetUserByName(string userName)
        {
            UserRepository userRepository = new UserRepository();
            return userRepository.GetUserByName(userName);
        }
        #endregion
    }
}
