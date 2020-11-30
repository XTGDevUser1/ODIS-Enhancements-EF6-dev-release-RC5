using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Models;
using Martex.DMS.BLL.Model;
using Martex.DMS.Common;
using System.Text;
using Martex.DMS.Areas.Application.Models;
using System.Xml;
using Kendo.Mvc.UI;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class ClosedLoopController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// Searches this instance.
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
            List<CloseLoopSearch_Result> list = null;
            return PartialView("_Search", list);
        }
        /// <summary>
        /// Gets the close loop ID.
        /// </summary>
        /// <param name="Id">The id.</param>
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
        /// Searches the list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        [DMSAuthorize]

        [NoCache]
        [ValidateInput(false)]
        public ActionResult SearchList([DataSourceRequest] DataSourceRequest request, CloseLoopSearchCriteria searchCriteria)
        {
            int totalRows = 0;
            List<CloseLoopSearch_Result> list = new List<CloseLoopSearch_Result>();
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
            return Json(new DataSourceResult() { Data = list, Total = totalRows });
        }

        #endregion

        #region Private Methods
        /// <summary>
        /// Gets the where clause XML.
        /// </summary>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
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
