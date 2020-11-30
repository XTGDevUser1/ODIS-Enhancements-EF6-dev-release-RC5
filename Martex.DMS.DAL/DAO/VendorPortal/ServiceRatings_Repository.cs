using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// Vendor Portal Repository
    /// </summary>
    public partial class VendorPortalRepository
    {
        /// <summary>
        /// Gets the service ratings product list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<ServiceRatingsProductList_Result> GetServiceRatingsProductList(PageCriteria pc,int? vendorID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetServiceRatingsProductList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, vendorID).ToList<ServiceRatingsProductList_Result>();
            }
        }
        /// <summary>
        /// Gets the vendor portal service ratings.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorPortalServiceRatingsList_Result> GetVendorPortalServiceRatings(PageCriteria pc, int? vendorID, int? productCategoryID,int? vendorLocationID = null)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetVendorPortalServiceRatingsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, vendorID, vendorLocationID, productCategoryID).ToList<VendorPortalServiceRatingsList_Result>();
            }
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
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetVendorPortalServiceContactActionsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, vendorID, productID).ToList<VendorPortalServiceContactActionsList_Result>();
            }
        }

        /// <summary>
        /// Gets the service ratings product category list.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<ServiceRatingsProductCategoryList_Result> GetServiceRatingsProductCategoryList(int? vendorID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetServiceRatingsProductCategoryList(vendorID).ToList<ServiceRatingsProductCategoryList_Result>();
            }
        }

       
    }
}
