using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade.DigitalDispatch;
using Martex.DMS.BLL.Model.DigitalDispatch;
using Martex.DMS.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Martex.DMS.Areas.DigitalDispatch.Controllers
{
    public class DSIController : BaseController
    {
        DigitalDispatchFacade facade = new DigitalDispatchFacade();
        //
        // GET: /DigitalDispatch/DSI/

        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public ActionResult SubmitDSI(DSIModel model)
        {
            OperationResult result = new OperationResult();
            result.Data = facade.Dsi(model);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

    }
}
