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
    public partial class CommentType
    {
    	public CommentType()
        {
            this.Comments = new HashSet<Comment>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
    
        public virtual ICollection<Comment> Comments { get; set; }
    }
}
