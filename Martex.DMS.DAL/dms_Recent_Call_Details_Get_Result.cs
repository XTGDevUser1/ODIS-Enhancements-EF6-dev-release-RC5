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
    
    [Serializable] 
    public partial class dms_Recent_Call_Details_Get_Result
    {
        public int ID { get; set; }
        public Nullable<int> ContactCategoryID { get; set; }
        public Nullable<int> ContactTypeID { get; set; }
        public Nullable<int> ContactMethodID { get; set; }
        public Nullable<int> ContactSourceID { get; set; }
        public string Company { get; set; }
        public string TalkedTo { get; set; }
        public Nullable<int> PhoneTypeID { get; set; }
        public string PhoneNumber { get; set; }
        public string Email { get; set; }
        public string Direction { get; set; }
        public string Description { get; set; }
        public string Data { get; set; }
        public string Comments { get; set; }
        public Nullable<int> AgentRating { get; set; }
        public Nullable<bool> IsPossibleCallback { get; set; }
        public Nullable<System.DateTime> DataTransferDate { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public Nullable<decimal> VendorServiceRatingAdjustment { get; set; }
    }
}
