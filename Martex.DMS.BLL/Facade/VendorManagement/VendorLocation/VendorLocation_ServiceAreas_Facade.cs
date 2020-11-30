using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using System.Transactions;
using Martex.DMS.DAL;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorManagementFacade
    {
        /// <summary>
        /// Gets the service area details.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public VendorLocationServiceAreaModel GetServiceAreaDetails(int vendorLocationID, int vendorID)
        {
            VendorLocationServiceAreaModel model = new VendorLocationServiceAreaModel();

            //1. Get business address

            var businessAddress = addressRepository.GetAddresses(vendorLocationID, EntityNames.VENDOR_LOCATION, "Business").FirstOrDefault();
            model.BusinessAddress = businessAddress;

            //2. Get Zip codes            
            var zipCodes = repository.GetZipCodes(vendorLocationID);
            model.PrimaryZipCodesAsCSV = string.Join(",", (from z in zipCodes
                                                           where (z.IsSecondary == null || z.IsSecondary == false)
                                                           select z.PostalCode).ToArray<string>());
            model.SecondaryZipCodesAsCSV = string.Join(",", (from z in zipCodes
                                                             where (z.IsSecondary == true)
                                                             select z.PostalCode).ToArray());

            logger.InfoFormat("Retrieved VendorLocation for id : {0} - [ {1} | {2} ]", vendorLocationID, model.PrimaryZipCodesAsCSV, model.SecondaryZipCodesAsCSV);

            //3. Get previously saved info for the vendor location
            Vendor vendor = repository.Get(vendorID);
            var currentLocation = repository.GetVendorLocationDetails(vendorLocationID);

            if (currentLocation != null)
            {
                logger.InfoFormat("Retrieving VendorLocation for id : {0}", vendorLocationID);

                model.IsAbleToCrossNationalBorders = currentLocation.IsAbleToCrossNationalBorders.GetValueOrDefault();
                model.IsAbleToCrossStateLines = currentLocation.IsAbleToCrossStateLines.GetValueOrDefault();
                model.IsUsingZipCodes = currentLocation.IsUsingZipCodes.GetValueOrDefault();
            }
            if (vendor != null)
            {
                model.IsVirtualLocationEnabled = vendor.IsVirtualLocationEnabled.GetValueOrDefault();
            }
            //4. Get virtual locations             
            model.VirtualLocations = repository.GetVirtualLocations(vendorLocationID);
            logger.InfoFormat("Got virtual locations for id : {0} [ {1} ]", vendorLocationID, model.VirtualLocations.Count);


            return model;
        }

        /// <summary>
        /// Saves the service area details.
        /// </summary>
        /// <param name="model">The model.</param>
        public void SaveServiceAreaDetails(VendorLocationServiceAreaModel model, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                logger.InfoFormat("VendorManagementFacade --> SaveServiceAreaDetails :  {0}", JsonConvert.SerializeObject(new
                {
                    VendorLocationID = model.VendorLocationID,
                    IsAbleToCrossStateLines = model.IsAbleToCrossStateLines,
                    IsUsingZipCodes = model.IsUsingZipCodes,
                    IsAbleToCrossNationalBorders = model.IsAbleToCrossNationalBorders,
                    IsVirtualLocationEnabled = model.IsVirtualLocationEnabled,
                    PrimaryZipCodesAsCSV = model.PrimaryZipCodesAsCSV,
                    SecondaryZipCodesAsCSV = model.SecondaryZipCodesAsCSV
                }));


                logger.InfoFormat("Saving flags for vendorLocationID {0}", model.VendorLocationID);
                repository.SaveVendorLocationServiceFlags(model.VendorLocationID, model.IsAbleToCrossStateLines, model.IsAbleToCrossNationalBorders, model.IsUsingZipCodes);

                logger.InfoFormat("Saving ZipCodes for vendorLocationID {0}", model.VendorLocationID);
                if (model.IsUsingZipCodes)
                {
                    repository.SaveZipCodes(model.VendorLocationID, model.PrimaryZipCodesAsCSV, currentUser);
                    repository.SaveZipCodes(model.VendorLocationID, model.SecondaryZipCodesAsCSV, currentUser, true);
                }

                logger.InfoFormat("Saving Virtual locations for vendorLocationID {0}", model.VendorLocationID);

                CommonLookUpRepository staticDataRepo = new CommonLookUpRepository();

                if (model.VirtualLocations != null)
                {
                    model.VirtualLocations.ForEach(v =>
                    {

                        if (!string.IsNullOrEmpty(v.LocationCountryCode) && v.LocationCountryCode.Length > 2)
                        {
                            Country src = staticDataRepo.GetCountryByName(v.LocationCountryCode);
                            if (src != null)
                            {
                                v.LocationCountryCode = src.ISOCode;
                            }
                        }
                    });
                }
                repository.SaveVirtualLocations(model.VendorLocationID, model.VirtualLocations, currentUser);


                addressRepository.UpdateGeographyType(model.VendorLocationID, EntityNames.VENDOR_LOCATION_VIRTUAL);
                tran.Complete();
            }
        }
    }
}
