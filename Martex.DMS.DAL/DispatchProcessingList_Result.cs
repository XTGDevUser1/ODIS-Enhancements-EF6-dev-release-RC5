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
    public partial class DispatchProcessingList_Result
    {
        public Nullable<int> ContactMethodID { get; set; }
        public int ServiceRequestID { get; set; }
        public bool IsSMSAvailable { get; set; }
        public Nullable<int> CaseID { get; set; }
        public Nullable<int> ContactPhoneTypeID { get; set; }
        public string ContactPhoneNumber { get; set; }
        public Nullable<int> MemberID { get; set; }
        public Nullable<System.DateTime> ETADate { get; set; }
        public Nullable<int> ProgramID { get; set; }
        public string TollFreeNumber { get; set; }
        public string PurchaseOrderNumber { get; set; }
        public bool IsClosedLoopAutomated { get; set; }
        public Nullable<int> SourceSystemID { get; set; }
        public string SourceSystem { get; set; }
        public string QueueARN { get; set; }
    }
}
