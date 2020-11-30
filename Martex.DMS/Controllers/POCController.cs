using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.Areas.Common.Controllers;
using Microsoft.AspNet.SignalR;
using Martex.DMS.Hubs;

namespace Martex.DMS.Controllers
{
    public class ChatUsers
    {
        public int UserID { get; set; }
        public string UserName { get; set; }
        public bool IsOnline { get; set; }
    }
    /// <summary>
    /// POC Controller
    /// </summary>
    public class POCController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [AllowAnonymous]
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult ChatUsers()
        {
            JsonResult result = new JsonResult();
            List<ChatUsers> Users = new List<ChatUsers>();
            Users.Add(new ChatUsers() { IsOnline = true, UserID = 1, UserName = "Krishna" });
            Users.Add(new ChatUsers() { IsOnline = false, UserID = 2, UserName = "Hemant" });
            Users.Add(new ChatUsers() { IsOnline = true, UserID = 3, UserName = "Kiran" });
            return Json(Users, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Orgses the specified feedback types.
        /// </summary>
        /// <param name="FeedbackTypes">The feedback types.</param>
        /// <returns></returns>
        public ActionResult Orgs(string FeedbackTypes)
        {
            List<SelectListItem> list = new List<SelectListItem>();
            list.Add(new SelectListItem() { Text = FeedbackTypes, Value = "ABC - " + FeedbackTypes });
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Drops the down1.
        /// </summary>
        /// <returns></returns>
        public ActionResult DropDown1()
        {
            List<SelectListItem> list = new List<SelectListItem>();
            list.Add(new SelectListItem() { Text = "From Server", Value = "1" });
            ViewData["controlFor"] = "Organization";
            return PartialView("_Dropdown", list);
        }
    }
}
