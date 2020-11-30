using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// ClickToCallModel
    /// </summary>
    public class ClickToCallModel
    {
        public string EventSource { get; set; }
        public string SessionID { get; set; }
        public string DeviceName { get; set; }
        public string PhoneNumber { get; set; }
        public string PhoneUserId { get; set; }
        public string PhonePassword { get; set; }
        public string CurrentUser { get; set; }
        public int UserId { get; set; }
    }
}
