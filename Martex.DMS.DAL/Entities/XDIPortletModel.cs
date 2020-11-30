using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class PortletModel
    {
        public List<PortletSection> Sections { get; set; }
        public List<DashboardPortlets_Result> Portlets { get; set; }
    }

    public class PortletPositionsModel
    {
        public int ColPosition { get; set; }
        public int RowPosition { get; set; }
        public int PortletID { get; set; }
    }
}
