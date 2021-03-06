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
    
    [Serializable] 
    public partial class Payment
    {
    	public Payment()
        {
            this.PaymentAuthorizations = new HashSet<PaymentAuthorization>();
            this.PaymentTransactions = new HashSet<PaymentTransaction>();
        }
    
        public int ID { get; set; }
        public Nullable<int> ServiceRequestID { get; set; }
        public Nullable<int> PaymentTypeID { get; set; }
        public Nullable<int> PaymentStatusID { get; set; }
        public Nullable<int> PaymentTransactionTypeID { get; set; }
        public Nullable<int> PaymentReasonID { get; set; }
        public string PaymentReasonOther { get; set; }
        public Nullable<System.DateTime> PaymentDate { get; set; }
        public Nullable<decimal> Amount { get; set; }
        public Nullable<int> CurrencyTypeID { get; set; }
        public string CCOrderID { get; set; }
        public string CCAccountNumber { get; set; }
        public string CCPartial { get; set; }
        public Nullable<System.DateTime> CCExpireDate { get; set; }
        public string CCNameOnCard { get; set; }
        public string CCAuthCode { get; set; }
        public string CCAuthType { get; set; }
        public string CCTransactionReference { get; set; }
        public string BillingLine1 { get; set; }
        public string BillingLine2 { get; set; }
        public string BillingCity { get; set; }
        public string BillingStateProvince { get; set; }
        public string BillingPostalCode { get; set; }
        public string BillingCountryCode { get; set; }
        public Nullable<int> BillingStateProvinceID { get; set; }
        public Nullable<int> BillingCountryID { get; set; }
        public string Comments { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    
        public virtual Country Country { get; set; }
        public virtual CurrencyType CurrencyType { get; set; }
        public virtual StateProvince StateProvince { get; set; }
        public virtual PaymentType PaymentType { get; set; }
        public virtual PaymentStatu PaymentStatu { get; set; }
        public virtual PaymentTransactionType PaymentTransactionType { get; set; }
        public virtual PaymentReason PaymentReason { get; set; }
        public virtual ICollection<PaymentAuthorization> PaymentAuthorizations { get; set; }
        public virtual ICollection<PaymentTransaction> PaymentTransactions { get; set; }
        public virtual ServiceRequest ServiceRequest { get; set; }
    }
}
