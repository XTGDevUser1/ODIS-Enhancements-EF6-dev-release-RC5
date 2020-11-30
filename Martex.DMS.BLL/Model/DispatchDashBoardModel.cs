using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    public class DispatchDashBoardModel
    {
        public List<DashboardDispatchChart_Result> DashboardDispatchChart { get; set; }
        public List<Message> DashboardMessages { get; set; }
        public List<DashboardServiceRequestCount_Result> DashboardSRCount { get; set; }
        public List<DashboardDispatchChartLabels_Result> DashboardDispatchChartLabels { get; set; }
    }
}
