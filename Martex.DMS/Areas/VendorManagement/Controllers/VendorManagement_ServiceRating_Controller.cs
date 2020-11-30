using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.Areas.VendorManagement.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Model;
using System.Text;
using Martex.DMS.BLL.SMTPSettings;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.Common;


namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    public partial class VendorHomeController
    {
        /// <summary>
        /// _Returns partial view of  the vendor_ service rating.
        /// </summary>
        /// <param name="vendorID">The vendor unique identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_ServiceRating(int vendorID)
        {
            VendorManagementFacade facade = new VendorManagementFacade();
            ViewData["VendorID"] = vendorID.ToString();
            List<VendorServiceRatings_Result> list = facade.GetServiceRatings(vendorID);
            return PartialView(list);
        }

        /// <summary>
        /// Returns partial view of vendor_ location_ service rating.
        /// </summary>
        /// <param name="vendorID">The vendor unique identifier.</param>
        /// <param name="vendorLocationID">The vendor location unique identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_ServiceRating(int vendorID, int vendorLocationID)
        {
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorLocationServiceRatings_Result> list = facade.GetLocationServiceRatings(vendorLocationID);
            ViewData["VendorID"] = vendorID.ToString();
            ViewData["VendorLocationID"] = vendorLocationID.ToString();
            ViewData["Products"] = list.ToSelectListItem<VendorLocationServiceRatings_Result>(x => x.ID.ToString(), y => y.Name, true);
            return PartialView(list);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult GetVendorLocationProductServiceRating(int serviceRatingID)
        {
            VendorLocationProduct vlp = facade.GetVendorLocationProductServiceRating(serviceRatingID);
            decimal rating = vlp.Rating.HasValue ? vlp.Rating.Value : 0;
            return Json(new { Rating = rating }, JsonRequestBehavior.AllowGet);
        }

        public ActionResult SaveVendorLocationProductServiceRating(int serviceRatingID, decimal serviceRating, int vendorLocationID)
        {
            OperationResult result = new OperationResult();

            try
            {
                facade.SaveVendorLocationProductServiceRating(serviceRatingID, serviceRating, LoggedInUserName,Request.RawUrl,Session.SessionID);
                result.Status = "Success";
                List<VendorLocationServiceRatings_Result> list = facade.GetLocationServiceRatings(vendorLocationID);
                result.Data = list;
            }
            catch (Exception ex)
            {
                throw new DMSException(ex.Message, ex.InnerException);
            }
            return Json(result, JsonRequestBehavior.AllowGet);

        }
    }
}
