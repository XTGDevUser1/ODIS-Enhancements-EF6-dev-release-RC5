//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Martex.DMS.DAL
{
    using System;
    using System.Collections.Generic;
    
    public partial class APCheckRequest
    {
        public int RecID { get; set; }
        public Nullable<int> ETL_Load_ID { get; set; }
        public Nullable<bool> ProcessFlag { get; set; }
        public string Status { get; set; }
        public string ErrorDescription { get; set; }
        public Nullable<System.DateTime> AddDateTime { get; set; }
        public Nullable<decimal> Division { get; set; }
        public string VendorNumber { get; set; }
        public string InvoiceNumber { get; set; }
        public Nullable<System.DateTime> InvoiceDate { get; set; }
        public Nullable<System.DateTime> InvoiceDueDate { get; set; }
        public string Comment { get; set; }
        public string SeparateCheck { get; set; }
        public Nullable<decimal> InvoiceAmount { get; set; }
        public string GLExpenseAccount { get; set; }
        public Nullable<decimal> ExpenseAmount { get; set; }
        public string AdditionalComment { get; set; }
        public string PaymentMethod { get; set; }
        public Nullable<int> DocumentNoteID { get; set; }
        public string PONumber { get; set; }
        public Nullable<System.DateTime> POIssuedDate { get; set; }
        public string VendorInvoiceNumber { get; set; }
        public Nullable<System.DateTime> ReceivedDate { get; set; }
        public string VendorRepContactName { get; set; }
        public string VendorRepContactPhoneNumber { get; set; }
        public string VendorRepContactEmail { get; set; }
        public string ProgramName { get; set; }
        public string ProgramRefNumber { get; set; }
        public string RegionNumber { get; set; }
        public string DivisionNumber { get; set; }
        public string DistrictNumber { get; set; }
        public Nullable<bool> Leader { get; set; }
        public Nullable<bool> Bulletin { get; set; }
        public Nullable<System.DateTime> ContractedDate { get; set; }
        public Nullable<System.DateTime> CancelledDate { get; set; }
        public Nullable<decimal> BegDebitBalance { get; set; }
        public Nullable<decimal> FirstyearCommissions { get; set; }
        public Nullable<decimal> Renewals { get; set; }
        public Nullable<decimal> Comissions { get; set; }
        public Nullable<decimal> Advances { get; set; }
        public Nullable<decimal> Backend { get; set; }
        public Nullable<decimal> ServiceCharge { get; set; }
        public Nullable<decimal> Other { get; set; }
        public Nullable<decimal> TotalCharges { get; set; }
        public Nullable<decimal> EndDebitBalance { get; set; }
        public Nullable<decimal> EstRemainFirstYear { get; set; }
        public Nullable<decimal> QualityRatioPct { get; set; }
        public Nullable<decimal> SilverRenewalQaulifier { get; set; }
        public Nullable<decimal> EarnedCommYTD { get; set; }
        public Nullable<decimal> AdvancesYTD { get; set; }
        public string SilverRenewalText { get; set; }
        public Nullable<decimal> QCQYTD { get; set; }
        public Nullable<decimal> AdvancesQualityYTD { get; set; }
        public Nullable<int> PersonalMembershipCount { get; set; }
        public Nullable<int> PersonalMemberCount { get; set; }
        public Nullable<decimal> PersonalNBAV { get; set; }
        public Nullable<decimal> PersonalAdvance { get; set; }
        public Nullable<decimal> PersonalBonus { get; set; }
        public Nullable<int> OverrideMembershipCount { get; set; }
        public Nullable<int> OverrideMemberCount { get; set; }
        public Nullable<decimal> OverrideNBAV { get; set; }
        public Nullable<decimal> OverrideAdvance { get; set; }
        public Nullable<decimal> OverrideBonus { get; set; }
        public Nullable<decimal> TIPS { get; set; }
        public Nullable<decimal> Multiplier { get; set; }
        public Nullable<decimal> AdjustmentAmount { get; set; }
        public string ContractType { get; set; }
        public Nullable<decimal> PersonalOverrideAdvance { get; set; }
        public Nullable<System.DateTime> DetailItem1Date { get; set; }
        public string DetailItem1Number { get; set; }
        public string DetailItem1Description { get; set; }
        public Nullable<decimal> DetailItem1Amount { get; set; }
        public Nullable<System.DateTime> DetailItem2Date { get; set; }
        public string DetailItem2Number { get; set; }
        public string DetailItem2Description { get; set; }
        public Nullable<decimal> DetailItem2Amount { get; set; }
        public Nullable<System.DateTime> DetailItem3Date { get; set; }
        public string DetailItem3Number { get; set; }
        public string DetailItem3Description { get; set; }
        public Nullable<decimal> DetailItem3Amount { get; set; }
        public Nullable<System.DateTime> DetailItem4Date { get; set; }
        public string DetailItem4Number { get; set; }
        public string DetailItem4Description { get; set; }
        public Nullable<decimal> DetailItem4Amount { get; set; }
        public Nullable<System.DateTime> DetailItem5Date { get; set; }
        public string DetailItem5Number { get; set; }
        public string DetailItem5Description { get; set; }
        public Nullable<decimal> DetailItem5Amount { get; set; }
        public string ClientName { get; set; }
        public string ClientAddress1 { get; set; }
        public string ClientAddress2 { get; set; }
        public string ClientCity { get; set; }
        public string ClientState { get; set; }
        public string ClientZip { get; set; }
    }
}