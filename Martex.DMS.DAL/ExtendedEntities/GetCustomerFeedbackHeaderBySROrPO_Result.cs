using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.DAL
{
    public partial class GetCustomerFeedbackHeaderBySROrPO_Result
    {
        public string SubmittedDateFormatted
        {
            get
            {
                if(this.SubmittedDate == null)
                {
                    return string.Empty;
                }
                return this.SubmittedDate.Value.ToString("M/d/yyyy");
            }
        }

        public bool IsSRExists { get; set; }
    }
}
