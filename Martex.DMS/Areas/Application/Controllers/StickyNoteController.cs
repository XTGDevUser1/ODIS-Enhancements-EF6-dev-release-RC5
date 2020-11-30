using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Models;
using Martex.DMS.ActionFilters;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class StickyNoteController : Controller
    {
        #region Public Methods
        /// <summary>
        /// Display Sticky Notes
        /// </summary>
        /// <param name="model">The model.</param>
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
