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
    public partial class VendorInvoiceCurrentBillingInformation_Result
    {
        public int VendorID { get; set; }
        public string VendorNumber { get; set; }
        public string Name { get; set; }
        public string Status { get; set; }
        public string Line1 { get; set; }
        public string Line2 { get; set; }
        public string Line3 { get; set; }
        public string BillingCityStZip { get; set; }
        public string PaymentType { get; set; }
        public string ContactName { get; set; }
        public string PhoneNumber { get; set; }
        public string Email { get; set; }
        public string TaxID { get; set; }
        public Nullable<bool> IsLevyActive { get; set; }
        public string LevyRecipientName { get; set; }
        public string LevyAddressLine1 { get; set; }
        public string LevyAddressLine2 { get; set; }
        public string LevyAddressLine3 { get; set; }
        public string LevyCityStZip { get; set; }
        public string LevyPaymentType { get; set; }
    }
}