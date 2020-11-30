using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.Models;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO.QA;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Areas.QA.Controllers
{
    [ValidateInput(false)]
    public class CXCoachingConcernController : BaseController
    {
        #region Listing

        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CX_COACHING_CONCERN)]
        [ReferenceDataFilter(StaticData.ConcernType, true)]
        public ActionResult Index()
        {
            return View();
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="request"></param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult CoachingConcernList([DataSourceRequest] DataSourceRequest request, CoachingConcernsSearchCriteria searchParams)
        {
            logger.Info("Inside Coaching Concern List of QACoaching Concern Controller. Attempt to get all Message depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ID";
            string sortOrder = "DESC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = searchParams.GetFilterClause();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.GetXML()
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }

            List<CoachingConcerns_List_Result> list = CoachingConcernService.List(pageCriteria, LoggedInUserName);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.GetValueOrDefault();
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }

        #endregion

        #region CRUD
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.ConcernType, false)]
        [ReferenceDataFilter(StaticData.UsersAgentTech, false)]
        public ActionResult _CoachingConcernDetails(int? recordID, string mode)
        {
            ViewBag.PageMode = mode;
            CoachingConcern model = CoachingConcernService.Get(recordID.GetValueOrDefault(), true);
            ViewData[StaticData.Concern.ToString()] = ReferenceDataRepository.GetConcern(model.ConcernTypeID.GetValueOrDefault()).ToSelectListItem<Concern>(u => u.ID.ToString(), v => v.Description, true);
            return PartialView(model);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveDetails(CoachingConcern model)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Trying to Insert or Update Coaching Concern record for ID {0}", model.ID);
            CoachingConcernService.SaveDetails(model, LoggedInUserName, Request.RawUrl, Session.SessionID);
            logger.InfoFormat("Coaching Concern Insert or Update success for ID {0}", model.ID);
            return Json(result);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult DeleteCoachingConcern(int recordID)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Trying to delete Coaching Concern for ID {0}", recordID);
            CoachingConcernService.Delete(recordID, LoggedInUserName);
            logger.InfoFormat("Coaching Concern record deleted for ID {0}", recordID);
            return Json(result);
        }
        #endregion

        #region Filters

        [ReferenceDataFilter(StaticData.UserAgents, true)]
        [ReferenceDataFilter(StaticData.UserManagers, true)]
        [ReferenceDataFilter(StaticData.CoachingConcernNameType, true)]
        [ReferenceDataFilter(StaticData.SearchFilterTypes, true)]
        [ReferenceDataFilter(StaticData.ConcernType, true)]
        public ActionResult _SearchCriteria(CoachingConcernsSearchCriteria model)
        {
            CoachingConcernsSearchCriteria tempModel = model;
            ModelState.Clear();
            if (model != null && model.FilterToLoadID.HasValue)
            {
                CoachingConcernsSearchCriteria dbModel = tempModel.GetView(model.FilterToLoadID) as CoachingConcernsSearchCriteria;
                if (dbModel != null)
                {
                    ViewData[StaticData.Concern.ToString()] = ReferenceDataRepository.GetConcern(model.SearchByConcernTypeID.GetValueOrDefault()).ToSelectListItem<Concern>(u => u.ID.ToString(), v => v.Description, true);
                    return PartialView(dbModel);
                }
            }
            ViewData[StaticData.Concern.ToString()] = ReferenceDataRepository.GetConcern(model.SearchByConcernTypeID.GetValueOrDefault()).ToSelectListItem<Concern>(u => u.ID.ToString(), v => v.Description, true);
            return PartialView(tempModel.GetModelForSearchCriteria());
        }

        [HttpPost]
        public ActionResult _SelectedCriteria(CoachingConcernsSearchCriteria model)
        {
            return PartialView(model.GetModelForSearchCriteria());
        }
        #endregion

        #region Documents
        /// <summary>
        /// Where ID Refers to Coaching Concern ID
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult Documents(int id, string mode)
        {
            logger.InfoFormat("Trying to load documents for the  Concern ID {0}", id);
            ViewData["CoachingConcernId"] = id.ToString();
            ViewBag.PageMode = mode;
            return PartialView();
        }
        #endregion
    }
}
