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
    public partial class HagertyProgramMap
    {
        public int ID { get; set; }
        public string CustomerType { get; set; }
        public string PlanType { get; set; }
        public int ProgramID { get; set; }
    
        public virtual Program Program { get; set; }
    }
}
