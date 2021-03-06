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
    public partial class TrailerType
    {
    	public TrailerType()
        {
            this.Cases = new HashSet<Case>();
            this.TrailerMakeModels = new HashSet<TrailerMakeModel>();
            this.Vehicles = new HashSet<Vehicle>();
            this.MakeModels = new HashSet<MakeModel>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string ImageFile { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
    
        public virtual ICollection<Case> Cases { get; set; }
        public virtual ICollection<TrailerMakeModel> TrailerMakeModels { get; set; }
        public virtual ICollection<Vehicle> Vehicles { get; set; }
        public virtual ICollection<MakeModel> MakeModels { get; set; }
    }
}
