using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using System.Transactions;
using Martex.DMS.Areas.Application.Models;
using log4net;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade.VendorManagement.VendorBase;

namespace Martex.DMS.BLL.Facade
{
    public class VendorMergeFacade
    {
        VendorMergeRepository repository = new VendorMergeRepository();

        /// <summary>
        /// Gets the duplicate vendor.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<DuplicateVendors_Result> GetDuplicateVendor(PageCriteria pc, int vendorID)
        {
            return repository.GetDuplicateVendors(pc, vendorID);
        }

        /// <summary>
        /// Merges the vendors.
        /// </summary>
        /// <param name="sourceVendorID">The source vendor ID.</param>
        /// <param name="targetVendorID">The target vendor ID.</param>
        public void MergeVendors(int sourceVendorID, int targetVendorID, int sourceVendorLocationID, int targetVendorLocationID, string currentUser, string requestUrl, string SessionID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                #region 1. Update PO
                List<PurchaseOrder> poList = repository.UpdatePOForMergeVendor(sourceVendorLocationID, targetVendorLocationID, currentUser);
                #endregion

                #region 2.Update Vendor Invoice
                List<VendorInvoice> viList = repository.UpdateVendorInvoiceForMergeVendor(sourceVendorID, targetVendorID, currentUser);
                #endregion

                #region 3.Delete Source Vendor Location
                repository.DeleteSourceVendor(sourceVendorID, sourceVendorLocationID, currentUser);
                #endregion

                #region 4.Insert EventLog
                StringBuilder sb=new StringBuilder();
                string Comments = "<EventData><SourceVendor>" + sourceVendorID + "</SourceVendor><br/><TargetVendor>" + targetVendorID + "</TargetVendor><br/>"
                                + "<SourceVendorLocation>" + sourceVendorLocationID + "</SourceVendorLocation><br/><TargetVendorLocation>" + targetVendorLocationID + "</TargetVendorLocation><br/>";
                sb.Append(Comments);
                sb.Append("<PurchaseOrders>");
                bool firstIteration = true;
                foreach (var po in poList)
                {
                    string poComments = po.ID.ToString();
                    if (!firstIteration)
                    {
                        sb.Append(",");
                        firstIteration = false;
                    }
                    sb.Append(poComments);

                    
                }
                sb.Append("</PurchaseOrders><br/>");
                sb.Append("<VendorInvoices>");
                firstIteration = true;
                foreach (var vi in viList)
                {
                    string viComments = vi.ID.ToString();
                    if (!firstIteration)
                    {
                        sb.Append(",");
                        firstIteration = false;
                    }
                    sb.Append(viComments);
                }
                sb.Append("</VendorInvoices>");
                sb.Append("</EventData>");
                //MergeVendor

                var eventLoggerFacade = new EventLoggerFacade();

                long eventLogID=eventLoggerFacade.LogEvent(requestUrl, EventNames.MERGE_VENDOR,sb.ToString(), currentUser,SessionID);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, sourceVendorID, EntityNames.VENDOR);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, targetVendorID, EntityNames.VENDOR);

                #endregion

                tran.Complete();
            }
        }
    }
}
