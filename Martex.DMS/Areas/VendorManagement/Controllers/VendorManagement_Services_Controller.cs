using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Models;

using Martex.DMS.BLL.Model;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    /// <summary>
    /// VendorHomeController
    /// </summary>
    public partial class VendorHomeController
    {
        /// <summary>
        /// _s the vendor_ location_ service_ repairs.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <param name="vendorLocationID">The vendor location identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_Service_Repairs(int vendorID, int vendorLocationID)
        {
            logger.InfoFormat("Trying to load Vendor Service Details for Vendor ID {0} and Vendor Location ID:{1}", vendorID, vendorLocationID);
            var model = facade.GetVendorLocationServiceDetails(vendorID, vendorLocationID);
            logger.InfoFormat("Execution Finished for the Vendor Service Details with Vendor ID {0} Vendor Location ID:{1}", vendorID, vendorLocationID);
            return PartialView(model);
        }

        /// <summary>
        /// Saves the vendor location services.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult SaveVendorLocationServices(VendorLocationServiceModel model)
        {
            var result = new OperationResult();
            logger.InfoFormat("Trying to Save Vendor Location Service Information with Vendor ID:{0}", model.VendorID);
            facade.SaveVendorLocationServices(model, LoggedInUserName);
            logger.InfoFormat("Added Vendor Location Services and Repairs Successfully");
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
