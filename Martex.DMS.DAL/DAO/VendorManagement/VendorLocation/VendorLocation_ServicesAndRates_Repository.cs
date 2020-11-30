using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public partial class VendorManagementRepository
    {
        /// <summary>
        /// Gets the vendor location services and results.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorServicesAndRates_Result> GetVendorLocationServicesAndResults(int VendorLocationID, int rateScheduleID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorServicesAndRates(rateScheduleID, VendorLocationID).ToList<VendorServicesAndRates_Result>();
            }
        }


        /// <summary>
        /// Gets the vendor location services.
        /// </summary>
        /// <returns></returns>
        public List<Product> GetVendorLocationServices()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Products.Where(a => a.IsActive == true).ToList<Product>();
            }
        }

        /// <summary>
        /// Gets the vendor products.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<DropDownEntity> GetVendorProducts(int vendorID, int? contractRateScheduleID, int? productID)
        {
            List<DropDownEntity> vpList = null;
            List<DropDownEntity> crspList = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                // Step 1 Get All the Product Associated with this Vendor
                vpList = (from vp in dbContext.VendorProducts
                          join pr in dbContext.Products
                          on vp.ProductID equals pr.ID
                          where vp.VendorID == vendorID
                          where vp.IsActive == true
                          select new DropDownEntity()
                          {
                              ID = pr.ID,
                              Name = pr.Name
                          }).ToList();


                crspList = (from crsp in dbContext.ContractRateScheduleProducts
                            join pr in dbContext.Products
                            on crsp.ProductID equals pr.ID
                            where crsp.ContractRateScheduleID == contractRateScheduleID && crsp.ProductID != (productID ?? 0)
                            select new DropDownEntity()
                            {
                                ID = pr.ID,
                                Name = pr.Name
                            }).Distinct().ToList();
            }
            var results = (from vp in vpList
                           join crsp in crspList on vp.ID equals crsp.ID into l
                           from crsp in l.DefaultIfEmpty()
                           where crsp == null
                           select new DropDownEntity()
                           {
                               ID = vp.ID,
                               Name = vp.Name
                           }).ToList();
            return results;
        }


        public List<DropDownEntity> GetVendorProducts(int vendorID)
        {
            List<DropDownEntity> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                // Step 1 Get All the Product Associated with this Vendor
                list = (from vp in dbContext.VendorProducts
                        join pr in dbContext.Products
                        on vp.ProductID equals pr.ID
                        where vp.VendorID == vendorID
                        where vp.IsActive == true
                        select new DropDownEntity()
                        {
                            ID = pr.ID,
                            Name = pr.Name
                        }).ToList();

            }

            return list;
        }

        /// <summary>
        /// Gets the contract rate schedule status ID.
        /// </summary>
        /// <param name="Name">The name.</param>
        /// <returns></returns>
        public ContractRateScheduleStatu GetContractRateScheduleStatusID(string Name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContractRateScheduleStatus.Where(a => a.Name == Name && a.IsActive == true).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the type of the rate.
        /// </summary>
        /// <param name="Name">The name.</param>
        /// <returns></returns>
        public RateType GetRateType(string Name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.RateTypes.Where(a => a.Name == Name && a.IsActive == true).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the product.
        /// </summary>
        /// <param name="Name">The name.</param>
        /// <returns></returns>
        public Product GetProduct(string Name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Products.Where(a => a.Name == Name && a.IsActive == true).FirstOrDefault();
            }
        }

        /// <summary>
        /// Saves the contract rate schedule status.
        /// </summary>
        /// <param name="crs">The CRS.</param>
        public void SaveContractRateSchedule(VendorRatesDetailsModel model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existing = dbContext.ContractRateSchedules.Where(c => c.ID == model.ContractRateScheduleID).FirstOrDefault();
                if (existing != null)
                {
                    existing.ContractRateScheduleStatusID = model.ContractRateScheduleStatusID;
                    existing.StartDate = model.StartDate;
                    existing.EndDate = model.EndDate;
                    existing.SignedBy = model.SignedBy;
                    existing.SignedByTitle = model.SignedByTitle;
                    existing.SignedDate = model.SignedDate;

                    existing.ModifyBy = userName;
                    existing.ModifyDate = DateTime.Now;

                    dbContext.Entry(existing).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Saves the vendor rates.
        /// </summary>
        /// <param name="crsp">The CRSP.</param>
        public void SaveVendorRates(ContractRateScheduleProduct crsp)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ContractRateScheduleProducts.Add(crsp);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the contract rate schedule product.
        /// </summary>
        /// <param name="crsp">The CRSP.</param>
        public void UpdateContractRateScheduleProduct(ContractRateScheduleProduct crsp)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Entry(crsp).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Saves the contract rate schedule product log.
        /// </summary>
        /// <param name="crspl">The CRSPL.</param>
        public void SaveContractRateScheduleProductLog(ContractRateScheduleProductLog crspl)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ContractRateScheduleProductLogs.Add(crspl);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the existing vendor location rate list.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="ProductID">The product ID.</param>
        /// <returns></returns>
        public List<ContractRateScheduleProduct> GetExistingContractRateScheduleProductsList(int? ContractRateScheduleID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContractRateScheduleProducts.Where(a => a.ContractRateScheduleID == ContractRateScheduleID).ToList<ContractRateScheduleProduct>();
            }
        }

        /// <summary>
        /// Updates the VLR details.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="VLRS">The VLRS.</param>
        /// <param name="currentUser">The current user.</param>
        public void UpdateVLRDetails(int vendorLocationID, VendorLocationRatesAndServices_Result VLRS, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<ContractRateScheduleProduct> contractList = dbContext.ContractRateScheduleProducts.Where(a => a.ContractRateScheduleID == VLRS.ContractRateScheduleID).ToList<ContractRateScheduleProduct>();
                decimal value = Convert.ToDecimal(0);
                UpdateContractRateScheduleProduct(VLRS.ProductID, RateTypes.BASE, VLRS.BaseRate, Convert.ToDecimal(1), currentUser, contractList, VLRS.ContractRateScheduleID, vendorLocationID);
                UpdateContractRateScheduleProduct(VLRS.ProductID, RateTypes.ENROUTE, VLRS.EnrouteRate, value, currentUser, contractList, VLRS.ContractRateScheduleID, vendorLocationID);
                UpdateContractRateScheduleProduct(VLRS.ProductID, RateTypes.ENROUTE_FREE, -1*VLRS.EnrouteRate, VLRS.EnrouteFreeMiles, currentUser, contractList, VLRS.ContractRateScheduleID, vendorLocationID);
                UpdateContractRateScheduleProduct(VLRS.ProductID, RateTypes.GONE_ON_ARRIVAL, VLRS.GoaRate, value, currentUser, contractList, VLRS.ContractRateScheduleID, vendorLocationID);
                UpdateContractRateScheduleProduct(VLRS.ProductID, RateTypes.HOURLY, VLRS.HourlyRate, value, currentUser, contractList, VLRS.ContractRateScheduleID, vendorLocationID);
                UpdateContractRateScheduleProduct(VLRS.ProductID, RateTypes.SERVICE, VLRS.ServiceRate, value, currentUser, contractList, VLRS.ContractRateScheduleID, vendorLocationID);
                UpdateContractRateScheduleProduct(VLRS.ProductID, RateTypes.SERVICE_FREE, -1*VLRS.ServiceRate, VLRS.ServiceFreeMiles, currentUser, contractList, VLRS.ContractRateScheduleID, vendorLocationID);
                foreach (var list in contractList)
                {
                    dbContext.Entry(list).State = EntityState.Modified;
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the vendor rates.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void UpdateVendorRates(VendorServicesAndRates_Result model, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<ContractRateScheduleProduct> contractList = dbContext.ContractRateScheduleProducts.Where(a => a.ContractRateScheduleID == model.ContractRateScheduleID).ToList<ContractRateScheduleProduct>();
                decimal value = Convert.ToDecimal(0);
                UpdateContractRateScheduleProduct(model.ProductID, RateTypes.BASE, model.BaseRate, Convert.ToDecimal(1), currentUser, contractList, model.ContractRateScheduleID, null);
                UpdateContractRateScheduleProduct(model.ProductID, RateTypes.ENROUTE, model.EnrouteRate, value, currentUser, contractList, model.ContractRateScheduleID, null);
                UpdateContractRateScheduleProduct(model.ProductID, RateTypes.ENROUTE_FREE, -1*model.EnrouteRate, model.EnrouteFreeMiles, currentUser, contractList, model.ContractRateScheduleID, null);
                UpdateContractRateScheduleProduct(model.ProductID, RateTypes.GONE_ON_ARRIVAL, model.GoaRate, value, currentUser, contractList, model.ContractRateScheduleID, null);
                UpdateContractRateScheduleProduct(model.ProductID, RateTypes.HOURLY, model.HourlyRate, value, currentUser, contractList, model.ContractRateScheduleID, null);
                UpdateContractRateScheduleProduct(model.ProductID, RateTypes.SERVICE, model.ServiceRate, value, currentUser, contractList, model.ContractRateScheduleID, null);
                UpdateContractRateScheduleProduct(model.ProductID, RateTypes.SERVICE_FREE, -1*model.ServiceRate, model.ServiceFreeMiles, currentUser, contractList, model.ContractRateScheduleID, null);
                foreach (var list in contractList)
                {
                    dbContext.Entry(list).State = EntityState.Modified;
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Deletes the vendor service and rates.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void DeleteVendorRates(VendorServicesAndRates_Result model, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<ContractRateScheduleProduct> contractList = dbContext.ContractRateScheduleProducts.Where(a => a.ContractRateScheduleID == model.ContractRateScheduleID && a.ProductID == model.ProductID && a.VendorLocationID == null).ToList<ContractRateScheduleProduct>();
                if (contractList.Count > 0)
                {
                    InsertContractRateScheduleProductLogForDelete(model.ProductID, RateTypes.BASE, currentUser, contractList, model.ContractRateScheduleID);
                    InsertContractRateScheduleProductLogForDelete(model.ProductID, RateTypes.ENROUTE, currentUser, contractList, model.ContractRateScheduleID);
                    InsertContractRateScheduleProductLogForDelete(model.ProductID, RateTypes.ENROUTE_FREE, currentUser, contractList, model.ContractRateScheduleID);
                    InsertContractRateScheduleProductLogForDelete(model.ProductID, RateTypes.GONE_ON_ARRIVAL, currentUser, contractList, model.ContractRateScheduleID);
                    InsertContractRateScheduleProductLogForDelete(model.ProductID, RateTypes.HOURLY, currentUser, contractList, model.ContractRateScheduleID);
                    InsertContractRateScheduleProductLogForDelete(model.ProductID, RateTypes.SERVICE, currentUser, contractList, model.ContractRateScheduleID);
                    InsertContractRateScheduleProductLogForDelete(model.ProductID, RateTypes.SERVICE_FREE, currentUser, contractList, model.ContractRateScheduleID);

                    foreach (var list in contractList)
                    {
                        dbContext.Entry(list).State = EntityState.Deleted;
                    }
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the contract rate schedule product.
        /// </summary>
        /// <param name="productID">The product ID.</param>
        /// <param name="rateTypeName">Name of the rate type.</param>
        /// <param name="Price">The price.</param>
        /// <param name="Quantity">The quantity.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="existingProducts">The existing products.</param>
        /// <param name="ContractScheduleID">The contract schedule ID.</param>
        /// <param name="vendorLocatioID">The vendor location ID.</param>
        /// <exception cref="DMSException"></exception>
        private void UpdateContractRateScheduleProduct(int? productID, string rateTypeName, decimal? Price, decimal? Quantity, string currentUser, List<ContractRateScheduleProduct> existingProducts, int? ContractScheduleID, int? vendorLocationID)
        {
            RateType rateType = GetRateType(rateTypeName);
            if (rateType == null)
            {
                throw new DMSException(rateTypeName + " - Rate Type not set up in the system");
            }
            ContractRateScheduleProduct crsp = existingProducts.Where(a => a.RateTypeID == rateType.ID && a.ProductID == productID).FirstOrDefault();
            if (crsp != null)
            {
                decimal? oldPrice = crsp.Price;
                int? oldQuanitity = crsp.Quantity;
                //if (Convert.ToDecimal(Price) > 0) TFS : 2259
                //{
                    crsp.Price = Convert.ToDecimal(Price);
                //}
                if (Quantity > 0)
                {
                    crsp.Quantity = int.Parse(Quantity.ToString());
                }
                if (productID != null)
                {
                    crsp.ProductID = int.Parse(productID.ToString());
                }
                crsp.ModifyBy = currentUser;
                crsp.ModifyDate = DateTime.Now;

                using (DMSEntities dbContext = new DMSEntities())
                {
                    ContractRateScheduleProductLog crspl = new ContractRateScheduleProductLog();
                    crspl.ContractRateScheduleID = int.Parse(ContractScheduleID.ToString());
                    crspl.VendorLocationID = vendorLocationID.HasValue ? vendorLocationID.Value : (int?)null;
                    if (productID != null)
                    {
                        crspl.ProductID = int.Parse(productID.ToString());
                    }
                    crspl.RateTypeID = rateType.ID;
                    if (oldPrice != null)
                    {
                        crspl.OldPrice = oldPrice;
                    }
                    if (Convert.ToDecimal(Price) > 0)
                    {
                        crspl.NewPrice = Convert.ToDecimal(Price);
                    }
                    if (oldQuanitity != null)
                    {
                        crspl.OldQuantity = oldQuanitity;
                    }
                    if (Quantity > 0)
                    {
                        crspl.NewQuantity = int.Parse(Quantity.ToString());
                    }
                    crspl.ActivityType = "Update";
                    crspl.CreateBy = currentUser;
                    crspl.CreateDate = DateTime.Now;
                    dbContext.ContractRateScheduleProductLogs.Add(crspl);
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Inserts the contract rate schedule product log for delete.
        /// </summary>
        /// <param name="productID">The product ID.</param>
        /// <param name="rateTypeName">Name of the rate type.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="existingProducts">The existing products.</param>
        /// <param name="ContractScheduleID">The contract schedule ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <exception cref="DMSException"></exception>
        private void InsertContractRateScheduleProductLogForDelete(int? productID, string rateTypeName, string currentUser, List<ContractRateScheduleProduct> existingProducts, int? ContractScheduleID)
        {
            RateType rateType = GetRateType(rateTypeName);
            if (rateType == null)
            {
                throw new DMSException(rateTypeName + " - Rate Type not set up in the system");
            }
            ContractRateScheduleProduct crsp = existingProducts.Where(a => a.RateTypeID == rateType.ID).FirstOrDefault();
            if (crsp != null)
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    decimal? oldPrice = crsp.Price;
                    int? oldQuanitity = crsp.Quantity;
                    ContractRateScheduleProductLog crspl = new ContractRateScheduleProductLog();
                    crspl.ContractRateScheduleID = int.Parse(ContractScheduleID.ToString());
                    if (productID != null)
                    {
                        crspl.ProductID = int.Parse(productID.ToString());
                    }
                    crspl.RateTypeID = rateType.ID;
                    if (oldPrice != null)
                    {
                        crspl.OldPrice = oldPrice;
                    }
                    if (oldQuanitity != null)
                    {
                        crspl.OldQuantity = oldQuanitity;
                    }
                    crspl.ActivityType = "Delete";
                    crspl.CreateBy = currentUser;
                    crspl.CreateDate = DateTime.Now;
                    dbContext.ContractRateScheduleProductLogs.Add(crspl);
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets the vendor location contract rate schedule product log.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationContractRateScheduleProductLog_Result> GetVendorLocationContractRateScheduleProductLog(PageCriteria pc, int contractRateScheduleID, int? vendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationContractRateScheduleProductLog(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, contractRateScheduleID, vendorLocationID).ToList<VendorLocationContractRateScheduleProductLog_Result>();
            }
        }

        /// <summary>
        /// Gets the vendor contracts.
        /// </summary>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Contract> GetVendorContracts(int VendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Contracts.OrderByDescending(a => a.StartDate).Where(a => a.VendorID == VendorID && a.IsActive == true).ToList<Contract>();
            }
        }

        /// <summary>
        /// Adds the contract rate schedule.
        /// </summary>
        /// <param name="crs">The CRS.</param>
        /// <param name="status">The status.</param>
        public void AddContractRateSchedule(ContractRateSchedule crs, string status)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var crsStatus = dbContext.ContractRateScheduleStatus.Where(c => c.Name == status).FirstOrDefault();
                if (crsStatus == null)
                {
                    throw new DMSException(string.Format("ContractRateScheduleStatus - {0} is not set up in the system", status));
                }
                crs.ContractRateScheduleStatusID = crsStatus.ID;

                dbContext.ContractRateSchedules.Add(crs);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Adds the vendor contract rate schedule.
        /// </summary>
        /// <param name="contractID">The contract ID.</param>
        /// <param name="userName">Name of the user.</param>
        public void AddVendorContractRateSchedule(int contractID, int contractRateScheduleID, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.AddVendorContractRateSchedule(contractRateScheduleID, contractID, userName);
            }
        }

        /// <summary>
        /// Gets the service ratings.
        /// </summary>
        /// <param name="vendorLocationId">The vendor location unique identifier.</param>
        /// <returns></returns>
        public List<VendorLocationServiceRatings_Result> GetLocationServiceRatings(int vendorLocationId)
        {
            List<VendorLocationServiceRatings_Result> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.GetVendorLocationServiceRatings(vendorLocationId).ToList<VendorLocationServiceRatings_Result>();
            }
            return list;
        }

        public VendorLocationProduct GetVendorLocationProductServiceRating(int serviceRatingID)
        {
            VendorLocationProduct vlp = new VendorLocationProduct();
            using (DMSEntities dbContext = new DMSEntities())
            {
                vlp = dbContext.VendorLocationProducts.Where(a => a.ID == serviceRatingID).FirstOrDefault();
            }
            return vlp;
        }

        public decimal? SaveVendorLocationProductServiceRating(int serviceRatingID, decimal serviceRating, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorLocationProduct vlp = dbContext.VendorLocationProducts.Where(a => a.ID == serviceRatingID).FirstOrDefault();
                decimal? oldServiceRating = vlp.Rating;
                vlp.Rating = serviceRating;
                vlp.ModifyBy = currentUser;
                vlp.ModifyDate = DateTime.Now;
                dbContext.Entry(vlp).State = EntityState.Modified;
                dbContext.SaveChanges();
                return oldServiceRating;
            }
        }
    }
}
