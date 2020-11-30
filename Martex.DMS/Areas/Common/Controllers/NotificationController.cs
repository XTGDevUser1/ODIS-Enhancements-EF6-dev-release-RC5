using System.Collections.Generic;
using System.Web.Mvc;
using Martex.DMS.Models;
using Martex.DMS.Areas.Common.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.ActionFilters;
using Martex.DMS.Common;
using Martex.DMS.BLL.Facade;

namespace Martex.DMS.Areas.Common.Controllers
{
    [DMSAuthorize]
    public class NotificationController : BaseController
    {
        //
        // GET: /Common/Notification/

        public ActionResult Index()
        {
            return View();
        }

        public ActionResult GetUsersOrRolesRecipents(int? notificationRecipentID)
        {
            OperationResult result = new OperationResult();
            List<UsersOrRolesForNotification_Result> list = new NotificationRepository().GetUsersOrRolesForNotification(notificationRecipentID);
            result.Data = list.ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [ValidateInput(false)]
        public ActionResult SendNotificationMessage(NotificationModel model)
        {
            OperationResult result = new OperationResult();

            var facade = new EventLoggerFacade();
            facade.LogManualNotificationEvent(Request.RawUrl, Session.SessionID, model.NotificationMessage, LoggedInUserName, model.NotificationRecipentType, model.NotificationSeconds, string.Join(",", model.NotificationUserRoleID));

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the notification history.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        public ActionResult GetNotificationHistory()
        {
            var facade = new CommunicationServiceFacade();
            var list = facade.GetNotificationHistory(LoggedInUserName);
           
            return PartialView("_NotificationHistory", list);
        }
    }
}
