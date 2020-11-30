using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Kendo.Mvc.UI;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Common;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.Claims.Controllers
{
    [DMSAuthorize]
    public class ClaimsACESPaymentsController : BaseController
    {
        ClaimsFacade facade = new ClaimsFacade();

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CLAIMS_ACESPAYMENTS)]
        public ActionResult Index()
        {
            ViewData["PaymentType"] = ReferenceDataRepository.GetPaymentTypesForACES().ToSelectListItem(x => x.Text, y => y.Value, "Check");
            ViewData["LoggedInUser"] = LoggedInUserName;
            ClientsFacade facade = new ClientsFacade();
            ViewData["DefaultACESPaymentListDays"] = AppConfigRepository.GetValue(AppConfigConstants.DEFAULT_ACES_PAYMENT_LIST_DAYS);
            //Client client = facade.GetByClientName(StringConstants.ACES_CLIENT_FORD);
            //decimal value = 0;
            //if (client != null)
            //{
            //    ViewData["PaymentBalance"] = client.PaymentBalance.ToString();
            //}
            //else
            //{
            //    ViewData["PaymentBalance"] = value.ToString();
            //}
            return View();
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CLAIMS_ACESPAYMENTS)]
        public ActionResult _GetPaymentsList([DataSourceRequest] DataSourceRequest request, ClaimACESPaymentSearchCriteria model)
        {

            logger.Info("Inside _GetPaymentsList of ClaimsACESPaymentsController. Attempt to get all the Rates depending upon the GridCommand ");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "RecievedDate";
            string sortOrder = "DESC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = model.GetFilterClause();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            //if (pageCriteria.PageSize < 1)
            //{
            //    pageCriteria.PageSize = 10;
            //    pageCriteria.EndInd = 10;
            //}
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            List<ACESPaymentList_Result> paymentsList = new List<ACESPaymentList_Result>();

            paymentsList = facade.GetACESPaymentsList(pageCriteria);
            logger.InfoFormat("Call the view by sending {0} number of records", paymentsList.Count);

            int totalRows = 0;
            if (paymentsList.Count > 0)
            {
                totalRows = paymentsList[0].TotalRows.Value;
            }
            var result = new DataSourceResult()
            {
                Data = paymentsList,
                Total = totalRows
            };
            return Json(result, JsonRequestBehavior.AllowGet);
        }


        public ActionResult GetPaymentAmount()
        {
            OperationResult result = new OperationResult();
            ClientsFacade clientsFacade = new ClientsFacade();
            Client client = clientsFacade.GetByClientName(StringConstants.ACES_CLIENT_FORD);
            decimal value = 0;
            if (client != null)
            {
                value = client.PaymentBalance.GetValueOrDefault();
            }
            result.Data = value;
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _InsertACESPayment([DataSourceRequest] DataSourceRequest request, ACESPaymentList_Result payment)
        {
            OperationResult result = new OperationResult();
            facade.InsertACESPayment(payment, LoggedInUserName);


            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _UpdateACESPayment([DataSourceRequest] DataSourceRequest request, ACESPaymentList_Result payment)
        {
            OperationResult result = new OperationResult();
            result.Status = "Success";
            facade.UpdateACESPayment(payment, LoggedInUserName);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _DeleteACESPayment([DataSourceRequest] DataSourceRequest request, ACESPaymentList_Result payment)
        {
            OperationResult result = new OperationResult();
            result.Status = "Success";
            facade.DeleteACESPayment(payment, LoggedInUserName);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the apply cash.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult _ApplyCash(int? clientId)
        {
            ClientsFacade clientFacade = new ClientsFacade();
            Client client = null;
            if (clientId != null)
            {
                client = clientFacade.Get(clientId.ToString());
                ViewData["ClientId"] = client.ID.ToString();

            }
            else
            {
                client = clientFacade.GetByClientName(StringConstants.ACES_CLIENT_FORD);
                if (client != null)
                {
                    ViewData["ClientId"] = client.ID.ToString();
                }
            }
            ClaimsFacade facade = new ClaimsFacade();
            ApplyCashClaimsModel model = facade.GetApplyCashClaimsDetails();
            if (client != null)
            {
                model.OnAccount = (client.PaymentBalance != null) ? Math.Round(client.PaymentBalance.Value, 2) : 0;
            }
            return View(model);
        }

        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _BindApplyCashClaims([DataSourceRequest] DataSourceRequest request)
        {

            int totalRows = 0;
            ClaimsFacade facade = new ClaimsFacade();
            List<ClaimApplyCashClaimsList_Result> list = facade.GetApplyCashClaimsList();

            if (list.Count > 0)
            {
                totalRows = list.Count;
            }
            return Json(new DataSourceResult() { Data = list, Total = totalRows });
        }

        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        [ReferenceDataFilter(StaticData.ClientPaymentCreatedBy, true)]
        public ActionResult _SearchCriteria(ClaimACESPaymentSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SearchCriteria() model in Claim ACES Payments with Model:{0}", model);
            ViewData["DefaultACESPaymentListDays"] = AppConfigRepository.GetValue(AppConfigConstants.DEFAULT_ACES_PAYMENT_LIST_DAYS);
            var tempHoldModel = model.GetModelForSearchCriteria();
            ModelState.Clear();
            if (model.FilterToLoadID.HasValue)
            {
                ClaimACESPaymentSearchCriteria dbModel = model.GetView(model.FilterToLoadID.Value) as ClaimACESPaymentSearchCriteria;
                if (dbModel != null)
                {
                    return PartialView(dbModel);
                }
            }
            logger.Info("Returns the View");
            return PartialView(tempHoldModel);
        }

        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult _SelectedCriteria(ClaimACESPaymentSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SelectedCriteria() model in Claim ACES Payments with Model:{0}", model);
            logger.Info("Returns the View");
            return View(model.GetModelForSearchCriteria());
        }

        /// <summary>
        /// Update Cash payment balance for selected claims.
        /// </summary>
        /// <param name="claimIdList">The claim unique identifier list.</param>
        /// <param name="totalApplied">The total applied.</param>
        /// <param name="clientId">The client unique identifier.</param>
        /// <param name="paymentBalance">The payment balance.</param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        public ActionResult _ApplyCashClaimFinish(string[] claimIdList, decimal totalApplied, int clientId, decimal paymentBalance)
        {

            OperationResult result = new OperationResult();
            ClaimsFacade facade = new ClaimsFacade();
            logger.InfoFormat("Inside the _ApplyCashClaimFinish method in ClaimsACESPaymentsController");
            logger.InfoFormat("Updating Cash claim for client {0} with Total applied amount {1} and paymentBalance {2}", clientId, totalApplied, paymentBalance);
            facade.UpdateCashClaims(clientId, Request.RawUrl, LoggedInUserName, Session.SessionID, claimIdList, totalApplied, paymentBalance);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
