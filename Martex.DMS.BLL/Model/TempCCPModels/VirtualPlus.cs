using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.TempCCPModels
{

    public class VirtualPlus
    {
        /*
        * KB (4/12): Updated the mapping as per the latest file format. 
        * Commented out the older mappings as those fields are no longer in use
        */
        public string PurchaseId { get; set; }
        public DateTime CreateDate { get; set; }
        //public string CorporateName { get; set; }
        public string UserName { get; set; }
        public string ActionType { get; set; }
        //public string PurchaseStatus { get; set; }
        public string PurchaseType { get; set; }
        //public decimal RequestedAmount { get; set; }
        public decimal ApprovedAmount { get; set; }
        //public decimal HistorialAvlBalance { get; set; }
        public string VCardAlias { get; set; }
        public int CurrencyCode { get; set; }
        //public string JournalStatus { get; set; }
        //public int HistoryID { get; set; }
        public string CpnPan { get; set; }
        public decimal AvailableBalance { get; set; }
        public string CDF_PO { get; set; }
        public string CDF_ISP_Vendor { get; set; }
    }

  
    public class ChargedTransactions
    {
        public string AccountName { get; set; }
        public string AccountnNumber { get; set; }
        public DateTime FinTransactionDate { get; set; }
        public DateTime FinPostingDate { get; set; }
        public string FinTransactionDescription { get; set; }
        public decimal FinTransactionAmount { get; set; }
        public string FinVirtualCardNumber { get; set; }
        public string FinCFFDataFirst { get; set; }
        public string FinCFFDataSecond { get; set; }
        public string FinCFFDataThird { get; set; }
    }

    public class ImportCCFileResult
    {
        public int TotalRecordRead { get; set; }
        public int TotalRecordIgnored { get; set; }
        public int TotalCreditCardAdded { get; set; }
        public int TotalDetailTransactionAdded { get; set; }
        public int TotalErrorRecords { get; set; }
    }

}
