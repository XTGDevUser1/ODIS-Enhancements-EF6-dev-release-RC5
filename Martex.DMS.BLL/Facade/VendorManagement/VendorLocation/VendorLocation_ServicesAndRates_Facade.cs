using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorManagementFacade
    {
        /// <summary>
        /// Gets the vendor location services and rates.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorServicesAndRates_Result> GetVendorLocationServicesAndRates(int vendorLocationID, int rateScheduleID)
        {
            return repository.GetVendorLocationServicesAndResults(vendorLocationID, rateScheduleID);
        }

        /// <summary>
        /// Gets the vendor location services.
        /// </summary>
        /// <param name="ratesList">The rates list.</param>
        /// <returns></returns>
        public List<Product> GetVendorLocationServices()
        {
            List<Product> ServicesList = repository.GetVendorLocationServices();
            return ServicesList.OrderBy(a => a.Name).Where(a => a.IsActive == true).ToList<Product>();
        }

        /// <summary>
        /// Gets the vendor products.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="contractRateSchedule">The contract rate schedule.</param>
        /// <returns></returns>
        public List<DropDownEntity> GetVendorProducts(int vendorID, int? contractRateScheduleID, int? productID)
        {
            return repository.GetVendorProducts(vendorID, contractRateScheduleID, productID);
        }

        public List<DropDownEntity> GetVendorProducts(int vendorID)
        {
            return repository.GetVendorProducts(vendorID);
        }


        /// <summary>
        /// Inserts the vendor service rates.
        /// </summary>
        /// <param name="vendorLocationRatesAndService">The vendor location rates and service.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="rateScheduleID">The rate schedule ID.</param>
        public void InsertVendorServiceRates(VendorServicesAndRates_Result vendorLocationRatesAndService, string currentUser, int rateScheduleID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                int ContractRateSechduleID = rateScheduleID;
                int ProductID = 0;
                if (vendorLocationRatesAndService.ProductID != null)
                {
                    ProductID = int.Parse(vendorLocationRatesAndService.ProductID.ToString());
                }
                decimal value = Convert.ToDecimal(0);
                SaveContractRateScheduleProduct(ContractRateSechduleID, ProductID, RateTypes.BASE, vendorLocationRatesAndService.BaseRate, Convert.ToDecimal(1), currentUser);
                SaveContractRateScheduleProduct(ContractRateSechduleID, ProductID, RateTypes.ENROUTE, vendorLocationRatesAndService.EnrouteRate, value, currentUser);
                SaveContractRateScheduleProduct(ContractRateSechduleID, ProductID, RateTypes.ENROUTE_FREE, -1*vendorLocationRatesAndService.EnrouteRate, vendorLocationRatesAndService.EnrouteFreeMiles, currentUser);
                SaveContractRateScheduleProduct(ContractRateSechduleID, ProductID, RateTypes.GONE_ON_ARRIVAL, vendorLocationRatesAndService.GoaRate, value, currentUser);
                SaveContractRateScheduleProduct(ContractRateSechduleID, ProductID, RateTypes.HOURLY, vendorLocationRatesAndService.HourlyRate, value, currentUser);
                SaveContractRateScheduleProduct(ContractRateSechduleID, ProductID, RateTypes.SERVICE, vendorLocationRatesAndService.ServiceRate, value, currentUser);
                SaveContractRateScheduleProduct(ContractRateSechduleID, ProductID, RateTypes.SERVICE_FREE, -1*vendorLocationRatesAndService.ServiceRate, vendorLocationRatesAndService.ServiceFreeMiles, currentUser);
                tran.Complete();
            }
        }

        /// <summary>
        /// Updates the VLR details.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="VLRS">The VLRS.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="rateScheduleID">The rate schedule ID.</param>
        public void UpdateVLRDetails(int vendorLocationID, VendorLocationRatesAndServices_Result VLRS, string currentUser, int rateScheduleID)
        {
            using (TransactionScope transcope = new TransactionScope())
            {
                List<ContractRateScheduleProduct> contractList = repository.GetExistingContractRateScheduleProductsList(VLRS.ContractRateScheduleID);
                if (contractList.Count > 0)
                {
                    repository.UpdateVLRDetails(vendorLocationID, VLRS, currentUser);
                }
                transcope.Complete();
            }
        }

        /// <summary>
        /// Updates the vendor rates.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="rateScheduleID">The rate schedule ID.</param>
        public void UpdateVendorRates(VendorServicesAndRates_Result model, string currentUser, int rateScheduleID)
        {
            using (TransactionScope transcope = new TransactionScope())
            {
                List<ContractRateScheduleProduct> contractList = repository.GetExistingContractRateScheduleProductsList(rateScheduleID);
                if (contractList.Count > 0)
                {
                    repository.UpdateVendorRates(model, currentUser);
                }
                transcope.Complete();
            }
        }

        /// <summary>
        /// Deletes the vendor rates.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void DeleteVendorRates(VendorServicesAndRates_Result model, string currentUser)
        {
            if (model.ContractRateScheduleID > 0)
            {
                repository.DeleteVendorRates(model, currentUser);
            }
        }

        /// <summary>
        /// Saves the contract rate schedule product.
        /// </summary>
        /// <param name="ContractScheduleID">The contract schedule ID.</param>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <param name="ProductID">The product ID.</param>
        /// <param name="rateTypeName">Name of the rate type.</param>
        /// <param name="Price">The price.</param>
        /// <param name="Quantity">The quantity.</param>
        /// <param name="currentUser">The current user.</param>
        /// <exception cref="DMSException"></exception>
        private void SaveContractRateScheduleProduct(int? ContractScheduleID, int ProductID, string rateTypeName, decimal? Price, decimal? Quantity, string currentUser)
        {
            ContractRateScheduleProduct crsp = new ContractRateScheduleProduct();
            crsp.ContractRateScheduleID = ContractScheduleID.GetValueOrDefault();
            crsp.VendorLocationID = null;
            crsp.ProductID = ProductID;
            //if (Convert.ToDecimal(Price) > 0) TFS : 2259
            //{
                crsp.Price = Convert.ToDecimal(Price);
            //}
            if (Quantity > 0)
            {
                crsp.Quantity = int.Parse(Quantity.ToString());
            }
            crsp.CreateBy = currentUser;
            crsp.CreateDate = DateTime.Now;
            RateType rateType = repository.GetRateType(rateTypeName);
            if (rateType == null)
            {
                throw new DMSException(rateTypeName + " - Rate Type not set up in the system");
            }
            crsp.RateTypeID = rateType.ID;
            repository.SaveVendorRates(crsp);

            int contractRateScheduleProductID = crsp.ID;

            ContractRateScheduleProductLog crspl = new ContractRateScheduleProductLog();
            crspl.ContractRateScheduleID = ContractScheduleID.GetValueOrDefault();
            crspl.ProductID = ProductID;
            crspl.RateTypeID = rateType.ID;
            if (Convert.ToDecimal(Price) > 0)
            {
                crspl.NewPrice = Convert.ToDecimal(Price);
            }
            if (Quantity > 0)
            {
                crspl.NewQuantity = int.Parse(Quantity.ToString());
            }
            crspl.ActivityType = "Insert";
            crspl.CreateBy = currentUser;
            crspl.CreateDate = DateTime.Now;

            repository.SaveContractRateScheduleProductLog(crspl);
        }

        /// <summary>
        /// Gets the vendor location contract rate schedule product log.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationContractRateScheduleProductLog_Result> GetVendorLocationContractRateScheduleProductLog(PageCriteria pc, int contractRateScheduleID, int? vendorLocationID)
        {
            return repository.GetVendorLocationContractRateScheduleProductLog(pc, contractRateScheduleID, vendorLocationID);
        }

        /// <summary>
        /// Gets the vendor contract.
        /// </summary>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Contract> GetVendorContracts(int VendorID)
        {
            return repository.GetVendorContracts(VendorID);
        }

        /// <summary>
        /// Gets the location service ratings.
        /// </summary>
        /// <param name="vendorLocationId">The vendor location unique identifier.</param>
        /// <returns></returns>
        public List<VendorLocationServiceRatings_Result> GetLocationServiceRatings(int vendorLocationId)
        {
            return repository.GetLocationServiceRatings(vendorLocationId);
        }

        public VendorLocationProduct GetVendorLocationProductServiceRating(int serviceRatingID)
        {
            return repository.GetVendorLocationProductServiceRating(serviceRatingID);
        }

        public void SaveVendorLocationProductServiceRating(int serviceRatingID, decimal serviceRating, string currentUser, string eventSource, string sessionId)
        {
            decimal? oldServiceRating = repository.SaveVendorLocationProductServiceRating(serviceRatingID, serviceRating, currentUser);
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            decimal oldServiceRatingValue = oldServiceRating.HasValue ? oldServiceRating.Value : 0;
            string comments = "<EventDetail><BeforeRating>" + oldServiceRatingValue + "</BeforeRating><br/><AfterRating>" + serviceRating + "</AfterRating></EventDetail>";
            eventLoggerFacade.LogEvent(eventSource, EventNames.OVER_RIDE_SERVICE_RATING, comments, currentUser, sessionId);
        }
    }
}
