using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Models;
using Martex.DMS.Areas.ClientManagement.Models;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities.Clients;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    /// <summary>
    /// Client Invoice History Controller
    /// </summary>
    public class ClientInvoiceHistoryController : BaseController
    {
        protected ClientsFacade facade = new ClientsFacade();
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_BILLING_INVOICEHISTORY)]
        [ReferenceDataFilter(StaticData.POProductsForClientInvoice, false)]
        [ReferenceDataFilter(StaticData.BillingInvoiceLineStatus, false)]
        public ActionResult Index()
        {
           
            return View();
        }

        
        [HttpPost]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.BillingEvent, true)]
        //[ReferenceDataFilter(StaticData.BillingScheduleType, true)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        public ActionResult _SearchCriteria(ClientBillableInvoiceSearchCriteria model)
        {
            ClientBillableInvoiceSearchCriteria tempModel = model;
            ModelState.Clear();
            ViewData[StaticData.BillingDefinitionInvoice.ToString()] = ReferenceDataRepository.GetBillingDefinitionInvoice(model.ClientID.GetValueOrDefault()).ToSelectListItem(u => u.ID.ToString(), y => y.Description, true).ToList();
            if (model.FilterToLoadID.HasValue)
            {
                ClientBillableInvoiceSearchCriteria dbModel = tempModel.GetView(model.FilterToLoadID) as ClientBillableInvoiceSearchCriteria;
                if (dbModel != null)
                {
                    return PartialView(dbModel);
                }
            }
            return PartialView(tempModel.GetModelForSearchCriteria());
        }

        [HttpPost]
        [DMSAuthorize]
        public ActionResult _SelectedCriteria(ClientBillableInvoiceSearchCriteria model)
        {
            return PartialView(model.GetModelForSearchCriteria());
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _BillingDefinitionInvoiceLine(int? recordID)
        {
            // WHERE recordID = BillingDefinitionInvoiceID
            ClientBillableInvoiceSearchCriteriaPartial model = new ClientBillableInvoiceSearchCriteriaPartial();
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
    }
}
