using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities.Claims
{
    [Serializable]
    public class ClaimACESPaymentSearchCriteria : ListFilterViewCommonAttributes
    {
        #region Helper Properties
        public bool ResetModelCriteria { get; set; }
        public int? FilterToLoadID { get; set; }
        public string NewViewName { get; set; }
        #endregion

        #region Panel Selection Status

        public bool PanelItemsSelected { get; set; }
        public bool PanelViewsSelected { get; set; }
        public bool PanelCheckNumberSelected { get; set; }
        public bool PanelCheckDateRangeSelected { get; set; }
        public bool PanelCheckAmountRangeSelected { get; set; }
        public bool PanelCreatedBySelected { get; set; }
        public bool PanelCreatedDateRangeSelected { get; set; }
        #endregion

        #region Criteria
        public string CheckNumber { get; set; }
        public DateTime? CheckFromDate { get; set; }
        public DateTime? CheckToDate { get; set; }
        public decimal? AmountFrom { get; set; }
        public decimal? AmountTo { get; set; }
        public string CreatedBy { get; set; }
        public DateTime? CreatedDateFrom { get; set; }
        public DateTime? CreatedDateTo { get; set; }
        #endregion
    }
    public static class ClaimACESPaymentSearchCriteria_Extension
    {
        public static ClaimACESPaymentSearchCriteria GetModelForSearchCriteria(this ClaimACESPaymentSearchCriteria model)
        {
            #region Check When Model is Null
            if (model == null)
            {
                model = new ClaimACESPaymentSearchCriteria();
                model.PanelCheckNumberSelected = true;
                model.PanelViewsSelected = true;
            }
            #endregion
          
            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                model.CheckNumber = string.Empty;
                model.CheckFromDate = null;
                model.CheckToDate = null;
                model.AmountFrom = null;
                model.AmountTo = null;
                model.CreatedBy = string.Empty;
                model.CreatedDateFrom = null;
                model.CreatedDateTo = null;
                model.ResetModelCriteria = false;
                model.PanelCheckNumberSelected = true;
            }
            #endregion

            return model;
        }
     
        public static List<NameValuePair> GetFilterClause(this ClaimACESPaymentSearchCriteria model)
        {
            ClaimACESPaymentSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();

            if (!string.IsNullOrEmpty(refreshModel.CheckNumber))
            {
                filterList.Add(new NameValuePair() { Name = "CheckNumber", Value = refreshModel.CheckNumber });
            }
            if (refreshModel.CreatedDateFrom.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "CreatedDateFrom", Value = refreshModel.CreatedDateFrom.Value.ToShortDateString() });
            }
            if (refreshModel.CreatedDateTo.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "CreatedDateTo", Value = refreshModel.CreatedDateTo.Value.ToShortDateString() });
            }
            if (refreshModel.AmountFrom.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "AmountFrom", Value = refreshModel.AmountFrom.ToString() });
            }
            if (refreshModel.AmountTo.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "AmountTo", Value = refreshModel.AmountTo.ToString() });
            }
            if (!string.IsNullOrEmpty(refreshModel.CreatedBy))
            {
                filterList.Add(new NameValuePair() { Name = "CreatedBy", Value = refreshModel.CreatedBy });
            } 
            if (refreshModel.CheckFromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "CheckDateFrom", Value = refreshModel.CheckFromDate.Value.ToShortDateString() });
            }
            if (refreshModel.CheckToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "CheckDateTo", Value = refreshModel.CheckToDate.Value.ToShortDateString() });
            }

            return filterList;
        }
    }
}
