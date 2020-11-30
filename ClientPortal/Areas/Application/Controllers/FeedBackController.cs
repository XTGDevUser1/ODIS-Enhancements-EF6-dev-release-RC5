using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using ClientPortal.Common;
using Martex.DMS.BLL.Facade;
using log4net;
using Martex.DMS.DAL.Common;
using System.Web.Security;

using System.Web.Hosting;
using System.IO;
using ClientPortal.Areas.Common.Controllers;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;

namespace ClientPortal.Areas.Application.Controllers
{
    public class FeedbackController : BaseController
    {
        #region Private Members
        private static readonly string DEFAULT_ATTACHMENT_STORE = HostingEnvironment.MapPath("~/Attachments");
        #endregion

        #region Public Methods
        /// <summary>
        /// Get the Feedback Page
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.FeedbackTypes)]
        [ReferenceDataFilter(StaticData.Priorities)]        
        [ReferenceDataFilter(StaticData.CountryCode,false)]
        [DMSAuthorize]
        [NoCache]
        public ActionResult Index()
        {
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes("Member").ToSelectListItem<PhoneType>(x=>x.ID.ToString(), y=>y.Name, true);
            ViewData["HelpText"] = "Help";
            FeedbackFacade feedbackFacade = new FeedbackFacade();
            // Prepopulate user details by using GetFeedback method
            return View(GetFeedback());
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="fData"></param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        [ReferenceDataFilter(StaticData.FeedbackTypes)]
        [ReferenceDataFilter(StaticData.Priorities)]
        [ReferenceDataFilter(StaticData.CountryCode,false)]
        public ActionResult Index(Feedback fData)
        {
            ViewData["HelpText"] = "Help";//helpRepository.Get<string>("FEEDBACK_HELP").Text;
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
                    if (Request.Files.Count > 0 && !string.IsNullOrEmpty(Request.Files[0].FileName))
                    {
                        var uploadedFile = Request.Files[0];
                        stream = uploadedFile.InputStream;
                        fileName = uploadedFile.FileName;
                        string pathToAttachment = SaveUploadedFile(uploadedFile);
                        fData.AttachmentFilePath = pathToAttachment;
                        fData.IsReviewed = false;
                    }
                    feedbackFacade.Save(fData, stream, fileName);
                    ViewData["FeedbackStatus"] = "Thank you for taking the time to contact us.  Your feedback is greatly appreciated and will help us continue to improve the dispatching process!";
                    ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes("Member").ToSelectListItem<PhoneType>(x => x.ID.ToString(), y => y.Name, true);

                    logger.InfoFormat("Send email from {0} to {1}", fData.Name, fData.Email);
                    // Prepopulate user details by using GetFeedback method
                    return View(GetFeedback());
                }
                catch (Exception ex)
                {
                    return View("Error", ex);
                }
            }
            ViewData["FeedbackStatus"] = "Enter valid details";


            return View(GetFeedback());

        }
        /// <summary>
        /// 
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
        /// 
        /// </summary>
        /// <param name="fileBase"></param>
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
