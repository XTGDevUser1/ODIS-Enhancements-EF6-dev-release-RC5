using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using VendorPortal.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using System.Web.Security;
using System.Web.Hosting;
using System.IO;
using VendorPortal.Areas.Common.Controllers;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using VendorPortal.Controllers;
using VendorPortal.Models;

namespace VendorPortal.Areas.ISP.Controllers
{
    [Authorize]
    public class FeedbackController : BaseController
    {
        FeedbackFacade feedbackFacade = new FeedbackFacade();

        #region Private Members
        /// <summary>
        /// The DEFAULT_ ATTACHMENT_ STORE
        /// </summary>
        private static readonly string DEFAULT_ATTACHMENT_STORE = HostingEnvironment.MapPath("~/Attachments");
        #endregion

        #region Public Methods
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Priorities)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult Index()
        {
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes("Vendor").ToSelectListItem<PhoneType>(x => x.ID.ToString(), y => y.Name, true);
            ViewData["ContactMethods"] = ReferenceDataRepository.GetContactMethods().Where(a => a.Name == "Phone" || a.Name == "Email").ToSelectListItem<ContactMethod>(x => x.ID.ToString(), y => y.Name, true);
            ViewData["FeedbackTypes"] = ReferenceDataRepository.GetFeedbackTypes().Where(a => a.IsShownOnVendorPortal == true).ToSelectListItem<FeedbackType>(x => x.ID.ToString(), y => y.Name, true);
            ViewData["HelpText"] = "Help";
            return View(GetFeedback());
        }

        /// <summary>
        /// Indexes the specified f data.
        /// </summary>
        /// <param name="fData">The f data.</param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult Index(Feedback fData)
        {
            ViewData["HelpText"] = "Help";
            logger.InfoFormat("Save feedback details and send email");
            OperationResult result = new OperationResult();
            if (ModelState.IsValid)
            {
                FeedbackFacade feedbackFacade = new FeedbackFacade();
                System.IO.Stream stream = null;
                string fileName = string.Empty;

                // getting the attachment file name and the stream
                if (Request.Files.Count > 0 && !string.IsNullOrEmpty(Request.Files[0].FileName))
                {
                    var uploadedFile = Request.Files[0];
                    stream = uploadedFile.InputStream;
                    fileName = uploadedFile.FileName;
                    string pathToAttachment = SaveUploadedFile(uploadedFile);
                    fData.AttachmentFilePath = pathToAttachment;
                    fData.IsReviewed = false;
                }
                RegisterUserModel user = GetProfile();
                fData.VendorID = user.VendorID;
                feedbackFacade.SaveVendorPortalFeedback(fData, Session.SessionID, Request.RawUrl, stream, fileName,LoggedInUserName,SourceSystemName.VENDOR_PORTAL);
                if (!string.IsNullOrEmpty(fData.AttachmentFilePath))
                {
                    logger.Info("Deleting document file");
                    FileInfo fi = new FileInfo(fData.AttachmentFilePath);
                    fi.Delete();
                }
                
                result.Status = OperationStatus.SUCCESS;
                result.Data = "Thank you for taking the time to contact us.  Your feedback is greatly appreciated and will help us continue to improve the dispatching process!";
            }
            return Json(result,"text/plain", JsonRequestBehavior.AllowGet);

        }


        /// <summary>
        /// Gets the feedback.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public Feedback GetFeedback()
        {
            RegisterUserModel user = GetProfile();
            Feedback feedback = new Feedback();
            feedback.Email = user.Email;
            feedback.Name = user.FirstName + " " + user.LastName;
            feedback.PhoneNumber = GetLoggedInUserPhone("Office");
            return feedback;
        }

        /// <summary>
        /// Saves the uploaded file.
        /// </summary>
        /// <param name="fileBase">The file base.</param>
        /// <returns></returns>
        [NoCache]
        public string SaveUploadedFile(HttpPostedFileBase fileBase)
        {
            var identifier = Guid.NewGuid();
            FileInfo fi = new FileInfo(fileBase.FileName);
            string fileNameFromRequest = fi.Name;
            string targetFileName = GetDiskLocation(identifier) + "_" + fileNameFromRequest;
            fileBase.SaveAs(targetFileName);
            return targetFileName;
        }
        #endregion

        #region Private Members
        /// <summary>
        /// Gets the disk location.
        /// </summary>
        /// <param name="identifier">The identifier.</param>
        /// <returns></returns>
        [NoCache]
        private string GetDiskLocation(Guid identifier)
        {

            string attachmentStore = AppConfigRepository.GetValue(AppConfigConstants.FEEDBACK_ATTACHMENT_PATH);
            if (string.IsNullOrEmpty(attachmentStore))
            {
                attachmentStore = DEFAULT_ATTACHMENT_STORE;
            }
            else
            {
                attachmentStore = HostingEnvironment.MapPath(attachmentStore);
                DirectoryInfo fi = new DirectoryInfo(attachmentStore);
                if (!fi.Exists)
                {
                    fi.Create();
                }

            }
            return Path.Combine(attachmentStore, identifier.ToString());
        }
        #endregion
    }
}
