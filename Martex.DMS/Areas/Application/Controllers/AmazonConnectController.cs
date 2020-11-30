using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.Areas.Application.Controllers
{
    public class AmazonConnectController : Controller
    {

        /// <summary>
        /// Returns the view page for custom CCP
        /// </summary>
        /// <returns></returns>
        public ActionResult Index()
        {
            return View();
        }

    }
}
