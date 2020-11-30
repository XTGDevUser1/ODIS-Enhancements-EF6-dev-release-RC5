using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class DashBoardRepository
    {

        /// <summary>
        /// Gets the dash board list.
        /// </summary>
        /// <returns></returns>
        public List<DashboardDispatchChart_Result> GetDashBoardList()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetDashboardDispatchChart().ToList();
            }
        }
        public List<DashboardDispatchChartLabels_Result> GetDashBoardLabelsList()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetDashboardDispatchChartLabels().ToList();
            }
        }
    }
}
