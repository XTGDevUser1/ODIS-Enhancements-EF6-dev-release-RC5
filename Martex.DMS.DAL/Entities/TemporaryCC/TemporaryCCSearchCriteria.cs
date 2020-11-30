using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;

namespace Martex.DMS.DAL.Entities.TemporaryCC
{

    [Serializable]
    public class TemporaryCCSearchCriteria : ListFilterViewCommonAttributes
    {
        #region Search Criteria
        public string LookUpTypeName { get; set; }
        public string LookUpTypeValue { get; set; }

        public string LookUpTypeIDValue { get; set; }

        public List<CheckBoxLookUp> CCMatchStatus { get; set; }

        public List<CheckBoxLookUp> ExceptionType { get; set; }

        public List<CheckBoxLookUp> POPayStatus { get; set; }

        public DateTime? IssueDateFrom { get; set; }
        public DateTime? IssueDateTo { get; set; }

        public DateTime? ChargedDateFrom { get; set; }
        public DateTime? ChargedDateTo { get; set; }

        public DateTime? PODateFrom { get; set; }
        public DateTime? PODateTo { get; set; }

        public decimal? ChargedAmountFrom { get; set; }
        public decimal? ChargedAmountTo { get; set; }

        public int? PostingBatchID { get; set; }
        public string PostingBatchName { get; set; }

        public int? ClientID { get; set; }
        public string ClientName { get; set; }
        #endregion

        #region Helper Properties
        public bool ResetModelCriteria { get; set; }
        public int? FilterToLoadID { get; set; }
        public string NewViewName { get; set; }
        public string GridSortColumnName { get; set; }
        public string GridSortOrder { get; set; }
        #endregion

        #region Panel Selection Status
        public bool PanelItemsSelected { get; set; }
        public bool PanelViewsSelected { get; set; }

        public bool? PanelIDSelected { get; set; }
        public bool? PanelCCMatchStatusSelected { get; set; }
        public bool? PanelPOPayStatusSelected { get; set; }
        public bool? PanelCreditCardIssueDateRangeSelected { get; set; }
        public bool? PanelCreditCardChargedDateRangeSelected { get; set; }
        public bool? PanelPODateRangeSelected { get; set; }
        public bool? PanelChargedAmountSelected { get; set; }
        public bool? PanelPostingBatchSelected { get; set; }
        public bool? PanelExceptionTypeSelected { get; set; }
        public bool? PanelClientSelected { get; set; }
        #endregion

    }

    public static class TemporaryCCSearchCriteria_Extension
    {
        public static TemporaryCCSearchCriteria GetModelForSearchCriteria(this TemporaryCCSearchCriteria model)
        {
            #region Check When Model is Null
            if (model == null)
            {
                model = new TemporaryCCSearchCriteria();
                model.PanelIDSelected = true;
                model.PanelViewsSelected = true;
                model.PanelItemsSelected = true;
            }
            #endregion

            #region CC Match Status
            List<CheckBoxLookUp> ccMatchStatus = new List<CheckBoxLookUp>();
            List<TemporaryCreditCardStatu> ccMatchStatusDetails = ReferenceDataRepository.GetCCMatchStatus();
            if (model.CCMatchStatus == null)
            {
                foreach (var status in ccMatchStatusDetails)
                {
                    ccMatchStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.CCMatchStatus = ccMatchStatus;
            }
            #endregion

            #region Po Pay Status
            List<CheckBoxLookUp> poPayStatus = new List<CheckBoxLookUp>();
            List<PurchaseOrderPayStatusCode> poPayStatusDetails = ReferenceDataRepository.GetPurchaseOrderPayStatusCodes();
            if (model.POPayStatus == null)
            {
                foreach (var status in poPayStatusDetails)
                {
                    poPayStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.POPayStatus = poPayStatus;
            }
            #endregion

            #region Credit Card Exceptions
            List<CheckBoxLookUp> exceptions = new List<CheckBoxLookUp>();
            List<DropDownEntityForString> exceptionsList = ReferenceDataRepository.GetTemporaryCreditCardExceptions();
            if (model.ExceptionType == null)
            {
                for (int i = 0; i < exceptionsList.Count; i++)
                {
                    exceptions.Add(new CheckBoxLookUp()
                    {
                        ID = i,
                        Name = exceptionsList[i].Text,
                        Selected = false
                    });
                }
                model.ExceptionType = exceptions;
            }
            #endregion

            #region Verfying Inputs
            if (string.IsNullOrEmpty(model.LookUpTypeName))
            {
                model.LookUpTypeIDValue = string.Empty;
            }

            if (!model.PostingBatchID.HasValue)
            {
                model.PostingBatchName = string.Empty;
            }
            if (!model.ClientID.HasValue)
            {
                model.ClientName = string.Empty;
            }
            #endregion

            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                model.FilterToLoadID = null;
                model.ResetModelCriteria = false;

                model.CCMatchStatus.ForEach(u => u.Selected = false);
                model.POPayStatus.ForEach(u => u.Selected = false);
                model.ExceptionType.ForEach(u => u.Selected = false);

                model.LookUpTypeIDValue = string.Empty;
                model.LookUpTypeName = string.Empty;
                model.LookUpTypeValue = string.Empty;

                model.IssueDateFrom = null;
                model.IssueDateTo = null;

                model.ChargedDateFrom = null;
                model.ChargedDateTo = null;

                model.PODateFrom = null;
                model.PODateTo = null;

                model.ChargedAmountFrom = null;
                model.ChargedAmountTo = null;

                model.PostingBatchID = null;
                model.PostingBatchName = string.Empty;

                model.ClientID = null;
                model.ClientName = string.Empty;
            }
            #endregion

            return model;
        }

        private static string ToDelimitedString_<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }

        public static List<NameValuePair> GetFilterSearchCritera(this TemporaryCCSearchCriteria model)
        {
            TemporaryCCSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();

            if (!string.IsNullOrEmpty(model.LookUpTypeName))
            {
                filterList.Add(new NameValuePair() { Name = "IDType", Value = refreshModel.LookUpTypeName });
            }
            if (!string.IsNullOrEmpty(model.LookUpTypeIDValue))
            {
                filterList.Add(new NameValuePair() { Name = "IDValue", Value = refreshModel.LookUpTypeIDValue });
            }

            if (refreshModel.CCMatchStatus != null && refreshModel.CCMatchStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.CCMatchStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var ccMatchStatus = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "CCMatchStatuses", Value = ccMatchStatus });
                }
            }

            if (refreshModel.POPayStatus != null && refreshModel.POPayStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.POPayStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var poPayStatus = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "POPayStatuses", Value = poPayStatus });
                }
            }

            if (refreshModel.IssueDateFrom.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "CCFromDate", Value = refreshModel.IssueDateFrom.GetValueOrDefault().ToShortDateString() });
            }

            if (refreshModel.IssueDateTo.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "CCToDate", Value = refreshModel.IssueDateTo.GetValueOrDefault().ToShortDateString() });
            }

            if (refreshModel.ChargedDateFrom.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ChargedDateFrom", Value = refreshModel.ChargedDateFrom.GetValueOrDefault().ToShortDateString() });
            }

            if (refreshModel.ChargedDateTo.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ChargedDateTo", Value = refreshModel.ChargedDateTo.GetValueOrDefault().ToShortDateString() });
            }

            if (refreshModel.PODateFrom.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "POFromDate", Value = refreshModel.PODateFrom.GetValueOrDefault().ToShortDateString() });
            }

            if (refreshModel.PODateTo.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "POToDate", Value = refreshModel.PODateTo.GetValueOrDefault().ToShortDateString() });
            }
            if (refreshModel.ChargedAmountFrom.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ChargedAmountFrom", Value = refreshModel.ChargedAmountFrom.GetValueOrDefault().ToString() });
            }
            if (refreshModel.ChargedAmountTo.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ChargedAmountTo", Value = refreshModel.ChargedAmountTo.GetValueOrDefault().ToString() });
            }
            if (refreshModel.PostingBatchID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "PostingBatchID", Value = refreshModel.PostingBatchID.GetValueOrDefault().ToString() });
            }

            if (refreshModel.ExceptionType != null && refreshModel.ExceptionType.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.ExceptionType.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var excpetionTypes = result.ToDelimitedString_(u => u.Name);
                    filterList.Add(new NameValuePair() { Name = "ExceptionType", Value = excpetionTypes });
                }
            }
            if (refreshModel.ClientID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClientID", Value = refreshModel.ClientID.GetValueOrDefault().ToString() });
            }
            return filterList;
        }
    }
}
