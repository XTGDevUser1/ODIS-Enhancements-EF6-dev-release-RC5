using Martex.DMS.DAL.DMSBaseException;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorManagementRepository
    {
        /// <summary>
        /// Gets the zip codes as CSV.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationPostalCode> GetZipCodes(int vendorLocationID)
        {   
            using (DMSEntities dbContext = new DMSEntities())
            {
                var zipCodes = dbContext.VendorLocationPostalCodes.Where(vlp => vlp.VendorLocationID == vendorLocationID).ToList();
                return zipCodes;
            }
        }



        /// <summary>
        /// Gets the virtual locations.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationVirtual_Result> GetVirtualLocations(int vendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationVirtual(vendorLocationID).ToList<VendorLocationVirtual_Result>();
                //var list = dbContext.VendorLocationVirtuals.Include("VendorLocations").Where(x => x.VendorLocationID == vendorLocationID).ToList<VendorLocationVirtual>();
                //return list;
            }

        }

        /// <summary>
        /// Saves the vendor location service area details.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="isAbleToCrossStateLines">if set to <c>true</c> [is able to cross state lines].</param>
        /// <param name="isAbleToCrossNationalBorders">if set to <c>true</c> [is able to cross national borders].</param>
        /// <param name="isUsingZipCodes">if set to <c>true</c> [is using zip codes].</param>
        public void SaveVendorLocationServiceFlags(int vendorLocationID, bool isAbleToCrossStateLines, bool isAbleToCrossNationalBorders, bool isUsingZipCodes)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var record = dbContext.VendorLocations.Where(v => v.ID == vendorLocationID).FirstOrDefault();
                if (record != null)
                {
                    record.IsUsingZipCodes = isUsingZipCodes;
                    record.IsAbleToCrossStateLines = isAbleToCrossStateLines;
                    record.IsAbleToCrossNationalBorders = isAbleToCrossNationalBorders;

                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Saves the zip codes.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="zipCodesAsCSV">The zip codes as CSV.</param>
        public void SaveZipCodes(int vendorLocationID, string zipCodesAsCSV, string currentUser, bool isSecondary = false)
        {
            List<string> postalCodes = new List<string>();
            if (!string.IsNullOrEmpty(zipCodesAsCSV))
            {
                postalCodes = zipCodesAsCSV.Split(',', ' ', '\r', '\n').ToList<string>();
            }

            postalCodes.ForEach(p =>
            {
                if (p.Length > 20)
                {
                    throw new DMSException(string.Format("Zip codes are not in correct format - {0}", p));
                }
            });

            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingPostalCodes = dbContext.VendorLocationPostalCodes.Where(x => x.VendorLocationID == vendorLocationID && (x.IsSecondary == null || x.IsSecondary == isSecondary)).ToList<VendorLocationPostalCode>();
                existingPostalCodes.ForEach(v =>
                {
                    dbContext.Entry(v).State = EntityState.Deleted;
                });
                postalCodes.ForEach(s =>
                {
                    if (!string.IsNullOrEmpty(s) && s.Trim().Length > 0)
                    {
                        VendorLocationPostalCode vlpc = new VendorLocationPostalCode();
                        vlpc.PostalCode = s.Trim();
                        vlpc.VendorLocationID = vendorLocationID;
                        vlpc.CreateBy = currentUser;
                        vlpc.CreateDate = DateTime.Now;
                        vlpc.IsActive = true;
                        vlpc.IsSecondary = isSecondary;
                        dbContext.VendorLocationPostalCodes.Add(vlpc);
                    }
                });
                dbContext.SaveChanges();
            }

        }

        /// <summary>
        /// Saves the virtual locations.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="virtualLocations">The virtual locations.</param>
        public void SaveVirtualLocations(int vendorLocationID, List<VendorLocationVirtual_Result> virtualLocations, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingVirtualLocations = dbContext.VendorLocationVirtuals.Where(x => x.VendorLocationID == vendorLocationID).ToList<VendorLocationVirtual>();
                existingVirtualLocations.ForEach(v =>
                {
                    dbContext.Entry(v).State = EntityState.Deleted;
                });

                if (virtualLocations != null)
                {
                    virtualLocations.ForEach(s =>
                    {
                        VendorLocationVirtual vl = new VendorLocationVirtual();
                        vl.LocationAddress = s.LocationAddress;
                        vl.LocationCity = s.LocationCity;
                        vl.LocationCountryCode = s.LocationCountryCode;
                        vl.LocationPostalCode = s.LocationPostalCode;
                        vl.LocationStateProvince = s.LocationStateProvince;
                        vl.Longitude = s.Longitude;
                        vl.Latitude = s.Latitude;
                        vl.VendorLocationID = vendorLocationID;
                        vl.CreateBy = currentUser;
                        vl.CreateDate = DateTime.Now;
                        dbContext.VendorLocationVirtuals.Add(vl);
                    });
                }
                dbContext.SaveChanges();
            }

        }
    }
}
