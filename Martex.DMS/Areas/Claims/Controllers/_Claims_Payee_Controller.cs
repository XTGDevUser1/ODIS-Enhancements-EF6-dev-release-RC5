using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.ActionFilters;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.Claims.Controllers
{
    public partial class ClaimController
    {
        //
        // GET: /Claims/_Claims_Payee_/

        public ActionResult _Claims_Payee(int suffixClaimID)
        {
            return View();
        }

    }
}
