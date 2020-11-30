using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class OptionsRepository
    {
        /// <summary>
        /// Gets the business options.
        /// </summary>
        /// <param name="vehicleTypeId">The vehicle type id.</param>
        /// <returns></returns>
        public List<string> GetBusinessOptions(int? vehicleTypeId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from v in dbContext.VehicleTypeBusinessSearchOptions
                              where v.IsActive == true && v.VehicleTypeID == vehicleTypeId
                              orderby v.Sequence
                              select v.Keywords
                              ).ToList<string>();
                return result;
            }
        }

        /// <summary>
        /// Gets the service location options.
        /// </summary>
        /// <returns></returns>
        public List<ServiceLocationOption> GetServiceLocationOptions()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from p in dbContext.Products
                              join pc in dbContext.ProductCategories on p.ProductCategoryID equals pc.ID
                              join pt in dbContext.ProductTypes on p.ProductTypeID equals pt.ID
                              join pst in dbContext.ProductSubTypes on p.ProductSubTypeID equals pst.ID
                              where pc.Name == "Repair" && pt.Name == "Attribute" && pst.IsActive == true
                              orderby pst.Sequence, p.Name
                              select new ServiceLocationOption
                              {
                                  
                                  ProductSubTypeName = pst.Name,
                                  ProductName = p.Name
                              }
                              ).ToList<ServiceLocationOption>();
                return result;
            }
        }

        /// <summary>
        /// Gets the product options.
        /// </summary>
        /// <param name="productCategoryID">The product category ID.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <param name="vehicleCategoryID">The vehicle category ID.</param>
        /// <returns></returns>
        public List<Product> GetProductOptions(int? productCategoryID, int? vehicleTypeID, int? vehicleCategoryID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetProductOptions(productCategoryID, vehicleTypeID, vehicleCategoryID).ToList<Product>();
                return result;
            }
        }
    }
}
