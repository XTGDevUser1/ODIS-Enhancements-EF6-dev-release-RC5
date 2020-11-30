using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    
    public class DashboardController : BaseController
    {
        [DMSAuthorize(Securable=DMSSecurityProviderFriendlyName.MENU_TOP_MEMBER)]
        public ActionResult Index()
        {
            return View();
        }

    }
}
