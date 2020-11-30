using log4net;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.Models;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.Common;

namespace SRTracker.Controllers
{
    public class HomeController : Controller
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(HomeController));

        [Route("TrackSR/{serviceRequestID}")]
        public ActionResult TrackSR(string serviceRequestID)
        {
            var refreshInterval = AppConfigRepository.GetValue(AppConfigConstants.STATUS_PAGE_AUTOREFRESH_INTERVAL_IN_MILLIS);
            var iRefreshInterval = 3000; /* default */
            int.TryParse(refreshInterval, out iRefreshInterval);
            ViewBag.AutoRefreshInterval = iRefreshInterval; /* milliseconds */
            ViewBag.ServiceRequestID = serviceRequestID;
            return View();
        }

        [HttpPost]
        public ActionResult _ServiceRequestDetails(int? serviceRequestID, bool loadTemplates)
        {
            OperationResult result = new OperationResult();

            if (serviceRequestID == null)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = "Invalid Service Request ID";
                return Json(result, JsonRequestBehavior.AllowGet);
            }

            logger.InfoFormat("Looking up SR for ID = {0}", serviceRequestID);
            var srRepository = new ServiceRequestRepository();
            //var serviceRequest = srRepository.GetByTrackerID(Guid.Parse(serviceRequestID));
            //var serviceRequest = srRepository.GetById(int.Parse(serviceRequestID));
            logger.InfoFormat("START getting SR Details - {0}", serviceRequestID);

            var queueRepository = new QueueRepository();
            var srDetails = queueRepository.GetServiceRequest(serviceRequestID.Value);
            var serviceRequestDetail = srDetails.OrderByDescending(x => x.PONumber).FirstOrDefault();

            logger.InfoFormat("DONE getting SR Details - {0}", serviceRequestID);

            if (serviceRequestDetail != null)
            {
                int iServiceRequestID = serviceRequestDetail.RequestNumber;
                logger.InfoFormat("Determined SR ID {0}", iServiceRequestID);

                logger.InfoFormat("START getting service request status history for SR {0}", iServiceRequestID);
                var srStatusHistory = srRepository.GetStatusHistory(iServiceRequestID);
                logger.InfoFormat("DONE retrieving service request status history for SR {0}", iServiceRequestID);

                string mapSnapshot = string.Empty;
                string dispatchPhoneNumber = string.Empty;
                List<NameValuePair> templates = null;
                // Do not load the information that doesn't change.
                if (loadTemplates)
                {
                    templates = GetTemplates(serviceRequestDetail.ProgramID.GetValueOrDefault());

                    var srFromDB = srRepository.GetById(iServiceRequestID);
                    mapSnapshot = srFromDB.MapSnapshot;

                    dispatchPhoneNumber = GetDispatchPhoneNumber(serviceRequestDetail.ProgramID.GetValueOrDefault());
                }
                result.Data = new { ServiceRequestDetail = serviceRequestDetail, StatusHistory = srStatusHistory, MapSnapshot = mapSnapshot, Templates = templates, DispatchPhoneNumber = dispatchPhoneNumber };
            }

            return Json(result, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// Gets the templates.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        private List<NameValuePair> GetTemplates(int programID)
        {
            List<NameValuePair> listOfTemplates = new List<NameValuePair>();
            TryAddingToList(listOfTemplates, TemplateNames.HAS_SERVICE_ARRIVED, null);
            string dispatchPhoneNumber = GetDispatchPhoneNumber(programID);
            Hashtable ht = new Hashtable();
            ht.Add("DispatchPhoneNumber", dispatchPhoneNumber);
            TryAddingToList(listOfTemplates, TemplateNames.HAS_SERVICE_ARRIVED_NO, ht);

            TryAddingToList(listOfTemplates, TemplateNames.SERVICE_NOT_ARRIVED_NO_CALL, null);

            return listOfTemplates;
        }

        private static string GetDispatchPhoneNumber(int programID)
        {
            var programDispatchNumber = new ProgramMaintenanceRepository().GetProgramDispatchNumbers(programID).FirstOrDefault();
            return programDispatchNumber != null ? programDispatchNumber.DispatchPhoneNumber.BlankIfNull() : string.Empty;
        }

        /// <summary>
        /// Tries to add to the list after checking if Templates are set up.
        /// </summary>
        /// <param name="list">The list.</param>
        /// <param name="templateName">Name of the template.</param>
        /// <param name="dataForSubstitution">The data for substitution.</param>
        /// <exception cref="DMSException"></exception>
        private void TryAddingToList(List<NameValuePair> list, string templateName, Hashtable dataForSubstitution)
        {
            var templateRepository = new TemplateRepository();
            var template = templateRepository.GetTemplateByName(templateName);
            if (template == null)
            {
                throw new DMSException(string.Format("Template {0} not defined", templateName));
            }

            list.Add(new NameValuePair() { Name = TemplateUtil.ProcessTemplate(template.Subject,dataForSubstitution), Value = TemplateUtil.ProcessTemplate(template.Body,dataForSubstitution) });
        }



        [HttpPost]
        public ActionResult ShouldFollowup(int serviceRequestID)
        {
            OperationResult result = new OperationResult();
            var repository = new ServiceRequestRepository();

            var listOfContactLogActions = repository.GetContactLogActions(serviceRequestID);

            var shouldAskForResponse = (listOfContactLogActions.Count > 0 && listOfContactLogActions.Where(x => x.ContactAction == "Sent" ||
                                                               x.ContactAction == "SendFailure").Count() > 0 &&
                            listOfContactLogActions.Where(x => x.ContactAction == "ServiceArrived" ||
                                                                x.ContactAction == "ServiceNotArrived" ||
                                                                x.ContactAction == "NoAnswer").Count() == 0);
            int? contactLogID = null;
            if (shouldAskForResponse)
            {
                contactLogID = (from c in listOfContactLogActions
                                orderby c.ContactLogID descending
                                where c.ContactMethodName == ContactMethodNames.MOBILE_NOTIFICATION
                                select c.ContactLogID).FirstOrDefault();
            }
            result.Data = new { Followup = shouldAskForResponse, ContactLogID = contactLogID };
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult LogResponse(int serviceRequestID, string contactLogID, string serviceStatus)
        {
            OperationResult result = new OperationResult();
            var closedLoopFacade = new ClosedLoopFacade();
            logger.InfoFormat("Processing Log Response with parameters {0}, {1}, {2}", serviceRequestID, contactLogID, serviceStatus);
            switch (serviceStatus)
            {
                case "Complete":
                case "NotArrived":
                    closedLoopFacade.UpdateClosedLoopCallResults("Answered", serviceStatus, contactLogID);
                    break;
                case "NoAnswer":
                    /*
                     * Update the SR attributes
                     * Set SR Next Action = Manual Closed Loop
                     * Set SR Assigned To = Agent User
                     * Set SR Next Action Scheduled = Now
                     */
                    var serviceFacade = new ServiceFacade();
                    serviceFacade.UpdateNextActionAndAssignedTo(serviceRequestID, "ManualClosedLoop", "AgentUser", DateTime.Now, Request.RawUrl, null, User.Identity.Name);
                    break;
                default:
                    break;
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}