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
    public partial class AddressTypeEntity
    {
        public int ID { get; set; }
        public int EntityID { get; set; }
        public int AddressTypeID { get; set; }
        public bool IsShownOnScreen { get; set; }
        public Nullable<int> Sequence { get; set; }
    
        public virtual AddressType AddressType { get; set; }
        public virtual Entity Entity { get; set; }
    }
}
