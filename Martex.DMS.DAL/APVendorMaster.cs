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
    
    public partial class APVendorMaster
    {
        public int RecID { get; set; }
        public Nullable<int> ETL_Load_ID { get; set; }
        public Nullable<bool> ProcessFlag { get; set; }
        public string Status { get; set; }
        public string ErrorDescription { get; set; }
        public Nullable<System.DateTime> AddDateTime { get; set; }
        public Nullable<decimal> Division { get; set; }
        public string VendorNumber { get; set; }
        public string VendorName { get; set; }
        public string AddressLine1 { get; set; }
        public string AddressLine2 { get; set; }
        public string AddressLine3 { get; set; }
        public string City { get; set; }
        public string State { get; set; }
        public string ZipCode { get; set; }
        public string PhoneNumber { get; set; }
        public string VendorRef { get; set; }
        public string MasterFileComment { get; set; }
        public string SSN { get; set; }
        public string Fax { get; set; }
        public string EmailAddress { get; set; }
        public string ISRNumber { get; set; }
        public string ContractType { get; set; }
        public string BankAccountNumber { get; set; }
        public string BankTransitNumber { get; set; }
        public string BankAccountType { get; set; }
        public string CountryCode { get; set; }
    }
}
