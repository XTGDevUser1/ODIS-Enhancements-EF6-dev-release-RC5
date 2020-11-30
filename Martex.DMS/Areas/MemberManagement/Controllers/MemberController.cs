using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Controllers;
using Martex.DMS.BLL.Facade;

using Martex.DMS.BLL.Model;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.Areas.Application.Models;
using System.Text;
using System.Xml;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    [DMSAuthorize]
    partial class MemberController : VehicleBaseController
    {
        public ActionResult _MemberShipInfo()
        {
            return PartialView();
        }

        public ActionResult BindMembershipMember(int membershipID)
        {
            var facade = new MemberManagementFacade();
            logger.InfoFormat("Get Members related to the Membership whose ID is :{0} ", membershipID);

            ViewData[StaticData.MemberManagementMembers.ToString()] = facade.GetMembersByMembershipID(membershipID).ToSelectListItem(x => x.Value, y => y.Text);
            IEnumerable<SelectListItem> list = null;
            list = facade.GetMembersByMembershipID(membershipID).ToSelectListItem(x => x.Value, y => y.Text);
            logger.InfoFormat("Get the Vendor Locations of count:{0}", list.Count());
            return Json(list, JsonRequestBehavior.AllowGet);
        }

    }
}
