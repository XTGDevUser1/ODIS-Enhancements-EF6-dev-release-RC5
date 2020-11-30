using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using Martex.DMS.BLL.Model;
using VendorPortal.ActionFilters;
using Martex.DMS.BLL.Facade;
using VendorPortal.Models;

namespace VendorPortal.Areas.ISP.Controllers
{
    public class VendorServicesController : BaseController
    {
        /// <summary>
        /// Get the vendor services.
        /// </summary>
        /// <param name="vendorID">The Vendor ID.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult _Vendor_Service(int? vendorID)
        {
            logger.InfoFormat("Trying to load Vendor Service Details for Vendor ID {0}", vendorID);
            VendorManagementFacade facade = new VendorManagementFacade();
            VendorPortalServiceModel model = new VendorPortalServiceModel();
            if (vendorID != null)
            {
                model = facade.GetVendorPortalServiceDetails(vendorID.GetValueOrDefault());
            }
            else
            {
                logger.Warn("Executing _Vendor_Service in VendorServicesController, vendorID is null");
            }

            logger.InfoFormat("Execution Finished for the Vendor Service Details with Vendor ID {0}", vendorID);
            return PartialView(model);
        }

        /// <summary>
        /// Saves the vendor services.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost, ValidateInput(false)]
        public ActionResult SaveVendorServices(VendorServiceModel model)
        {
            OperationResult result = new OperationResult();
            try
            {
                VendorManagementFacade facade = new VendorManagementFacade();
                logger.InfoFormat("Trying to Save Vendor Service Information with Vendor ID:{0}", model.VendorID);
                facade.SaveVendorServices(model, LoggedInUserName);
                logger.InfoFormat("Added Vendor Services and Repairs Successfully");
                result.Status = "Success";
            }
            catch (Exception Ex)
            {
                logger.Info(Ex);
                result.Status = "Failure";
                result.ErrorMessage = Ex.ToString();
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_Service_Repairs(int vendorID, int vendorLocationID)
        {
            VendorManagementFacade facade = new VendorManagementFacade();
            logger.InfoFormat("Trying to load Vendor Service Details for Vendor ID {0} and Vendor Location ID:{1}", vendorID, vendorLocationID);
            VendorPortalLocationServiceModel model = new VendorPortalLocationServiceModel();
            model = facade.GetVendorPortalLocationServicesList(vendorID, vendorLocationID);
            logger.InfoFormat("Execution Finished for the Vendor Service Details with Vendor ID {0} Vendor Location ID:{1}", vendorID, vendorLocationID);
            return PartialView(model);
        }

        /// <summary>
        /// Saves the vendor location services.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [DMSAuthorize, ValidateInput(false)]
        public ActionResult SaveVendorLocationServices(VendorPortalLocationServiceModel model)
        {
            OperationResult result = new OperationResult();
            VendorManagementFacade facade = new VendorManagementFacade();
            logger.InfoFormat("Trying to Save Vendor Location Service Information with Vendor ID:{0}", model.VendorID);
            facade.SaveVendorPortalLocationServices(model, LoggedInUserName);
            logger.InfoFormat("Added Vendor Location Services and Repairs Successfully");
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }


    }
}
