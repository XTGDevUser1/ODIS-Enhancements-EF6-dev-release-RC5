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
    public partial class RVMakeModel
    {
        public int ID { get; set; }
        public Nullable<int> RVTypeID { get; set; }
        public string Make { get; set; }
        public string Model { get; set; }
        public Nullable<bool> IsSportUtility { get; set; }
        public Nullable<int> VehicleCategoryID { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public Nullable<int> WarrantyPeriod { get; set; }
        public string WarrantyPeriodUOM { get; set; }
        public Nullable<int> WarrantyMileageMiles { get; set; }
        public Nullable<int> WarrantyMileageKilometers { get; set; }
    
        public virtual RVType RVType { get; set; }
        public virtual VehicleCategory VehicleCategory { get; set; }
    }
}
