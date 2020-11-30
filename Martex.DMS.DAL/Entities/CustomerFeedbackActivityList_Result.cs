using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.DAL
{
    public partial class CustomerFeedbackActivityList_Result
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
