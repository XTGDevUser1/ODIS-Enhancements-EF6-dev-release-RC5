using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL
{
    public partial class ServiceRequest_Result
    {
        public string FormattedElapsedTime
        {
            get
            {
                if (this.Elapsed == null)
                {
                    return string.Empty;
                }
                int intElapsed = 0;
                int.TryParse(this.Elapsed, out intElapsed);

                int totalMinutes = intElapsed / 60;
                int totalSeconds = intElapsed % 60;
                int totalHours = (int)totalMinutes / 60;
                totalMinutes = totalMinutes % 60;

                return string.Format("{0:d2}:{1:d2}:{2:d2}", totalHours, totalMinutes, totalSeconds);
            }
        }
    }
}
