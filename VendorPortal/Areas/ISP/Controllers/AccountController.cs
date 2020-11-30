using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using VendorPortal.Models;
using System.Web.Security;
using System.Collections;
using System.Text;
using System.Net.Mail;
using System.Web.Hosting;
using Commons.Collections;
using NVelocity.App;
using NVelocity;
using System.IO;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.BLL.SMTPSettings;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using VendorPortal.ActionFilters;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.Facade.VendorPortal;
using Martex.DMS.BLL.Model.VendorPortal;
using VendorPortal.Common;

namespace VendorPortal.Areas.ISP.Controllers
{
    [Authorize]
    public class AccountController : BaseController
    {
        VendorPortalFacade facade = new VendorPortalFacade();
        UsersFacade userFacade = new UsersFacade();

        public ActionResult _PasswordTips()
        {
            return PartialView();
        }


        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_ACCOUNT)]
        public ActionResult MyAccount(string defaulttabtoload)
        {
            VendorPortalAccountFacade facade = new VendorPortalAccountFacade();
            VendorManagementFacade vendorManagementfacade = new VendorManagementFacade();

            int vendorID = LoggedInUserVendorID;
            VendorAccountModel model = facade.GetVendorAccountDetails(vendorID);
            model.VendorLocationID = 0;
            List<VendorLocationsList_Result> vendorLocationList = vendorManagementfacade.GetVendorLocationsList(vendorID);
            if (vendorLocationList.Count > 0)
            {
                vendorLocationList[0].LocationAddress = "Billing Information";
            }
            IEnumerable<SelectListItem> list = vendorLocationList.OrderBy(x => x.VendorLocationID).ToSelectListItem(x => x.VendorLocationID.ToString(), y => y.LocationAddress, false);

            ViewData[StaticData.LocationList.ToString()] = new SelectList(list, "Value", "Text");
            if (!string.IsNullOrEmpty(defaulttabtoload) && defaulttabtoload == "VendorDetailsDocumentsTab")
            {
                ViewData["IsDocumentsTabSelected"] = true;
            }

            if (!string.IsNullOrEmpty(defaulttabtoload) && defaulttabtoload == "VendorLocationServiceAreasTab")
            {
                ViewData["IsLocationsServiceAreasTabSelected"] = true;
            }
            return View(model);
        }


        [DMSAuthorize]
        [NoCache]
        public ActionResult _VendorLocationTabs(int vendorID, int vendorLocationID)
        {
            logger.InfoFormat("Inside the method _VendorLocationTabs() in Account with Vendor ID:{0} and Vendor Location ID:{1}", vendorID, vendorLocationID);
            VendorPortalAccountFacade facade = new VendorPortalAccountFacade();
            VendorManagementFacade vendorManagementfacade = new VendorManagementFacade();
            VendorAccountModel model = facade.GetVendorAccountDetails(vendorID);
            model.VendorLocationID = vendorLocationID;
            logger.InfoFormat("Returns the View with Model:{0}", model);
            return View(model);
        }


        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.VendorInfoTaxClassification, true)]
        public ActionResult _VendorTabs(int vendorID)
        {
            logger.InfoFormat("Inside _VendorTabs() model with Vendor ID:{0}", vendorID);
            VendorPortalAccountFacade facade = new VendorPortalAccountFacade();
            VendorManagementFacade vendorManagementfacade = new VendorManagementFacade();
            VendorAccountModel model = facade.GetVendorAccountDetails(vendorID);
            model.VendorLocationID = 0;
            logger.InfoFormat("Returns the View _VendorTabs with Model:{0} ", model);
            return View(model);
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_MYPROFILE)]
        public ActionResult UserProfile()
        {
            RegisterUserModel user = GetProfile();
            UserProfileModel userProfileModel = new UserProfileModel();
            ChangePasswordModel cpm = new ChangePasswordModel();
            cpm.Email = user.Email;
            cpm.UserName = user.UserName;

            UserInformation ui = new UserInformation();
            ui.Email = user.Email;
            ui.FirstName = user.FirstName;
            ui.LastName = user.LastName;
            ui.UserName = user.UserName;
            ui.ReceiveNotification = user.ReceiveNotification;

            userProfileModel.ChangePasswordModel = cpm;
            userProfileModel.UserInformation = ui;
            return View(userProfileModel);
        }

        /// <summary>
        /// Updates the user information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        public ActionResult UpdateUserInformation(UserProfileModel upm)
        {
            OperationResult result = new OperationResult();
            UserInformation model = upm.UserInformation;
            RegisterUserModel userProfile = GetProfile();

            var loggedInUserId = Guid.Empty;
            MembershipUserCollection users = System.Web.Security.Membership.FindUsersByName(LoggedInUserName);
            if (users.Count > 0)
            {
                loggedInUserId = (Guid)users[LoggedInUserName].ProviderUserKey;
            }
            aspnet_Users user = userFacade.Get(loggedInUserId);
            facade.UpdateUserInformation(model, user.UserId, LoggedInUserName);
            StoreProfile(LoggedInUserName);

            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.UPDATE_INFORMATION, "Update User Information", LoggedInUserName, Session.SessionID);
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
