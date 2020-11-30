using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;

namespace Martex.DMS.DAL.Entities.Clients
{
    public class ClientBillableInvoiceSearchCriteriaPartial
    {
        public List<CheckBoxLookUp> BillingDefinitionInvoiceLine { get; set; }
    }


    [Serializable]
    public class ClientBillableInvoiceSearchCriteria : ListFilterViewCommonAttributes
    {
        public List<CheckBoxLookUp> InvoiceStatus { get; set; }
        public List<CheckBoxLookUp> LineStatus { get; set; }
        public List<CheckBoxLookUp> BillingDefinitionInvoiceLine { get; set; }

        public int? ClientID { get; set; }
        public string ClientIDValue { get; set; }

        public int? BillingDefinitionInvoiceID { get; set; }
        public string BillingDefinitionInvoiceName { get; set; }

        public DateTime? ScheduleDateFrom { get; set; }
        public DateTime? ScheduleDateTo { get; set; }

        public string Status { get; set; }

        #region Helpers
        public bool ResetModelCriteria { get; set; }
        public int? FilterToLoadID { get; set; }
        public string NewViewName { get; set; }
        public string GridSortColumnName { get; set; }
        public string GridSortOrder { get; set; }
        #endregion

        #region Panel Selection Status
        public bool? PanelItemsSelected { get; set; }
        public bool? PanelViewsSelected { get; set; }
        public bool PanelScheduleDateSelected { get; set; }
        public bool PanelInvoiceDefinitionSelected { get; set; }
        public bool PanelInvoiceStatusSelected { get; set; }
        public bool PanelLineStatusSelected { get; set; }
        #endregion
    }

    public static class ClientBillableInvoiceProcessingSearchCriteria_Extension
    {
        private static string ToDelimitedString_<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }

        public static List<NameValuePair> GetFilterSearchCritera(this ClientBillableInvoiceSearchCriteria model)
        {
            ClientBillableInvoiceSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (refreshModel.InvoiceStatus != null && refreshModel.InvoiceStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.InvoiceStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var invoiceStatuses = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "InvoiceStatuses", Value = invoiceStatuses });
                }
            }

            if (refreshModel.LineStatus != null && refreshModel.LineStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.LineStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var lineStatuses = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "LineStatuses", Value = lineStatuses });
                }
            }

            if (refreshModel.BillingDefinitionInvoiceLine != null && refreshModel.BillingDefinitionInvoiceLine.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.BillingDefinitionInvoiceLine.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var invoiceLines = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "BillingDefinitionInvoiceLines", Value = invoiceLines });
                }
            }
            
            if (refreshModel.ClientID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClientID", Value = refreshModel.ClientID.Value.ToString() });
            }

            if (refreshModel.BillingDefinitionInvoiceID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "BillingDefinitionInvoiceID", Value = refreshModel.BillingDefinitionInvoiceID.Value.ToString() });
            }

            if (refreshModel.ScheduleDateFrom != null)
            {
                filterList.Add(new NameValuePair() { Name = "ScheduleDateFrom", Value = refreshModel.ScheduleDateFrom.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.ScheduleDateTo != null)
            {
                filterList.Add(new NameValuePair() { Name = "ScheduleDateTo", Value = refreshModel.ScheduleDateTo.Value.ToString("yyyy-MM-dd") });
            }
            
            return filterList;
        }

        public static ClientBillableInvoiceSearchCriteria GetModelForSearchCriteria(this ClientBillableInvoiceSearchCriteria model)
        {
            #region Check When Model is Null or ReSet
            if (model == null || model.ResetModelCriteria)
            {
                model = new ClientBillableInvoiceSearchCriteria();
                model.PanelViewsSelected = null;
                model.PanelItemsSelected = null;
                model.ResetModelCriteria = false;
                model.FilterToLoadID = null;
                model.GridSortColumnName = string.Empty;
                model.GridSortOrder = string.Empty;
                model.NewViewName = string.Empty;
            }
            #endregion

            #region Invoice Status
            List<CheckBoxLookUp> invoiceStatus = new List<CheckBoxLookUp>();
            List<BillingInvoiceStatu> invoiceStatusDetails = ReferenceDataRepository.GetBillingInvoiceStatus();
            if (model.InvoiceStatus == null)
            {
                foreach (var status in invoiceStatusDetails)
                {
                    invoiceStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.InvoiceStatus = invoiceStatus;
            }
            #endregion

            #region Line Status
            List<CheckBoxLookUp> lineStatus = new List<CheckBoxLookUp>();
            List<BillingInvoiceLineStatu> lineStatusDetails = ReferenceDataRepository.GetBillingInvoiceLineStatus();
            if (model.LineStatus == null)
            {
                foreach (var status in lineStatusDetails)
                {
                    lineStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.LineStatus = lineStatus;
            }
            #endregion

            #region Billing Definition Invoice
            List<CheckBoxLookUp> line = new List<CheckBoxLookUp>();
            List<BillingDefinitionInvoiceLine> lineDetails = ReferenceDataRepository.GetBillingDefinitionInvoiceLine(model.BillingDefinitionInvoiceID.GetValueOrDefault());
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
            #endregion

            return model;
        }
    }
}
