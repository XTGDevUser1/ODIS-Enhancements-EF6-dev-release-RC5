using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.Common;
namespace Martex.DMS.Areas.QA.Controllers
{
    public partial class CXCustomerFeedbackController
    {
        //
        // GET: /CX/CustomerFeedbackDocument/

        public ActionResult _CustomerFeedback_Documents(int? id)
        {

            logger.InfoFormat("Trying to load documents for the  Customer Feedback ID {0}", id);
            ViewData["CustomerFeedBackId"] = id.GetValueOrDefault().ToString();
            return PartialView(id);
        }

    }
}
