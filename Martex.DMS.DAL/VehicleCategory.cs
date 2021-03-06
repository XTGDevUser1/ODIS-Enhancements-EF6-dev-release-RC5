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
    public partial class VehicleCategory
    {
    	public VehicleCategory()
        {
            this.Cases = new HashSet<Case>();
            this.Claims = new HashSet<Claim>();
            this.ProductCategoryQuestionPrograms = new HashSet<ProductCategoryQuestionProgram>();
            this.ProductCategoryQuestionVehicleTypes = new HashSet<ProductCategoryQuestionVehicleType>();
            this.ProgramProductCategories = new HashSet<ProgramProductCategory>();
            this.RVMakeModels = new HashSet<RVMakeModel>();
            this.TrailerMakeModels = new HashSet<TrailerMakeModel>();
            this.Vehicles = new HashSet<Vehicle>();
            this.VehicleTypeVehicleCategories = new HashSet<VehicleTypeVehicleCategory>();
            this.VehicleMakeModels = new HashSet<VehicleMakeModel>();
            this.Products = new HashSet<Product>();
            this.ServiceRequests = new HashSet<ServiceRequest>();
            this.PurchaseOrders = new HashSet<PurchaseOrder>();
            this.MakeModels = new HashSet<MakeModel>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
    
        public virtual ICollection<Case> Cases { get; set; }
        public virtual ICollection<Claim> Claims { get; set; }
        public virtual ICollection<ProductCategoryQuestionProgram> ProductCategoryQuestionPrograms { get; set; }
        public virtual ICollection<ProductCategoryQuestionVehicleType> ProductCategoryQuestionVehicleTypes { get; set; }
        public virtual ICollection<ProgramProductCategory> ProgramProductCategories { get; set; }
        public virtual ICollection<RVMakeModel> RVMakeModels { get; set; }
        public virtual ICollection<TrailerMakeModel> TrailerMakeModels { get; set; }
        public virtual ICollection<Vehicle> Vehicles { get; set; }
        public virtual ICollection<VehicleTypeVehicleCategory> VehicleTypeVehicleCategories { get; set; }
        public virtual ICollection<VehicleMakeModel> VehicleMakeModels { get; set; }
        public virtual ICollection<Product> Products { get; set; }
        public virtual ICollection<ServiceRequest> ServiceRequests { get; set; }
        public virtual ICollection<PurchaseOrder> PurchaseOrders { get; set; }
        public virtual ICollection<MakeModel> MakeModels { get; set; }
    }
}
