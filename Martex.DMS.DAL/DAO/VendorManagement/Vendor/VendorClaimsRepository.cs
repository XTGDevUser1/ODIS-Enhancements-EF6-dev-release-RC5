using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorManagementRepository
    {
        /// <summary>
        /// Gets the vendor claims.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Vendor_Claims_Result> GetVendorClaims(PageCriteria criteria,int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorClaims(criteria.WhereClause,criteria.StartInd,criteria.EndInd,criteria.PageSize,criteria.SortColumn,criteria.SortDirection,vendorID).ToList();
            }
        }
    }
}
