using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Mvc;
using System.Web.Script.Serialization;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.BLL.Facade;

namespace Martex.DMS.Areas.Common.Controllers
{
    public class ProgramDataItemsController : Controller
    {
        //
        // GET: /Common/ProgramDataItems/
        /// <summary>
        /// Get program data items for a program and a screen name.
        /// </summary>
        /// <param name="id">The screen name</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult Index(string screenName)
        {
            var questions = CallLogFacade.GetProgramDataItems(DMSCallContext.ProgramID, screenName);
            // JSONify Questions.
            JavaScriptSerializer jsonSerializer = new JavaScriptSerializer();
            StringBuilder jsonQuestions = new StringBuilder();
            jsonSerializer.Serialize(questions, jsonQuestions);
            ViewData["JSON_MODEL"] = jsonQuestions.ToString();
            return PartialView(questions);
        }

    }
}
