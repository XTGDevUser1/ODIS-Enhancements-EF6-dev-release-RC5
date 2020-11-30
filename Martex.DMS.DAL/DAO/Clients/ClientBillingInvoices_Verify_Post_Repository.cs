using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Data.Entity.Core.Objects;
using Martex.DMS.DAL.DMSBaseException;
using log4net;
using System.Data.Entity;

namespace Martex.DMS.DAO
{
    public partial class ClientRepository
    {

        protected static readonly ILog logger = LogManager.GetLogger(typeof(ClientRepository));
        /// <summary>
        /// Verifies the invoices.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <param name="currentUser">The current user.</param>
        /// <returns></returns>
        public List<VerifyBillingInvoices_Result> VerifyInvoices(List<int> invoices, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VerifyBillingInvoices(string.Join(",", invoices)).ToList<VerifyBillingInvoices_Result>();
            }
        }


        /// <summary>
        /// Gets the etl execution log unique identifier.
        /// </summary>
        /// <param name="description">The description.</param>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public int GetETLExecutionLogID(string description, string userName)
        {
            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                ObjectParameter logIDParam = new ObjectParameter("LogID", typeof(int));
                dbContext.CreateExecutionLog(description, userName, logIDParam);
                return (int)logIDParam.Value;
            }
        }

        private string LeftPadZeroes(string s, int maxLengthOfString)
        {
            if (string.IsNullOrEmpty(s))
            {
                s = string.Empty;
            }
            int numberOfZerosToPad = (maxLengthOfString - s.Length);
            string zeros = string.Empty;
            for (int i = 0, l = numberOfZerosToPad; i < l; i++)
            {
                zeros += "0";
            }

            return zeros + s;
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
            List<BillingInvoiceLine> billingInvoiceLines = null;
            BillingInvoice currentBillingInvoice = null;
            Batch batch = null;
            decimal? accountDivisionCodeForClient = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var bi = dbContext.BillingInvoices.Include(x=>x.BillingInvoiceLines).Include(x=>x.Client).Where(x => x.ID == invoiceID).FirstOrDefault();
                if (bi == null)
                {
                    throw new DMSException(string.Format("Billing Invoice ID {0} is invalid",invoiceID));
                }
                if (string.IsNullOrEmpty(bi.InvoiceNumber))
                {
                    NextNumber nextNumber = dbContext.NextNumbers.Where(u => u.Name.Equals("InvoiceNumber")).FirstOrDefault();
                    if (nextNumber == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve Configuration for {0}", "InvoiceNumber"));
                    }
                    nextNumber.Value = nextNumber.Value.GetValueOrDefault() + 1;

                    //TODO: Left pad zeros.
                    bi.InvoiceNumber = LeftPadZeroes(nextNumber.Value.GetValueOrDefault().ToString(), 6);
                    dbContext.SaveChanges();
                }

                currentBillingInvoice = bi;
                //TFS: 1174
                billingInvoiceLines = bi.BillingInvoiceLines.Where(x=>x.IsActive == true).ToList<BillingInvoiceLine>();
                batch = dbContext.Batches.Include("BatchType").Where(y => y.ID == billedBatchID).FirstOrDefault();
                accountDivisionCodeForClient = bi.Client.AccountingSystemDivisionCode;

            }

            string productName = null;
            Product product = null;
            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                billingInvoiceLines.ForEach(bil =>
                {
                    //TFS:342 - Several changes.
                    if (bil.LineAmount != null && bil.LineAmount != 0)
                    {
                        product = null;
                        productName = null;
                        product = ReferenceDataRepository.GetProductById(bil.ProductID);
                        if (product != null)
                        {
                            productName = product.Name;
                        }
                        InvoiceRequest ir = new InvoiceRequest()
                        {
                            AddDateTime = batchTimeStamp,
                            Division =  accountDivisionCodeForClient, //TFS : 694 - Get the code by Client. GetAccountDivisionNumber(batch),
                            CustomerNumber = ReplaceCommas(currentBillingInvoice.AccountingSystemCustomerNumber, " "),
                            InvoiceNumber = currentBillingInvoice.InvoiceNumber,
                            //OLD: InvoiceDate = currentBillingInvoice.InvoiceDate.HasValue ? currentBillingInvoice.InvoiceDate.Value.Date : (DateTime?)null,
                            //NEW: TFS 342
                            InvoiceDate = currentBillingInvoice.ScheduleRangeEnd.HasValue ? currentBillingInvoice.ScheduleRangeEnd.Value.Date : (DateTime?)null,
                            CustomerPONumber = Left(currentBillingInvoice.PONumber, 15),
                            //NP 02/07: Issue 2365 : Comment updated currentBillingInvoice.Name to bil.Name
                            //TFS : 455, undone TFS 342.
                            Comment = ReplaceCommas(Left(bil.Description, 30), " "),
                            //NEW: TFS 342 -> Reverted due to TFS 455
                            //Comment = ReplaceCommas(Left(productName, 30), " "),
                            ItemCode = bil.AccountingSystemItemCode,
                            LineAmount = bil.LineAmount,
                            AdditionalComment = ReplaceCommas(bil.Comment, " "),
                            AccountingSystemAddressCode = Left(currentBillingInvoice.AccountingSystemAddressCode, 4),
                            POPrefix = Left(currentBillingInvoice.POPrefix, 10),
                            BillingPeriodEndDate = currentBillingInvoice.ScheduleRangeEnd.HasValue ? currentBillingInvoice.ScheduleRangeEnd.Value.Date : (DateTime?)null,
                            InvoiceDescription = ReplaceCommas(currentBillingInvoice.Description, " "),
                            LineQuantity = bil.LineQuantity,
                            LineCost = bil.LineCost,
                            LineNumber = bil.Sequence,
                            ETL_Load_ID = batch.TransactionETLLoadID
                        };

                        dbContext.InvoiceRequests.Add(ir);
                        dbContext.SaveChanges();
                    }
                });
            }

        }

        public string ReplaceCommas(string s, string replacementString)
        {
            if (string.IsNullOrEmpty(s))
            {
                return s;
            }

            return s.Replace(",", replacementString);
        }

        /// <summary>
        /// Gets the account division number.
        /// </summary>
        /// <param name="batch">The batch.</param>
        /// <returns></returns>
        private decimal? GetAccountDivisionNumber(Batch batch)
        {
            if (batch != null && batch.BatchType != null && batch.BatchType.AccountingDivisionNumber != null)
            {
                string s = Left(batch.BatchType.AccountingDivisionNumber.ToString(), 2);
                return Convert.ToDecimal(s);
            }
            return null;
        }

        /// <summary>
        /// Get the first n characters from the left.
        /// </summary>
        /// <param name="s">The string</param>
        /// <param name="number">The number of characters to be extracted from the start.</param>
        /// <returns></returns>
        public string Left(string s, int number)
        {
            if (!string.IsNullOrEmpty(s) && s.Length > number)
            {
                return s.Substring(0, number);
            }
            else if (!string.IsNullOrEmpty(s) && s.Length <= number)
            {
                return s;
            }

            return s;
        }

        public List<InvoiceRequest> GetInvoiceRequestLines(long etlExecutionLogID)
        {
            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                var result = dbContext.InvoiceRequests.Where(a => a.ETL_Load_ID == etlExecutionLogID).ToList();
                return result;
            }
        }

        /// <summary>
        /// Updates the staging and execution log.
        /// </summary>
        /// <param name="etlExecutionLogId">The etl execution log unique identifier.</param>
        public void UpdateStagingAndExecutionLog(int etlExecutionLogId)
        {
            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                dbContext.UpdateStatusOnInvoiceRequest(etlExecutionLogId);
                dbContext.UpdateExecutionLogForBilling(etlExecutionLogId, 1);
            }
        }

        public void UpdateBatchDetailsOnInvoice(List<int> invoices, long billedBatchID, long unbilledBatchID, string currentUser, string eventSource, string eventName, string eventDetails, string entityName, string sessionID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                StringBuilder invoicesXML = new StringBuilder("<Invoices>");
                invoices.ForEach(i =>
                {
                    invoicesXML.AppendFormat("<ID>{0}</ID>", i);
                });
                invoicesXML.Append("</Invoices>");
                dbContext.TagInvoices(invoicesXML.ToString(), billedBatchID,unbilledBatchID, currentUser, eventSource, eventName, eventDetails, entityName, sessionID);
                dbContext.SaveChanges();


            }
        }
    }
}
