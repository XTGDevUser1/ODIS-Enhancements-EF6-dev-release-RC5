using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using log4net;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade.VendorPortal;
using Martex.DMS.BLL.Model;
using Martex.DMS.Models;

namespace Martex.DMS.Controllers
{
    /// <summary>
    /// Home Controller
    /// </summary>
    public class HomeController : Controller
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(HomeController));
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_TOP_DISPATCH)]
        public ActionResult Index()
        {
            DashBoardFacade facade = new DashBoardFacade();
            DispatchDashBoardModel model = new DispatchDashBoardModel();
            model = facade.GetDispatchDashBoardModel();
            return View(model);
        }

        /// <summary>
        /// Abouts this instance.
        /// </summary>
        /// <returns></returns>
        public ActionResult About()
        {
            return View();
        }

        public ActionResult BingMapServiceDown()
        {
            logger.Info("Bing Map Service Down");
            OperationResult result = new OperationResult();
            EventLoggerFacade facade = new EventLoggerFacade();
            Dictionary<string, string> eventDetails = new Dictionary<string, string>();
            eventDetails.Add("Service", "Bing Map Service Down");
            facade.LogEvent(Request.RawUrl, EventNames.BING_MAP_SERVICE_DOWN, eventDetails, User.Identity.Name, HttpContext.Session.SessionID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
