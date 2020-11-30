﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    /// <summary>
    /// Client Members Controller
    /// </summary>
    public class ClientMembersController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CLIENT_MEMBERS)]
        public ActionResult Index()
        {
            return View();
        }

    }
}
