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
    public partial class ContactLogReason
    {
        public int ID { get; set; }
        public int ContactLogID { get; set; }
        public int ContactReasonID { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
    
        public virtual ContactLog ContactLog { get; set; }
        public virtual ContactReason ContactReason { get; set; }
    }
}