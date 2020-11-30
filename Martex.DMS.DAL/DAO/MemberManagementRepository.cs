using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    public partial class MemberManagementRepository
    {
        #region Public Methods

        /// <summary>
        /// Searches the specified criteria.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<MemberManagementSearch_Result> Search(PageCriteria criteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberManagementSearch(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection).ToList();
            }
        }

        /// <summary>
        /// Gets the excluded vendor for membership.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<ExcludedVendorItem> GetExcludedVendorForMembership(int membershipID)
        {
            List<ExcludedVendorItem> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = (from black in dbContext.MembershipBlackListVendors
                        join vendor in dbContext.Vendors on black.VendorID equals vendor.ID
                        where black.IsActive == true
                        where black.MembershipID == membershipID
                        orderby vendor.Name
                        select new ExcludedVendorItem()
                        {
                            ID = black.ID,
                            MembershipID = membershipID,
                            VendorID = vendor.ID,
                            VendorName = vendor.Name,
                            VendorNumber = vendor.VendorNumber
                        }
                        ).ToList();
            }
            return list;
        }

        /// <summary>
        /// Deletes the excluded vendor.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="userName">Name of the user.</param>
        public void DeleteExcludedVendor(int recordID, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.MembershipBlackListVendors.Where(u => u.ID == recordID).FirstOrDefault();
                if (existingRecord != null)
                {
                    existingRecord.IsActive = false;
                    existingRecord.ModifyBy = userName;
                    existingRecord.ModifyDate = DateTime.Now;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Creates the membership black list vendor.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="memberShipId">The member ship id.</param>
        /// <param name="userName">Name of the user.</param>
        public void CreateMembershipBlackListVendor(int vendorID,int memberShipId,string userName)
        {
            var model = new MembershipBlackListVendor()
            {
                MembershipID = memberShipId,
                VendorID = vendorID,
                IsActive = true,
                CreateBy = userName,
                CreateDate = DateTime.Now,
                ModifyDate = null,
                ModifyBy = null
            };
            using (DMSEntities dbContext = new DMSEntities())
            {
                var isDuplicate = dbContext.MembershipBlackListVendors.Where(u => u.VendorID == vendorID && u.MembershipID == memberShipId && u.IsActive == true).FirstOrDefault();
                if (isDuplicate != null)
                {
                    throw new DMSException(string.Format("Vendor is already added in your list"));
                }
                dbContext.MembershipBlackListVendors.Add(model);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the membership details.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public Membership GetMembershipDetails(int membershipID)
        {
            Membership model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.Memberships.Where(u => u.ID == membershipID).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the member details.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public Member GetMemberDetails(int membershipID)
        {
            Member model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.Members.Where(u => u.MembershipID == membershipID && u.IsPrimary == true).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the members by membership ID.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<MembersByMembershipID_Result> GetMembersByMembershipID(int membershipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMembersByMembershipID(membershipID).ToList();
            }
        }

        /// <summary>
        /// Creates the membership.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void CreateMembership(MembershipAddModel model, string userName)
        {
            model.MembershipInformation.ClientMembershipKey = null;
            model.MembershipInformation.Note = null;
            model.MembershipInformation.IsActive = true;
            model.MembershipInformation.CreateDate = DateTime.Now;
            model.MembershipInformation.CreateBy = userName;

            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Memberships.Add(model.MembershipInformation);
                dbContext.SaveChanges();

                model.MemberInformation.MembershipID = model.MembershipInformation.ID;
                model.MemberInformation.Email = model.MembershipInformation.Email;
                model.MemberInformation.MemberSinceDate = null;
                model.MemberInformation.ClientMemberKey = null;
                model.MemberInformation.IsActive = true;
                model.MemberInformation.IsPrimary = true;
                model.MemberInformation.CreateBatchID = null;
                model.MemberInformation.CreateDate = DateTime.Now;
                model.MemberInformation.CreateBy = userName;
                model.MemberInformation.ModifyBatchID = null;
                model.MemberInformation.ModifyBy = null;
                model.MemberInformation.ModifyDate = null;

                dbContext.Members.Add(model.MemberInformation);
                dbContext.SaveChanges();

            }
        }
        #endregion
    }
}
