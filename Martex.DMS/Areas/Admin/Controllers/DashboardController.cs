using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;

namespace Martex.DMS.Areas.Admin.Controllers
{
    public class DashboardController : BaseController
    {
        [DMSAuthorize]
        public ActionResult Index()
        {
            return View();
        }

    }
}
