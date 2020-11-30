using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.Areas.VendorManagement.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Model;
using System.Text;
using Martex.DMS.BLL.SMTPSettings;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.Common;
using System.Web.Script.Serialization;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.QA.Controllers
{
    /// <summary>
    /// CX Survey Controller
    /// </summary>
    [ValidateInput(false)]
    public class CXSurveyController : BaseController
    {

        #region Private Members
        private CustomerFeedbackFacade facade = new CustomerFeedbackFacade();
        #endregion
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        /// 


        //
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CX_SURVEY)]
        public ActionResult Index()
        {
            CustomerFeedbackSurveySearchCirteria model = new CustomerFeedbackSurveySearchCirteria();
            model = model.GetModelForSearchCriteria();
            logger.Info("Inside the Index() method in CX Survey Controller");
            return View(model);
        }


        /// <summary>
        /// Survey the search.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult CXSearch([DataSourceRequest] DataSourceRequest request, CustomerFeedbackSurveySearchCirteria model)
        {
            logger.Info("Inside CXSurvey Controller. Attempt to get all Customer Feedback depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = model.GetFilterSearchCritera();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }

            List<CustomerFeedbackSurveyList_Result> list = new List<CustomerFeedbackSurveyList_Result>();            
            if (filter.Count > 0)
            {
                list = facade.GetCustomerFeedbackSurveyList(pageCriteria);
            }
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int? totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows; // uncomment after editing sp
                
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows.GetValueOrDefault()
            };

            var data = Json(result, JsonRequestBehavior.AllowGet);
            data.MaxJsonLength = int.MaxValue;
            return data;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.CustomerFeedbackSearchCriteriaNamesurveyFilterType, true)]
        //[ReferenceDataFilter(StaticData.CustomerFeedbackIDFilterTypes, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackSearchCriteriaValueMemberType, true)]
        public ActionResult _SearchCriteria(CustomerFeedbackSurveySearchCirteria model)
        {
            logger.InfoFormat("Inside the _SearchCriteria() model in CXCustomerFeedbackController with Model:{0}", model);
            //ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            ViewData[StaticData.CustomerFeedbackIDFilterTypes.ToString()] = ReferenceDataRepository.GetCustomerFeedbackIDFilterTypes(CallFrom.SURVEY).ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text.ToString(), true);
            var tempHoldModel = model.GetModelForSearchCriteria();
            ModelState.Clear();
            if (model.FilterToLoadID.HasValue)
            {
                CustomerFeedbackSurveySearchCirteria dbModel = model.GetView(model.FilterToLoadID.Value) as CustomerFeedbackSurveySearchCirteria;
                if (dbModel != null)
                {
                    //    if (dbModel.Statuses.Count != 0)
                    //    {
                    //        ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetCustomerFeedbackStatus().ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
                    //    }
                    return View(dbModel);
                }
            }
            logger.Info("Returns the View");
            return View(tempHoldModel);



        }


        /// <summary>
        /// Loads the selected criteria.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult _SelectedCriteria(CustomerFeedbackSurveySearchCirteria model)
        {
            logger.InfoFormat("Inside the _SelectedCriteria() model in CX Survey with Model:{0}", model);
            logger.Info("Returns the View");
            return View(model.GetModelForSearchCriteria());
        }


        public void UpdateSurvey(int surveyId, string userAction)
        {
            logger.InfoFormat("Inside the UpdateSurvey() model in CX Survey with SurveyID:{0} and UserAction {1}", surveyId,userAction);
            facade.UpdateCustomerSurvey(surveyId, userAction, Session.SessionID, LoggedInUserName, Request.RawUrl);
        }

    }
}
