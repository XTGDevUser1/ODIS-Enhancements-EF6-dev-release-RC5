using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO.ListViewFilters;
using Martex.DMS.DAO;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;

namespace Martex.DMS.DAL.Entities
{
    /// <summary>
    /// Vendor Invoice Search Criteria
    /// </summary>
    [Serializable]
    public class VendorInvoiceSearchCriteria : ListFilterViewCommonAttributes
    {
        public string IDType { get; set; }
        public string IDValue { get; set; }

        public int? NameOperator { get; set; }
        public string NameValue { get; set; }

        public List<CheckBoxLookUp> InvoiceStatuses { get; set; }
        public List<CheckBoxLookUp> POStatuses { get; set; }
        public List<CheckBoxLookUp> PayStatusCodes { get; set; }
        public List<CheckBoxLookUp> ExceptionTypes { get; set; }

        public DateTime? InvoiceFrom { get; set; }
        public DateTime? InvoiceTo { get; set; }

        public DateTime? ToBePaidFrom { get; set; }
        public DateTime? ToBePaidTo { get; set; }


        public string ExportType { get; set; }
        public string ExportTypeName { get; set; }

        public bool ResetModelCriteria { get; set; }

        public int? FilterToLoadID { get; set; }
        public string NewViewName { get; set; }
        public string GridSortColumnName { get; set; }
        public string GridSortOrder { get; set; }

        #region Panel Selection Status
        public bool PanelItemsSelected { get; set; }
        public bool PanelViewsSelected { get; set; }
        public bool? PanelIDSelected { get; set; }
        public bool? PanelNameSelected { get; set; }
        public bool? PanelInvoiceStatusSelected { get; set; }
        public bool? PanelPayStatusCodeSelected { get; set; }
        public bool? PanelExceptionTypesSelected { get; set; }
        public bool? PanelPOStatusSelected { get; set; }
        public bool? PanelDateRangeSelected { get; set; }
        public bool? PanelToBePaidRangeSelected { get; set; }
        public bool? PanelExportStatusSelected { get; set; }
        #endregion
    }

    public static class VendorInvoiceSearchCriteria_Extension
    {
        private static string ToDelimitedString_<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }

        public static List<NameValuePair> GetFilterSearchCritera(this VendorInvoiceSearchCriteria model)
        {
            VendorInvoiceSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(refreshModel.IDType))
            {
                filterList.Add(new NameValuePair() { Name = "IDType", Value = refreshModel.IDType });
            }
            if (!string.IsNullOrEmpty(refreshModel.IDValue))
            {
                filterList.Add(new NameValuePair() { Name = "IDValue", Value = refreshModel.IDValue });
            }
            if (refreshModel.NameOperator.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "NameOperator", Value = refreshModel.NameOperator.Value.ToString() });
            }
            if (!string.IsNullOrEmpty(refreshModel.NameValue))
            {
                filterList.Add(new NameValuePair() { Name = "NameValue", Value = refreshModel.NameValue });
            }

            // Invoice Status Section
            if (refreshModel.InvoiceStatuses != null && refreshModel.InvoiceStatuses.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.InvoiceStatuses.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var invoiceStatuses = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "InvoiceStatuses", Value = invoiceStatuses });
                }
            }

            // PO Status Section
            if (refreshModel.POStatuses != null && refreshModel.POStatuses.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.POStatuses.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var poStatuses = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "POStatuses", Value = poStatuses });
                }
            }

            // Pay Status Codes
            if (refreshModel.PayStatusCodes != null && refreshModel.PayStatusCodes.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.PayStatusCodes.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var payStatusCodes = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "PayStatusCodes", Value = payStatusCodes });
                }
            }

            // Exception Types
            if (refreshModel.ExceptionTypes != null && refreshModel.ExceptionTypes.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.ExceptionTypes.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var exceptionTypes = result.ToDelimitedString_(u => u.Name);
                    filterList.Add(new NameValuePair() { Name = "ExceptionTypes", Value = exceptionTypes });
                }
            }

            if (refreshModel.InvoiceFrom != null)
            {
                filterList.Add(new NameValuePair() { Name = "FromDate", Value = refreshModel.InvoiceFrom.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.InvoiceTo != null)
            {
                filterList.Add(new NameValuePair() { Name = "ToDate", Value = refreshModel.InvoiceTo.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.ToBePaidFrom != null)
            {
                filterList.Add(new NameValuePair() { Name = "ToBePaidFromDate", Value = refreshModel.ToBePaidFrom.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.ToBePaidTo != null)
            {
                filterList.Add(new NameValuePair() { Name = "ToBePaidToDate", Value = refreshModel.ToBePaidTo.Value.ToString("yyyy-MM-dd") });
            }

            if (!string.IsNullOrEmpty(model.ExportType))
            {
                filterList.Add(new NameValuePair() { Name = "ExportType", Value = refreshModel.ExportType });
            }

            return filterList;
        }

        public static VendorInvoiceSearchCriteria GetModelForSearchCriteria(this VendorInvoiceSearchCriteria model)
        {
            #region Check When Model is Null
            if (model == null)
            {
                model = new VendorInvoiceSearchCriteria();
                model.PanelIDSelected = true;
                model.PanelNameSelected = true;
                model.PanelInvoiceStatusSelected = false;
                model.PanelPOStatusSelected = false;
                model.PanelDateRangeSelected = false;
                model.PanelExportStatusSelected = false;
                model.PanelPayStatusCodeSelected = false;
                model.PanelExceptionTypesSelected = false;
            }
            #endregion

            #region Invoice Status
            List<CheckBoxLookUp> invoiceStatus = new List<CheckBoxLookUp>();
            List<VendorInvoiceStatu> invoiceStatuses = ReferenceDataRepository.GetVendorInvoiceStatus();

            if (model.InvoiceStatuses == null)
            {
                foreach (var status in invoiceStatuses)
                {
                    invoiceStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.InvoiceStatuses = invoiceStatus;
            }
            #endregion

            #region PO Status
            List<CheckBoxLookUp> poStatus = new List<CheckBoxLookUp>();
            List<PurchaseOrderStatu> poList = ReferenceDataRepository.GetPOStatusList();

            if (model.POStatuses == null)
            {
                foreach (var status in poList)
                {
                    poStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.POStatuses = poStatus;
            }
            #endregion

            #region Pay Status Codes
            List<CheckBoxLookUp> payStatusCodes = new List<CheckBoxLookUp>();
            List< PurchaseOrderPayStatusCode> payStatusList = ReferenceDataRepository.GetPurchaseOrderPayStatusCodes();
            if (model.PayStatusCodes == null)
            {
                foreach (var status in payStatusList)
                {
                    payStatusCodes.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.PayStatusCodes = payStatusCodes;
            }
            #endregion

            #region Exception Types
            List<CheckBoxLookUp> exceptionTypes = new List<CheckBoxLookUp>();
            List<string> exceptionTypesList = ReferenceDataRepository.GetVendorInvoiceExceptions();
            if (model.ExceptionTypes == null)
            {
                foreach (var status in exceptionTypesList)
                {
                    exceptionTypes.Add(new CheckBoxLookUp()
                    {
                        ID = 0,
                        Name = status,
                        Selected = false
                    });
                }
                model.ExceptionTypes = exceptionTypes;
            }
            #endregion

            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                foreach (CheckBoxLookUp lookup in model.InvoiceStatuses)
                {
                    lookup.Selected = false;
                }
                foreach (CheckBoxLookUp lookup in model.POStatuses)
                {
                    lookup.Selected = false;
                }
                foreach (CheckBoxLookUp lookup in model.PayStatusCodes)
                {
                    lookup.Selected = false;
                }
                foreach (CheckBoxLookUp lookup in model.ExceptionTypes)
                {
                    lookup.Selected = false;
                }
                model.IDType = string.Empty;
                model.IDValue = null;

                model.NameValue = string.Empty;
                model.NameOperator = null;

                model.InvoiceFrom = null;
                model.InvoiceTo = null;

                model.ToBePaidFrom = null;
                model.ToBePaidTo = null;

                model.ExportType = null;

                model.ResetModelCriteria = false;
                model.PanelIDSelected = true;
                model.PanelNameSelected = true;
                model.PanelInvoiceStatusSelected = false;
                model.PanelPOStatusSelected = false;
                model.PanelDateRangeSelected = false;
                model.PanelExportStatusSelected = false;
                model.PanelToBePaidRangeSelected = null;
                model.PanelPayStatusCodeSelected = null;
                model.PanelExceptionTypesSelected = null;
            }
            #endregion

            return model;
        }
    }

    [Serializable]
    public class ListFilterViewCommonAttributes
    {

        public object GetView(int? recordID)
        {
            object obj = null;
            if (recordID.HasValue)
            {
                ListViewFilterRepository repository = new ListViewFilterRepository();
                ListViewFilter filter = repository.Get(recordID.Value);
                if (filter != null)
                {
                    BinaryFormatter bformatter = new BinaryFormatter();
                    MemoryStream memStream = new MemoryStream();
                    memStream.Write(filter.SerializedObject, 0, filter.SerializedObject.Length);
                    memStream.Flush();
                    memStream.Seek(0, SeekOrigin.Begin);
                    obj = bformatter.Deserialize(memStream);
                }
            }
            return obj;
        }
    }

    [Serializable]
    public class VendorInvoicePaymentRunsCriteria
    {
        public int? BatchStatusID { get; set; }
        public DateTime? DateSectionFromDate { get; set; }
        public DateTime? DateSectionToDate { get; set; }
        public int? DateSectionPreset { get; set; }
        public string DateSectionPresetValue { get; set; }
    }
}
