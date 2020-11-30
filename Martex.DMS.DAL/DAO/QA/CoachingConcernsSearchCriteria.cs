using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;

namespace Martex.DMS.DAL.DAO.QA
{
    [Serializable]
    public class CoachingConcernsSearchCriteria : ListFilterViewCommonAttributes
    {
        #region Search Criteria
        public string NameType { get; set; }
        public string NameValue { get; set; }
        public string NameOperator { get; set; }

        public List<CheckBoxLookUp> ConcernTypeList { get; set; }

        public int? SearchByConcernTypeID { get; set; }
        public string SearchByConcernTypeText { get; set; }

        public int? SearchByConcernID { get; set; }
        public string SearchByConcernText { get; set; }
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

        public bool? PanelNameSelected { get; set; }
        public bool? PanelConcernTypeListSelected { get; set; }
        public bool? PanelConcernSelected { get; set; }
        public bool? PanelConcernStatusListSelected { get; set; }
       
        #endregion
    }

    public static class CoachingConcernsSearchCriteriaExtended
    {
        public static CoachingConcernsSearchCriteria GetModelForSearchCriteria(this CoachingConcernsSearchCriteria model)
        {
            #region Check When Model is Null
            if (model == null)
            {
                model = new CoachingConcernsSearchCriteria();
                model.PanelViewsSelected = true;
                model.PanelItemsSelected = true;
                model.PanelNameSelected = true;
                model.PanelConcernTypeListSelected = false;
                model.PanelConcernSelected = false;
                model.PanelConcernStatusListSelected = false;
            }
            #endregion

            #region Concern Types
            List<CheckBoxLookUp> concernTypes = new List<CheckBoxLookUp>();
            List<ConcernType> concerns = ReferenceDataRepository.GetConcernType();

            if (model.ConcernTypeList == null)
            {
                foreach (var item in concerns)
                {
                    concernTypes.Add(new CheckBoxLookUp()
                    {
                        ID = item.ID,
                        Name = item.Description,
                        Selected = false
                    });
                }
                model.ConcernTypeList = concernTypes;
            }
            #endregion

            #region Verify Inputs
            if (string.IsNullOrEmpty(model.NameValue))
            {
                model.NameValue = string.Empty;
                model.NameOperator = string.Empty;
                model.NameType = string.Empty;
            }
            if (!model.SearchByConcernID.HasValue)
            {
                model.SearchByConcernText = string.Empty;
            }
            if (!model.SearchByConcernTypeID.HasValue)
            {
                model.SearchByConcernTypeText = string.Empty;
                model.SearchByConcernText = string.Empty;
                model.SearchByConcernID = null;
            }
            #endregion

            #region Reset Critera
            
            if (model.ResetModelCriteria)
            {
                model.FilterToLoadID = null;
                model.ResetModelCriteria = false;

                model.NameValue = string.Empty;
                model.NameOperator = string.Empty;
                model.NameType = string.Empty;
                model.SearchByConcernID = null;
                model.SearchByConcernText = string.Empty;
                model.SearchByConcernTypeID = null;
                model.SearchByConcernTypeText = string.Empty; 

                foreach (CheckBoxLookUp item in model.ConcernTypeList)
                {
                    item.Selected = false;
                }
            }
            #endregion

            return model;
        }

        public static List<NameValuePair> GetFilterClause(this CoachingConcernsSearchCriteria model)
        {
            CoachingConcernsSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(refreshModel.NameValue))
            {
                filterList.Add(new NameValuePair() { Name = "NameOperator", Value = refreshModel.NameOperator });
                filterList.Add(new NameValuePair() { Name = "NameType", Value = refreshModel.NameType });
                filterList.Add(new NameValuePair() { Name = "NameValue", Value = refreshModel.NameValue });
            }
            // Concern Types
            if (refreshModel.ConcernTypeList != null && refreshModel.ConcernTypeList.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.ConcernTypeList.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var claimTypes = result.ToDelimitedStringForCoachingConcerns(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "ConcernTypeList", Value = claimTypes });
                }
            }
            if (refreshModel.SearchByConcernID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ConcernID", Value = refreshModel.SearchByConcernID.GetValueOrDefault().ToString() });
            }
            if (refreshModel.SearchByConcernTypeID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ConcernTypeID", Value = refreshModel.SearchByConcernTypeID.GetValueOrDefault().ToString() });
            }
            return filterList;
        }
        private static string ToDelimitedStringForCoachingConcerns<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }
    }
}
