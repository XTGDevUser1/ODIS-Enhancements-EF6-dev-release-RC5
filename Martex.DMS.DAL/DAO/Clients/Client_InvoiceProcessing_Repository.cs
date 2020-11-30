using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// Client Repository
    /// </summary>
    public partial class ClientRepository
    {
        /// <summary>
        /// Gets the billing manage invoices list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<BillingManageInvoicesList_Result> GetBillingManageInvoicesList(PageCriteria pc,string pageMode)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetBillingManageInvoicesList(pc.WhereClause,pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, pageMode).ToList<BillingManageInvoicesList_Result>();
            }
        }

        public List<BillingInvoiceLinesList_Result> GetBillingInvoiceLinesList(PageCriteria pc,int? billingInvoiceID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetBillingInvoiceLinesList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, billingInvoiceID).ToList<BillingInvoiceLinesList_Result>();
            }
        }

        public RateType GetRateType(string rateTypeName)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.RateTypes.Where(a => a.Name == rateTypeName).FirstOrDefault();
            }
        }

        public Product GetProduct(int? productID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.Products.Where(a => a.ID == productID).FirstOrDefault();
            }
        }

        public BillingInvoiceLineStatu GetBillingInvoiceLineStatus(string invoiceLinestatus)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.BillingInvoiceLineStatus.Where(a => a.Name == invoiceLinestatus).FirstOrDefault();
            }
        }

        public void SaveBillingInvoiceLine(BillingInvoiceLine bil,string currentUser)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                bil.IsActive = true;
                bil.CreateBy = currentUser;
                bil.CreateDate = DateTime.Now;
                dbContext.BillingInvoiceLines.Add(bil);
                dbContext.SaveChanges();
            }
        }

        //NP

        public void DeleteBillingInvoiceLine(BillingInvoiceLinesList_Result bil, string currentUser)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                BillingInvoiceLine existingRecord = dbContext.BillingInvoiceLines.Where(a => a.ID == bil.ID).FirstOrDefault();
                existingRecord.IsActive = false;
                existingRecord.ModifyBy = currentUser;
                existingRecord.ModifyDate = DateTime.Now;
                dbContext.Entry(existingRecord).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        public void RefreshBillingInvoice(string invoiceXML,int? scheduleTypeID, int? scheduleDateTypeID, int? scheduleRangeTypeID, string currentUser,bool? refreshDetail)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 6000;
                dbContext.BillingGenerateInvoices(currentUser, refreshDetail, scheduleTypeID, scheduleDateTypeID, scheduleRangeTypeID, invoiceXML);
            }
        }

        public List<ClientInvoiceEventProcessingList_Result> GetClientInvoiceEventProcessingList(PageCriteria pc, int billingInvoiceLineID)
        {
            using (DMSEntities dbcontext=new DMSEntities())
            {
                return dbcontext.GetClientInvoiceEventProcessingList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, billingInvoiceLineID).ToList<ClientInvoiceEventProcessingList_Result>();
            }
        }

        public void UpdateSelectedBillingEventDetailStatus(int[] billinginvoicedetailid, int tostatus, string currentUser, int eventLogId)
        {
            StringBuilder billinginvoiceDetailXML = new StringBuilder("<BillingInvoiceDetail>");
            foreach (int element in billinginvoicedetailid)
            {
                billinginvoiceDetailXML.AppendFormat("<ID>{0}</ID>", element);
            }

            billinginvoiceDetailXML.Append("</BillingInvoiceDetail>");

            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                dbContext.UpdateBillingEventDetailStatus(billinginvoiceDetailXML.ToString(), currentUser, tostatus, eventLogId);
            }
        }

        public void UpdateSelectedBillingEventDetailDisposition(int[] billinginvoicedetailid, int eventLogId, string currentUser,int dispositionId)
        {
            StringBuilder billinginvoiceDetailXML = new StringBuilder("<BillingInvoiceDetail>");
            foreach (int element in billinginvoicedetailid)
            {
                billinginvoiceDetailXML.AppendFormat("<ID>{0}</ID>", element);
            }

            billinginvoiceDetailXML.Append("</BillingInvoiceDetail>");

            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                dbContext.UpdateBillinginvoiceDetailDisposition(billinginvoiceDetailXML.ToString(), currentUser, dispositionId, eventLogId);
            }
        }
    }
}
