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
    public partial class ServiceRequestHistoryList_Result
    {
        public Nullable<int> TotalRows { get; set; }
        public int RowNum { get; set; }
        public int RequestNumber { get; set; }
        public int CaseID { get; set; }
        public Nullable<int> ProgramID { get; set; }
        public string Program { get; set; }
        public Nullable<int> ClientID { get; set; }
        public string Client { get; set; }
        public string MemberName { get; set; }
        public string MemberNumber { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string POCreateBy { get; set; }
        public string POModifyBy { get; set; }
        public string SRCreateBy { get; set; }
        public string SRModifyBy { get; set; }
        public string VIN { get; set; }
        public Nullable<int> VehicleTypeID { get; set; }
        public string VehicleType { get; set; }
        public Nullable<int> ServiceTypeID { get; set; }
        public string ServiceType { get; set; }
        public Nullable<int> StatusID { get; set; }
        public string Status { get; set; }
        public Nullable<int> PriorityID { get; set; }
        public string Priority { get; set; }
        public string ISPName { get; set; }
        public string VendorNumber { get; set; }
        public string PONumber { get; set; }
        public Nullable<int> PurchaseOrderStatusID { get; set; }
        public string PurchaseOrderStatus { get; set; }
        public Nullable<decimal> PurchaseOrderAmount { get; set; }
        public Nullable<int> AssignedToUserID { get; set; }
        public Nullable<int> NextActionAssignedToUserID { get; set; }
        public Nullable<bool> IsGOA { get; set; }
        public Nullable<bool> IsRedispatched { get; set; }
        public Nullable<bool> IsPossibleTow { get; set; }
        public Nullable<int> VehicleYear { get; set; }
        public string VehicleMake { get; set; }
        public string VehicleModel { get; set; }
        public Nullable<bool> PaymentByCard { get; set; }
    }
}
