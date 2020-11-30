using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.BLL.Model;
using Martex.DMS.Models;
using Martex.DMS.DAL.Common;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Common;
using Martex.DMS.DAL.DAO;
using System.Web.Script.Serialization;
using System.Text;
using Martex.DMS.BLL.DataValidators;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DMSBaseException;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application.Controllers
{
    public class FinishController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// _s the index.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ContactCategory, false)]
        [ReferenceDataFilter(StaticData.ServiceRequestStatus, false)]
        [ReferenceDataFilter(StaticData.NextAction, false)]
        [ReferenceDataFilter(StaticData.FinishUsers, false)]
        [ReferenceDataFilter(StaticData.ClosedLoopStatus, false)]
        [ReferenceDataFilter(StaticData.Priorities, false)]
        [ReferenceDataFilter(StaticData.ServiceMemberPayMode, true)]
        [NoCache]
        [DMSAuthorize]
        public ActionResult _Index()
        {
            logger.InfoFormat("FinishController - _Index()");
            var loggedInUser = LoggedInUserName;

            FinishModel fModel = new FinishModel();
            FinishReasonsActionsModel freasonsActions = new FinishReasonsActionsModel();
            FinishFacade facade = new FinishFacade();
            fModel.ServiceRequestStatus = 1;
            if (DMSCallContext.ContactCategoryID != 0)
            {
                fModel.ContactCategory = DMSCallContext.ContactCategoryID;
                freasonsActions.ContactReasons = facade.GetContactReasons(DMSCallContext.ContactCategoryID);
                freasonsActions.ContactActions = facade.GetContactAction(DMSCallContext.ContactCategoryID);
            }
            else
            {
                fModel.ContactCategory = DMSCallContext.ContactCategoryID;
                freasonsActions.ContactActions = new List<ContactAction>();
                freasonsActions.ContactReasons = new List<ContactReason>();
                ServiceRequestRepository srRepository = new ServiceRequestRepository();
                var srStatus = srRepository.GetServiceRequestStatus("Complete");
                fModel.ServiceRequestStatus = srStatus != null ? srStatus.ID : 0;
            }
            fModel.ReasonsActions = freasonsActions;
            fModel.ClosedLoopActivities = new List<ClosedLoopActivities_Result>();
            ServiceFacade srfacade = new ServiceFacade();
            if (DMSCallContext.ServiceRequestID != 0)
            {
                ServiceRequest sr = srfacade.GetServiceRequestById(DMSCallContext.ServiceRequestID);
                if (sr.ServiceRequestStatusID.HasValue)
                {
                    fModel.ServiceRequestStatus = sr.ServiceRequestStatusID.Value;
                }

                fModel.Priority = sr.ServiceRequestPriorityID;
                fModel.NextAction = sr.NextActionID;
                CommonLookUpRepository commonRepository = new CommonLookUpRepository();
                NextAction nextAction = commonRepository.GetNextAction(sr.NextActionID.GetValueOrDefault());
                if (nextAction != null)
                {
                    fModel.IsShowConfirmPrompt = nextAction.IsShowConfirmPrompt;
                }
                fModel.AssignedTo = sr.NextActionAssignedToUserID;
                if (sr.ClosedLoopStatusID.HasValue)
                {
                    fModel.ClosedLoopStatus = sr.ClosedLoopStatusID.Value;
                }
                fModel.NextSend = sr.ClosedLoopNextSend;
                fModel.ScheduledDate = sr.NextActionScheduledDate;

                fModel.ClosedLoopActivities = facade.GetClosedLoopActivities(DMSCallContext.ServiceRequestID);

                fModel.ProviderClaimNumber = sr.ProviderClaimNumber;

            }

            //Lakshmi - Email on Map tab: Begin
            ViewData["MemberEmail"] = string.Empty;
            bool showsurveyemail = IsShowSurveyEmail();             //Lakshmi - Code added for Program Specific survey email
            ViewBag.ShowSurveyEmail = showsurveyemail;              //Lakshmi - Code added for Program Specific survey email

            CaseFacade casefacade = new CaseFacade();
            Case casemodel = casefacade.GetCaseById(DMSCallContext.CaseID);

            if (casemodel != null)
            {
                if (casemodel.ReasonID != null & casemodel.ReasonID.HasValue)
                {
                    ContactEmailDeclineReason declinedReason = casefacade.GetDeclinedReasonById(casemodel.ReasonID.Value);
                    ViewData["DeclinedReason"] = declinedReason.ID.ToString();
                }
                else
                {
                    ViewData["DeclinedReason"] = string.Empty;
                }

                ViewData["MemberEmail"] = casemodel.ContactEmail;

            }

            ViewData[Martex.DMS.ActionFilters.StaticData.DeclinedReasons.ToString()] = ReferenceDataRepository.GetDeclineReasons().ToSelectListItem<ContactEmailDeclineReason>(x => x.ID.ToString(), y => y.Description.Trim(), true);

            //TFS:163
            SetTabValidationStatus(RequestArea.FINISH);


            var captureClaimNumberDetails = ReferenceDataRepository.GetCaptureClaimNumberDetailsForSR(DMSCallContext.ServiceRequestID);
            if (captureClaimNumberDetails != null)
            {
                fModel.ProductProviderDescription = captureClaimNumberDetails.ProductProviderDescription;
                DMSCallContext.IsCaptureClaimNumber = captureClaimNumberDetails.IsCaptureClaimNumber.GetValueOrDefault();
                DMSCallContext.ProductProviderID = captureClaimNumberDetails.ProductProviderID;
            }

            //End
            return View(fModel);
        }

        /// <summary>
        /// Gets the reasons.
        /// </summary>
        /// <param name="selectedValue">The selected value.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult GetReasons(int selectedValue)
        {
            logger.InfoFormat("FinishController - GetReasons() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                selectedValue = selectedValue
            }));
            FinishReasonsActionsModel model = new FinishReasonsActionsModel();
            FinishFacade facde = new FinishFacade();
            model.ContactReasons = facde.GetContactReasons(selectedValue);
            model.ContactActions = facde.GetContactAction(selectedValue);
            logger.InfoFormat("FinishController - GetReasons() - Returns :  {0}", JsonConvert.SerializeObject(new
            {
                ContactActions = model.ContactActions != null ? model.ContactActions.Count() : 0,
                ContactReasons = model.ContactReasons != null ? model.ContactReasons.Count() : 0
            }));
            return PartialView("_ReasonsActions", model);
        }

        /// <summary>
        /// Validates the configuration finish.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        protected OperationResult ValidateOnFinish(FinishModel model)
        {
            logger.InfoFormat("FinishController - ValidateOnFinish() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                FinishModel = model
            }));
            OperationResult result = new OperationResult();
            IServiceRequestDataValidator dataValidator = new FinishDataValidator();

            model.ServiceRequestID = DMSCallContext.ServiceRequestID;
            if (DMSCallContext.ActiveRequestLocked)
            {
                //model.ServiceRequestID = DMSCallContext.ActiveServiceRequestId.GetValueOrDefault();
                logger.InfoFormat("Locked SR {0}", DMSCallContext.ActiveServiceRequestId);
                return result;
            }

            var status = ReferenceDataRepository.ServiceRequestStatus().Where(x => x.ID == model.ServiceRequestStatus).FirstOrDefault();
            // Create an instance of SR and initialize it with the attributes from Finish tab.
            ServiceRequest sr = new ServiceRequest();
            sr.ID = model.ServiceRequestID;
            sr.ServiceRequestStatu = new ServiceRequestStatu();
            if (status != null)
            {
                logger.InfoFormat("Service request {0} status from screen {1}", sr.ID, status.Name);
                sr.ServiceRequestStatu.Name = status.Name;
            }

            dataValidator.Validate(sr);

            if (status != null && "Cancelled".Equals(status.Name, StringComparison.InvariantCultureIgnoreCase))
            {
                return result;
            }
            var tabValidationStatuses = CallFacade.GetAllTabValidationStatuses(model.ServiceRequestID);
            JavaScriptSerializer jsonSerializer = new JavaScriptSerializer();
            StringBuilder sb = new StringBuilder();
            jsonSerializer.Serialize(tabValidationStatuses, sb);
            result.Data = sb.ToString();

            bool stopProcessing = tabValidationStatuses.Where(a => a.Value == TabValidationStatus.VISITED_WITH_ERRORS).Count() > 0;
            if (stopProcessing)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
            }
            logger.InfoFormat("FinishController - ValidateOnFinish() - Returns :  {0}", JsonConvert.SerializeObject(new
            {
                Data = result.Data,
                Status = result.Status
            }));
            return result;
        }

        /// <summary>
        /// Verifies the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult Verify(FinishModel model)
        {
            logger.InfoFormat("FinishController - Verify() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                FinishModel = model
            }));
            return Json(ValidateOnFinish(model), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult Save(FinishModel model)
        {
            logger.InfoFormat("FinishController - Save() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                FinishModel = model
            }));
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            bool stopProcessing = false;
            CaseFacade casefacade = new CaseFacade();
            var mapfacade = new MapFacade();
            // Set the session variables on the model.
            model.ServiceRequestID = DMSCallContext.ServiceRequestID;
            model.CaseID = DMSCallContext.CaseID;
            model.MemberID = DMSCallContext.MemberID;
            model.InBoundCallId = DMSCallContext.InboundCallID;
            model.ProgramID = DMSCallContext.ProgramID;
            model.AmazonConnectID = DMSCallContext.AmazonConnectID;
            FinishFacade facade = new FinishFacade();
            string loggedInUser = LoggedInUserName;

            result = ValidateOnFinish(model);



            if (OperationStatus.BUSINESS_RULE_FAIL == result.Status)
            {
                return Json(result, JsonRequestBehavior.AllowGet);
            }



            if (DMSCallContext.ActiveRequestLocked)
            {
                model.ServiceRequestID = DMSCallContext.ActiveServiceRequestId.GetValueOrDefault();
                facade.SaveOnActiveServiceRequestLocked(model, Request.RawUrl, loggedInUser, HttpContext.Session.SessionID, DMSCallContext.MembershipID);
            }
            else
            {

                if (!string.IsNullOrEmpty(model.ServiceRequestEmail))
                {
                    //mapfacade.UpdateMemberEmailInfo(model.ServiceRequestEmail, null, DMSCallContext.CaseID, loggedInUser);
                    ViewData["DeclinedReason"] = string.Empty;
                }
                else
                {
                    //mapfacade.UpdateMemberEmailInfo(model.ServiceRequestEmail, model.DeclinedReason, DMSCallContext.CaseID, loggedInUser);
                    if (model.DeclinedReason.HasValue)
                    {
                        ContactEmailDeclineReason declinedReason = casefacade.GetDeclinedReasonById(model.DeclinedReason.Value);
                        ViewData["DeclinedReason"] = declinedReason.ID.ToString();
                    }
                }

                ViewData["MemberEmail"] = model.ServiceRequestEmail;
                if (!DMSCallContext.IsCaptureClaimNumber)
                {
                    model.ProviderClaimNumber = string.Empty;
                    model.ProductProviderID = null;
                }
                else
                {
                    model.ProductProviderID = DMSCallContext.ProductProviderID;
                }
                facade.Save(model, Request.RawUrl, loggedInUser, HttpContext.Session.SessionID, DMSCallContext.MembershipID, DMSCallContext.RequestOpenedTime, DMSCallContext.SRAgentTime);
                DMSCallContext.AmazonConnectID = null;
                if (DMSCallContext.ServiceRequestID > 0)
                {
                    var status = ReferenceDataRepository.ServiceRequestStatus().Where(x => x.ID == model.ServiceRequestStatus).FirstOrDefault();
                    bool skipValidation = false;
                    if (status != null && "Cancelled".Equals(status.Name))
                    {
                        skipValidation = true;
                    }

                    if (!skipValidation)
                    {
                        var tabValidationStatuses = CallFacade.GetAllTabValidationStatuses(DMSCallContext.ServiceRequestID);
                        JavaScriptSerializer jsonSerializer = new JavaScriptSerializer();
                        StringBuilder sb = new StringBuilder();
                        jsonSerializer.Serialize(tabValidationStatuses, sb);
                        result.Data = sb.ToString();

                        stopProcessing = tabValidationStatuses.Where(a => a.Value == TabValidationStatus.VISITED_WITH_ERRORS).Count() > 0;
                        if (stopProcessing)
                        {
                            result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                        }
                    }
                }
            }

            //TFS:163: Check to see if other tabs have errors.


            if (!stopProcessing)
            {
                if (DMSCallContext.StartingPoint == StringConstants.START)
                {
                    DMSCallContext.InboundCallID = 0;
                    DMSCallContext.ServiceRequestID = 0;
                    DMSCallContext.MemberID = 0;
                    DMSCallContext.CaseID = 0;
                    result.TabNavigation = "Start";
                    if (DMSCallContext.IsFromHistoryList)
                    {
                        result.TabNavigation = "History";
                    }
                    DMSCallContext.Reset();
                }
                else
                {
                    DMSCallContext.ServiceRequestID = 0;
                    DMSCallContext.InboundCallID = 0;
                    //DMSCallContext.ServiceRequestID = 0;
                    DMSCallContext.MemberID = 0;
                    DMSCallContext.CaseID = 0;
                    result.TabNavigation = "Queue";
                    if (DMSCallContext.IsFromHistoryList)
                    {
                        result.TabNavigation = "History";
                    }
                    DMSCallContext.Reset();

                }
                if (!DMSCallContext.ActiveRequestLocked)
                {
                    var commentFacade = new CommentFacade();
                    var currentUser = LoggedInUserName;
                    if (!string.IsNullOrEmpty(DMSCallContext.ServiceTechComments))
                    {
                        commentFacade.Save(CommentTypeNames.SERVICE_REQUEST, EntityNames.SERVICE_REQUEST, model.ServiceRequestID, DMSCallContext.ServiceTechComments, currentUser);

                    }
                }
                DMSCallContext.ServiceTechComments = string.Empty;

            }
            logger.InfoFormat("FinishController - Save(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                OperationResult = result
            }));
            return Json(result);
        }

        /// <summary>
        /// Gets the latest SR attributes.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        public ActionResult GetLatestSRAttributes()
        {
            logger.InfoFormat("FinishController - GetLatestSRAttributes()");
            logger.InfoFormat("Trying to get the latest SR attributes - status and closedloop status");
            var srRepository = new ServiceRepository();
            ServiceRequest sr = srRepository.GetServiceRequestById(DMSCallContext.ServiceRequestID);

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            if (sr != null)
            {
                logger.InfoFormat("Returning new status : {0} and closedloopstatusId : {1}", sr.ServiceRequestStatusID, sr.ClosedLoopStatusID);
                result.Data = new { StatusId = sr.ServiceRequestStatusID, ClosedLoopStatusId = sr.ClosedLoopStatusID };
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult GetTabValidationStatus()
        {
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            bool stopProcessing = false;

            if (DMSCallContext.ServiceRequestID > 0)
            {
                var tabValidationStatuses = CallFacade.GetAllTabValidationStatuses(DMSCallContext.ServiceRequestID);
                JavaScriptSerializer jsonSerializer = new JavaScriptSerializer();
                StringBuilder sb = new StringBuilder();
                jsonSerializer.Serialize(tabValidationStatuses, sb);
                result.Data = sb.ToString();

                stopProcessing = tabValidationStatuses.Where(a => a.Value == TabValidationStatus.VISITED_WITH_ERRORS).Count() > 0;
                if (stopProcessing)
                {
                    result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                }
            }
            return Json(result);
        }

        [DMSAuthorize]
        public ActionResult NextActionDefaultValues(int nextActionID)
        {
            logger.InfoFormat("FinishController - NextActionDefaultValues() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                NextActionID = nextActionID
            }));
            JsonResult result = new JsonResult();
            CommonLookUpRepository repository = new CommonLookUpRepository();
            NextAction nextAction = repository.GetNextAction(nextActionID);
            if (nextAction == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Next Action - {0}", nextActionID));
            }
            //bool IsCreditCardNeeded = nextAction.Name.Equals("CreditCardNeeded", StringComparison.CurrentCultureIgnoreCase) ? true : false;
            DateTime? scheduleDate = null;
            //string scheduleTime = string.Empty;
            //if (IsCreditCardNeeded)
            // {
            if (!string.IsNullOrEmpty(nextAction.DefaultScheduleDateIntervalUOM))
            {
                if (nextAction.DefaultScheduleDateIntervalUOM.Equals("seconds", StringComparison.OrdinalIgnoreCase))
                {
                    scheduleDate = DateTime.Now.AddSeconds(nextAction.DefaultScheduleDateInterval.GetValueOrDefault());//.ToString("MM/dd/yyyy");
                    //scheduleTime = DateTime.Now.AddSeconds(nextAction.DefaultScheduleDateInterval.GetValueOrDefault()).ToShortTimeString();
                }
                else if (nextAction.DefaultScheduleDateIntervalUOM.Equals("minutes", StringComparison.OrdinalIgnoreCase))
                {
                    scheduleDate = DateTime.Now.AddMinutes(nextAction.DefaultScheduleDateInterval.GetValueOrDefault());//.ToString("MM/dd/yyyy");
                    //scheduleTime = DateTime.Now.AddMinutes(nextAction.DefaultScheduleDateInterval.GetValueOrDefault()).ToShortTimeString();
                }
                else if (nextAction.DefaultScheduleDateIntervalUOM.Equals("hours", StringComparison.OrdinalIgnoreCase))
                {
                    scheduleDate = DateTime.Now.AddHours(nextAction.DefaultScheduleDateInterval.GetValueOrDefault());//.ToString("MM/dd/yyyy");
                    //scheduleTime = DateTime.Now.AddHours(nextAction.DefaultScheduleDateInterval.GetValueOrDefault()).ToShortTimeString();
                }
                else if (nextAction.DefaultScheduleDateIntervalUOM.Equals("days", StringComparison.OrdinalIgnoreCase))
                {
                    scheduleDate = DateTime.Now.AddDays(nextAction.DefaultScheduleDateInterval.GetValueOrDefault());//.ToString("MM/dd/yyyy");
                    //scheduleTime = DateTime.Now.AddDays(nextAction.DefaultScheduleDateInterval.GetValueOrDefault()).ToShortTimeString();
                }
            }
            //}
            if (nextAction.DefaultPriorityID == null)
            {
                List<ServiceRequestPriority> list = ReferenceDataRepository.GetPriorities();
                if (list.Count > 0)
                {
                    var normalPriority = list.Where(a => a.Name == "Normal").FirstOrDefault();
                    nextAction.DefaultPriorityID = normalPriority.ID;
                }
            }
            result.Data = new { PriorityID = nextAction.DefaultPriorityID, ScheduleDate = scheduleDate, DefaultAssignedToUserID = nextAction.DefaultAssignedToUserID };
            logger.InfoFormat("FinishController - NextActionDefaultValues() - Returns :  {0}", JsonConvert.SerializeObject(new
            {
                JsonResult = result
            }));
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        public ActionResult NextActionUsers(int? nextActionID)
        {
            logger.InfoFormat("FinishController - NextActionUsers() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                NextActionID = nextActionID
            }));
            JsonResult result = new JsonResult();
            ReferenceDataRepository refRepository = new ReferenceDataRepository();
            result.Data = refRepository.GetUsersForNextAction(nextActionID).OrderBy(x => x.FirstName).ToSelectListItem(x => x.ID.ToString(), y => (y.FirstName + " " + y.LastName), false);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion

        private bool IsShowSurveyEmail()
        {
            MapFacade mapfacade = new MapFacade();
            return mapfacade.IsShowSurveyEmailAllowed(DMSCallContext.MemberProgramID, "Application", "Rule", "ShowSurveyEmail");
        }
    }
}
