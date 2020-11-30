using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;

namespace Martex.DMS.Areas.Claims.Controllers
{
    public partial class ClaimController
    {
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ClaimDocuments(int suffixClaimID)
        {
            return PartialView(suffixClaimID);
        }
    }
}
