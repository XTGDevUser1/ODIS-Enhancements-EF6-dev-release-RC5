using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_TOP_VENDOR)]
    public class VendorDashboardController : BaseController
    {
        #region Private Members
        PortletsRepository portletService;
        #endregion

        #region Constructor
        public VendorDashboardController()
        {
            portletService = new PortletsRepository();
        }
        #endregion

        public ActionResult Index()
        {
            PortletModel model = new PortletModel(); //KB: To be enabled later: portletService.GetPortletModel(GetLoggedInUserId(), "Vendor");
            return View(model);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        public ActionResult SaveDashBoardPositions(List<PortletPositionsModel> positions)
        {
            OperationResult result = new OperationResult();
            portletService.Save(positions, LoggedInUserName, GetLoggedInUserId());
            return Json(result);
        }

        public ActionResult TOP_VENDORS(int id)
        {
            return PartialView(portletService.Get(id));
        }

        public ActionResult VENDORS_ISSUES(int id)
        {
            return PartialView(portletService.Get(id));
        }

        public ActionResult NEXT_EVENTS(int id)
        {
            return PartialView(portletService.Get(id));
        }

        public ActionResult NEWS(int id)
        {
            return PartialView(portletService.Get(id));
        }

        public ActionResult RATINGS(int id)
        {
            return PartialView(portletService.Get(id));
        }

        public ActionResult FEEDBACK(int id)
        {
            return PartialView(portletService.Get(id));
        }

    }
}
