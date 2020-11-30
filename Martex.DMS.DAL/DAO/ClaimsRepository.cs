using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class ClaimsRepository
    {
        /// <summary>
        /// Gets the claims list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ClaimsList_Result> GetClaimsList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClaimsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<ClaimsList_Result>();
            }
        }

        /// <summary>
        /// Deletes the claim.
        /// </summary>
        /// <param name="claimID">The claim ID.</param>
        public void DeleteClaim(int claimID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Claim existingClaim = dbContext.Claims.Where(c => c.ID == claimID).FirstOrDefault();
                existingClaim.IsActive = false;
                dbContext.Entry(existingClaim).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Looks up purchase order number.
        /// </summary>
        /// <param name="purchaseOrderNumber">The purchase order number.</param>
        /// <returns></returns>
        public ClaimPurchaseOrderNumberLookUPDetails_Result LookUpPurchaseOrderNumber(string purchaseOrderNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClaimPurchaseOrderNumberLookUPDetails(purchaseOrderNumber).FirstOrDefault();
            }

        }

        /// <summary>
        /// Determines whether [is securable accessible] [the specified securable].
        /// </summary>
        /// <param name="securable">The securable.</param>
        /// <param name="userID">The user ID.</param>
        /// <returns>
        ///   <c>true</c> if [is securable accessible] [the specified securable]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsSecurableAccessible(string securable, Guid userID)
        {
            bool isAccessible = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<Securable_IsAccessible_Result> list = dbContext.GetSecurableIsAccessible(userID, securable).ToList();
                if (list != null && list.Count > 0)
                {
                    isAccessible = true;
                }
            }
            return isAccessible;
        }

        /// <summary>
        /// Looks up member address details.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public ClaimMemberAddressPhoneNumberLookUP_Result LookUpMemberAddressDetails(int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClaimMemberAddressPhoneNumberLookUP(memberID).FirstOrDefault();
            }

        }


        /// <summary>
        /// Gets the member name using membership number.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public Member GetMemberUsingMembershipNumber(string membershipNumber, int? programID, PageCriteria pageCriteria)
        {
            // DO NOT WRITE THROW EXCEPTION
            Member memberDetails = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (programID.HasValue)
                {
                    List<SearchMember_Result> list = new List<SearchMember_Result>();
                    list = dbContext.SearchMember(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, programID.Value).ToList<SearchMember_Result>();
                    if (list != null && list.Count > 0)
                    {
                        SearchMember_Result listMember = list.ElementAt(0);
                        memberDetails = dbContext.Members.Where(u => u.ID == listMember.MemberID).FirstOrDefault();
                    }
                }
                else
                {
                    memberDetails = (from member in dbContext.Members
                                     join membership in dbContext.Memberships on member.MembershipID equals membership.ID
                                     where membership.MembershipNumber == membershipNumber
                                     && member.IsActive == true
                                     && member.IsPrimary == true
                                     select member
                                     ).FirstOrDefault();
                }
            }
            return memberDetails;
        }

        /// <summary>
        /// Gets the vendor by vendor number.
        /// </summary>
        /// <param name="vendorNumber">The vendor number.</param>
        /// <returns></returns>
        public Vendor GetVendorByVendorNumber(string vendorNumber)
        {
            // DO NOT WRITE THROW EXCEPTION
            Vendor vendor = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                vendor = dbContext.Vendors.Where(u => u.VendorNumber.Equals(vendorNumber, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
            }

            return vendor;
        }

        /// <summary>
        /// Gets the vehicle formembership.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns></returns>
        public Vehicle GetVehicleFormembership(string membershipNumber)
        {
            Vehicle vehcile = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<Vehicle> result = (from v in dbContext.Vehicles
                                        join m in dbContext.Memberships
                                        on v.MembershipID equals m.ID
                                        where m.MembershipNumber.Equals(membershipNumber)
                                        select v).ToList();
                if (result.Count == 1)
                {
                    vehcile = result.ElementAtOrDefault(0);
                }
            }
            return vehcile;
        }

        /// <summary>
        /// Gets the P ofor claim.
        /// </summary>
        /// <param name="suffixClaimID">The suffix claim ID.</param>
        /// <returns></returns>
        public PurchaseOrder GetPOforClaim(int suffixClaimID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Claim claim = dbContext.Claims.Where(a => a.ID == suffixClaimID).FirstOrDefault();
                PurchaseOrder po = new PurchaseOrder();
                if (claim.PurchaseOrderID != null)
                {
                    po = dbContext.PurchaseOrders.Where(a => a.ID == claim.PurchaseOrderID).Include(p => p.PurchaseOrderStatu).FirstOrDefault();
                }
                return po;
            }
        }


    }
}
