using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.SqlClient;
using System.Data;
using System.Configuration;
using System.Data.Entity;
using log4net;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorTemporaryCCProcessingRepository
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(VendorTemporaryCCProcessingRepository));
        #endregion

        public List<VendorCCProcessingList_Result> GetVendorCCProcessingList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorCCProcessingList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<VendorCCProcessingList_Result>();
            }
        }

        public List<VendorCCProcessingDetailList_Result> GetVendorCCProcessingDetailList(PageCriteria pc, int? temporaryCCID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorCCProcessingDetailList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, temporaryCCID).ToList<VendorCCProcessingDetailList_Result>();
            }
        }

        public TemporaryCCCardDetails_Result GetTemporaryCCCardDetails(int? temporaryCCID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetTemporaryCCCardDetails(temporaryCCID).FirstOrDefault();
            }
        }

        public void SaveTemporaryCCDetails(TemporaryCCCardDetails_Result temporaryCCCardDetails, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                TemporaryCreditCard temporaryCC = dbContext.TemporaryCreditCards.Where(a => a.ID == temporaryCCCardDetails.ID).FirstOrDefault();
                if (temporaryCC != null)
                {
                    temporaryCC.Note = temporaryCCCardDetails.Note;
                    temporaryCC.ReferencePurchaseOrderNumber = temporaryCCCardDetails.CCRefPO;
                    temporaryCC.ModifyBy = currentUser;
                    temporaryCC.ModifyDate = DateTime.Now;
                    //Bug 169
                    if (temporaryCCCardDetails.IsExceptionOverride.HasValue && temporaryCCCardDetails.IsExceptionOverride.Value && temporaryCCCardDetails.MatchStatus == "Exception")
                    {
                        temporaryCC.ExceptionMessage = null;
                        temporaryCC.TemporaryCreditCardStatusID = (from cardstatus in dbContext.TemporaryCreditCardStatus
                                                                   where cardstatus.Name == "Matched"
                                                                   select cardstatus.ID).FirstOrDefault();

                    }

                    if (temporaryCCCardDetails.IsExceptionOverride.HasValue && temporaryCCCardDetails.MatchStatus == "Exception")
                    {
                        temporaryCC.IsExceptionOverride = temporaryCCCardDetails.IsExceptionOverride;
                    }

                    dbContext.Entry(temporaryCC).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
                else
                {
                    throw new DMSException("Details not found for the specified card.");
                }
            }
        }

        public DataTable DumpRecordsForTemporaryCreditCard(DataTable dataTable, Guid processUID)
        {
            DataTable results = null;
            using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["ApplicationServices"].ConnectionString))
            {
                SqlTransaction transaction = null;
                connection.Open();
                try
                {
                    transaction = connection.BeginTransaction();
                    using (var sqlBulkCopy = new SqlBulkCopy(connection, SqlBulkCopyOptions.Default, transaction))
                    {
                        sqlBulkCopy.DestinationTableName = "dbo.TemporaryCreditCard_Import";
                        sqlBulkCopy.ColumnMappings.Add("ProcessIdentifier", "ProcessIdentifier");
                        sqlBulkCopy.ColumnMappings.Add("PurchaseID_CreditCardIssueNumber", "PurchaseID_CreditCardIssueNumber");
                        sqlBulkCopy.ColumnMappings.Add("CPN_PAN_CreditCardNumber", "CPN_PAN_CreditCardNumber");
                        sqlBulkCopy.ColumnMappings.Add("PurchaseOrderID", "PurchaseOrderID");
                        sqlBulkCopy.ColumnMappings.Add("VendorInvoiceID", "VendorInvoiceID");
                        sqlBulkCopy.ColumnMappings.Add("CREATE_DATE_IssueDate_TransactionDate", "CREATE_DATE_IssueDate_TransactionDate");
                        sqlBulkCopy.ColumnMappings.Add("USER_NAME_IssueBy_TransactionBy", "USER_NAME_IssueBy_TransactionBy");
                        sqlBulkCopy.ColumnMappings.Add("IssueStatus", "IssueStatus");
                        sqlBulkCopy.ColumnMappings.Add("CDF_PO_ReferencePurchaseOrderNumber", "CDF_PO_ReferencePurchaseOrderNumber");
                        sqlBulkCopy.ColumnMappings.Add("CDF_PO_OriginalReferencePurchaseOrderNumber", "CDF_PO_OriginalReferencePurchaseOrderNumber");
                        sqlBulkCopy.ColumnMappings.Add("CDF_ISP_Vendor_ReferenceVendorNumber", "CDF_ISP_Vendor_ReferenceVendorNumber");
                        sqlBulkCopy.ColumnMappings.Add("ApprovedAmount", "ApprovedAmount");
                        sqlBulkCopy.ColumnMappings.Add("TotalChargeAmount", "TotalChargeAmount");
                        sqlBulkCopy.ColumnMappings.Add("TemporaryCreditCardStatusID", "TemporaryCreditCardStatusID");
                        sqlBulkCopy.ColumnMappings.Add("ExceptionMessage", "ExceptionMessage");
                        sqlBulkCopy.ColumnMappings.Add("Note", "Note");
                        sqlBulkCopy.ColumnMappings.Add("CreateDate", "CreateDate");
                        sqlBulkCopy.ColumnMappings.Add("CreateBy", "CreateBy");
                        sqlBulkCopy.ColumnMappings.Add("ModifyDate", "ModifyDate");
                        sqlBulkCopy.ColumnMappings.Add("ModifyBy", "ModifyBy");
                        sqlBulkCopy.ColumnMappings.Add("HISTORY_ID_TransactionSequence", "HISTORY_ID_TransactionSequence");
                        sqlBulkCopy.ColumnMappings.Add("ACTION_TYPE_TransactionType", "ACTION_TYPE_TransactionType");
                        sqlBulkCopy.ColumnMappings.Add("REQUESTED_AMOUNT_RequestedAmount", "REQUESTED_AMOUNT_RequestedAmount");
                        sqlBulkCopy.ColumnMappings.Add("APPROVED_AMOUNT_ApprovedAmount", "APPROVED_AMOUNT_ApprovedAmount");
                        sqlBulkCopy.ColumnMappings.Add("AVAILABLE_BALANCE_AvailableBalance", "AVAILABLE_BALANCE_AvailableBalance");
                        sqlBulkCopy.ColumnMappings.Add("ChargeDate", "ChargeDate");
                        sqlBulkCopy.ColumnMappings.Add("ChargeDescription", "ChargeDescription");
                        sqlBulkCopy.ColumnMappings.Add("TemporaryCreditCardID", "TemporaryCreditCardID");
                        sqlBulkCopy.ColumnMappings.Add("TemporaryCreditCardDetailsID", "TemporaryCreditCardDetailsID");
                        sqlBulkCopy.ColumnMappings.Add("PURCHASE_TYPE", "PURCHASE_TYPE");
                        sqlBulkCopy.WriteToServer(dataTable);
                    }
                    DataSet dsResults = new DataSet();
                    SqlCommand command = new SqlCommand("dbo.dms_CCImport_CreditCardIssueTransactions", connection);
                    command.CommandTimeout = 600;
                    command.Transaction = transaction;
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@processGUID", processUID));
                    SqlDataAdapter sql_adapter = new SqlDataAdapter(command);
                    sql_adapter.Fill(dsResults);
                    if (dsResults.Tables.Count > 0)
                    {
                        results = dsResults.Tables[0];
                    }

                    //Update temp card status and amount fields for all detail records
                    SqlCommand updateCommand = new SqlCommand("dbo.dms_CCImport_UpdateTempCreditCardDetails", connection);
                    updateCommand.CommandTimeout = 600;
                    updateCommand.Transaction = transaction;
                    updateCommand.CommandType = CommandType.StoredProcedure;
                    updateCommand.ExecuteNonQuery();

                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    logger.Info(string.Format("VendorTemporaryCCProcessingRepository -> DumpRecordsForTemporaryCreditCard : Error occurred : {0}", ex.Message != null ? ex.Message : ex.ToString()));
                    transaction.Rollback();
                    throw ex;
                }

            }
            return results;
        }

        public DataTable DumpRecordsForTemporaryCreditCardChargedTransactions(DataTable dataTable, Guid processUID)
        {
            DataTable results = null;
            using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["ApplicationServices"].ConnectionString))
            {
                SqlTransaction transaction = null;
                connection.Open();
                try
                {
                    transaction = connection.BeginTransaction();
                    using (var sqlBulkCopy = new SqlBulkCopy(connection, SqlBulkCopyOptions.Default, transaction))
                    {
                        sqlBulkCopy.DestinationTableName = "dbo.TemporaryCreditCard_Import_ChargedTransactions";
                        sqlBulkCopy.ColumnMappings.Add("ProcessIdentifier", "ProcessIdentifier");
                        sqlBulkCopy.ColumnMappings.Add("TemporaryCreditCardID", "TemporaryCreditCardID");
                        sqlBulkCopy.ColumnMappings.Add("TemporaryCreditCardDetailsID", "TemporaryCreditCardDetailsID");
                        sqlBulkCopy.ColumnMappings.Add("FINVirtualCardNumber_C_CreditCardNumber", "FINVirtualCardNumber_C_CreditCardNumber");
                        sqlBulkCopy.ColumnMappings.Add("FINCFFData02_C_OriginalReferencePurchaseOrderNumber", "FINCFFData02_C_OriginalReferencePurchaseOrderNumber");
                        sqlBulkCopy.ColumnMappings.Add("TransactionSequence", "TransactionSequence");
                        sqlBulkCopy.ColumnMappings.Add("FINTransactionDate_C_IssueDate_TransactionDate", "FINTransactionDate_C_IssueDate_TransactionDate");
                        sqlBulkCopy.ColumnMappings.Add("TransactionType", "TransactionType");
                        sqlBulkCopy.ColumnMappings.Add("TransactionBy", "TransactionBy");
                        sqlBulkCopy.ColumnMappings.Add("RequestedAmount", "RequestedAmount");
                        sqlBulkCopy.ColumnMappings.Add("ApprovedAmount", "ApprovedAmount");
                        sqlBulkCopy.ColumnMappings.Add("AvailableBalance", "AvailableBalance");
                        sqlBulkCopy.ColumnMappings.Add("FINPostingDate_ChargeDate", "FINPostingDate_ChargeDate");
                        sqlBulkCopy.ColumnMappings.Add("FINTransactionAmount_ChargeAmount", "FINTransactionAmount_ChargeAmount");
                        sqlBulkCopy.ColumnMappings.Add("FINTransactionDescription_ChargeDescription", "FINTransactionDescription_ChargeDescription");
                        sqlBulkCopy.ColumnMappings.Add("CreateDate", "CreateDate");
                        sqlBulkCopy.ColumnMappings.Add("CreatedBy", "CreatedBy");
                        sqlBulkCopy.ColumnMappings.Add("ModifyDate", "ModifyDate");
                        sqlBulkCopy.ColumnMappings.Add("ModifiedBy", "ModifiedBy");
                        sqlBulkCopy.ColumnMappings.Add("ExceptionMessage", "ExceptionMessage");
                        sqlBulkCopy.WriteToServer(dataTable);
                    }
                    DataSet dsResults = new DataSet();
                    SqlCommand command = new SqlCommand("dbo.dms_CCImport_CreditCardChargedTransactions", connection);
                    command.Transaction = transaction;
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@processGUID", processUID));
                    command.CommandTimeout = 600;
                    SqlDataAdapter sql_adapter = new SqlDataAdapter(command);
                    sql_adapter.Fill(dsResults);
                    if (dsResults.Tables.Count > 0)
                    {
                        results = dsResults.Tables[0];
                    }

                    //Update temp card status and amount fields for all detail records
                    SqlCommand updateCommand = new SqlCommand("dbo.dms_CCImport_UpdateTempCreditCardDetails", connection);
                    updateCommand.CommandTimeout = 600;
                    updateCommand.Transaction = transaction;
                    updateCommand.CommandType = CommandType.StoredProcedure;
                    updateCommand.ExecuteNonQuery();

                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    throw ex;
                }

            }
            return results;
        }

        public int GetTemporaryCreditCardStatusID(string statusName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.TemporaryCreditCardStatus.Where(u => u.Name.Equals(statusName)).FirstOrDefault();
                if (existingRecord == null)
                {
                    throw new Exception(string.Format("Unable to Retrieve Temporary Credit Card Status {0}", statusName));
                }

                return existingRecord.ID;
            }
        }
    }
}
