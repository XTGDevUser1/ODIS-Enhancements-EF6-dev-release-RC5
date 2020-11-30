using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using ClientPortal.Areas.Application.Models;
using Martex.DMS.BLL.Model;
using ClientPortal.Models;
using Martex.DMS.DAL.Common;
using ClientPortal.Areas.Common.Controllers;
using ClientPortal.Common;

namespace ClientPortal.Areas.Application.Controllers
{
    public class FinishController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ContactCategory, false)]
        [ReferenceDataFilter(StaticData.ServiceRequestStatus, false)]
        [ReferenceDataFilter(StaticData.NextAction, false)]
        [ReferenceDataFilter(StaticData.FinishUsers, false)]
        [ReferenceDataFilter(StaticData.ClosedLoopStatus, false)]
        [ReferenceDataFilter(StaticData.Priorities, false)]
        [NoCache]
        [DMSAuthorize]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_FINISH)]
        public ActionResult _Index()
        {
            var loggedInUser = LoggedInUserName;
            // Log an event that Finish tab is visited.
            EventLoggerFacade eventLogFacade = new EventLoggerFacade();
            eventLogFacade.LogEvent(Request.RawUrl, EventNames.ENTER_FINISH_TAB, "Enter Finish Tab", loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, HttpContext.Session.SessionID);

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
                fModel.AssignedTo = sr.NextActionAssignedToUserID;
                if (sr.ClosedLoopStatusID.HasValue)
                {
                    fModel.ClosedLoopStatus = sr.ClosedLoopStatusID.Value;
                }
                fModel.NextSend = sr.ClosedLoopNextSend;
                fModel.ScheduledDate = sr.NextActionScheduledDate;

                fModel.ClosedLoopActivities = facade.GetClosedLoopActivities(DMSCallContext.ServiceRequestID);
            }
            return View(fModel);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="selectedValue"></param>
        /// <returns></returns>
        [NoCache]
        public ActionResult GetReasons(int selectedValue)
        {
            FinishReasonsActionsModel model = new FinishReasonsActionsModel();
            FinishFacade facde = new FinishFacade();
            model.ContactReasons = facde.GetContactReasons(selectedValue);
            model.ContactActions = facde.GetContactAction(selectedValue);
            return PartialView("_ReasonsActions", model);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [NoCache]
        public ActionResult Save(FinishModel model)
        {
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            
            // Set the session variables on the model.
            model.ServiceRequestID = DMSCallContext.ServiceRequestID;
            model.CaseID = DMSCallContext.CaseID;
            model.MemberID = DMSCallContext.MemberID;
            model.InBoundCallId = DMSCallContext.InboundCallID;
            model.ProgramID = DMSCallContext.ProgramID;
            //KB: The dynamic elements are now populated via the Ajax call.
            //if(DMSCallContext.StartCallData!=null)
            //{
            //    model.DynamicDataElements = DMSCallContext.StartCallData.DynamicDataElements;
            //}
            FinishFacade facade = new FinishFacade();
            string loggedInUser = LoggedInUserName;
            facade.Save(model,Request.RawUrl,loggedInUser,HttpContext.Session.SessionID,DMSCallContext.MembershipID);
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
                DMSCallContext.ServiceRequestID = 0;
                DMSCallContext.MemberID = 0;
                DMSCallContext.CaseID = 0;
                result.TabNavigation = "Queue";
                if (DMSCallContext.IsFromHistoryList)
                {
                    result.TabNavigation = "History";
                }
                DMSCallContext.Reset();
               
            }

           
            var commentFacade = new CommentFacade();
            var currentUser = LoggedInUserName;
            if (!string.IsNullOrEmpty(DMSCallContext.ServiceTechComments))
            {
                commentFacade.Save(null, EntityNames.SERVICE_REQUEST, model.ServiceRequestID, DMSCallContext.ServiceTechComments, currentUser);
                DMSCallContext.ServiceTechComments = string.Empty;
            }

            return Json(result);
        }
        #endregion

    }
}
