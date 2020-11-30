using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
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
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Facade
{

    public partial class VendorTemporaryCCProcessingFacade
    {
        public VendorCCStatusSummary VerifyVendorTempCC(List<int> tempcclist, string eventSource, string currentUser, string sessionID)
        {
            VendorCCStatusSummary summary = new VendorCCStatusSummary();

            TransactionOptions tranOptions = new TransactionOptions();
            tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
            tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
            {
                logger.InfoFormat("Verifying temp cc list - {0}", tempcclist.Count);
                // Verify invoices, process status and log exceptions.
                summary = repository.VerifyVendorTempCC(tempcclist, currentUser);

                // Log Events and links.
                var eventLoggerFacade = new EventLoggerFacade();
                eventLoggerFacade.LogEvent(eventSource, EventNames.MATCH_TEMP_CC, "Match Temporary Credit Card", currentUser, sessionID);
                logger.Info("Event logs created successfully");

                tran.Complete();
            }

            return summary;
        }

        public Dictionary<string, long> GetETLExecutionLogID(string description, string currentUser)
        {
            BatchRepository batchRepo = new BatchRepository();
            var batchID = batchRepo.Add(new DAL.Batch()
            {
                Description = "Temporary CC Post",
                TotalAmount = 0,
                TotalCount = 0,
                MasterETLLoadID = null,
                TransactionETLLoadID = null,
                CreateDate = DateTime.Now,
                CreateBy = currentUser,
                Direction = "Import"
            }, "TemporaryCCPost", "In-Progress");

            Dictionary<string, long> ids = new Dictionary<string, long>();
            ids.Add("BatchID", batchID);

            return ids;
        }

        public void CreateStagingDataForPost(int tempccId, long batchID, DateTime? batchTimeStamp, string currentUser)
        {
            repository.CreateStagingDataForPost(tempccId, batchID, batchTimeStamp, currentUser);
        }

        public VendorCCStatusSummary UpdateBatchInvoiceStatus(List<int> tempccInvoices, long batchID, string eventSource, string currentUser, string sessionID)
        {
            decimal totalInvoiceAmount = 0;
            totalInvoiceAmount = repository.UpdateBatchStatistics(batchID, "Success", tempccInvoices, currentUser, sessionID, eventSource);
            //2452 issue update gl account for all vendor invoices created for batchid
            repository.UpdateGLAccountForInvoices(batchID);
            return new VendorCCStatusSummary()
            {
                Posted = tempccInvoices.Count,
                PostedAmount = totalInvoiceAmount
            };
        }
    }
}
