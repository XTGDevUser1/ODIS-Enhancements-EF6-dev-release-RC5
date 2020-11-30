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
    public partial class PaymentAuthorization
    {
        public int ID { get; set; }
        public Nullable<int> PaymentID { get; set; }
        public int SequenceNumber { get; set; }
        public Nullable<System.DateTime> AuthorizationDate { get; set; }
        public string AuthorizationCode { get; set; }
        public string AuthorizationType { get; set; }
        public string ReferenceNumber { get; set; }
        public Nullable<decimal> Amount { get; set; }
        public string ProcessorReferenceNumber { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
    
        public virtual Payment Payment { get; set; }
    }
}