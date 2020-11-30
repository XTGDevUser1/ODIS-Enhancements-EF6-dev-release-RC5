using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// MemberManagementRepository
    /// </summary>
    public partial class MemberManagementRepository
    {
        /// <summary>
        /// Gets the members claims.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<Member_Claims_Result> GetMemberClaims(int? memberID, int? membershipID, PageCriteria criteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberClaims(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection, memberID, membershipID).ToList();
            }
        }
        /// <summary>
        /// Gets the member products.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<MemberProducts_Result> GetMemberProducts(int? memberID, PageCriteria criteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberProducts(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection, memberID).ToList();
            }
        }

        /// <summary>
        /// Gets the membership products.
        /// </summary>
        /// <param name="membershipID">The membership identifier.</param>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<MemberShipProducts_Result> GetMembershipProducts(int? membershipID, PageCriteria criteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberShipProducts(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection, membershipID).ToList();
            }
        }
        /// <summary>
        /// Gets the member products.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="productCategoryID">The product category identifier.</param>
        /// <param name="vinNumber">The vin number.</param>
        /// <returns></returns>
        public List<MemberProductsUsingCategory_Result> GetMemberProducts(int? memberID, int? productCategoryID, string vinNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberProductsUsingCategory(memberID, productCategoryID, vinNumber).ToList();
            }
        }
    }
}
