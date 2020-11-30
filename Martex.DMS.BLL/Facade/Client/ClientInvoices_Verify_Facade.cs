using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Transactions;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using System.Runtime.InteropServices;
using System.Configuration;
using Martex.DMS.BLL.Common;
using System.Security.Principal;
using System.IO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    public partial class ClientsFacade
    {
        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

        protected ClientRepository repository = new ClientRepository();

        public List<VerifyBillingInvoices_Result> VerifyInvoices(List<int> invoices, string eventSource, string currentUser, string sessionID)
        {
            List<VerifyBillingInvoices_Result> summary = null;
            TransactionOptions tranOptions = new TransactionOptions();
            tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
            tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
            {
                logger.InfoFormat("Verifying Invoices - {0}", invoices.Count);
                // Verify invoices, process status and log exceptions.
                summary = repository.VerifyInvoices(invoices, currentUser);

                // Log Events and links.
                //var eventLoggerFacade = new EventLoggerFacade();
                //eventLoggerFacade.LogEvent(eventSource, EventNames.VERIFY_INVOICES, "Verify Invoices", currentUser, sessionID);
                //logger.Info("Event logs created successfully");

                tran.Complete();
            }

            return summary;

        }

        /// <summary>
        /// Gets the etl execution log unique identifier.
        /// </summary>
        /// <param name="description">The description.</param>
        /// <param name="currentUser">The current user.</param>
        /// <returns></returns>
        public Dictionary<string, long> GetETLExecutionLogID(string description, string currentUser)
        {
            var executionLogID = repository.GetETLExecutionLogID(description, currentUser);
            BatchRepository batchRepo = new BatchRepository();
            var billedBatchID = batchRepo.Add(new DAL.Batch()
            {
                Direction = "Export",
                Description = "Client Billing Export",
                TotalAmount = 0,
                TotalCount = 0,
                MasterETLLoadID = executionLogID,
                TransactionETLLoadID = executionLogID,
                CreateDate = DateTime.Now,
                CreateBy = currentUser
            }, "ClientBillingExport", "In-Progress");

            var unBilledBatchID = batchRepo.Add(new DAL.Batch()
            {
                Direction = "Export",
                Description = "Client Billing Unbilled",
                TotalAmount = 0,
                TotalCount = 0,
                MasterETLLoadID = executionLogID,
                TransactionETLLoadID = executionLogID,
                CreateDate = DateTime.Now,
                CreateBy = currentUser
            }, "ClientBillingUnbilled", "In-Progress");

            Dictionary<string, long> ids = new Dictionary<string, long>();
            ids.Add("ETLExecutionLogID", executionLogID);
            ids.Add("BilledBatchID", billedBatchID);
            ids.Add("UnbilledBatchID", unBilledBatchID);

            return ids;
        }

        /// <summary>
        /// Creates the staging data for invoice.
        /// </summary>
        /// <param name="invoiceID">The invoice unique identifier.</param>
        /// <param name="billedBatchID">The billed batch unique identifier.</param>
        /// <param name="unbilledBatchID">The unbilled batch unique identifier.</param>
        /// <param name="batchTimeStamp">The batch time stamp.</param>
        public void CreateStagingDataForInvoice(int invoiceID, long billedBatchID, long unbilledBatchID, DateTime? batchTimeStamp)
        {
            repository.CreateStagingDataForInvoice(invoiceID, billedBatchID, unbilledBatchID, batchTimeStamp);
        }

        public VendorInvoiceStatusSummary CreateExportFiles(List<int> invoices, long etlExecutionLogID, long billedBatchID, long unbilledBatchID, string eventSource, string currentUser, string sessionID)
        {
            // Get all the information required to create export files.
            var invoiceRequestLines = repository.GetInvoiceRequestLines(etlExecutionLogID);
            //TFS: 1754 - Do not copy the file to Export folder path.
            //string exportFolderPath = ConfigurationManager.AppSettings["MAS90ExportFilePath"];
            string archiveFolderPath = ConfigurationManager.AppSettings["MAS90ArchiveFilePath"];
            string reviewFolderPath = ConfigurationManager.AppSettings["AccountingReviewFilePath"];

            DateTime today = DateTime.Now;
            string customerSalesOrderFile = "CustomerSalesOrder.csv"; // string.Format("{0}_{1}_ISPVendorMaster.csv", today.ToString("yyyyMMdd"), etlExecutionLogID);
            

            string customerSalesOrderArchiveFile = string.Format("{0}_{1}_CustomerSalesOrder.csv", today.ToString("yyyyMMdd"), etlExecutionLogID);
            

            string userNameForDocuments = AppConfigRepository.GetValue(AppConfigConstants.EXPORTFILES_FOLDER_USERNAME);
            string passwordForDocuments = AppConfigRepository.GetValue(AppConfigConstants.EXPORTFILES_FOLDER_PASSWORD);
            logger.InfoFormat("Retireved UserName - {0}, and Password for Export folder", userNameForDocuments);

            string userName = string.Empty;
            string domain = string.Empty;
            string[] strTokens = userNameForDocuments.Split('\\');
            if (strTokens.Length > 1)
            {
                domain = strTokens[0];
                userName = strTokens[1];
            }
            else
            {
                userName = strTokens[0];
            }

            IntPtr token = IntPtr.Zero;
            LogonUser(userName,
                        domain,
                        passwordForDocuments,
                        9,
                        0,
                        ref token);
            using (WindowsImpersonationContext context = WindowsIdentity.Impersonate(token))
            {

                logger.InfoFormat("Creating Customer Sales Order file - {0} @ {1}", customerSalesOrderFile, reviewFolderPath);
                using (StreamWriter writer = new StreamWriter(Path.Combine(reviewFolderPath, customerSalesOrderFile)))
                {
                    invoiceRequestLines.ForEach(l =>
                        {
                            writer.WriteLine(string.Join(",", (l.Division == null ? string.Empty : l.Division.Value.ToString()),
                                                                (l.CustomerNumber ?? string.Empty),
                                                                (l.InvoiceNumber ?? string.Empty),
                                                                (l.InvoiceDate == null ? string.Empty : l.InvoiceDate.Value.ToString("M/d/yyyy")),
                                                                (l.InvoiceDueDate == null ? string.Empty : l.InvoiceDueDate.Value.ToString("M/d/yyyy")),
                                                                (l.TermsCode == null ? string.Empty : l.TermsCode.Value.ToString("F0")),
                                                                (l.CustomerPONumber ?? string.Empty),
                                                                (l.Comment ?? string.Empty),
                                                                (l.ItemCode ?? string.Empty),
                                                                (l.LineAmount == null ? string.Empty : l.LineAmount.Value.ToString("F2")),
                                                                (l.AdditionalComment ?? string.Empty),
                                                                (l.AccountingSystemAddressCode ?? string.Empty),
                                                                (l.POPrefix ?? string.Empty),
                                                                (l.BillingPeriodEndDate == null ? string.Empty : l.BillingPeriodEndDate.Value.ToString("M/d/yyyy")),
                                                                (l.InvoiceDescription ?? string.Empty),
                                                                (l.LineQuantity == null ? string.Empty : l.LineQuantity.Value.ToString("F0")),
                                                                (l.LineCost == null ? string.Empty : l.LineCost.Value.ToString("F2")),
                                                                (l.LineNumber == null ? string.Empty : l.LineNumber.Value.ToString("F0"))
                                                                )
                                            );
                        });

                    writer.Flush();
                    writer.Close();
                }
                logger.InfoFormat("Copying the files to the archive folder - {0}", archiveFolderPath);
                File.Copy(Path.Combine(reviewFolderPath, customerSalesOrderFile), Path.Combine(archiveFolderPath, customerSalesOrderArchiveFile), true);                
            }

            decimal totalInvoiceAmount = 0;
            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, new System.TimeSpan(0, 15, 0)))
            {
                // Update batch status
                logger.Info("Updating batch details and logging events for Invoices");
                repository.UpdateBatchDetailsOnInvoice(invoices, billedBatchID, unbilledBatchID, currentUser, eventSource, EventNames.POST_INVOICE, "Post Invoice", EntityNames.BILLING_INVOICE, sessionID);

                logger.Info("Setting batch statistics");
                BatchRepository batchRepository = new BatchRepository();
                totalInvoiceAmount = batchRepository.UpdateBatchStatistics(billedBatchID, "Success", invoices, currentUser, EntityNames.BILLING_INVOICE, unbilledBatchID);
                logger.Info("Processing completed.");
                tran.Complete();
            }

            logger.InfoFormat("Updating Staging tables");
            // Update ETL tables
            using (TransactionScope etlTran = new TransactionScope(TransactionScopeOption.Required, new System.TimeSpan(0, 15, 0)))
            {
                repository.UpdateStagingAndExecutionLog((int)etlExecutionLogID);
                etlTran.Complete();
            }
            logger.InfoFormat("Posted Count = {0}, Posted Amount = {1}", invoices.Count, totalInvoiceAmount);
            return new VendorInvoiceStatusSummary()
            {
                Paid = invoices.Count,
                PaidAmount = totalInvoiceAmount
            };
        }
    }
}
