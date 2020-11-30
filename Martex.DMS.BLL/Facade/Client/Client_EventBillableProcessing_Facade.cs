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
using Martex.DMS.DAL.Entities.Clients;
using Martex.DMS.DAL.DAO.Clients;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public partial class ClientsFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ClientsFacade));
        #endregion

        protected ClientRepository clientRepository = new ClientRepository();

        /// <summary>
        /// Gets the client billable event processing list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ClientBillableEventProcessingList_Result> GetClientBillableEventProcessingList(PageCriteria pc, string invoiceStatus)
        {
            return clientRepository.GetClientBillableEventProcessingList(pc,invoiceStatus);
        }

        /// <summary>
        /// Gets the billing invoice detail.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        public BillingDetailMaintenanceModel GetBillingInvoiceDetail(int recordID)
        {
            BillingDetailMaintenanceModel model = new BillingDetailMaintenanceModel();
            var lookUp = new CommonLookUpRepository();

            model.BillingInvoiceDetails = clientRepository.GetBillingInvoiceDetail(recordID);
            model.Exceptions = clientRepository.GetBillingInvoiceDetailException(recordID);

            if (model.BillingInvoiceDetails == null)
            {
                throw new DMSException(string.Format("Unable to retrireve Details for the Given Record ID {0}", recordID));
            }
            return model;
        }

        /// <summary>
        /// Saves the client billable event processing details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void SaveClientBillableEventProcessingDetails(ClientBillableEventProcessingDetailsModel model, string userName, string sessionID)
        {
            ClientBillableEventProcessingDetails_Result result = clientRepository.GetBillingInvoiceDetail(model.BillingInvoiceDetailID);

            using (TransactionScope transaction = new TransactionScope())
            {
                logger.InfoFormat("Trying to Update Client Billable Event Processing Details for the Record ID {0}", model.BillingInvoiceDetailID);
                clientRepository.SaveClientBillableEventProcessingDetails(model, userName);
                logger.Info("Record Updated Successfully");

                #region Event Log
                logger.Info("Trying to Create Event Log and Event Log Link");
                string data = string.Format("<MessageData><Before>{0}</Before><After>{1}</After></MessageData>", result.DetailsStatusID, model.InvoiceDetailStatusID);
                EventLogRepository eventRepo = new EventLogRepository();
                var lookUp = new CommonLookUpRepository();
                Event theEvent = lookUp.GetEvent(EventNames.UPDATE_BILLING_INVOICE_DETAIL);
                EventLog eventLog = new EventLog()
                {
                    EventID = theEvent.ID,
                    SessionID = sessionID,
                    Source = "BillingInvoiceDetail",
                    Description = "",
                    Data = data,
                    NotificationQueueDate = null,
                    CreateBy = userName,
                    CreateDate = DateTime.Now
                };
                logger.InfoFormat("Trying to log the event {0}", EventNames.UPDATE_BILLING_INVOICE_DETAIL);
                eventRepo.Add(eventLog, model.BillingInvoiceDetailID,EntityNames.BILLING_INVOICE);
                logger.Info("Event Log Created");
                #endregion
             
                transaction.Complete();
            }
        }
    }
}
