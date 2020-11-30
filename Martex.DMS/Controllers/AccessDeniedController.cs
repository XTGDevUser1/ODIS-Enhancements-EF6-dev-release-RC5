using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Martex.DMS.Controllers
{
    /// <summary>
    /// Access Denied Controller
    /// </summary>
    public class AccessDeniedController : Controller
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        public ActionResult Index()
        {
            return View("AccessDenied");
        }

    }
}
