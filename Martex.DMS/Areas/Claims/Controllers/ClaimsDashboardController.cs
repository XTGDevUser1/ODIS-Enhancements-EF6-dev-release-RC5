using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.Claims.Controllers
{
    public class ClaimsDashboardController : Controller
    {
        //
        // GET: /Claims/ClaimsDashboard/
        [DMSAuthorize(Securable=DMSSecurityProviderFriendlyName.MENU_TOP_CLAIMS)]
        public ActionResult Index()
        {
            return View();
        }

    }
}
