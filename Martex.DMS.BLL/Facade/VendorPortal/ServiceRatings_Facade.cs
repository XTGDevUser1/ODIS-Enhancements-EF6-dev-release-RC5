using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model.VendorPortal;
using Martex.DMS.DAL.DAO;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO.VendorPortal;
using Martex.DMS.DAL.Entities;
using System.Transactions;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Vendor Portal Facade
    /// </summary>
    public partial class VendorPortalFacade
    {
        /// <summary>
        /// Gets the service ratings product list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<ServiceRatingsProductList_Result> GetServiceRatingsProductList(PageCriteria pc, int? vendorID)
        {
            return repository.GetServiceRatingsProductList(pc, vendorID);
        }

        /// <summary>
        /// Gets the vendor portal service ratings.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorPortalServiceRatingsList_Result> GetVendorPortalServiceRatings(PageCriteria pc, int? vendorID, int? productCategoryID)
        {
            return repository.GetVendorPortalServiceRatings(pc, vendorID, productCategoryID);
        }

        /// <summary>
        /// Gets the vendor portal service contact actions.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="contactLogID">The contact log ID.</param>
        /// <returns></returns>
        public List<VendorPortalServiceContactActionsList_Result> GetVendorPortalServiceContactActions(PageCriteria pc, int? vendorID, int? productID)
        {
            return repository.GetVendorPortalServiceContactActions(pc, vendorID, productID);
        }

        /// <summary>
        /// Gets the service ratings product category list.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<ServiceRatingsProductCategoryList_Result> GetServiceRatingsProductCategoryList(int? vendorID)
        {
            return repository.GetServiceRatingsProductCategoryList(vendorID);
        }


        
    }
}
