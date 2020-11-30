using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;

namespace Martex.DMS.Areas.QA.Controllers
{
    public partial class CXCustomerFeedbackController
    {
        public ActionResult _CustomerFeedback_SR(int? id)
        {
            CustomerFeedback feedback = facade.GetCustomerFeedbackById(id);
            ViewData["ServiceRequestId"] = feedback.ServiceRequestID.GetValueOrDefault().ToString();
            return PartialView();
        }
    }
}
