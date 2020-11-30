using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorManagementRepository
    {
        /// <summary>
        /// Saves the business hours.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="businessHours">The business hours.</param>
        /// <param name="createBy">The create by.</param>
        public void SaveBusinessHours(int vendorLocationID, List<BusinessHours> businessHours, string createBy)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<VendorLocationBusinessHour> existingList = dbContext.VendorLocationBusinessHours.Where(a => a.VendorLocationID == vendorLocationID).ToList<VendorLocationBusinessHour>();
                foreach (var item in existingList)
                {
                    dbContext.Entry(item).State = EntityState.Deleted;
                }
                var newBH = (VendorLocationBusinessHour)null;
                foreach (var bh in businessHours)
                {
                    newBH = new VendorLocationBusinessHour()
                    {
                        VendorLocationID = vendorLocationID,
                        DayName = bh.DayName,
                        DayNumber = bh.DayNumber,
                        StartTime = bh.StartTime,
                        EndTime = bh.EndTime,
                        CreateBy = createBy,
                        CreateDate = DateTime.Now
                    };
                    dbContext.VendorLocationBusinessHours.Add(newBH);
                }
                dbContext.SaveChanges();
            }

        }

        /// <summary>
        /// Gets the business hours.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        public List<BusinessHours> GetBusinessHours(int vendorLocationID)
        {
            List<BusinessHours> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.VendorLocationBusinessHours
                                .Where(u => u.VendorLocationID.Value == vendorLocationID)
                                .Select(u => new BusinessHours()
                                {
                                    DayName = u.DayName,
                                    DayNumber = u.DayNumber.Value,
                                    StartTime = u.StartTime,
                                    EndTime = u.EndTime

                                }).ToList();
            }
            return list;
        }
    }
}
