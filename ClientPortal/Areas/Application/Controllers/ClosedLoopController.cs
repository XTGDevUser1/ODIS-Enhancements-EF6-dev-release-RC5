using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using ClientPortal.Areas.Common.Controllers;
using ClientPortal.ActionFilters;
using ClientPortal.Models;
using Martex.DMS.BLL.Model;
using ClientPortal.Common;
using System.Text;
using ClientPortal.Areas.Application.Models;
using System.Xml;
using Kendo.Mvc.UI;

namespace ClientPortal.Areas.Application.Controllers
{
    public class ClosedLoopController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult Search()
        {
            logger.Info("Inside Search() of Closed Loop Controller");
            
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortColumn = "MemberName",
                SortDirection = "ASC",
                PageSize = 10
            };
            List<CloseLoopSearch_Result> list = new List<CloseLoopSearch_Result>();
            return PartialView("_Search", list);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="Id"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult GetCloseLoopID(string Id)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside GetCloseLoopID() of Close Loop. Call by the grid with the userId {0}, try to returns the Json object", Id);
            return Json(new { IdValue = Id }, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <param name="searchCriteria"></param>
        /// <returns></returns>
        [DMSAuthorize]

        [NoCache]
        [ValidateInput(false)]
        public ActionResult SearchList([DataSourceRequest] DataSourceRequest request, CloseLoopSearchCriteria searchCriteria)
        {
            int totalRows = 0;
            List<CloseLoopSearch_Result> list = new List<CloseLoopSearch_Result>();

            if (!string.IsNullOrEmpty(searchCriteria.MemberNumber) ||
                !string.IsNullOrEmpty(searchCriteria.LastName) ||
                !string.IsNullOrEmpty(searchCriteria.FirstName) ||
                !string.IsNullOrEmpty(searchCriteria.CallbackNumber)
                )
            {
                logger.Info("Inside SearchList of ClosedLoop Controller");
                GridUtil gridUtil = new GridUtil();
                string sortColumn = "MemberName";
                string sortOrder = "ASC";
                if (request.Sorts.Count > 0)
                {
                    sortColumn = request.Sorts[0].Member;
                    sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
                }
                PageCriteria pageCriteria = new PageCriteria()
                {
                    StartInd = request.PageSize * (request.Page - 1) + 1,
                    EndInd = request.PageSize * request.Page,
                    PageSize = request.PageSize,
                    SortColumn = sortColumn,
                    SortDirection = sortOrder,
                    WhereClause = GetWhereClauseXML(searchCriteria)
                };
                POFacade facade = new POFacade();
                if (string.IsNullOrEmpty(pageCriteria.WhereClause))
                {
                    pageCriteria.WhereClause = null;
                }             
                
                int inboundCallId = DMSCallContext.InboundCallID;
                string loggedInUserName = GetLoggedInUser().UserName;
                list = new MemberFacade().GetClosedLoop(loggedInUserName, Request.RawUrl, inboundCallId, pageCriteria, HttpContext.Session.SessionID);

                if (list.Count > 0)
                {
                    totalRows = list[0].TotalRows.Value;
                }
            }

            return Json(new DataSourceResult() { Data = list, Total = totalRows });
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <param name="searchCriteria"></param>
        /// <returns></returns>
        //[DMSAuthorize]
        //[GridAction(EnableCustomBinding = true)]
        //[NoCache]
        //[ValidateInput(false)]
        //public ActionResult SearchList(GridCommand command, CloseLoopSearchCriteria searchCriteria)
        //{
        //    int totalRows = 0;
        //    logger.Info("Inside SearchList() of Member Controller");
        //    GridUtil gridUtil = new GridUtil();
        //    string sortColumn = "MemberName";
        //    string sortOrder = "ASC";
        //    if (command.SortDescriptors.Count > 0)
        //    {
        //        sortColumn = command.SortDescriptors[0].Member;
        //        sortOrder = (command.SortDescriptors[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
        //    }
        //    PageCriteria pageCriteria = new PageCriteria()
        //    {
        //        StartInd = command.PageSize * (command.Page - 1) + 1,
        //        EndInd = command.PageSize * command.Page,
        //        PageSize = command.PageSize,
        //        SortColumn = sortColumn,
        //        SortDirection = sortOrder,
        //        WhereClause = GetWhereClauseXML(searchCriteria)
        //    };

        //    int inboundCallId = DMSCallContext.InboundCallID;
        //    string loggedInUserName = GetLoggedInUser().UserName;
        //    List<CloseLoopSearch_Result> list = new MemberFacade().GetClosedLoop(loggedInUserName, Request.RawUrl, inboundCallId, pageCriteria,HttpContext.Session.SessionID);
        //    if (list.Count > 0)
        //    {
        //        totalRows = list[0].TotalRows.Value;
        //    }
        //    logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
        //    return View("_Search", new GridModel() { Data = list, Total = totalRows });
        //}
        #endregion

        #region Private Methods
        private string GetWhereClauseXML(CloseLoopSearchCriteria searchCriteria)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");
                // Append operator and values
                if (!string.IsNullOrEmpty(searchCriteria.MemberNumber))
                {
                    writer.WriteAttributeString("MemberNumberOperator", "6");
                    writer.WriteAttributeString("MemberNumberValue", searchCriteria.MemberNumber);
                }
                if (!string.IsNullOrEmpty(searchCriteria.LastName))
                {
                    writer.WriteAttributeString("LastNameOperator", "6");
                    writer.WriteAttributeString("LastNameValue", searchCriteria.LastName);
                }
                if (!string.IsNullOrEmpty(searchCriteria.FirstName))
                {
                    writer.WriteAttributeString("FirstNameOperator", "6");
                    writer.WriteAttributeString("FirstNameValue", searchCriteria.FirstName);
                }
                if (!string.IsNullOrEmpty(searchCriteria.CallbackNumber))
                {
                    writer.WriteAttributeString("CallbackNumberOperator", "6");
                    writer.WriteAttributeString("CallbackNumberValue", searchCriteria.CallbackNumber);
                }
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }
            return whereClauseXML.ToString();
        }
        #endregion

    }
}
