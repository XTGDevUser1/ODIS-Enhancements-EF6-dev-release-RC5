using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;

namespace Martex.DMS.Areas.Reports.Controllers
{
    /// <summary>
    /// System Report Controller
    /// </summary>
    public class SystemReportController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_SECOND_REPORTS_SYSTEM)]
        public ActionResult Index()
        {
            return View();
        }

    }
}
