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
    public partial class PaymentReceiptValues_Result
    {
        public string CCOrderID { get; set; }
        public string PaymentDate { get; set; }
        public string Service { get; set; }
        public string ServiceLocationAddress { get; set; }
        public string DestinationAddress { get; set; }
        public string NameOnCard { get; set; }
        public string CardType { get; set; }
        public string CardNumber { get; set; }
        public string ExpirationDate { get; set; }
        public Nullable<decimal> Amount { get; set; }
        public string Program { get; set; }
        public string Type { get; set; }
    }
}
