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
    public partial class ProgramManagementServicesList_Result
    {
        public Nullable<int> TotalRows { get; set; }
        public long RowNum { get; set; }
        public Nullable<int> ProgramProductID { get; set; }
        public string Category { get; set; }
        public string Service { get; set; }
        public Nullable<System.DateTime> StartDate { get; set; }
        public Nullable<System.DateTime> EndDate { get; set; }
        public Nullable<decimal> ServiceCoverageLimit { get; set; }
        public Nullable<bool> IsServiceCoverageBestValue { get; set; }
        public Nullable<decimal> MaterialsCoverageLimit { get; set; }
        public Nullable<bool> IsMaterialsMemberPay { get; set; }
        public Nullable<int> ServiceMileageLimit { get; set; }
        public Nullable<bool> IsServiceMileageUnlimited { get; set; }
        public Nullable<bool> IsServiceMileageOverageAllowed { get; set; }
        public Nullable<bool> IsReimbursementOnly { get; set; }
        public int ProgramID { get; set; }
        public string ProgramName { get; set; }
    }
}
