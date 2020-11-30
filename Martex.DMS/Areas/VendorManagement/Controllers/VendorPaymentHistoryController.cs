using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    public class VendorPaymentHistoryController : BaseController
    {
        public ActionResult Index()
        {
            return View();
        }
    }
}
