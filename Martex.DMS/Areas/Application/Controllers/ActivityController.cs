using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.Common;
using System.Text;
using Martex.DMS.Models;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.ActionFilters;
using Kendo.Mvc.UI;
using System.Configuration;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    ///
    /// </summary>
    public class ActivityController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult Index()
        {
            logger.InfoFormat("ActivityController - Index()");
            //int serviceRequestId = DMSCallContext.ServiceRequestID;
            //if (serviceRequestId != 0)
            //{
            //    var facade = new ActivityFacade();
            //    logger.InfoFormat("Updating the activity tab status for service request id {0}", serviceRequestId);
            //    facade.LogActivity(serviceRequestId, Request.RawUrl, LoggedInUserName, EventNames.ENTER_ACTIVITY_TAB, HttpContext.Session.SessionID);
            //}
            return View();
        }
        /// <summary>
        /// _s the activity.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult _Activity(string id, string isCallFrom = "")
        {
            logger.InfoFormat("ActivityController - _Activity() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                ServiceRequestID = id
            }));
            //int serviceRequestID = 0;
            //int.TryParse(id, out serviceRequestID);
            logger.Info("Inside Index() of QueueController. Attempt to call the view");
            ActivityFacade activityFacade = new ActivityFacade();
            //PageCriteria pageCriteria = new PageCriteria()
            //{
            //    StartInd = 1,
            //    EndInd = 10,
            //    PageSize = 10,
            //};
            //List<ActivityList_Result> list = activityFacade.List(serviceRequestID > 0 ? serviceRequestID : DMSCallContext.ServiceRequestID, pageCriteria);
            ViewData["ServiceRequestID"] = id;
            //int totalRows = 0;
            //if (list.Count > 0 && list[0].TotalRows.HasValue)
            //{
            //    totalRows = list[0].TotalRows.Value;
            //}
            ViewData["IsCallFrom"] = isCallFrom;
            ViewData["AmazonConnectURL"] = ConfigurationManager.AppSettings["AmazonConnectCallDetailURL"];

            int serviceRequestId = 0;
            int.TryParse(id, out serviceRequestId);

            if (serviceRequestId != null && serviceRequestId != 0)
            {
                var facade = new ActivityFacade();
                logger.InfoFormat("Updating the activity tab status for service request id {0}", serviceRequestId);
                facade.LogActivity(serviceRequestId, LoggedInUserName);
            }
            return PartialView("_Activity");
        }

        [NoCache]
        [DMSAuthorize]
        public ActionResult _ActivityFromPO(string id, string poID)
        {
            logger.InfoFormat("ActivityController - _ActivityFromPO() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                ServiceRequestID = id,
                PurchaseOrderID = poID
            }));
            //int serviceRequestID = 0;
            //int.TryParse(id, out serviceRequestID);
            logger.Info("Inside Index() of QueueController. Attempt to call the view");
            ActivityFacade activityFacade = new ActivityFacade();
            //PageCriteria pageCriteria = new PageCriteria()
            //{
            //    StartInd = 1,
            //    EndInd = 10,
            //    PageSize = 10,
            //};
            //List<ActivityList_Result> list = activityFacade.List(serviceRequestID > 0 ? serviceRequestID : DMSCallContext.ServiceRequestID, pageCriteria);
            ViewData["ServiceRequestID"] = id;
            ViewData["POID"] = poID;
            //int totalRows = 0;
            //if (list.Count > 0 && list[0].TotalRows.HasValue)
            //{
            //    totalRows = list[0].TotalRows.Value;
            //}
            return PartialView("_Activity");
        }
        /// <summary>
        /// Lists the specified request.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="filterColumnName">Name of the filter column.</param>
        /// <param name="filterColumnValue">The filter column value.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        [NoCache]
        public JsonResult List([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, string serviceRequestID)
        {
            logger.InfoFormat("ActivityController - List() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                DataSourceRequest = request,
                filterColumnName = filterColumnName,
                filterColumnValue = filterColumnValue,
                serviceRequestID = serviceRequestID
            }));
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
            var list = activityFacade.List(serviceRequestIDInt > 0 ? serviceRequestIDInt : DMSCallContext.ServiceRequestID, pageCriteria);
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
        /// Gets the custom where clause XML.
        /// </summary>
        /// <param name="columnName">Name of the column.</param>
        /// <param name="filterValue">The filter value.</param>
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
        /// Updates the activity status.
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
                facade.LogActivity(serviceRequestId, LoggedInUserName);
            }
            result.Status = OperationStatus.SUCCESS;
            return Json(result);

        }
        #endregion

    }
}
