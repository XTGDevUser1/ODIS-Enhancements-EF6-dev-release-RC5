using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL
{
    public partial class MembershipManagementActivityList_Result
    {
        public string FormattedCreateDate
        {
            get
            {
                string formattedDate = string.Empty;
                if (this.CreateDate != null)
                {
                    formattedDate = this.CreateDate.Value.ToString("ddd, MMMM dd, yyyy h:mm:ss tt") + " CDT";
                }
                return formattedDate;
            }
        }
    }
}
