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
    
    [Serializable] 
    public partial class MemberPaymentMethodList_Result
    {
        public int PaymentID { get; set; }
        public Nullable<int> PaymentTypeID { get; set; }
        public string PaymentType { get; set; }
        public string CardNumber { get; set; }
        public string Last4OfCC { get; set; }
        public string CCPartial { get; set; }
        public Nullable<System.DateTime> ExpirationDate { get; set; }
        public Nullable<int> ExpirationMonth { get; set; }
        public Nullable<int> ExpirationYear { get; set; }
        public string NameOnCard { get; set; }
        public string Address1 { get; set; }
        public string Address2 { get; set; }
        public string City { get; set; }
        public string StateProvince { get; set; }
        public string PostalCode { get; set; }
        public string CoutnryCode { get; set; }
        public Nullable<int> StateProvinceID { get; set; }
        public Nullable<int> CountryID { get; set; }
        public string Comments { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string Username { get; set; }
        public string BillingAddress { get; set; }
    }
}
