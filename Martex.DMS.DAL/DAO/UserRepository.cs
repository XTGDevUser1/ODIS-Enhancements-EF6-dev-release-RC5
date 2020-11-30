using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using System.Transactions;
using System.Data.Entity.Core.Objects;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using log4net;
using System.Data.Entity;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class UserRepository : IRepository<aspnet_Users>
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(UserRepository));
        /// <summary>
        /// Gets the access control list.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <returns></returns>
        public List<AccessControlList_Result> GetAccessControlList(Guid userID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetAccessControlList(userID).ToList();
            }
        }
        /// <summary>
        /// Gets all.
        /// </summary>
        /// <returns></returns>
        public List<aspnet_Users> GetAll()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.aspnet_Users.Include(a => a.Users).ToList<aspnet_Users>();
                return list;
            }
        }

        /// <summary>
        /// Adds the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve user details.</exception>
        public int Add(aspnet_Users entity)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var user = dbContext.aspnet_Users.Where(x => x.UserName == entity.UserName).Include(a => a.Users).FirstOrDefault();

                if (user == null) { throw new DMSException("Unable to retrieve user details."); }

                user.Users.Add(entity.Users.First());
                AddPasswordToHistory(user.UserId, entity.UserName);
                dbContext.Entry(user).State = EntityState.Modified;
                dbContext.SaveChanges();

                return user.Users.First().ID;
            }
        }

        /// <summary>
        /// Gets the user by name.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public aspnet_Users GetUserByName(string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var user = dbContext.aspnet_Users.Where(x => x.UserName == userName).Include(a => a.Users).FirstOrDefault();
                if (user == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve user details with User Name : {0}.",userName));
                }
                return user;
            }
        }

        /// <summary>
        /// Gets the user name by pin.
        /// </summary>
        /// <param name="pin">The pin.</param>
        /// <returns></returns>
        public List<UserNameByPIN_Result> GetUserNameByPin(int? pin)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetUserNameByPIN(pin).ToList();
            }
        }

        /// <summary>
        /// Updates the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public void Update(aspnet_Users entity)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var userProfileFromUI = entity.Users.FirstOrDefault();
                var user = dbContext.aspnet_Users.Where(x => x.UserName == entity.UserName)
                    .Include(x => x.Users)
                    .Include(x => x.Users.Select(a => a.UserDataGroups))
                    .FirstOrDefault();
                var userProfile = user.Users.FirstOrDefault();

                userProfile.OrganizationID = userProfileFromUI.OrganizationID;
                userProfile.FirstName = userProfileFromUI.FirstName;
                userProfile.LastName = userProfileFromUI.LastName;
                userProfile.ModifyBy = userProfileFromUI.ModifyBy;
                userProfile.ModifyDate = userProfileFromUI.ModifyDate;
                userProfile.AgentNumber = userProfileFromUI.AgentNumber;

                userProfile.PhoneUserID = userProfileFromUI.PhoneUserID;
                userProfile.PhonePassword = userProfileFromUI.PhonePassword;
                userProfile.Pin = userProfileFromUI.Pin;
                userProfile.UserDataGroups.ToList<UserDataGroup>().ForEach(x =>
                {
                    dbContext.UserDataGroups.Remove(x);
                });

                if (userProfileFromUI.UserDataGroups != null)
                {
                    foreach (UserDataGroup udgroup in userProfileFromUI.UserDataGroups)
                    {
                        userProfile.UserDataGroups.Add(new UserDataGroup() { UserID = userProfile.ID, DataGroupID = udgroup.DataGroupID });

                    }
                }
                AddPasswordToHistory(user.UserId, entity.UserName);
                dbContext.SaveChanges();
            }

        }

        /// <summary>
        /// Deletes the specified userid.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="userid">The userid.</param>
        public void Delete<T1>(T1 userid)
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                using (DMSEntities dbContext = new DMSEntities())
                {

                    Guid id = (Guid)(object)userid;
                    var user = dbContext.aspnet_Users.Where(a => a.UserId == id)
                                                       .Include(a => a.aspnet_Roles)
                                                       .Include(a => a.Users)
                                                       .Include(a => a.Users.Select(y => y.UserDataGroups)).First();
                    var userProfile = dbContext.Users.Where(x => x.aspnet_UserID == id).Include(a => a.UserDataGroups).FirstOrDefault();

                    if (user != null)
                    {
                        //Update Service Request Assigned To User ID
                        var serviceRequestList = dbContext.ServiceRequests.Where(u => u.NextActionAssignedToUserID == userProfile.ID).ToList();
                        logger.InfoFormat("Rendered {0} Service Requests.", serviceRequestList != null ? serviceRequestList.Count : 0);
                        serviceRequestList.ForEach(s =>
                        {
                            s.NextActionAssignedToUserID = null;
                            logger.InfoFormat("Updating the NextActionAssignedToUserID to null for SR with ID :{0}.", s.ID);
                        });
                        logger.InfoFormat("Updated all the Service Requests.");

                        //Update Case Assigned To User ID
                        var caseList = dbContext.Cases.Where(u => u.AssignedToUserID == userProfile.ID).ToList();
                        logger.InfoFormat("Rendered {0} Case Records.", caseList != null ? caseList.Count : 0);
                        caseList.ForEach(c =>
                        {
                            c.AssignedToUserID = null;
                            logger.InfoFormat("Updating the AssignedToUserID to null for Case Record with ID :{0}.", c.ID);
                        });
                        logger.InfoFormat("Updated all the case records.");
                        //Update InboundCall Assigned To User ID
                        var inboundCallList = dbContext.InboundCalls.Where(u => u.AssignedtoUserID == userProfile.ID).ToList();
                        logger.InfoFormat("Rendered {0} Inbound Call Records.", inboundCallList != null ? inboundCallList.Count : 0);
                        inboundCallList.ForEach(i =>
                        {
                            i.AssignedtoUserID = null;
                            logger.InfoFormat("Updating the AssignedToUserID to null for Inbound Call Record with ID :{0}.", i.ID);
                        });
                        logger.InfoFormat("Updated all the inbound call records.");
                        //Delete Password History
                        var passwordHistoryList = dbContext.UserPasswordHistories.Where(u => u.aspnet_UserId == id).ToList();
                        logger.InfoFormat("Rendered {0} Password History List records.", passwordHistoryList != null ? passwordHistoryList.Count : 0);
                        passwordHistoryList.ForEach(p =>
                        {
                            dbContext.UserPasswordHistories.Remove(p);
                        });
                        logger.InfoFormat("Deleted all the inbound Password History List records.");
                        // Delete user data groups
                        user.Users.FirstOrDefault().UserDataGroups.ToList<UserDataGroup>().ForEach(x =>
                        {
                            dbContext.UserDataGroups.Remove(x);
                        });
                        logger.InfoFormat("Deleted user data groups.");
                        // Delete user roles
                        user.aspnet_Roles.ToList<aspnet_Roles>().ForEach(x =>
                        {
                            user.aspnet_Roles.Remove(x);
                        });
                        logger.InfoFormat("Deleted user roles.");
                        //Delete user
                        if (userProfile != null)
                        {
                            dbContext.Entry(userProfile).State = EntityState.Deleted;
                            logger.InfoFormat("Deleted user.");
                        }

                        // Delete Membership
                        var membership = dbContext.aspnet_Membership.Where(x => x.UserId == id).FirstOrDefault();

                        if (membership != null)
                        {
                            dbContext.Entry(membership).State = EntityState.Deleted;
                            logger.InfoFormat("Deleted membership.");
                        }

                        // Delete aspnet_user
                        dbContext.Entry(user).State = EntityState.Deleted;

                        dbContext.SaveChanges();
                    }
                }
                transaction.Complete();
            }
        }
        /// <summary>
        /// Searches the client profile.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<SearchUsersListClientPortal_Result> SearchClientProfile(Guid? userID, DAL.Common.PageCriteria pageCriteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetUsersListClientPortal(userID.Value, pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection).ToList();
                return list;
            }
        }




        /// <summary>
        /// Searches the specified user ID.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<SearchUsersResult> Search(Guid? userID, DAL.Common.PageCriteria pageCriteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetUsers(userID.Value, pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection).ToList();
                return list;
            }
        }

        /// <summary>
        /// Gets the user by id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public User GetUserById(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.Users.Where(u => u.ID == id).Include(a => a.UserDataGroups).FirstOrDefault();
                return result;
            }

        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="membershipUserID"></param>
        /// <returns></returns>
        public User GetUserManager(Guid membershipUserID)
        {
            User manager = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.Users.Where(u => u.aspnet_UserID == membershipUserID).FirstOrDefault();
                if (result != null && result.ManagerID.HasValue)
                {
                    manager = dbContext.Users.Where(u => u.ID == result.ManagerID).FirstOrDefault();
                }
            }
            return manager;
        }

        public List<UserPasswordHistory> GetUserPasswordHistory(Guid userID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<UserPasswordHistory> list = new List<UserPasswordHistory>();
                list = dbContext.UserPasswordHistories.Where(a => a.aspnet_UserId == userID).OrderByDescending(x => x.CreateDate).Take(5).ToList<UserPasswordHistory>();
                return list;
            }
        }

        #region IRepository<aspnet_Users> Members


        /// <summary>
        /// Gets the specified id.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public aspnet_Users Get<T1>(T1 id) //where T1 : struct
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Guid userId = (Guid)(object)id;
                var user = dbContext.aspnet_Users.Where(a => a.UserId == userId)
                                                    .Include(x => x.Users)
                                                    .Include(x => x.aspnet_Membership)
                                                    .Include(x => x.Users.Select(s => s.Organization))
                                                    .Include(x => x.aspnet_Roles)
                                                    .Include(x => x.Users.Select(a => a.UserDataGroups))
                                                    .Include(x => x.aspnet_Membership)
                                                    .First();
                return user;
            }
        }

        /// <summary>
        /// Gets the user.
        /// </summary>
        /// <param name="aspnetUserId">The aspnet user id.</param>
        /// <returns></returns>
        public User GetUser(Guid aspnetUserId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Users.Where(a => a.aspnet_UserID == aspnetUserId).Include(u => u.aspnet_Users).Include(u => u.UserDataGroups).SingleOrDefault();
            }
        }

        #endregion



        public void AddPasswordToHistory(Guid loggedInUserID, string currentUser = null)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                aspnet_Membership membership = dbContext.aspnet_Membership.Where(a => a.UserId == loggedInUserID).FirstOrDefault();

                UserPasswordHistory password = new UserPasswordHistory();
                password.aspnet_UserId = loggedInUserID;
                password.Password = membership.Password;
                password.PasswordSalt = membership.PasswordSalt;
                password.PasswordFormat = membership.PasswordFormat;
                password.InitialUseDate = DateTime.Now;
                password.CreateDate = DateTime.Now;
                password.CreateBy = currentUser;
                dbContext.UserPasswordHistories.Add(password);
                dbContext.SaveChanges();

            }
        }

        public List<aspnet_Users> GetUsersInRole(string roleName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var role = dbContext.aspnet_Roles.Where(r => r.RoleName == roleName && r.aspnet_Applications.ApplicationName == "DMS").Include(a => a.aspnet_Users).FirstOrDefault();
                if (role != null)
                {
                    var list = role.aspnet_Users.ToList<aspnet_Users>();
                    return list;
                }
                return null;
            }
        }
    }
}
