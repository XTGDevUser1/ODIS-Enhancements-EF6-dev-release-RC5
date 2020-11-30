using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Areas.QA.Controllers
{
    public partial class CXCustomerFeedbackController
    {
        //[ReferenceDataFilter(StaticData.MemberShipMembers, false)]
        //[ReferenceDataFilter(StaticData.Province, true)]
        //[ReferenceDataFilter(StaticData.CountryCode, true)]
        //public ActionResult _CustomerFeedback_Member(int id)
        //{
        //    CustomerFeedback model = new CustomerFeedback();            
        //    model = facade.GetCustomerFeedbackById(id);            
        //    return PartialView(model);
        //}
    }
}
