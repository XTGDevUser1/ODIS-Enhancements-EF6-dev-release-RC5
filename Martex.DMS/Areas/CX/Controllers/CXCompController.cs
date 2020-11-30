using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;

namespace Martex.DMS.Areas.QA.Controllers
{
    /// <summary>
    /// CX Comp Controller
    /// </summary>
    [ValidateInput(false)]
    public class CXCompController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_QA_COMP)]
        public ActionResult Index()
        {
            return View();
        }

    }
}
