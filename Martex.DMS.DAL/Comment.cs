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
    public partial class Comment
    {
        public int ID { get; set; }
        public Nullable<int> CommentTypeID { get; set; }
        public Nullable<int> EntityID { get; set; }
        public Nullable<int> RecordID { get; set; }
        public string Description { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
    
        public virtual CommentType CommentType { get; set; }
        public virtual Entity Entity { get; set; }
    }
}
