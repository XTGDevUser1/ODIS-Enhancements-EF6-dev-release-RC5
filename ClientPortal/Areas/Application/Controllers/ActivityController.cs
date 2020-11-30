using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using ClientPortal.Common;
using System.Text;
using ClientPortal.Models;
using ClientPortal.Areas.Application.Models;
using ClientPortal.ActionFilters;
using Kendo.Mvc.UI;

namespace ClientPortal.Areas.Application.Controllers
{
    public class ActivityController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult Index()
        {
            return View();
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_ACTIVITY)]
        public ActionResult _Activity(string id)
        {
            int serviceRequestID = 0;
            int.TryParse(id, out serviceRequestID);
            logger.Info("Inside Index() of QueueController. Attempt to call the view");
            ActivityFacade activityFacade = new ActivityFacade();
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                PageSize = 10,
            };
            List<ActivityList_Result> list = activityFacade.List(serviceRequestID > 0 ? serviceRequestID : DMSCallContext.ServiceRequestID, pageCriteria);
            ViewData["ServiceRequestID"] = id;
            int totalRows = 0;
            if (list.Count > 0 && list[0].TotalRows.HasValue)
            {
                totalRows = list[0].TotalRows.Value;
            }
            //   DateTime.Now.ToString("dddd, MMMM dd, yyyy h:mm:ss tt")
            return PartialView("_Activity", list);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <param name="filterColumnName"></param>
        /// <param name="filterColumnValue"></param>
        /// <returns></returns>
        [NoCache]
        public JsonResult List([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, string serviceRequestID)
        {
            int serviceRequestIDInt = 0;
            int.TryParse(serviceRequestID, out serviceRequestIDInt);
            logger.Info("Inside List() of QueueController. Attempt to get Queue depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            ViewData["ServiceRequestID"] = serviceRequestID;
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,

                WhereClause = GetCustomWhereClauseXml(filterColumnName, filterColumnValue)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }


            ActivityFacade activityFacade = new ActivityFacade();
            List<ActivityList_Result> list = activityFacade.List(serviceRequestIDInt > 0 ? serviceRequestIDInt : DMSCallContext.ServiceRequestID, pageCriteria);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0 && list[0].TotalRows.HasValue)
            {
                totalRows = list[0].TotalRows.Value;
            }
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            return Json(new DataSourceResult() { Data = list, Total = totalRows }, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="columnName"></param>
        /// <param name="filterValue"></param>
        /// <returns></returns>

        public string GetCustomWhereClauseXml(string columnName, string filterValue)
        {
            StringBuilder WhereClauseXml = new StringBuilder();
            if (!string.IsNullOrEmpty(columnName) && !string.IsNullOrEmpty(filterValue))
            {
                WhereClauseXml.Append("<ROW><Filter");
                string filterFinalValue = ((filterValue.Replace("&", "")).Replace("<", "")).Replace("\"", "");
                WhereClauseXml.Append(" ");
                WhereClauseXml.AppendFormat("{0}Operator=\"{1}\" ", columnName, 11);
                WhereClauseXml.AppendFormat(" {0}Value=\"{1}\"", columnName, filterFinalValue);
                WhereClauseXml.Append("></Filter></ROW>");
            }

            return WhereClauseXml.ToString();
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult UpdateActivityStatus()
        {
            OperationResult result = new OperationResult();

            int serviceRequestId = DMSCallContext.ServiceRequestID;
            if (serviceRequestId != 0)
            {
                var facade = new ActivityFacade();
                logger.InfoFormat("Updating the activity tab status for service request id {0}", serviceRequestId);
                facade.LogActivity(serviceRequestId, Request.RawUrl, LoggedInUserName, EventNames.LEAVE_ACTIVITY_TAB, HttpContext.Session.SessionID);
            }
            result.Status = OperationStatus.SUCCESS;
            return Json(result);

        }
        #endregion

    }
}
