using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public class VendorUserRepository
    {
        /// <summary>
        /// Adds the user.
        /// </summary>
        /// <param name="aspnetUser">The aspnet user.</param>
        /// <param name="vendorUser">The vendor user.</param>
        public void AddUser(aspnet_Users aspnetUser, VendorUser vendorUser)
        {


        }

        /// <summary>
        /// Updates the user.
        /// </summary>        
        /// <param name="vendorUser">The vendor user.</param>
        public void UpdateUser(VendorUser vendorUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var vendorUserFromDB = dbContext.VendorUsers.Where(v => v.ID == vendorUser.ID).FirstOrDefault();
                vendorUserFromDB.FirstName = vendorUser.FirstName;
                vendorUserFromDB.LastName = vendorUser.LastName;
                vendorUser.VendorID = vendorUser.VendorID;

                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Deletes the user.
        /// </summary>
        /// <param name="aspnetUser">The aspnet user.</param>
        /// <param name="vendorUser">The vendor user.</param>
        public void DeleteUser(Guid aspnetUserID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var user = dbContext.aspnet_Users.Where(a => a.UserId == aspnetUserID).Include(a=>a.VendorUsers).Include(a=>a.aspnet_Roles).FirstOrDefault();

                if (user != null)
                {

                    // Delete user data groups
                    user.VendorUsers.ToList<VendorUser>().ForEach(x =>
                    {
                        dbContext.VendorUsers.Remove(x);
                    });

                    // Delete user roles
                    user.aspnet_Roles.ToList<aspnet_Roles>().ForEach(x =>
                    {
                        user.aspnet_Roles.Remove(x);
                    });

                    // Delete Membership
                    var membership = dbContext.aspnet_Membership.Where(x => x.UserId == aspnetUserID).FirstOrDefault();

                    if (membership != null)
                    {
                        dbContext.Entry(membership).State = EntityState.Deleted;
                    }

                    // Delete aspnet_user
                    dbContext.Entry(user).State = EntityState.Deleted;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets the users for vendor portal.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<UsersForVendorPortal_Result> GetUsersForVendorPortal(Guid? userID, PageCriteria pageCriteria)
        {
            List<UsersForVendorPortal_Result> userList = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                userList = dbContext.GetUsersForVendorPortal(userID.Value, pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection).ToList();
            }

            return userList;
        }

        /// <summary>
        /// Gets the vendor user profile.
        /// </summary>
        /// <param name="loggedInUserName">Name of the logged information user.</param>
        /// <returns></returns>
        public VendorUserProfile_Result GetVendorUserProfile(string loggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var userProfile = dbContext.GetVendorUserProfile(loggedInUserName).FirstOrDefault();
                return userProfile;
            }
        }

    }
}
