using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.DAL.Common;
using VendorPortal.Common;
using VendorPortal.ActionFilters;
using VendorPortal.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Model;
using Newtonsoft.Json;

namespace VendorPortal.Areas.ISP.Controllers
{
    public partial class VendorLocationController
    {
        VendorManagementFacade facade = new VendorManagementFacade();
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_Service(int vendorID, int vendorLocationID)
        {
            logger.InfoFormat("Trying to load Vendor Location Service Details for Vendor ID {0}", vendorLocationID);
            VendorLocationServiceAreaModel model = facade.GetServiceAreaDetails(vendorLocationID, vendorID);
            ViewData["VendorLocationID"] = vendorLocationID.ToString();
            ViewData["VendorID"] = vendorID.ToString();
            logger.InfoFormat("Execution Finished for the Vendor Service Details with Vendor ID {0} and VendorLocationID {1}", vendorID, vendorLocationID);
            return PartialView(model);
        }

        [HttpPost, ValidateInput(false)]
        public ActionResult _SaveVendorLocationServiceArea(VendorLocationServiceAreaModel model)
        {

            logger.InfoFormat("VendorLocationController --> _SaveVendorLocationServiceArea :  {0}", JsonConvert.SerializeObject(new
            {
                VendorLocationID = model.VendorLocationID,
                IsAbleToCrossStateLines = model.IsAbleToCrossStateLines,
                IsUsingZipCodes = model.IsUsingZipCodes,
                IsAbleToCrossNationalBorders = model.IsAbleToCrossNationalBorders,
                IsVirtualLocationEnabled = model.IsVirtualLocationEnabled,
                PrimaryZipCodesAsCSV = model.PrimaryZipCodesAsCSV,
                SecondaryZipCodesAsCSV = model.SecondaryZipCodesAsCSV
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            VendorManagementFacade facade = new VendorManagementFacade();
            facade.SaveServiceAreaDetails(model, LoggedInUserName);

            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
