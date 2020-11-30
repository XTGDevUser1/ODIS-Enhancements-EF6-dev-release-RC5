using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Transactions;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using System.Configuration;
using System.IO;
using Martex.DMS.BLL.Common;
using System.Security.Principal;
using System.Runtime.InteropServices;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorInvoiceFacade
    {

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

        /// <summary>
        /// Verifies the invoices.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session unique identifier.</param>
        /// <returns></returns>
        public VendorInvoiceStatusSummary VerifyInvoices(List<int> invoices, string eventSource, string currentUser, string sessionID, bool includeValidationsForPayment = false)
        {
            VendorInvoiceStatusSummary summary = new VendorInvoiceStatusSummary();
            TransactionOptions tranOptions = new TransactionOptions();
            tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
            tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
            {
                logger.InfoFormat("Verifying Invoices - {0}", invoices.Count);
                // Verify invoices, process status and log exceptions.
                summary = repository.VerifyInvoices(invoices, currentUser, includeValidationsForPayment);

                // Log Events and links.
                var eventLoggerFacade = new EventLoggerFacade();
                eventLoggerFacade.LogEvent(eventSource, EventNames.VERIFY_INVOICES, "Verify Invoices", currentUser, sessionID);
                logger.Info("Event logs created successfully");

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
            var batchID = batchRepo.Add(new DAL.Batch()
            {
                Direction = "Export",
                Description = "Vendor Invoice Export",
                TotalAmount = 0,
                TotalCount = 0,
                MasterETLLoadID = executionLogID,
                TransactionETLLoadID = executionLogID,
                CreateDate = DateTime.Now,
                CreateBy = currentUser
            }, "VendorInvoiceExport", "In-Progress");

            Dictionary<string, long> ids = new Dictionary<string, long>();
            ids.Add("ETLExecutionLogID", executionLogID);
            ids.Add("BatchID", batchID);

            return ids;
        }

        /// <summary>
        /// Creates the staging data for invoice.
        /// </summary>
        /// <param name="invoiceID">The invoice unique identifier.</param>
        /// <param name="batchID">The batch unique identifier.</param>
        /// <param name="batchTimeStamp">The batch time stamp.</param>
        public void CreateStagingDataForInvoice(int invoiceID, long batchID, DateTime? batchTimeStamp)
        {
            repository.CreateStagingDataForInvoice(invoiceID, batchID, batchTimeStamp);
        }

        /// <summary>
        /// Creates the export files.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <param name="etlExecutionLogID">The etl execution log unique identifier.</param>
        /// <param name="batchID">The batch unique identifier.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session unique identifier.</param>
        public VendorInvoiceStatusSummary CreateExportFiles(List<int> invoices, long etlExecutionLogID, long batchID, string eventSource, string currentUser, string sessionID)
        {
            // Get all the information required to create export files.
            var vendorMasterLines = repository.GetVendorMasterLines(etlExecutionLogID);
            var checkRequestLines = repository.GetCheckRequestLines(etlExecutionLogID);

            string exportFolderPath = ConfigurationManager.AppSettings["MAS90ExportFilePath"];
            string archiveFolderPath = ConfigurationManager.AppSettings["MAS90ArchiveFilePath"];
            string reviewFolderPath = ConfigurationManager.AppSettings["AccountingReviewFilePath"];

            DateTime today = DateTime.Now;

            string vendorMasterFile_CNET = "ISPVendorMaster_Coach-Net.csv";
            string checkRequestFile_CNET = "ISPCheckRequest_Coach-Net.csv";


            string vendorMasterArchiveFile_CNET = string.Format("{0}_{1}_ISPVendorMaster_Coach-Net.csv", today.ToString("yyyyMMdd"), etlExecutionLogID);
            string checkRequestArchiveFile_CNET = string.Format("{0}_{1}_ISPCheckRequest_Coach-Net.csv", today.ToString("yyyyMMdd"), etlExecutionLogID);

            string userNameForDocuments = AppConfigRepository.GetValue(AppConfigConstants.EXPORTFILES_FOLDER_USERNAME);
            string passwordForDocuments = AppConfigRepository.GetValue(AppConfigConstants.EXPORTFILES_FOLDER_PASSWORD);
            logger.InfoFormat("Retrieved UserName - {0}, and Password for Export folder", userNameForDocuments);

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

                logger.InfoFormat("Creating VendorMaster file - {0} @ {1}", vendorMasterFile_CNET, exportFolderPath);
                using (StreamWriter writer = new StreamWriter(Path.Combine(exportFolderPath, vendorMasterFile_CNET)))
                {
                    vendorMasterLines.ForEach(l =>
                        {
                            writer.WriteLine(string.Join(",", (l.Division == null ? string.Empty : l.Division.Value.ToString()),
                                                                (l.VendorNumber ?? string.Empty),
                                                                (l.VendorName ?? string.Empty),
                                                                (l.AddressLine1 ?? string.Empty),
                                                                (l.AddressLine2 ?? string.Empty),
                                                                (l.AddressLine3 ?? string.Empty),
                                                                (l.City ?? string.Empty),
                                                                (l.State ?? string.Empty),
                                                                (l.ZipCode ?? string.Empty),
                                                                (l.PhoneNumber ?? string.Empty),
                                                                (l.VendorRef ?? string.Empty),
                                                                (l.MasterFileComment ?? string.Empty),
                                                                (l.SSN ?? string.Empty),
                                                                (l.Fax ?? string.Empty),
                                                                (l.EmailAddress ?? string.Empty),
                                                                (l.ISRNumber ?? string.Empty),
                                                                (l.ContractType ?? string.Empty),
                                                                (l.BankAccountNumber ?? string.Empty),
                                                                (l.BankTransitNumber ?? string.Empty),
                                                                (l.BankAccountType ?? string.Empty),
                                                                (l.CountryCode ?? string.Empty)
                                                                )
                                            );
                        });

                    writer.Flush();
                    writer.Close();
                }

                logger.InfoFormat("Created Vendor Master files for Coach-Net");

                logger.InfoFormat("Creating CheckRequest file - {0} @ {1}", checkRequestFile_CNET, exportFolderPath);


                CreateCheckRequestFile(Path.Combine(exportFolderPath, checkRequestFile_CNET), checkRequestLines);

                logger.InfoFormat("Copying the files to the archive folder - {0}", archiveFolderPath);

                File.Copy(Path.Combine(exportFolderPath, vendorMasterFile_CNET), Path.Combine(archiveFolderPath, vendorMasterArchiveFile_CNET), true);
                File.Copy(Path.Combine(exportFolderPath, checkRequestFile_CNET), Path.Combine(archiveFolderPath, checkRequestArchiveFile_CNET), true);


                // Copy the files to Review folder too. - TFS 1750

                File.Copy(Path.Combine(exportFolderPath, vendorMasterFile_CNET), Path.Combine(reviewFolderPath, vendorMasterArchiveFile_CNET), true);
                File.Copy(Path.Combine(exportFolderPath, checkRequestFile_CNET), Path.Combine(reviewFolderPath, checkRequestArchiveFile_CNET), true);

            }
            // Update invoices with the status.
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            decimal totalInvoiceAmount = 0;
            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, new System.TimeSpan(0, 15, 0)))
            {
                // Update batch status
                logger.Info("Updating batch details and logging events for Invoices");
                repository.UpdateBatchDetailsOnInvoice(invoices, batchID, currentUser, eventSource, EventNames.PAY_INVOICES, "Pay Invoices", EntityNames.VENDOR_INVOICE, sessionID);

                logger.Info("Setting batch statistics");
                BatchRepository batchRepository = new BatchRepository();
                totalInvoiceAmount = batchRepository.UpdateBatchStatistics(batchID, "Success", invoices, currentUser, EntityNames.VENDOR_INVOICE);
                logger.Info("Processing completed.");
                tran.Complete();
            }

            logger.InfoFormat("Updating Staging tables");
            // Update ETL tables
            using (TransactionScope etlTran = new TransactionScope())
            {
                repository.UpdateStagingAndExecutionLog((int)etlExecutionLogID);
                etlTran.Complete();
            }

            return new VendorInvoiceStatusSummary()
            {
                Paid = invoices.Count,
                PaidAmount = totalInvoiceAmount
            };

        }

        private void CreateCheckRequestFile(string filePath, List<DAL.APCheckRequest> checkRequestLines)
        {
            using (StreamWriter writer = new StreamWriter(filePath))
            {
                checkRequestLines.ForEach(l =>
                {
                    writer.WriteLine(string.Join(",", (l.Division == null ? string.Empty : l.Division.Value.ToString()),
                                                            (l.VendorNumber ?? string.Empty),
                                                            (l.InvoiceNumber ?? string.Empty),
                                                            (l.InvoiceDate == null ? string.Empty : l.InvoiceDate.Value.ToString("M/d/yyyy")),
                                                            (l.InvoiceDueDate == null ? string.Empty : l.InvoiceDueDate.Value.ToString("M/d/yyyy")),
                                                            (l.Comment ?? string.Empty),
                                                            (l.SeparateCheck ?? string.Empty),
                                                            (l.InvoiceAmount == null ? string.Empty : l.InvoiceAmount.GetValueOrDefault().ToString("F2")),
                                                            (l.GLExpenseAccount ?? string.Empty),
                                                            (l.ExpenseAmount == null ? string.Empty : l.ExpenseAmount.GetValueOrDefault().ToString("F2")),
                                                            (l.AdditionalComment ?? string.Empty),
                                                            (l.PaymentMethod ?? string.Empty),
                                                            (l.DocumentNoteID == null ? string.Empty : l.DocumentNoteID.GetValueOrDefault().ToString()),
                                                            (l.PONumber ?? string.Empty),
                                                            (l.POIssuedDate == null ? string.Empty : l.POIssuedDate.Value.ToString("M/d/yyyy")),
                                                            (l.VendorInvoiceNumber ?? string.Empty),
                                                            (l.ReceivedDate == null ? string.Empty : l.ReceivedDate.Value.ToString("M/d/yyyy")),
                                                            (l.VendorRepContactName ?? string.Empty),
                                                            (l.VendorRepContactPhoneNumber ?? string.Empty),
                                                            (l.VendorRepContactEmail ?? string.Empty),
                                                            (l.ProgramName ?? string.Empty),
                                                            (l.ProgramRefNumber ?? string.Empty),
                                                            (l.RegionNumber ?? string.Empty),
                                                            (l.DivisionNumber ?? string.Empty),
                                                            (l.DistrictNumber ?? string.Empty),
                                                            (l.Leader == null ? string.Empty : l.Leader.GetValueOrDefault().ToString()),
                                                            (l.Bulletin == null ? string.Empty : l.Bulletin.GetValueOrDefault().ToString()),
                                                            (l.ContractedDate == null ? string.Empty : l.ContractedDate.Value.ToString("M/d/yyyy")),
                                                            (l.CancelledDate == null ? string.Empty : l.CancelledDate.Value.ToString("M/d/yyyy")),

                                                            (l.BegDebitBalance == null ? string.Empty : l.BegDebitBalance.GetValueOrDefault().ToString("F2")),
                                                            (l.FirstyearCommissions == null ? string.Empty : l.FirstyearCommissions.GetValueOrDefault().ToString("F2")),
                                                            (l.Renewals == null ? string.Empty : l.Renewals.GetValueOrDefault().ToString("F2")),
                                                            (l.Comissions == null ? string.Empty : l.Comissions.GetValueOrDefault().ToString("F2")),
                                                            (l.Advances == null ? string.Empty : l.Advances.GetValueOrDefault().ToString("F2")),
                                                            (l.Backend == null ? string.Empty : l.Backend.GetValueOrDefault().ToString("F2")),
                                                            (l.ServiceCharge == null ? string.Empty : l.ServiceCharge.GetValueOrDefault().ToString("F2")),
                                                            (l.Other == null ? string.Empty : l.Other.GetValueOrDefault().ToString("F2")),
                                                            (l.TotalCharges == null ? string.Empty : l.TotalCharges.GetValueOrDefault().ToString("F2")),
                                                            (l.EndDebitBalance == null ? string.Empty : l.EndDebitBalance.GetValueOrDefault().ToString("F2")),
                                                            (l.EstRemainFirstYear == null ? string.Empty : l.EstRemainFirstYear.GetValueOrDefault().ToString("F2")),
                                                            (l.QualityRatioPct == null ? string.Empty : l.QualityRatioPct.GetValueOrDefault().ToString("F2")),
                                                            (l.SilverRenewalQaulifier == null ? string.Empty : l.SilverRenewalQaulifier.GetValueOrDefault().ToString("F2")),
                                                            (l.EarnedCommYTD == null ? string.Empty : l.EarnedCommYTD.GetValueOrDefault().ToString("F2")),
                                                            (l.AdvancesYTD == null ? string.Empty : l.AdvancesYTD.GetValueOrDefault().ToString("F2")),
                                                            (l.SilverRenewalText ?? string.Empty),
                                                            (l.QCQYTD == null ? string.Empty : l.QCQYTD.GetValueOrDefault().ToString("F2")),
                                                            (l.AdvancesQualityYTD == null ? string.Empty : l.AdvancesQualityYTD.GetValueOrDefault().ToString("F2")),
                                                            (l.PersonalMembershipCount == null ? string.Empty : l.PersonalMembershipCount.GetValueOrDefault().ToString()),
                                                            (l.PersonalMemberCount == null ? string.Empty : l.PersonalMemberCount.GetValueOrDefault().ToString()),
                                                            (l.PersonalNBAV == null ? string.Empty : l.PersonalNBAV.GetValueOrDefault().ToString("F2")),
                                                            (l.PersonalBonus == null ? string.Empty : l.PersonalBonus.GetValueOrDefault().ToString("F2")),
                                                            (l.OverrideMembershipCount == null ? string.Empty : l.OverrideMembershipCount.GetValueOrDefault().ToString()),
                                                            (l.OverrideMemberCount == null ? string.Empty : l.OverrideMemberCount.GetValueOrDefault().ToString()),
                                                            (l.OverrideNBAV == null ? string.Empty : l.OverrideNBAV.GetValueOrDefault().ToString("F2")),
                                                            (l.OverrideAdvance == null ? string.Empty : l.OverrideAdvance.GetValueOrDefault().ToString("F2")),
                                                            (l.OverrideBonus == null ? string.Empty : l.OverrideBonus.GetValueOrDefault().ToString("F2")),
                                                            (l.TIPS == null ? string.Empty : l.TIPS.GetValueOrDefault().ToString("F2")),
                                                            (l.Multiplier == null ? string.Empty : l.Multiplier.GetValueOrDefault().ToString("F2")),
                                                            (l.AdjustmentAmount == null ? string.Empty : l.AdjustmentAmount.GetValueOrDefault().ToString("F2")),
                                                            (l.ContractType ?? string.Empty),
                                                            (l.PersonalOverrideAdvance == null ? string.Empty : l.PersonalOverrideAdvance.GetValueOrDefault().ToString("F2")),
                                                            (l.DetailItem1Date == null ? string.Empty : l.DetailItem1Date.Value.ToString("M/d/yyyy")),
                                                            (l.DetailItem1Number ?? string.Empty),
                                                            (l.DetailItem1Description ?? string.Empty),
                                                            (l.DetailItem1Amount == null ? string.Empty : l.DetailItem1Amount.GetValueOrDefault().ToString("F2")),

                                                            (l.DetailItem2Date == null ? string.Empty : l.DetailItem2Date.Value.ToString("M/d/yyyy")),
                                                            (l.DetailItem2Number ?? string.Empty),
                                                            (l.DetailItem2Description ?? string.Empty),
                                                            (l.DetailItem2Amount == null ? string.Empty : l.DetailItem2Amount.GetValueOrDefault().ToString("F2")),

                                                            (l.DetailItem3Date == null ? string.Empty : l.DetailItem3Date.Value.ToString("M/d/yyyy")),
                                                            (l.DetailItem3Number ?? string.Empty),
                                                            (l.DetailItem3Description ?? string.Empty),
                                                            (l.DetailItem3Amount == null ? string.Empty : l.DetailItem3Amount.GetValueOrDefault().ToString("F2")),

                                                            (l.DetailItem4Date == null ? string.Empty : l.DetailItem4Date.Value.ToString("M/d/yyyy")),
                                                            (l.DetailItem4Number ?? string.Empty),
                                                            (l.DetailItem4Description ?? string.Empty),
                                                            (l.DetailItem4Amount == null ? string.Empty : l.DetailItem4Amount.GetValueOrDefault().ToString("F2")),

                                                            (l.DetailItem5Date == null ? string.Empty : l.DetailItem5Date.Value.ToString("M/d/yyyy")),
                                                            (l.DetailItem5Number ?? string.Empty),
                                                            (l.DetailItem5Description ?? string.Empty),
                                                            (l.DetailItem5Amount == null ? string.Empty : l.DetailItem5Amount.GetValueOrDefault().ToString("F2")),

                                                            (l.ClientName ?? string.Empty),
                                                            (l.ClientAddress1 ?? string.Empty),
                                                            (l.ClientAddress2 ?? string.Empty),
                                                            (l.ClientCity ?? string.Empty),
                                                            (l.ClientState ?? string.Empty),
                                                            (l.ClientZip ?? string.Empty)
                                                            )
                                                );
                });
            }
        }
    }
}
