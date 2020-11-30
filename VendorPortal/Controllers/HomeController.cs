using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;
using VendorPortal.Models;
using VendorPortal.ActionFilters;
using VendorPortal.Common;
using VendorPortal.BLL.Models;
//using VendorPortal.Areas.Common.Controllers;

namespace VendorPortal.Controllers
{
    
    public class HomeController : BaseController
    {
        [AllowAnonymous]
        [NoCache]
        public ActionResult Index()
        {
            LogBrowserInformation();
            return View();
        }

        public ActionResult LoadHelpText(string view)
        {
            return PartialView(view);
        }
    }
}
