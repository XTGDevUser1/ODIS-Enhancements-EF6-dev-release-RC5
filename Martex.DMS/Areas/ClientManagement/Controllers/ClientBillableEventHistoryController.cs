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
    public class ClientBillableEventHistoryController : BaseController
    {
        //
        // GET: /ClientManagement/ClientBillableEventHistory/
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_BILLING_BILLINGHISTORY)]
        public ActionResult Index()
        {
            ClientBillableEventProcessingSearchCriteria model = null;
            model = model.GetModelForSearchCriteria();
            return View(model);
        }

        
        [DMSAuthorize]
        [NoCache]
        public ActionResult _BillingDefinitionInvoiceLine(int? recordID)
        {
            // WHERE recordID = BillingDefinitionInvoiceID
            ClientBillableEventProcessingSearchCriteriaPartial model = new ClientBillableEventProcessingSearchCriteriaPartial();
            List<CheckBoxLookUp> line = new List<CheckBoxLookUp>();
            List<BillingDefinitionInvoiceLine> lineDetails = ReferenceDataRepository.GetBillingDefinitionInvoiceLine(recordID.GetValueOrDefault());
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
            return PartialView(model);
        }


        [HttpPost]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.BillingEvent, true)]
        [ReferenceDataFilter(StaticData.BillingScheduleType, true)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        public ActionResult _SearchCriteria(ClientBillableEventProcessingSearchCriteria model)
        {
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
        public ActionResult _BillingInvoiceDetails(int recordID, string mode, string gridName, string tabName)
        {
            // WHERE recordID = BillingInvoiceDetail.ID 

            ClientsFacade facade = new ClientsFacade();
            BillingDetailMaintenanceModel model = facade.GetBillingInvoiceDetail(recordID);
            model.DisplayMode = mode;
            //When the Invoice Is Posted it should be open in View Mode.
            if (!string.IsNullOrEmpty(model.BillingInvoiceDetails.DetailStatus) && (
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
        public ActionResult _GetClientBillableEventProcessingList([DataSourceRequest] DataSourceRequest request, ClientBillableEventProcessingSearchCriteria model)
        {
            logger.Info("Inside _GetClientBillableEventProcessingList of ClientBillableEventHistory Controller. Attempt to get all Events depending upon the GridCommand");
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
                list = facade.GetClientBillableEventProcessingList(pageCriteria, "POSTED");
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
