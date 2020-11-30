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
    public partial class CustomerFeedbackDetail
    {
        public int ID { get; set; }
        public int CustomerFeedbackID { get; set; }
        public int CustomerFeedbackTypeID { get; set; }
        public Nullable<int> CustomerFeedbackCategoryID { get; set; }
        public Nullable<int> CustomerFeedbackSubCategoryID { get; set; }
        public string ResolutionDescription { get; set; }
        public Nullable<int> UserID { get; set; }
        public Nullable<int> VendorLocationID { get; set; }
        public Nullable<int> CoachingID { get; set; }
        public Nullable<bool> IsInvalid { get; set; }
        public Nullable<int> CustomerFeedbackInvalidReasonID { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    
        public virtual CustomerFeedbackCategory CustomerFeedbackCategory { get; set; }
        public virtual CustomerFeedbackInvalidReason CustomerFeedbackInvalidReason { get; set; }
        public virtual CustomerFeedbackSubCategory CustomerFeedbackSubCategory { get; set; }
        public virtual CustomerFeedbackType CustomerFeedbackType { get; set; }
        public virtual CustomerFeedback CustomerFeedback { get; set; }
    }
}
