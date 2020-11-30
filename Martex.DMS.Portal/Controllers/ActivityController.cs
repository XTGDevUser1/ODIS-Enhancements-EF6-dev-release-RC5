using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
//using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Telerik.Web.Mvc;
using Martex.DMS.Common;
using System.Text;
using Martex.DMS.Models;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.ActionFilters;

namespace Martex.DMS.Areas.Application.Controllers
{
    public class ActivityController : Controller
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
        public ActionResult _Activity(string srid)
        {
          //  logger.Info("Inside Index() of QueueController. Attempt to call the view");
            ActivityFacade activityFacade = new ActivityFacade();
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                PageSize = 10,
            };
            List<ActivityList_Result> list = activityFacade.List(int.Parse(srid), pageCriteria);
            //DMSCallContext.ServiceRequestID
            int totalRows = 0;
            if (list.Count > 0 && list[0].TotalRows.HasValue)
            {
                totalRows = list[0].TotalRows.Value;
            }
         //   DateTime.Now.ToString("dddd, MMMM dd, yyyy h:mm:ss tt")
            ViewData["srid"] = srid;
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
        [GridAction(EnableCustomBinding = true)]
        public ActionResult List(GridCommand command, string filterColumnName, string filterColumnValue,string srid)
        {
            //logger.Info("Inside List() of QueueController. Attempt to get Queue depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = command.PageSize * (command.Page - 1) + 1,
                EndInd = command.PageSize * command.Page,
                PageSize = command.PageSize,

                WhereClause = GetCustomWhereClauseXml(filterColumnName, filterColumnValue)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }


            ActivityFacade activityFacade = new ActivityFacade();
            List<ActivityList_Result> list = activityFacade.List(int.Parse(srid), pageCriteria);
           // logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0 && list[0].TotalRows.HasValue)
            {
                totalRows = list[0].TotalRows.Value;
            }
           // logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            return View(new GridModel() { Data = list, Total = totalRows });
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
        //[HttpPost]
        //[ValidateInput(false)]
        //[NoCache]
        //public ActionResult UpdateActivityStatus()
        //{
        //    OperationResult result = new OperationResult();

        //    int serviceRequestId = DMSCallContext.ServiceRequestID;
        //    if (serviceRequestId != 0)
        //    {
        //        var facade = new ActivityFacade();
        //        logger.InfoFormat("Updating the activity tab status for service request id {0}", serviceRequestId);
        //        facade.LogActivity(serviceRequestId, Request.RawUrl, LoggedInUserName, EventNames.LEAVE_ACTIVITY_TAB, HttpContext.Session.SessionID);
        //    }
        //    result.Status = OperationStatus.SUCCESS;
        //    return Json(result);

       // }
        #endregion

    }
}
