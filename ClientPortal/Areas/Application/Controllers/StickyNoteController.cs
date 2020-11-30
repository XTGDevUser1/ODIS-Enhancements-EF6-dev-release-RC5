using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Models;
using ClientPortal.ActionFilters;

namespace ClientPortal.Areas.Application.Controllers
{
    public class StickyNoteController : Controller
    {
        #region Public Methods
        /// <summary>
        /// Display Sticky Notes
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        public ActionResult Index(StickyNoteModel model)
        {   
            Session["stickyNote"] = model;
            return Json(new { success = true });
        }
        #endregion

    }
}
