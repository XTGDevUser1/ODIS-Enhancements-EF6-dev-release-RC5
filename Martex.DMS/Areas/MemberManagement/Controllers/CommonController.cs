using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Models;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    public class CommonController : BaseController
    {
        /// <summary>
        /// Deletes the excluded vendor.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult DeleteExcludedVendor(int recordID)
        {
            var repository = new MemberManagementRepository();
            logger.InfoFormat("Trying to delete excluded vendor for the given ID {0} ", recordID);
            OperationResult result = new OperationResult();
            repository.DeleteExcludedVendor(recordID, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Record Deleted Successfully");
            return Json(result);
        }

        /// <summary>
        /// Gets the excluded vendor list.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult GetExcludedVendorList(int membershipID)
        {
            logger.InfoFormat("Trying to load excluded vendor list for the membership id {0}", membershipID);
            ExcludedVendorExtended model = new ExcludedVendorExtended();
            model.MemberShipID = membershipID;
            logger.InfoFormat("Execution finished");
            return PartialView("_ScrollableExcludedVendors", model);
        }

        /// <summary>
        /// Gets the excluded vendor.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public ActionResult GetExcludedVendor(int membershipID)
        {
            ExcludedVendorItem model = new ExcludedVendorItem();
            model.MembershipID = membershipID;
            return PartialView("_ExcludedVendorGet", model);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveExcludedVendor(ExcludedVendorItem model)
        {
            logger.InfoFormat("Trying to Add excluded vendor for the given Vendor ID {0} and Vendor Number {1}", model.VendorID, model.VendorNumber);
            OperationResult result = new OperationResult();
            var repository = new MemberManagementRepository();
            repository.CreateMembershipBlackListVendor(model.VendorID, model.MembershipID, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Record Created Successfully");
            return Json(result);
        }

    }
}
