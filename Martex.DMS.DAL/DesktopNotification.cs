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
    public partial class DesktopNotification
    {
        public long NotificationID { get; set; }
        public string UserName { get; set; }
        public string ConnectionID { get; set; }
        public string UserAgent { get; set; }
        public bool IsConnected { get; set; }
    }
}
