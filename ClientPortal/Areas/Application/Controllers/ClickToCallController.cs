using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Models;
using Martex.DMS.BLL.Facade;
using ClientPortal.Areas.Application.Models;
using ClientPortal.Areas.Common.Controllers;
using Martex.DMS.BLL.Model;

namespace ClientPortal.Areas.Application.Controllers
{
    public class ClickToCallController : BaseController
    {

        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public ActionResult Index()
        {
            return View();
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="phoneNumber"></param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult Call(string phoneNumber)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            try
            {
                RegisterUserModel up = GetProfile() as RegisterUserModel;
                logger.InfoFormat("Attempting to call {0}", phoneNumber);
                ClickToCallModel model = new ClickToCallModel()
                {
                    CurrentUser = up.UserName,
                    DeviceName = DMSCallContext.ClickToCallDeviceName,
                    EventSource = Request.RawUrl,
                    PhoneNumber = phoneNumber,
                    PhoneUserId = up.PhoneUserId, // TODO: Remove hardcode
                    PhonePassword = up.PhonePassword, // TODO: remove hardcode
                    SessionID = Session.SessionID,
                    UserId = up.ID.Value
                };
                ClickToCallFacade.Call(model);
                logger.InfoFormat("Call succeeded for {0}", phoneNumber);
            }
            catch (Exception ex)
            {
                logger.WarnFormat("Error while calling {0} - {1}", phoneNumber, ex.ToString());
                // CR: 910 : Do not disable the service when there is failure while processing the call.
                //DMSCallContext.IsClickToCallEnabled = false;
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return Json(result);
        }
        #endregion
    }
}
