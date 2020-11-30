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
    /// QA Tasks Controller
    /// </summary>
    public class CXTasksController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [ValidateInput(false)]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_QA_TASKS)]
        public ActionResult Index()
        {
            return View();
        }

    }
}
