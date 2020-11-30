using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities.Clients;
using Martex.DMS.DAL.DAO.Clients;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// Client Repository
    /// </summary>
    public partial class ClientRepository
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="billingScheduleListCommaSeparated"></param>
        /// <param name="userName"></param>
        public void ProcessClientClosePeriodList(string billingScheduleListCommaSeparated, string userName, string sessionID, string pageReference)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ProcessClientClosePeriod(billingScheduleListCommaSeparated, userName, sessionID, pageReference);
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="billingScheduleListCommaSeparated"></param>
        /// <param name="userName"></param>
        /// <param name="sessionID"></param>
        /// <param name="pageReference"></param>
        public void ProcessClientOpenPeriodList(int billingDefinitionInvoiceID, int billingScheduleID, int billingScheduleTypeID, int billingScheduleDateTypeID, int billingScheduleRangeTypeID, string userName, string sessionID, string pageReference)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 900;
                dbContext.ProcessClientOpenPeriod(billingDefinitionInvoiceID, billingScheduleID, billingScheduleTypeID, billingScheduleDateTypeID, billingScheduleRangeTypeID, userName, sessionID, pageReference);
            }
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="userName"></param>
        /// <param name="sessionID"></param>
        /// <param name="pageReference"></param>
        /// <param name="billingScheduleIDList"></param>
        /// <param name="billingDefinitionInvoiceIdList"></param>
        public void CreateClientOpenPeriodProcessEventLogs(string userName, string sessionID, string pageReference,string billingScheduleIDList,string billingDefinitionInvoiceIdList)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 900;
                dbContext.CreateClientOpenPeriodProcessEventLogs(userName, sessionID, pageReference, billingScheduleIDList, billingDefinitionInvoiceIdList);
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="billingScheduleListCommaSeparated"></param>
        /// <returns></returns>
        public List<ClientOpenPeriodToBeProcessRecords_Result> GetClientOpenPeriodToBeProcessRecords(string billingScheduleListCommaSeparated)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientOpenPeriodToBeProcessRecords(billingScheduleListCommaSeparated).ToList();
            }
        }




        /// <summary>
        /// 
        /// </summary>
        /// <param name="pc"></param>
        /// <returns></returns>
        public List<ClientClosePeriodList_Result> GetClientInvoiceClosePeriods(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientClosePeriodList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="pc"></param>
        /// <returns></returns>
        public List<ClientOpenPeriodList_Result> GetClientInvoiceOpenPeriodList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientOpenPeriodList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList();
            }
        }

        /// <summary>
        /// Gets the client billable event processing list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ClientBillableEventProcessingList_Result> GetClientBillableEventProcessingList(PageCriteria pc, string invoiceStatus)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientBillableEventProcessingList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, string.IsNullOrEmpty(invoiceStatus) ? null : invoiceStatus).ToList<ClientBillableEventProcessingList_Result>();
            }
        }

        /// <summary>
        /// Gets the billing invoice detail.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        public ClientBillableEventProcessingDetails_Result GetBillingInvoiceDetail(int recordID)
        {
            ClientBillableEventProcessingDetails_Result model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.GetClientBillableEventProcessingDetails(recordID).ToList().FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the billing invoice detail exception.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        public List<ClientBillableEventProcessingExceptions_Result> GetBillingInvoiceDetailException(int recordID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientBillableEventProcessingExceptions(recordID).ToList();
            }
        }

        /// <summary>
        /// Saves the client billable event processing details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="DMSException"></exception>
        public void SaveClientBillableEventProcessingDetails(ClientBillableEventProcessingDetailsModel model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.BillingInvoiceDetails.Where(u => u.ID == model.BillingInvoiceDetailID).FirstOrDefault();
                if (existingRecord == null)
                {
                    throw new DMSException(string.Format("Unable to Retrieve Billing Invoice Details for the ID {0}", model.BillingInvoiceDetailID));
                }

                if (model.IsAdjusted)
                {
                    existingRecord.AdjustedBy = userName;
                    existingRecord.AdjustmentDate = DateTime.Now;
                    existingRecord.AdjustmentReasonID = model.AdjustmentReasonID;
                    existingRecord.AdjustmentReasonOther = model.AdjustmentReasonOther;
                    existingRecord.AdjustmentComment = model.AdjustmentComment;
                    existingRecord.AdjustmentAmount = model.AdjustmentAmount;
                }
                else
                {
                    existingRecord.AdjustedBy = null;
                    existingRecord.AdjustmentDate = null;
                    existingRecord.AdjustmentAmount = null;
                    existingRecord.AdjustmentReasonOther = null;
                    existingRecord.AdjustmentReasonID = null;
                    existingRecord.AdjustmentComment = null;
                }

                if (model.IsExcluded)
                {
                    BillingInvoiceDetailStatu status = dbContext.BillingInvoiceDetailStatus.Where(u => u.Name.Equals("EXCLUDED", StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                    if (status == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve Details for Billing InvoiceDetail Status {0}", "EXCLUDED"));
                    }
                    existingRecord.ExcludedBy = userName;
                    existingRecord.ExcludeDate = DateTime.Now;
                    existingRecord.ExcludeComment = model.ExcludeComment;
                    existingRecord.ExcludeReasonID = model.ExcludeReasonID;
                    existingRecord.ExcludeReasonOther = model.ExcludeReasonOther;
                    model.InvoiceDetailStatusID = status.ID;
                }
                else
                {
                    existingRecord.ExcludedBy = null;
                    existingRecord.ExcludeDate = null;
                    existingRecord.ExcludeComment = null;
                    existingRecord.ExcludeReasonID = null;
                    existingRecord.ExcludeReasonOther = null;
                }

                existingRecord.InvoiceDetailDispositionID = model.BillingDispositionStatusID;
                existingRecord.InvoiceDetailStatusID = model.InvoiceDetailStatusID;
                existingRecord.IsExcluded = model.IsExcluded;
                existingRecord.IsAdjusted = model.IsAdjusted;
                if (existingRecord.IsEdited == null || existingRecord.IsEdited == false)
                {
                    if (model.Quantity != null && model.EventAmount != null && (existingRecord.Quantity != model.Quantity || existingRecord.EventAmount != model.EventAmount))
                    {
                        existingRecord.IsEdited = true;
                    }
                }
                existingRecord.Quantity = model.Quantity;
                existingRecord.EventAmount = model.EventAmount;
                existingRecord.InternalComment = model.InternalComment;
                existingRecord.ClientNote = model.ClientNote;

                existingRecord.ModifyBy = userName;
                existingRecord.ModifyDate = DateTime.Now;
                dbContext.SaveChanges();
            }
        }
    }
}
