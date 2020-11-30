using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;
using VendorPortal.Models;
using VendorPortal.ActionFilters;
using VendorPortal.Common;
using VendorPortal.BLL.Models;
using VendorPortal.Controllers;
using System.Web.Security;
using Martex.DMS.BLL.Facade.VendorPortal;
using Martex.DMS.BLL.Model.VendorPortal;
using Martex.DMS.DAL.DAO;
using VendorPortal.Areas.ISP.Models;

namespace VendorPortal.Areas.ISP.Controllers
{

    public class DashboardController : BaseController
    {
        private VendorApplicationFacade facade = new VendorApplicationFacade();
        private UsersFacade userFacade = new UsersFacade();
        //
        // GET: /ISP/Home/
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_TOP_ISP)]
        [NoCache]
        public ActionResult Index()
        {
            StoreProfile(LoggedInUserName);
            RegisterUserModel userProfile = GetProfile();
            ViewData["UserProfile"] = userProfile;
            var vendorPortalDashboardFacade = new VendorPortalDashboardFacade();
            var model = vendorPortalDashboardFacade.GetVendorDashboard(LoggedInUserVendorID);
            var messagefacade = new MessageFacade();
            var messageList = messagefacade.GetMessages(MessageScopeNames.VENDOR_PORTAL);
            model.MessageList = messageList;
            return View(model);
        }

        [DMSAuthorize]
        public ActionResult GetLatestContractAndTAForVendor()
        {
            OperationResult result = new OperationResult();
            PostLoginFacade facade = new PostLoginFacade();
            result.Data = facade.GetLatestContractAndTAForVendor(LoggedInUserVendorID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult ViewServiceProviderAgreement()
        {
            PostLoginFacade facade = new PostLoginFacade();
            LatestContractAndTAForVendor_Result result = facade.GetLatestContractAndTAForVendor(LoggedInUserVendorID);
            if (result == null)
            {
                return Content("No Contract exists for the Vendor");
            }

            string filename = "/ReferenceForms/" + result.VendorTermsAgreementFileName;
            string filepath = AppDomain.CurrentDomain.BaseDirectory + filename;
            byte[] filedata = System.IO.File.ReadAllBytes(filepath);

            return File(filedata, "application/pdf", result.VendorTermsAgreementFileName);
        }

        /// <summary>
        /// Posts the login prompt.
        /// </summary>
        /// <returns></returns>
        [AllowAnonymous]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.ReferralSource, false)]
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        public ActionResult PostLoginPrompt()
        {
            var postLoginfacade = new PostLoginFacade();
            var userProfile = GetProfile();
            var postLoginModel = postLoginfacade.GetVendorPostLoginDetails(userProfile.VendorID.GetValueOrDefault());
            postLoginModel.ContactLastName = userProfile.LastName;
            postLoginModel.ContactFirstName = userProfile.FirstName;
            postLoginModel.Email = userProfile.Email;

            ViewData["CA_STATES"] = ReferenceDataRepository.GetStateProvinces("Canada").ToSelectListItem<StateProvince>(x => x.ID.ToString(CultureInfo.InvariantCulture), y => y.Abbreviation.Trim() + "-" + y.Name, true);
            ViewData["MX_STATES"] = ReferenceDataRepository.GetStateProvinces("Mexico").ToSelectListItem<StateProvince>(x => x.ID.ToString(CultureInfo.InvariantCulture), y => y.Abbreviation.Trim() + "-" + y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).ToSelectListItem(x => x.ID.ToString(CultureInfo.InvariantCulture), y => y.Name, true);
            return View(postLoginModel);
        }

        public ActionResult GetInsurancePrompt()
        {
            var userProfile = GetProfile();
            #region  Logging Event
            var eventLogFacade = new EventLoggerFacade();
            long eventLogId = eventLogFacade.LogEvent(Request.RawUrl, EventNames.INSURANCE_PROMPT, "Insurance Prompt", LoggedInUserName, userProfile.VendorID, EntityNames.VENDOR, Session.SessionID);
            #endregion
            return View(userProfile);
        }

        [ReferenceDataFilter(StaticData.DispatchSoftwareProduct, true)]
        [ReferenceDataFilter(StaticData.DispatchGPSNetwork, true)]
        public ActionResult SoftwareZipCodes()
        {
            return View();
        }

        /// <summary>
        /// Submits the vendors software zip codes.
        /// </summary>
        /// <param name="vendor">The vendor.</param>
        /// <returns></returns>
        public ActionResult SubmitVendorsSoftwareZipCodes(Vendor vendor)
        {
            OperationResult result = new OperationResult();
            logger.Info("Inside SubmitSignNewContracts method of Home Controller to save Post Login Prompt Data");
            RegisterUserModel userProfile = GetProfile();
            var postLoginFacade = new PostLoginFacade();
            vendor.ID = userProfile.VendorID.GetValueOrDefault();
            postLoginFacade.SubmitVendorsSoftwareZipCodes(vendor, userProfile.ID.GetValueOrDefault(), LoggedInUserName, Request.RawUrl, Session.SessionID);
            result.Status = "Success";
            StoreProfile(LoggedInUserName);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Signs the new contracts.
        /// </summary>
        /// <returns></returns>
        public ActionResult SignNewContracts()
        {
            return View();
        }

        /// <summary>
        /// Submits the sign new contracts.
        /// </summary>
        /// <param name="NewContractName">New name of the contract.</param>
        /// <param name="NewContractTitle">The new contract title.</param>
        /// <param name="NewContractDate">The new contract date.</param>
        /// <returns></returns>
        public ActionResult SubmitSignNewContracts(string NewContractName, string NewContractTitle, DateTime? NewContractDate)
        {
            OperationResult result = new OperationResult();
            logger.Info("Inside SubmitSignNewContracts method of Home Controller to save Post Login Prompt Data");
            RegisterUserModel userProfile = GetProfile();
            var postLoginFacade = new PostLoginFacade();
            postLoginFacade.SubmitSignNewContracts(NewContractName, NewContractTitle, NewContractDate, userProfile.VendorID.GetValueOrDefault(), userProfile.ID.GetValueOrDefault(), LoggedInUserName, Request.RawUrl, Session.SessionID);
            result.Status = "Success";
            StoreProfile(LoggedInUserName);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult Save(PostLoginPromptModel model)
        {
            OperationResult result = new OperationResult();
            logger.Info("Inside Save method of Home Controller to save Post Login Prompt Data");
            RegisterUserModel userProfile = GetProfile();

            var loggedInUserId = Guid.Empty;
            MembershipUserCollection users = System.Web.Security.Membership.FindUsersByName(LoggedInUserName);
            if (users.Count > 0)
            {
                var providerUserKey = users[LoggedInUserName].ProviderUserKey;
                if (providerUserKey != null)
                    loggedInUserId = (Guid)providerUserKey;
            }
            aspnet_Users user = userFacade.Get(loggedInUserId);

            var postLoginFacade = new PostLoginFacade();
            postLoginFacade.SavePostLoginValues(model, userProfile.VendorID.GetValueOrDefault(), LoggedInUserName, Request.RawUrl, Session.SessionID, userProfile.ID, user.UserId);
            result.Status = "Success";
            StoreProfile(LoggedInUserName);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        public ActionResult Impersonate()
        {
            return View();
        }
        public ActionResult ImpersonateUser(string vendorNumber)
        {
            var result = new OperationResult();
            string userNameToBeSwapped = facade.GetVendorUserName(vendorNumber);
            if (!string.IsNullOrEmpty(userNameToBeSwapped) && userNameToBeSwapped != " ")
            {
                result.Status = "Success";
                logger.InfoFormat("Logged in and impersonated Vendor - {0}", vendorNumber);
                FormsAuthentication.SetAuthCookie(userNameToBeSwapped, true);
                StoreProfile(userNameToBeSwapped);
            }
            else
            {
                result.Status = "Failure";
                result.Data = "The Selected Vendor haven't yet registered.";
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult SearchVendor(string searchTerm)
        {
            var repository = new VendorRepository();
            var pg = new PageCriteria() { StartInd = 1, EndInd = 25, PageSize = 25 };
            var list = repository.Search(searchTerm, pg);
            var emptyItem = new VendorSearch_Result()
            {
                City = string.Empty,
                StateProvince = string.Empty,
                VendorNumber = string.Empty,

            };
            if (string.IsNullOrEmpty(searchTerm))
            {
                emptyItem.VendorName = "Please enter something to search on";
                list.Clear();
                list.Add(emptyItem);
            }

            else if (searchTerm.Length < 4)
            {
                emptyItem.VendorName = "Please enter at least 4 characters to search";
                list.Clear();
                list.Add(emptyItem);
            }
            else
            {
                if (list.Count == 0)
                {
                    emptyItem.VendorName = "No vendors found.Please adjust the search criteria and try again";
                    list.Clear();
                    list.Add(emptyItem);
                }
            }

            var gridModel = new ComboGridModel()
            {
                Count = list.Count,
                records = list.Count,
                total = list.Count,
                rows = list.ToArray<VendorSearch_Result>()
            };
            return Json(gridModel, JsonRequestBehavior.AllowGet);
        }
    }
}
