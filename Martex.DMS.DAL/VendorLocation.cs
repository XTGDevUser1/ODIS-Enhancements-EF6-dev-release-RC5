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
    public partial class VendorLocation
    {
    	public VendorLocation()
        {
            this.ContractRateScheduleProducts = new HashSet<ContractRateScheduleProduct>();
            this.ContractRateScheduleProductLogs = new HashSet<ContractRateScheduleProductLog>();
            this.VendorLocationVirtuals = new HashSet<VendorLocationVirtual>();
            this.VendorLocationBusinessHours = new HashSet<VendorLocationBusinessHour>();
            this.VendorLocationPaymentTypes = new HashSet<VendorLocationPaymentType>();
            this.VendorLocationPostalCodes = new HashSet<VendorLocationPostalCode>();
            this.VendorLocationProducts = new HashSet<VendorLocationProduct>();
            this.PurchaseOrders = new HashSet<PurchaseOrder>();
        }
    
        public int ID { get; set; }
        public int VendorID { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<decimal> Latitude { get; set; }
        public Nullable<decimal> Longitude { get; set; }
        public System.Data.Entity.Spatial.DbGeography GeographyLocation { get; set; }
        public string Email { get; set; }
        public string BusinessHours { get; set; }
        public string DealerNumber { get; set; }
        public Nullable<bool> IsOpen24Hours { get; set; }
        public bool IsActive { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public Nullable<bool> IsKeyDropAvailable { get; set; }
        public Nullable<bool> IsOvernightStayAllowed { get; set; }
        public Nullable<bool> IsDirectTow { get; set; }
        public string PartsAndAccessoryCode { get; set; }
        public Nullable<int> VendorLocationStatusID { get; set; }
        public string DispatchNote { get; set; }
        public Nullable<bool> IsElectronicDispatchAvailable { get; set; }
        public Nullable<bool> IsOvernightStorageAvailable { get; set; }
        public Nullable<bool> IsUsingZipCodes { get; set; }
        public Nullable<bool> IsAbleToCrossStateLines { get; set; }
        public Nullable<bool> IsAbleToCrossNationalBorders { get; set; }
        public string DispatchEmail { get; set; }
    
        public virtual ICollection<ContractRateScheduleProduct> ContractRateScheduleProducts { get; set; }
        public virtual ICollection<ContractRateScheduleProductLog> ContractRateScheduleProductLogs { get; set; }
        public virtual Vendor Vendor { get; set; }
        public virtual ICollection<VendorLocationVirtual> VendorLocationVirtuals { get; set; }
        public virtual VendorLocationStatu VendorLocationStatu { get; set; }
        public virtual ICollection<VendorLocationBusinessHour> VendorLocationBusinessHours { get; set; }
        public virtual ICollection<VendorLocationPaymentType> VendorLocationPaymentTypes { get; set; }
        public virtual ICollection<VendorLocationPostalCode> VendorLocationPostalCodes { get; set; }
        public virtual ICollection<VendorLocationProduct> VendorLocationProducts { get; set; }
        public virtual ICollection<PurchaseOrder> PurchaseOrders { get; set; }
    }
}
