using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class ClickToCallController : BaseController
    {

        #region Public Methods
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        public ActionResult Index()
        {
            return View();
        }
        /// <summary>
        /// Calls the specified phone number.
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
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
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }
            finally
            {
                IncrementCallCounts(AgentTimeCounts.CLICK_TO_CALL);
            }

            return Json(result);
        }
        #endregion
    }
}
