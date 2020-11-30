using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Facade;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    public partial class MemberController
    {
        [DMSAuthorize]
        public ActionResult _Member_Vehicles(int memberID, int memberShipID)
        {
            return PartialView();
        }
    }
}
