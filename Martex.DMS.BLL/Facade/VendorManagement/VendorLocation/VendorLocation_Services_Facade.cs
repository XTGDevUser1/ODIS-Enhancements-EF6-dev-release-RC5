using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using System.Transactions;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorManagementFacade
    {
        /// <summary>
        /// Gets the vendor location service details.
        /// </summary>
        /// <param name="vendorId">The vendor identifier.</param>
        /// <param name="vendorLocationId">The vendor location identifier.</param>
        /// <returns></returns>
        public VendorLocationServiceModel GetVendorLocationServiceDetails(int vendorId,int vendorLocationId)
        {
            var vendorServiceList = repository.GetVendorLocationServices(vendorId, vendorLocationId);
            var vlsModel = new VendorLocationServiceModel
            {
                VendorID = vendorId,
                VendorLocationID = vendorLocationId,
                DBServices = vendorServiceList
            };
            return vlsModel;
        }


        /// <summary>
        /// Vendor Portal Location Service
        /// </summary>
        /// <param name="vendorId"></param>
        /// <param name="vendorLocationId"></param>
        /// <returns></returns>
        public VendorPortalLocationServiceModel GetVendorPortalLocationServicesList(int vendorId, int vendorLocationId)
        {
            var list = repository.GetVendorPortalLocationServicesList(vendorId, vendorLocationId);
            var vlsModel = new VendorPortalLocationServiceModel
            {
                VendorID = vendorId,
                VendorLocationID = vendorLocationId,
                DBServices = list
            };
            return vlsModel;
        }


        

        /// <summary>
        /// Saves the vendor location services.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveVendorLocationServices(VendorLocationServiceModel model, string currentUser)
        {
            // Prepare a list using the selected services and repairs (essentially products).
            var productIDs = new List<string>();
            if (model.Services != null && model.Services.Count > 0)
            {
                productIDs = model.Services.Where(u => u.Selected == true).Select(u => u.ID.ToString()).ToList();
            }
            logger.InfoFormat("Saving {0} products against Vendor Location {1}", productIDs.Count, model.VendorLocationID);
            repository.SaveVendorLocationServices(model.VendorLocationID, productIDs, currentUser);
            
        }

        /// <summary>
        /// Save Vendor Portal Location Services
        /// </summary>
        /// <param name="model"></param>
        /// <param name="currentUser"></param>
        public void SaveVendorPortalLocationServices(VendorPortalLocationServiceModel model, string currentUser)
        {
            // Prepare a list using the selected services and repairs (essentially products).
            var productIDs = new List<string>();
            if (model.Services != null && model.Services.Count > 0)
            {
                productIDs = model.Services.Where(u => u.Selected == true).Select(u => u.ID.ToString()).ToList();
            }
            logger.InfoFormat("Saving {0} products against Vendor Location {1}", productIDs.Count, model.VendorLocationID);
            repository.SaveVendorLocationServices(model.VendorLocationID, productIDs, currentUser);

        }
    }
}
