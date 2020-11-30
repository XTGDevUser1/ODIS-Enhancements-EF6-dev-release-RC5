using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.BLL.Facade;
using log4net;
using Martex.DMS.DAL.Common;
using System.Web.Security;

using System.Web.Hosting;
using System.IO;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class FeedbackController : BaseController
    {
        #region Private Members
        /// <summary>
        /// The DEFAULT_ ATTACHMENT_ STORE
        /// </summary>
        private static readonly string DEFAULT_ATTACHMENT_STORE = HostingEnvironment.MapPath("~/Attachments");
        #endregion

        #region Public Methods
        /// <summary>
        /// Get the Feedback Page
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.FeedbackTypes)]
        [ReferenceDataFilter(StaticData.Priorities)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [DMSAuthorize]
        [NoCache]
        [HttpPost]
        public ActionResult Index(string capturedImage)
        {
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes("Member").ToSelectListItem<PhoneType>(x => x.ID.ToString(), y => y.Name, true);
            ViewData["HelpText"] = "Help";
            FeedbackFacade feedbackFacade = new FeedbackFacade();
            Feedback feedback = GetFeedback();
            feedback.CapturedScreenShot = capturedImage;
            return View(feedback);
        }

        ///// <summary>
        ///// Indexes the specified fData.
        ///// </summary>
        ///// <param name="fData">The fData.</param>
        ///// <returns></returns>
        //[HttpPost]
        //[NoCache]
        //[ValidateInput(false)]
        //[ReferenceDataFilter(StaticData.FeedbackTypes)]
        //[ReferenceDataFilter(StaticData.Priorities)]
        //[ReferenceDataFilter(StaticData.CountryCode, false)]
        //public ActionResult Index(Feedback fData)
        //{
        //    ViewData["HelpText"] = "Help";
        //    logger.InfoFormat("Save feedback details and send email");
        //    EventLoggerFacade facade = new EventLoggerFacade();
        //    Dictionary<string, string> eventDetails = new Dictionary<string, string>();
        //    if (ModelState.IsValid)
        //    {
        //        try
        //        {
        //            FeedbackFacade feedbackFacade = new FeedbackFacade();
        //            System.IO.Stream stream = null;
        //            string fileName = string.Empty;
        //            // getting the attachment file name and the stream
        //            if (Request.Files.Count > 0 && !string.IsNullOrEmpty(Request.Files[0].FileName))
        //            {
        //                var uploadedFile = Request.Files[0];
        //                stream = uploadedFile.InputStream;
        //                fileName = uploadedFile.FileName;
        //                string pathToAttachment = SaveUploadedFile(uploadedFile);
        //                fData.AttachmentFilePath = pathToAttachment;
        //                fData.IsReviewed = false;
        //            }
        //            fData.ID = feedbackFacade.Save(fData, stream, fileName);
        //            ViewData["FeedbackStatus"] = "Thank you for taking the time to contact us.  Your feedback is greatly appreciated and will help us continue to improve the dispatching process!";
        //            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes("Member").ToSelectListItem<PhoneType>(x => x.ID.ToString(), y => y.Name, true);

        //            logger.InfoFormat("Send email from {0} to {1}", fData.Name, fData.Email);
        //            SaveCapturedScreenshot(fData.CapturedScreenShot, fData.ID);
        //            return View(GetFeedback());
        //        }
        //        catch (Exception ex)
        //        {
        //            return View("Error", ex);
        //        }
        //    }
        //    ViewData["FeedbackStatus"] = "Enter valid details";


        //    return View(GetFeedback());

        //}


        [HttpPost]
        [AllowAnonymous]
        public ActionResult Save(Feedback fData, HttpPostedFileBase attachment)
        {

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            logger.InfoFormat("Save feedback details and send email");
            EventLoggerFacade facade = new EventLoggerFacade();
            Dictionary<string, string> eventDetails = new Dictionary<string, string>();
            if (ModelState.IsValid)
            {
                try
                {
                    FeedbackFacade feedbackFacade = new FeedbackFacade();
                    System.IO.Stream stream = null;
                    string fileName = string.Empty;
                    // getting the attachment file name and the stream
                    if (attachment != null && !string.IsNullOrEmpty(attachment.FileName))
                    {
                        var uploadedFile = attachment;
                        stream = uploadedFile.InputStream;
                        fileName = uploadedFile.FileName;
                        string pathToAttachment = SaveUploadedFile(uploadedFile);
                        fData.AttachmentFilePath = pathToAttachment;
                        fData.IsReviewed = false;
                    }
                    string screenshot = SaveCapturedScreenshot(fData.CapturedScreenShot);
                    fData.ID = feedbackFacade.Save(fData, stream, fileName,screenshot);


                    logger.InfoFormat("Send email from {0} to {1}", fData.Name, fData.Email);
                    
                }
                catch (Exception ex)
                {
                    result.Status = OperationStatus.ERROR;
                    result.ErrorDetail = ex.Message.ToString();
                }
            }
            else
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorDetail = "Enter Valid details";
            }

            return Json(result, JsonRequestBehavior.AllowGet);


        }

        /// <summary>
        /// Gets the feedback.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public Feedback GetFeedback()
        {
            MembershipUser user = GetLoggedInUser();
            Feedback feedback = new Feedback();
            feedback.Email = user.Email;
            feedback.Name = user.UserName;
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
        [NoCache]
        public string SaveCapturedScreenshot(string capturedImage)
        {
            var identifier = Guid.NewGuid();

            string trimmedData = capturedImage.Replace("data:image/png;base64,", "");

            //convert the base 64 string image to byte array
            byte[] uploadedImage = Convert.FromBase64String(trimmedData);

            //the byte array can be saved into database or on file system
            //saving the image on the server
            string fileNameFromRequest = "_" + LoggedInUserName + ".png";
            string targetFileName = GetDiskLocation(identifier) + "_" + fileNameFromRequest;
            System.IO.File.WriteAllBytes(targetFileName, uploadedImage);
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
