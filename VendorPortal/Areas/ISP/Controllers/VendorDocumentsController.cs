using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.ActionFilters;
using VendorPortal.Controllers;

namespace VendorPortal.Areas.ISP.Controllers
{
    public class VendorDocumentsController : BaseController
    {
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Documents(int? vendorID)
        {
            logger.InfoFormat("Trying to load documents for the  Vendor ID {0}", vendorID);
            if (vendorID == null)
            {
                logger.Warn("Executing _Vendor_Documents in VendorDocumentsController, vendorID is null");
            }
            ViewData["VendorID"] = vendorID.GetValueOrDefault().ToString();
            return PartialView(vendorID);
        }
    }
}
