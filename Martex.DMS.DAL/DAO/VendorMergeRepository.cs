using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Data.Entity.Core.Objects;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public class VendorMergeRepository
    {
        /// <summary>
        /// Gets the duplicate vendors.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<DuplicateVendors_Result> GetDuplicateVendors(PageCriteria pc, int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetDuplicateVendors(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, vendorID).ToList<DuplicateVendors_Result>();
            }
        }
        public Entity GetEntity(string EntityName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Entities.Where(a => a.Name == EntityName).FirstOrDefault();
            }
        }

        /// <summary>
        /// Updates the PO for merge vendor.
        /// </summary>
        /// <param name="sourceVendorLocationID">The source vendor location ID.</param>
        /// <param name="targetVendorLocationID">The target vendor location ID.</param>
        /// <param name="currentUser">The current user.</param>
        public List<PurchaseOrder> UpdatePOForMergeVendor(int sourceVendorLocationID, int targetVendorLocationID, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<PurchaseOrder> poList = dbContext.PurchaseOrders.Where(a => a.VendorLocationID == sourceVendorLocationID).ToList<PurchaseOrder>();
                foreach (var po in poList)
                {
                    po.VendorLocationID = targetVendorLocationID;
                    po.ModifyBy = currentUser;
                    po.ModifyDate = DateTime.Now;
                    dbContext.Entry(po).State = EntityState.Modified;
                }

                Entity entity = GetEntity("VendorLocation");
                List<EventLogLink> ellList = dbContext.EventLogLinks.Where(a => a.RecordID == sourceVendorLocationID && a.EntityID == entity.ID).ToList<EventLogLink>();
                foreach (var ell in ellList)
                {
                    ell.RecordID = targetVendorLocationID;
                    dbContext.Entry(ell).State = EntityState.Modified;
                }

                List<ContactLogLink> cllList = dbContext.ContactLogLinks.Where(a => a.RecordID == sourceVendorLocationID && a.EntityID == entity.ID).ToList<ContactLogLink>();
                foreach (var cll in cllList)
                {
                    cll.RecordID = targetVendorLocationID;
                    dbContext.Entry(cll).State = EntityState.Modified;
                }
                dbContext.SaveChanges();

                return poList;
            }
        }

        /// <summary>
        /// Updates the vendor invoice for merge vendor.
        /// </summary>
        /// <param name="sourceVendorID">The source vendor ID.</param>
        /// <param name="targetVendorID">The target vendor ID.</param>
        /// <param name="currentUser">The current user.</param>
        public List<VendorInvoice> UpdateVendorInvoiceForMergeVendor(int sourceVendorID, int targetVendorID, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<VendorInvoice> viList = dbContext.VendorInvoices.Where(a => a.VendorID == sourceVendorID).ToList<VendorInvoice>();
                foreach (var vi in viList)
                {
                    vi.VendorID = targetVendorID;
                    vi.ModifyBy = currentUser;
                    vi.ModifyDate = DateTime.Now;
                    dbContext.Entry(vi).State = EntityState.Modified;
                }

                Entity entity = GetEntity("Vendor");
                List<EventLogLink> ellList = dbContext.EventLogLinks.Where(a => a.RecordID == sourceVendorID && a.EntityID == entity.ID).ToList<EventLogLink>();
                foreach (var ell in ellList)
                {
                    ell.RecordID = targetVendorID;
                    dbContext.Entry(ell).State = EntityState.Modified;
                }

                List<ContactLogLink> cllList = dbContext.ContactLogLinks.Where(a => a.RecordID == sourceVendorID && a.EntityID == entity.ID).ToList<ContactLogLink>();
                foreach (var cll in cllList)
                {
                    cll.RecordID = targetVendorID;
                    dbContext.Entry(cll).State = EntityState.Modified;
                }
                dbContext.SaveChanges();
                return viList;
            }
        }

        /// <summary>
        /// Deletes the source vendor location.
        /// </summary>
        /// <param name="sourceVendorID">The source vendor ID.</param>
        /// <param name="sourceVendorLocationID">The source vendor location ID.</param>
        /// <param name="currentUser">The current user.</param>
        public void DeleteSourceVendor(int sourceVendorID, int sourceVendorLocationID, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorLocation vendorLocation = dbContext.VendorLocations.Where(a => a.ID == sourceVendorLocationID).FirstOrDefault();
                vendorLocation.IsActive = false;
                vendorLocation.ModifyBy = currentUser;
                vendorLocation.ModifyDate = DateTime.Now;
                dbContext.Entry(vendorLocation).State = EntityState.Modified;

                List<VendorLocation> vendorLocationsList = new List<VendorLocation>();
                vendorLocationsList = dbContext.VendorLocations.Where(a => a.VendorID == sourceVendorID && a.IsActive != false && a.ID != sourceVendorLocationID).ToList<VendorLocation>();

                if (vendorLocationsList.Count <= 0)
                {
                    Vendor vendor = dbContext.Vendors.Where(a => a.ID == sourceVendorID).FirstOrDefault();
                    vendor.IsActive = false;
                    vendor.ModifyBy = currentUser;
                    vendor.ModifyDate = DateTime.Now;
                    dbContext.Entry(vendor).State = EntityState.Modified;
                }
                dbContext.SaveChanges();
            }
        }
    }
}
