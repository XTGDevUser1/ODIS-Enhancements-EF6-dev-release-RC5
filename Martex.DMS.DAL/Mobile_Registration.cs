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
    public partial class Mobile_Registration
    {
        public int PKID { get; set; }
        public string MemberNumber { get; set; }
        public string GUID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string MemberDevicePhoneNumber { get; set; }
        public Nullable<bool> ValidGUID { get; set; }
        public Nullable<bool> ActiveMember { get; set; }
        public Nullable<bool> MemberExist { get; set; }
        public Nullable<bool> ValidRegistration { get; set; }
        public string DispatchPhoneNo { get; set; }
        public Nullable<int> ErrorCode { get; set; }
        public string ErrorMessage { get; set; }
        public Nullable<System.DateTime> DateTime { get; set; }
        public string memberDeviceGUID { get; set; }
        public string appOrgName { get; set; }
    }
}
