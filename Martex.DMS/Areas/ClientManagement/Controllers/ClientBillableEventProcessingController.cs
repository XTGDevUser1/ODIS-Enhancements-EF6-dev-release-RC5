using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.Entities.Clients;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Martex.DMS.Common;
using Kendo.Mvc.UI;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.BLL.Model.Clients;
using Martex.DMS.Models;
using Martex.DMS.DAL.DAO.Clients;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    public class ClientBillableEventProcessingController : BaseController
    {
        /// <summary>
        /// Clients the billable event processing save details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [DMSAuthorize]
        public ActionResult ClientBillableEventProcessingSaveDetails(ClientBillableEventProcessingDetailsModel model)
        {
            logger.InfoFormat("Inside ClientBillableEventProcessingSaveDetails method in ClientBillableEventProcessingController with record id : {0}", model.BillingInvoiceDetailID);
            OperationResult result = new OperationResult();
            ClientsFacade facade = new ClientsFacade();
            logger.Info("Validating the record");
            model.Validate();
            logger.Info("Validated Successfully");
            logger.Info("Saving Client Billable Event Processing Details");
            facade.SaveClientBillableEventProcessingDetails(model, LoggedInUserName, Session.SessionID);
            logger.Info("Saved Client Billable Event Processing Details Successfully");
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CLIENT_BILLING)]
        public ActionResult Index()
        {
            logger.Info("Inside Index method in ClientBillableEventProcessingController");
            ClientBillableEventProcessingSearchCriteria model = null;
            logger.Info("Retrieving the Search Criteria Model");
            model = model.GetModelForSearchCriteria();
            logger.Info("Retried the Search Criteria Model");
            return View(model);
        }

        /// <summary>
        /// Gets the billing definition invoice line.
        /// </summary>
        /// <param name="recordID">The record identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _BillingDefinitionInvoiceLine(int? recordID)
        {
            logger.InfoFormat("Inside _BillingDefinitionInvoiceLine method in ClientBillableEventProcessingController with record id : {0}.", recordID);
            ClientBillableEventProcessingSearchCriteriaPartial model = new ClientBillableEventProcessingSearchCriteriaPartial();
            List<CheckBoxLookUp> line = new List<CheckBoxLookUp>();
            logger.Info("Retrieving the Billing Definition Invoice Lines List.");
            List<BillingDefinitionInvoiceLine> lineDetails = ReferenceDataRepository.GetBillingDefinitionInvoiceLine(recordID.GetValueOrDefault());
            logger.Info("Retried the Billing Definition Invoice Lines List Successfully.");
            if (model.BillingDefinitionInvoiceLine == null)
            {
                foreach (var status in lineDetails)
                {
                    line.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.BillingDefinitionInvoiceLine = line;
            }
            logger.Info("Returning the Partial View _BillingDefinitionInvoiceLine.");
            return PartialView(model);
        }


        [HttpPost]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.BillingEvent, true)]
        [ReferenceDataFilter(StaticData.BillingScheduleType, true)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        public ActionResult _SearchCriteria(ClientBillableEventProcessingSearchCriteria model)
        {
            logger.InfoFormat("Inside _SearchCriteria method in ClientBillableEventProcessingController.");
            ClientBillableEventProcessingSearchCriteria tempModel = model;
            ModelState.Clear();
            ViewData[StaticData.BillingDefinitionInvoice.ToString()] = ReferenceDataRepository.GetBillingDefinitionInvoice(model.ClientID.GetValueOrDefault()).ToSelectListItem(u => u.ID.ToString(), y => y.Description, true).ToList();
            if (model.FilterToLoadID.HasValue)
            {
                ClientBillableEventProcessingSearchCriteria dbModel = tempModel.GetView(model.FilterToLoadID) as ClientBillableEventProcessingSearchCriteria;
                if (dbModel != null)
                {
                    return PartialView(dbModel);
                }
            }
            return PartialView(tempModel.GetModelForSearchCriteria());
        }

        [HttpPost]
        [DMSAuthorize]
        public ActionResult _SelectedCriteria(ClientBillableEventProcessingSearchCriteria model)
        {
            return PartialView(model.GetModelForSearchCriteria());
        }

        [HttpPost]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.BillingInvoiceDetailStatus, true)]
        [ReferenceDataFilter(StaticData.BillingAdjustmentReason, true)]
        [ReferenceDataFilter(StaticData.BillingExcludeReason, true)]
        [ReferenceDataFilter(StaticData.BillingDispositionStatus, true)]
        public ActionResult _BillingInvoiceDetails(int recordID, string mode,string gridName,string tabName)
        {
            // WHERE recordID = BillingInvoiceDetail.ID 

            ClientsFacade facade = new ClientsFacade();
            BillingDetailMaintenanceModel model = facade.GetBillingInvoiceDetail(recordID);
            model.DisplayMode = mode;
            //When the Invoice Is Posted it should be open in View Mode.
            if (!string.IsNullOrEmpty(model.BillingInvoiceDetails.DetailStatus) &&(
                                      model.BillingInvoiceDetails.DetailStatus.Equals("Posted", StringComparison.OrdinalIgnoreCase) || model.BillingInvoiceDetails.DetailStatus.Equals("Deleted", StringComparison.OrdinalIgnoreCase)))
            {
                model.DisplayMode = "View";
            }
            model.ParentGridName = gridName;
            model.ParentTabName = tabName;
            return PartialView(model);
        }

        [HttpPost]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.BillingScheduleType, true)]
        [ReferenceDataFilter(StaticData.RegenerateBillingEventsClientList, true)]
        public ActionResult _ReGenerateBillingEventDetails()
        {
            ViewData[StaticData.BillingDefinitionInvoice.ToString()] = ReferenceDataRepository.GetBillingDefinitionInvoice(0).ToSelectListItem<BillingDefinitionInvoice>(x => x.ID.ToString().ToString(), y => y.Description, true);
            return PartialView();
        }

        [HttpPost]
        [DMSAuthorize]
        public ActionResult _GetClientBillableEventProcessingList([DataSourceRequest] DataSourceRequest request, ClientBillableEventProcessingSearchCriteria model)
        {
            logger.Info("Inside _GetClientBillableEventProcessingList of ClientBillableEventProcessing Controller. Attempt to get all Events depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "BillingInvoiceDetailID";
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
            ClientsFacade facade = new ClientsFacade();
            List<ClientBillableEventProcessingList_Result> list = new List<ClientBillableEventProcessingList_Result>();
            if (filter.Count > 0)
            {
                list = facade.GetClientBillableEventProcessingList(pageCriteria,"POSTED");
            }
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }
    }
}
