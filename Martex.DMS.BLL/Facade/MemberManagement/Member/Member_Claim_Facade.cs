using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// MemberManagementFacade
    /// </summary>
    public partial class MemberManagementFacade
    {
        /// <summary>
        /// Gets the members claims.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<Member_Claims_Result> GetmemberClaims(int? memberID, int? membershipID, PageCriteria criteria)
        {
            logger.InfoFormat("MemberManagementFacade - GetmemberClaims(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                memberID = memberID,
                membershipID = membershipID,
                PageCriteria = criteria
            }));
            return repository.GetMemberClaims(memberID, membershipID, criteria);
        }

        /// <summary>
        /// Gets the member products.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<MemberProducts_Result> GetMemberProducts(int? memberID, PageCriteria criteria)
        {
            logger.InfoFormat("MemberManagementFacade - GetMemberProducts(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                memberID = memberID,
                PageCriteria = criteria
            }));
            return repository.GetMemberProducts(memberID, criteria);
        }

        public List<MemberShipProducts_Result> GetMembershipProducts(int? memberID, PageCriteria criteria)
        {
            logger.InfoFormat("MemberManagementFacade - GetMembershipProducts(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                memberID = memberID,
                PageCriteria = criteria
            }));
            return repository.GetMembershipProducts(memberID, criteria);
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
            logger.InfoFormat("MemberManagementFacade - GetMemberProducts(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                memberID = memberID,
                productCategoryID = productCategoryID,
                vinNumber = vinNumber
            }));
            return repository.GetMemberProducts(memberID, productCategoryID, vinNumber);
        }
    }
}
