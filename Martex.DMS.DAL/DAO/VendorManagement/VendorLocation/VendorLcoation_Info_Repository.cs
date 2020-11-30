using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorManagementRepository
    {
        #region Vendor Location Information Details

        public List<VendorLocationGeographyListManage_Result> GetVendorLocationGeographyList(PageCriteria page)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationGeographyListManage(page.WhereClause, page.StartInd, page.EndInd, page.PageSize, page.SortColumn, page.SortDirection).ToList();
            }
        }
        public VendorLocation GetVendorLocationDetails(int vendorLocationID)
        {
            VendorLocation model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.VendorLocations.Where(u => u.ID == vendorLocationID).FirstOrDefault();
            }
            return model;
        }

        public VendorLocation_GeographyLocation_Result GetVendorLocationGeographyDetails(int vendorLocationID)
        {
            VendorLocation_GeographyLocation_Result model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.GetVendorLocationGeographyLocation(vendorLocationID).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Determines whether [is vendor location coach net dealer partner] [the specified vendor location identifier].
        /// </summary>
        /// <param name="vendorLocationID">The vendor location identifier.</param>
        /// <returns></returns>
        public bool IsVendorLocationCoachNetDealerPartner(int vendorLocationID)
        {
            bool isVendorLocationCoachNetDealerPartner = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                Product product = dbContext.Products.Where(a => a.Name == Products.COACHNET_DEALER_PARTNER).FirstOrDefault();
                VendorLocationProduct vlp = dbContext.VendorLocationProducts.Where(a => a.VendorLocationID == vendorLocationID && a.ProductID == product.ID).FirstOrDefault();
                if (vlp != null)
                {
                    isVendorLocationCoachNetDealerPartner = true;
                }
            }
            return isVendorLocationCoachNetDealerPartner;
        }

        /// <summary>
        /// Gets the vendor location product rating for coach net dealer partner.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location identifier.</param>
        /// <returns></returns>
        public decimal? GetVendorLocationProductRatingForCoachNetDealerPartner(int vendorLocationID)
        {
            decimal? VLPRatingForCoachNetDealerPartner = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                Product product = dbContext.Products.Where(a => a.Name == "CoachNet Dealer Partner").FirstOrDefault();
                VendorLocationProduct vlp = dbContext.VendorLocationProducts.Where(a => a.VendorLocationID == vendorLocationID && a.ProductID == product.ID).FirstOrDefault();
                if (vlp != null)
                {
                    VLPRatingForCoachNetDealerPartner = vlp.Rating;
                }
            }
            return VLPRatingForCoachNetDealerPartner;
        }


        #endregion

        #region Get Payment types for Vendor Location
        public List<CheckBoxLookUp> GetPaymentTypesForVendorLocation(int vendorLocationID, string entityName)
        {
            List<CheckBoxLookUp> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                // Get All the payment Types
                list = dbContext.GetVendorLocationPaymentTypes(vendorLocationID, entityName).Select(f => new CheckBoxLookUp()
                {
                    ID = f.ProductID,
                    Name = f.Description,
                    Selected = f.IsSelected.Value
                }).ToList();


            }
            return list;
        }
        #endregion

        #region Save Details for Vendor Location
        public void UpdateVendorLocation(int vendorLcoationID, decimal? latitude, decimal? longitude, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.VendorLocations.Where(u => u.ID == vendorLcoationID).FirstOrDefault();
                if (existingRecord != null)
                {
                    // Address 
                    existingRecord.Latitude = latitude;
                    existingRecord.Longitude = longitude;
                    existingRecord.ModifyBy = userName;
                    existingRecord.ModifyDate = DateTime.Now;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Updates the vendor location.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void UpdateVendorLcoation(VendorLocation model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.VendorLocations.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingRecord != null)
                {

                    // Other Properties
                    existingRecord.ModifyBy = userName;
                    existingRecord.ModifyDate = DateTime.Now;

                    // Ford Dealer Section
                    existingRecord.IsDirectTow = model.IsDirectTow;
                    existingRecord.PartsAndAccessoryCode = model.PartsAndAccessoryCode;

                    // Dispatch Notes
                    existingRecord.DispatchNote = model.DispatchNote;
                    existingRecord.DispatchEmail = model.DispatchEmail;

                    // Address 
                    existingRecord.Latitude = model.Latitude;
                    existingRecord.Longitude = model.Longitude;

                    // Basic Information
                    existingRecord.VendorLocationStatusID = model.VendorLocationStatusID;
                    existingRecord.IsOpen24Hours = model.IsOpen24Hours;
                    existingRecord.BusinessHours = model.BusinessHours;
                    existingRecord.IsKeyDropAvailable = model.IsKeyDropAvailable;
                    existingRecord.IsOvernightStayAllowed = model.IsOvernightStayAllowed;
                    existingRecord.IsElectronicDispatchAvailable = model.IsElectronicDispatchAvailable;
                    existingRecord.DealerNumber = model.DealerNumber;

                    existingRecord.Sequence = null;

                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the vendor location coach net dealer partner details.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location identifier.</param>
        /// <param name="isCoachNetDealerPartner">if set to <c>true</c> [is coach net dealer partner].</param>
        /// <param name="VLPRatingForCoachNetDealerPartner">The VLP rating for coach net dealer partner.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="System.NotImplementedException"></exception>
        public void UpdateVendorLocationCoachNetDealerPartnerDetails(int vendorLocationID, bool isCoachNetDealerPartner, decimal? VLPRatingForCoachNetDealerPartner, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Product product = dbContext.Products.Where(a => a.Name == Products.COACHNET_DEALER_PARTNER).FirstOrDefault();
                VendorLocationProduct vlp = dbContext.VendorLocationProducts.Where(a => a.VendorLocationID == vendorLocationID && a.ProductID == product.ID).FirstOrDefault();
                if (isCoachNetDealerPartner)
                {
                    if (vlp != null)
                    {
                        vlp.Rating = VLPRatingForCoachNetDealerPartner;
                        vlp.ModifyBy = userName;
                        vlp.ModifyDate = DateTime.Now;
                        dbContext.Entry(vlp).State = EntityState.Modified;
                    }
                    else
                    {
                        vlp = new VendorLocationProduct();
                        vlp.ProductID = product.ID;
                        vlp.VendorLocationID = vendorLocationID;
                        vlp.Rating = VLPRatingForCoachNetDealerPartner;
                        vlp.IsActive = true;
                        vlp.CreateBy = userName;
                        vlp.CreateDate = DateTime.Now;
                        dbContext.VendorLocationProducts.Add(vlp);
                    }
                }
                else
                {
                    if (vlp != null)
                    {
                        dbContext.Entry(vlp).State = EntityState.Deleted;
                    }
                }
                dbContext.SaveChanges();
            }
        }
        #endregion
    }
}
