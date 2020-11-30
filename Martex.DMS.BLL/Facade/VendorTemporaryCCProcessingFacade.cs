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
using Martex.DMS.BLL.Model.TempCCPModels;
using System.Data;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorTemporaryCCProcessingFacade
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorTemporaryCCProcessingFacade));
        VendorTemporaryCCProcessingRepository repository = new VendorTemporaryCCProcessingRepository();

        public List<VendorCCProcessingList_Result> GetVendorCCProcessingList(PageCriteria pc)
        {
            return repository.GetVendorCCProcessingList(pc);
        }

        public List<VendorCCProcessingDetailList_Result> GetVendorCCProcessingDetailList(PageCriteria pc, int? temporaryCCID)
        {
            return repository.GetVendorCCProcessingDetailList(pc, temporaryCCID);
        }

        public TemporaryCCCardDetails_Result GetTemporaryCCCardDetails(int? temporaryCCID)
        {
            return repository.GetTemporaryCCCardDetails(temporaryCCID);
        }

        public void SaveTemporaryCCDetails(TemporaryCCCardDetails_Result temopraryCCCardDetails, string currentUser)
        {
            repository.SaveTemporaryCCDetails(temopraryCCCardDetails, currentUser);
        }

        public ImportCCFileResult ProcessCreditCardIssueTransactions(List<VirtualPlus> items, string userName, string sessionID, Guid processGUID,string source,string fileName)
        {
            ImportCCFileResult result = new ImportCCFileResult();
            VendorTemporaryCCProcessingRepository repository = new VendorTemporaryCCProcessingRepository();
            int statusID = repository.GetTemporaryCreditCardStatusID("Unmatched");

            DataTable dtImportData = new DataTable();

            dtImportData.Columns.Add("ProcessIdentifier", typeof(Guid));
            dtImportData.Columns.Add("PurchaseID_CreditCardIssueNumber");
            dtImportData.Columns.Add("CPN_PAN_CreditCardNumber");
            dtImportData.Columns.Add("PurchaseOrderID");
            dtImportData.Columns.Add("VendorInvoiceID");
            dtImportData.Columns.Add("CREATE_DATE_IssueDate_TransactionDate");
            dtImportData.Columns.Add("USER_NAME_IssueBy_TransactionBy");
            dtImportData.Columns.Add("IssueStatus");
            dtImportData.Columns.Add("CDF_PO_ReferencePurchaseOrderNumber");
            dtImportData.Columns.Add("CDF_PO_OriginalReferencePurchaseOrderNumber");
            dtImportData.Columns.Add("CDF_ISP_Vendor_ReferenceVendorNumber");
            dtImportData.Columns.Add("ApprovedAmount");
            dtImportData.Columns.Add("TotalChargeAmount");
            dtImportData.Columns.Add("TemporaryCreditCardStatusID");
            dtImportData.Columns.Add("ExceptionMessage");
            dtImportData.Columns.Add("Note");
            dtImportData.Columns.Add("CreateDate");
            dtImportData.Columns.Add("CreateBy");
            dtImportData.Columns.Add("ModifyDate");
            dtImportData.Columns.Add("ModifyBy");
            dtImportData.Columns.Add("HISTORY_ID_TransactionSequence");
            dtImportData.Columns.Add("ACTION_TYPE_TransactionType");
            dtImportData.Columns.Add("REQUESTED_AMOUNT_RequestedAmount");
            dtImportData.Columns.Add("APPROVED_AMOUNT_ApprovedAmount");
            dtImportData.Columns.Add("AVAILABLE_BALANCE_AvailableBalance");
            dtImportData.Columns.Add("ChargeDate");
            dtImportData.Columns.Add("ChargeAmount");
            dtImportData.Columns.Add("ChargeDescription");
            dtImportData.Columns.Add("TemporaryCreditCardID");
            dtImportData.Columns.Add("TemporaryCreditCardDetailsID");
            dtImportData.Columns.Add("PURCHASE_TYPE");

            items = items.OrderBy(u => u.PurchaseId).ThenBy(u => u.CpnPan).ToList();

            foreach (var item in items)
            {
                dtImportData.Rows.Add(
                                        processGUID,
                                        item.PurchaseId,
                                        item.CpnPan,
                                        null,
                                        null,
                                        item.CreateDate,
                                        item.UserName,
                                        "Active",
                                        item.CDF_PO,
                                        item.CDF_PO,
                                        item.CDF_ISP_Vendor,
                                        0,
                                        0,
                                        statusID,
                                        null,
                                        null,
                                        DateTime.Now,
                                        userName,
                                        null,
                                        null,
                                        0,//item.HistoryID,
                                        item.ActionType,
                                        0,//item.RequestedAmount,
                                        item.ApprovedAmount,
                                        item.AvailableBalance,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        item.PurchaseType
                                    );
            }
            DataTable dtResults = repository.DumpRecordsForTemporaryCreditCard(dtImportData, processGUID);

            if (dtResults != null)
            {
                if (dtResults.Rows.Count > 0)
                {
                    result.TotalRecordRead = Convert.ToInt32(dtResults.Rows[0]["TotalRecordCount"].ToString());
                    result.TotalRecordIgnored = Convert.ToInt32(dtResults.Rows[0]["TotalRecordsIgnored"].ToString());
                    result.TotalCreditCardAdded = Convert.ToInt32(dtResults.Rows[0]["TotalCreditCardAdded"].ToString());
                    result.TotalDetailTransactionAdded = Convert.ToInt32(dtResults.Rows[0]["TotalTransactionAdded"].ToString());
                    result.TotalErrorRecords = Convert.ToInt32(dtResults.Rows[0]["TotalErrorRecords"].ToString());
                }
            }

            Dictionary<string, string> eventLogDetails = new Dictionary<string, string>();
            eventLogDetails.Add("FileName", fileName);
            eventLogDetails.Add("TotalRecordsRead", result.TotalRecordRead.ToString());
            eventLogDetails.Add("TotalRecordsIgnored", result.TotalRecordIgnored.ToString());
            eventLogDetails.Add("TotalCreditCardsAdded", result.TotalCreditCardAdded.ToString());
            eventLogDetails.Add("TotalDetailTransactionsAdded", result.TotalDetailTransactionAdded.ToString());
            eventLogDetails.Add("TotalErrorRecords", result.TotalErrorRecords.ToString());
            //  Add Event log record for Import File.
            var eventLoggerFacade = new EventLoggerFacade();
            logger.Info("Logging an event for import cc file");
            eventLoggerFacade.LogEvent(source, EventNames.IMPORT_TEMP_CC_FILE, eventLogDetails, userName, sessionID);
            

           
            return result;
        }

        public ImportCCFileResult ProcessCreditCardChargedTransactions(List<ChargedTransactions> items, string userName, string sessionID, Guid processGUID,string source,string fileName)
        {
            ImportCCFileResult result = new ImportCCFileResult();
            VendorTemporaryCCProcessingRepository repository = new VendorTemporaryCCProcessingRepository();
            
            DataTable dtImportData = new DataTable();
            dtImportData.Columns.Add("ProcessIdentifier", typeof(Guid));
            dtImportData.Columns.Add("TemporaryCreditCardID");
            dtImportData.Columns.Add("TemporaryCreditCardDetailsID");
            dtImportData.Columns.Add("FINVirtualCardNumber_C_CreditCardNumber");
            dtImportData.Columns.Add("FINCFFData02_C_OriginalReferencePurchaseOrderNumber");
            dtImportData.Columns.Add("TransactionSequence");
            dtImportData.Columns.Add("FINTransactionDate_C_IssueDate_TransactionDate");
            dtImportData.Columns.Add("TransactionType");
            dtImportData.Columns.Add("TransactionBy");
            dtImportData.Columns.Add("RequestedAmount");
            dtImportData.Columns.Add("ApprovedAmount");
            dtImportData.Columns.Add("AvailableBalance");
            dtImportData.Columns.Add("FINPostingDate_ChargeDate");
            dtImportData.Columns.Add("FINTransactionAmount_ChargeAmount");
            dtImportData.Columns.Add("FINTransactionDescription_ChargeDescription");
            dtImportData.Columns.Add("CreateDate");
            dtImportData.Columns.Add("CreatedBy");
            dtImportData.Columns.Add("ModifyDate");
            dtImportData.Columns.Add("ModifiedBy");
            dtImportData.Columns.Add("ExceptionMessage");
            items = items.OrderBy(u => u.FinVirtualCardNumber).ThenBy(u => u.FinTransactionDate).ToList();
            foreach (var item in items)
            {
                dtImportData.Rows.Add
                    (
                        processGUID,
                        null,
                        null,
                        item.FinVirtualCardNumber,
                        item.FinCFFDataSecond,
                        null,
                        item.FinTransactionDate,
                        "Charge",
                        null,
                        null,
                        null,
                        null,
                        item.FinPostingDate,
                        item.FinTransactionAmount,
                        item.FinTransactionDescription,
                        DateTime.Now,
                        userName,
                        null,
                        null,
                        null
                    );
            }
            DataTable dtResults = repository.DumpRecordsForTemporaryCreditCardChargedTransactions(dtImportData, processGUID);
            if (dtResults != null)
            {
                if (dtResults.Rows.Count > 0)
                {
                    result.TotalRecordRead = Convert.ToInt32(dtResults.Rows[0]["TotalRecordCount"].ToString());
                    result.TotalRecordIgnored = Convert.ToInt32(dtResults.Rows[0]["TotalRecordsIgnored"].ToString());
                    result.TotalCreditCardAdded = Convert.ToInt32(dtResults.Rows[0]["TotalCreditCardAdded"].ToString());
                    result.TotalDetailTransactionAdded = Convert.ToInt32(dtResults.Rows[0]["TotalTransactionAdded"].ToString());
                    result.TotalErrorRecords = Convert.ToInt32(dtResults.Rows[0]["TotalErrorRecords"].ToString());
                }
            }

            Dictionary<string, string> eventLogDetails = new Dictionary<string, string>();
            eventLogDetails.Add("FileName", fileName);
            eventLogDetails.Add("TotalRecordsRead", result.TotalRecordRead.ToString());
            eventLogDetails.Add("TotalRecordsIgnored", result.TotalRecordIgnored.ToString());
            eventLogDetails.Add("TotalCreditCardsAdded", result.TotalCreditCardAdded.ToString());
            eventLogDetails.Add("TotalDetailTransactionsAdded", result.TotalDetailTransactionAdded.ToString());
            eventLogDetails.Add("TotalErrorRecords", result.TotalErrorRecords.ToString());

            //  Add Event log record for Import File.
            var eventLoggerFacade = new EventLoggerFacade();
            logger.Info("Logging an event for import cc file");
            eventLoggerFacade.LogEvent(source, EventNames.IMPORT_TEMP_CC_FILE, eventLogDetails, userName, sessionID);

           
            return result;
        }
    }
}
