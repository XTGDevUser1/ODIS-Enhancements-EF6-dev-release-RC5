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
    public partial class ContractRateSchedule
    {
    	public ContractRateSchedule()
        {
            this.ContractRateScheduleProducts = new HashSet<ContractRateScheduleProduct>();
            this.ContractRateScheduleProductLogs = new HashSet<ContractRateScheduleProductLog>();
        }
    
        public int ID { get; set; }
        public Nullable<int> ContractID { get; set; }
        public Nullable<int> ContractRateScheduleStatusID { get; set; }
        public Nullable<System.DateTime> StartDate { get; set; }
        public Nullable<System.DateTime> EndDate { get; set; }
        public Nullable<System.DateTime> SignedDate { get; set; }
        public string SignedBy { get; set; }
        public string SignedByTitle { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    
        public virtual ICollection<ContractRateScheduleProduct> ContractRateScheduleProducts { get; set; }
        public virtual ContractRateScheduleStatu ContractRateScheduleStatu { get; set; }
        public virtual ICollection<ContractRateScheduleProductLog> ContractRateScheduleProductLogs { get; set; }
        public virtual Contract Contract { get; set; }
    }
}