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
    public partial class PersonNotificationTiming
    {
        public int ID { get; set; }
        public Nullable<int> PersonID { get; set; }
        public Nullable<int> DayOfWeek { get; set; }
        public Nullable<int> MinimumTime { get; set; }
        public Nullable<int> MaximumTime { get; set; }
    
        public virtual Person Person { get; set; }
    }
}
