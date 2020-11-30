using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.Models;
using Martex.DMS.BLL.Model.Clients;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public partial class ClientsFacade
    {
        /// <summary>
        /// Gets the billing manage invoices list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<BillingManageInvoicesList_Result> GetBillingManageInvoicesList(PageCriteria pc, string pageMode)
        {
            return clientRepository.GetBillingManageInvoicesList(pc, pageMode);
        }

        public List<BillingInvoiceLinesList_Result> GetBillingInvoiceLinesList(PageCriteria pc, int? billingInvoiceID)
        {
            return clientRepository.GetBillingInvoiceLinesList(pc, billingInvoiceID);
        }

        public void InsertVendorInvoiceLine(BillingInvoiceLinesList_Result invoiceLine, string currentUser, int billingInvoiceID, string pageReference, string sessionID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                RateType rateType = clientRepository.GetRateType(RateTypeNames.Manual);
                Product product = clientRepository.GetProduct(invoiceLine.ProductID);
                BillingInvoiceLineStatu invoiceLineStatus = clientRepository.GetBillingInvoiceLineStatus("Ready");

                #region 1. Insert Billing Invoice Line
                BillingInvoiceLine bil = new BillingInvoiceLine();
                bil.BillingInvoiceID = billingInvoiceID;
                bil.ProductID = invoiceLine.ProductID;
                bil.RateTypeID = rateType.ID;
                bil.Name = invoiceLine.Name;
                bil.Description = invoiceLine.Description;
                bil.Comment = invoiceLine.Comment;
                // NP 01/20: Commented to solve the issue when inserting an invoice line, because there is no product was being selected by the user.
                //bil.AccountingSystemGLCode = product.AccountingSystemGLCode;
                //bil.AccountingSystemItemCode = product.AccountingSystemItemCode;
                bil.Sequence = invoiceLine.Sequence;
                bil.LineQuantity = invoiceLine.LineQuantity;
                bil.LineAmount = invoiceLine.LineAmount;
                bil.LineCost = invoiceLine.LineCost;
                bil.InvoiceLineStatusID = invoiceLineStatus.ID;
                bil.IsActive = true;
                clientRepository.SaveBillingInvoiceLine(bil, currentUser);
                #endregion

                #region 2 .Insert EventLog
                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                string eventDetails = BuildXMLVersionForInvoiceLineData(invoiceLine);
                long eventID = eventLoggerFacade.LogEvent(pageReference, EventNames.ADD_INVOICE_LINE, eventDetails, currentUser, sessionID);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, billingInvoiceID, EntityNames.BILLING_INVOICE);
                #endregion
                tran.Complete();
            }
        }

        public void DeleteVendorInvoiceLine(BillingInvoiceLinesList_Result invoiceLine, string currentUser, int billingInvoiceID, string pageReference, string sessionID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                #region 1. Insert Billing Invoice Line
                clientRepository.DeleteBillingInvoiceLine(invoiceLine, currentUser);
                #endregion
                #region 2 .Insert EventLog
                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                string eventDetails = BuildXMLVersionForInvoiceLineData(invoiceLine);
                long eventID = eventLoggerFacade.LogEvent(pageReference, EventNames.DELETE_INVOICE_LINE, eventDetails, currentUser, sessionID);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, billingInvoiceID, EntityNames.BILLING_INVOICE);
                #endregion
                tran.Complete();
            }
        }

        private string BuildXMLVersionForInvoiceLineData(BillingInvoiceLinesList_Result invoiceLine)
        {   
            Dictionary<string, string> dictionary = new Dictionary<string, string>();
            dictionary.Add("ID", invoiceLine.ID.ToString());
            dictionary.Add("ProductID", invoiceLine.ProductID.GetValueOrDefault().ToString());
            dictionary.Add("Name", invoiceLine.Name.BlankIfNull());
            dictionary.Add("Description", invoiceLine.Description.BlankIfNull());
            dictionary.Add("Comment", invoiceLine.Comment.BlankIfNull());
            dictionary.Add("LineQuantity", invoiceLine.LineQuantity.GetValueOrDefault().ToString());
            dictionary.Add("LineCost", invoiceLine.LineCost.GetValueOrDefault().ToString());
            dictionary.Add("LineAmount", invoiceLine.LineAmount.GetValueOrDefault().ToString());
            return dictionary.GetXml();            
        }

        public void RefreshBillingInvoice(int? billingDefinitionInvoiceID, int? scheduleTypeID, int? scheduleDateTypeID, int? scheduleRangeTypeID, string currentUser, string sessionID, string pageReference)
        {
            TransactionOptions tranOptions = new TransactionOptions();
            tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
            tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
            {
                #region 1. Refresh Billing Invoice
                string invoiceXML = "<Records><BillingDefinitionInvoiceID>" + billingDefinitionInvoiceID + "</BillingDefinitionInvoiceID></Records>";
                bool? refreshDetail = true;
                try
                {
                    clientRepository.RefreshBillingInvoice(invoiceXML, scheduleTypeID, scheduleDateTypeID, scheduleRangeTypeID, currentUser, refreshDetail);
                }
                catch (Exception ex)
                {
                    throw new DMSException("Error occured while Refreshing the Record.", ex);
                }

                #endregion
                #region 2 .Insert EventLog
                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                //string eventDetails =
                long eventID = eventLoggerFacade.LogEvent(pageReference, EventNames.REFRESH_INVOICE_DETAILS, "Refresh Invoice Details", currentUser, sessionID);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, billingDefinitionInvoiceID, EntityNames.INVOICE);
                #endregion
                tran.Complete();
            }
        }

        public void RefreshAllBillingInvoices(string currentUser, string sessionID, string pageReference)
        {
            TransactionOptions tranOptions = new TransactionOptions();
            tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
            tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
            {
                #region 1. Refresh All Billing Invoices
                bool? refreshDetail = true;
                try
                {
                    clientRepository.RefreshBillingInvoice(null, null, null, null, currentUser, refreshDetail);
                }
                catch (Exception ex)
                {
                    throw new DMSException("Error occured while Refreshing the Records.", ex);
                }
                #endregion
                tran.Complete();
            }
        }

        public List<ClientInvoiceEventProcessingList_Result> GetClientInvoiceEventProcessingList(PageCriteria pc, int? billingInvoiceLineID)
        {
            return clientRepository.GetClientInvoiceEventProcessingList(pc, billingInvoiceLineID.GetValueOrDefault());
        }

        public void UpdateSelectedBillingEventDetailStatus(int ToStatus, int[] ElementsToBeUpadted, string FromStatusText, string ToStatusText, string currentUser, string sessionID, string source)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                EventLoggerFacade eventFacade = new EventLoggerFacade();
                long eventID = eventFacade.LogEvent(source, EventNames.UPDATE_BILLING_EVENT_STATUS, "Update Billing Event Status", currentUser, sessionID);
                clientRepository.UpdateSelectedBillingEventDetailStatus(ElementsToBeUpadted, ToStatus, currentUser, Convert.ToInt32(eventID));
                tran.Complete();
            }
        }

        public void UpdateSelectedBillingEventDetailDisposition(int ToDisposition, int[] ElementsToBeUpadted, string FromDispositionText, string ToDispositionText, string currentUser, string sessionID, string source)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                EventLoggerFacade eventFacade = new EventLoggerFacade();
                long eventID = eventFacade.LogEvent(source, EventNames.UPDATE_BILLING_EVENT_DISPOSITION, "Update Billing Event Disposition", currentUser, sessionID);
                clientRepository.UpdateSelectedBillingEventDetailDisposition(ElementsToBeUpadted, Convert.ToInt32(eventID), currentUser, ToDisposition);
                tran.Complete();
            }
        }
    }
}
