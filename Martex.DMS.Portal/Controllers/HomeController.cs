using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;

namespace Martex.DMS.Portal.Controllers
{
    public class HomeController : Controller
    {
        //
        // GET: /Home/

        public ActionResult Index()
        {
            return View();
        }
        [HttpPost]
        public ActionResult ServiceRequest(string srid, string ponosave)
        {
            QueueFacade queueFacade = new QueueFacade();
            List<ServiceRequest_Result> serviceRequestResult = queueFacade.Get("", Request.RawUrl,0, srid,  false, HttpContext.Session.SessionID);
            ViewData["POID"] = ponosave;
            ViewData["srid"] = srid;
            return View(serviceRequestResult);
        }

    }
}
