using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorManagementFacade
    {
        /// <summary>
        /// Gets the vendor claims.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Vendor_Claims_Result> GetVendorClaims(PageCriteria criteria, int vendorID)
        {
            return repository.GetVendorClaims(criteria, vendorID);
        }
    }
}