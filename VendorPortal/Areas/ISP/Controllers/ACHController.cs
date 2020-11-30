using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using VendorPortal.ActionFilters;
using VendorPortal.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Facade;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAO;
using VendorPortal.Common;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade.VendorPortal;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using System.Web.Hosting;
using System.IO;

namespace VendorPortal.Areas.ISP.Controllers
{
    [DMSAuthorize]
    public class ACHController : BaseController
    {

        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ACHAccountType, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.Country, true)]
        [DMSAuthorize(Securable=DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_ACH)]
        public ActionResult Index()
        {
            #region Validate Request
            RegisterUserModel model = Session["LOGGED_IN_USER"] as RegisterUserModel;
            if (model == null || !model.VendorID.HasValue)
            {
                logger.Info("Unable to retrieve logged in user details from session so redirect user to Login page");
                return RedirectToAction("Login", "Account", new { area = "" });
            }
            #endregion

            ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);

            var facade = new VendorPortalACHFacade();
            VendorACH achModel = facade.GetVendorACHDetails(model.VendorID.Value);
            if (achModel.BankAddressCountryID.HasValue)
            {
                ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(achModel.BankAddressCountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }
            return View(achModel);
        }

        /// <summary>
        /// _s the sign up vendor ACH.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        [ReferenceDataFilter(StaticData.ACHAccountType, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.Country, true)]
        [ReferenceDataFilter(StaticData.Province, true)]
        public ActionResult _SignUpVendorACH(int vendorID)
        {
            logger.InfoFormat("Executing Signup for Vendor ACH with a given vendor ID {0}", vendorID);
            var facade = new VendorPortalACHFacade();
            var lookUp = new CommonLookUpRepository();
            facade.LogEventForSignUp(Session.SessionID, vendorID, LoggedInUserName);
            VendorACH model = new VendorACH();
            model.VendorID = vendorID;
            Country country = lookUp.GetCountryByName("United States");
            if (country != null)
            {
                model.BankAddressCountryID = country.ID;
            }
            return PartialView("_ACHRegistration", model);
        }

        /// <summary>
        /// Completes the sign up for vendor ACH.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        public ActionResult CompleteSignUpForVendorACH(VendorACH model, HttpPostedFileBase ACHVoidedCheck)
        {
            logger.InfoFormat("Executing Complete Signup for Vendor ACH with a given vendor ID {0}", model.VendorID);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            var facade = new VendorPortalACHFacade();
            facade.CompleteSignUpForVendorACH(model, LoggedInUserName, Session.SessionID, ACHVoidedCheck);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// Updates the ACH details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        public ActionResult UpdateACHDetails(VendorACH model, HttpPostedFileBase ACHVoidedCheck)
        {
            logger.InfoFormat("Executing Update for Vendor ACH with a given vendor ID {0}", model.VendorID);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            var facade = new VendorPortalACHFacade();
            facade.UpdateACHDetails(model, LoggedInUserName, Session.SessionID, ACHVoidedCheck);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Turns the onor off ACH.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        public ActionResult TurnOnorOffACH(VendorACH model)
        {
            logger.InfoFormat("Executing Turn on or Off for Vendor ACH with a given vendor ID {0}", model.VendorID);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            var facade = new VendorPortalACHFacade();
            model.IsActive = false;
            facade.TurnOnOrOffVendorACH(model, LoggedInUserName, Session.SessionID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

    }
}
