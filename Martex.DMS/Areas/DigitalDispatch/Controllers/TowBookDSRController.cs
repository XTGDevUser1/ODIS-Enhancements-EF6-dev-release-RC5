using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade.DigitalDispatch;
using Martex.DMS.BLL.Model.DigitalDispatch;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.DigitalDispatch.Controllers
{
    public class TowBookDSRController : BaseController
    {
        DigitalDispatchFacade facade = new DigitalDispatchFacade();
        //
        // GET: /DigitalDispatch/TowBookDSR/

        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public ActionResult TowBookDSR(DSRModel model)
        {
            OperationResult result = new OperationResult();
            result.Data = facade.TowBookDSR(model);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

    }
}
