using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;

namespace Martex.DMS.DAL.Entities.Clients
{
    public class ClientBillableEventProcessingSearchCriteriaPartial
    {
        public List<CheckBoxLookUp> BillingDefinitionInvoiceLine { get; set; }
    }

    [Serializable]
    public class ClientBillableEventProcessingSearchCriteria : ListFilterViewCommonAttributes
    {

        public List<CheckBoxLookUp> DispositionStatus { get; set; }
        public List<CheckBoxLookUp> DetailStatus { get; set; }
        public List<CheckBoxLookUp> BillingDefinitionInvoiceLine { get; set; }

        public string BillingEventName { get; set; }
        public int? BillingEvent { get; set; }

        public string BillingScheduleTypeName { get; set; }
        public int? BillingScheduleType { get; set; }


        public int? ClientID { get; set; }
        public string ClientIDValue { get; set; }

        public int? BillingDefinitionInvoiceID { get; set; }
        public string BillingDefinitionInvoiceName { get; set; }


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
        public bool PanelScheduleTypeSelected { get; set; }
        public bool PanelInvoiceDefinitionSelected { get; set; }
        public bool PanelBillingEventSelected { get; set; }
        public bool PanelDetailStatusSelected { get; set; }
        public bool PanelDispositionStatusSelected { get; set; }
        #endregion
    }

    public static class ClientBillableEventProcessingSearchCriteria_Extension
    {
        private static string ToDelimitedString_<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }

        public static List<NameValuePair> GetFilterSearchCritera(this ClientBillableEventProcessingSearchCriteria model)
        {
            ClientBillableEventProcessingSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (refreshModel.BillingScheduleType.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "BillingScheduleTypeID", Value = refreshModel.BillingScheduleType.Value.ToString() });
            }

            if (refreshModel.ClientID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClientID", Value = refreshModel.ClientID.Value.ToString() });
            }
            if (refreshModel.BillingDefinitionInvoiceID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "BillingDefinitionInvoiceID", Value = refreshModel.BillingDefinitionInvoiceID.Value.ToString() });
            }
            if (refreshModel.BillingEvent.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "BillingEvent", Value = refreshModel.BillingEvent.Value.ToString() });
            }

            if (refreshModel.DetailStatus != null && refreshModel.DetailStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.DetailStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var detailStatuses = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "DetailStatuses", Value = detailStatuses });
                }
            }

            if (refreshModel.DispositionStatus != null && refreshModel.DispositionStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.DispositionStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var dispositionStatuses = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "DispositionStatuses", Value = dispositionStatuses });
                }
            }

            if (refreshModel.BillingDefinitionInvoiceLine != null && refreshModel.BillingDefinitionInvoiceLine.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.BillingDefinitionInvoiceLine.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var invoiceLines = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "BillingDefinitionInvoiceLines", Value = invoiceLines});
                }
            }
            return filterList;
        }

        public static ClientBillableEventProcessingSearchCriteria GetModelForSearchCriteria(this ClientBillableEventProcessingSearchCriteria model)
        {
            #region Check When Model is Null or ReSet
            if (model == null || model.ResetModelCriteria)
            {
                model = new ClientBillableEventProcessingSearchCriteria();
                model.PanelViewsSelected = null;
                model.PanelItemsSelected = null;
                model.ResetModelCriteria = false;
                model.FilterToLoadID = null;
                model.GridSortColumnName = string.Empty;
                model.GridSortOrder = string.Empty;
                model.NewViewName = string.Empty;
            }
            #endregion

            #region Disposition Status
            List<CheckBoxLookUp> dispositionStatus = new List<CheckBoxLookUp>();
            List<BillingInvoiceDetailDisposition> dispositionStatusDetails = ReferenceDataRepository.GetBillingInvoiceDetailDisposition();
            if (model.DispositionStatus == null)
            {
                foreach (var status in dispositionStatusDetails)
                {
                    dispositionStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.DispositionStatus = dispositionStatus;
            }
            #endregion

            #region Detail Status
            List<CheckBoxLookUp> detailStatus = new List<CheckBoxLookUp>();
            List<BillingInvoiceDetailStatu> detailStatusDetails = ReferenceDataRepository.GetBillingInvoiceDetailStatus();
            if (model.DetailStatus == null)
            {
                foreach (var status in detailStatusDetails)
                {
                    detailStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.DetailStatus = detailStatus;
            }
            #endregion

            #region Line
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
