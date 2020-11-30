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
    public partial class AddressType
    {
    	public AddressType()
        {
            this.AddressEntities = new HashSet<AddressEntity>();
            this.AddressTypeEntities = new HashSet<AddressTypeEntity>();
            this.PurchaseOrders = new HashSet<PurchaseOrder>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public bool IsActive { get; set; }
        public Nullable<int> Sequence { get; set; }
    
        public virtual ICollection<AddressEntity> AddressEntities { get; set; }
        public virtual ICollection<AddressTypeEntity> AddressTypeEntities { get; set; }
        public virtual ICollection<PurchaseOrder> PurchaseOrders { get; set; }
    }
}
