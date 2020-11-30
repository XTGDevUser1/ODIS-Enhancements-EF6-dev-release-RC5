using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    [Serializable]
    public class ProgramManagementSearchCriteria : ListFilterViewCommonAttributes
    {
        #region Search Criteria
        
        public string Number { get; set; }
        
        public string Name { get; set; }
        public string NameOperator { get; set; }
        public string NameOperatorValue { get; set; }

        public int? ClientID { get; set; }
        public int? ProgramID { get; set; }

        public string ClientName { get; set; }
        public string ProgramName { get; set; }

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

        public bool? PanelNumberSelected { get; set; }
        public bool? PanelNameSelected { get; set; }
        public bool? PanelClientSelected { get; set; }
      
        #endregion
    }

    public static class ProgramManagementSearchCriteriaExtended
    {
        public static ProgramManagementSearchCriteria GetModelForSearchCriteria(this ProgramManagementSearchCriteria model)
        {
            #region Check When Model is Null
            if (model == null)
            {
                model = new ProgramManagementSearchCriteria();
                model.PanelViewsSelected = true;
                model.PanelItemsSelected = true;
            }
            #endregion

            #region Name Section
            if (string.IsNullOrEmpty(model.Name) || string.IsNullOrEmpty(model.NameOperatorValue))
            {
                model.NameOperatorValue = string.Empty;
                model.NameOperator = string.Empty;
                model.Name = string.Empty;
            }

            if (!model.ClientID.HasValue)
            {
                model.ProgramID = null;
                model.ClientName = string.Empty;
                model.ProgramName = string.Empty;
            }

            if (!model.ProgramID.HasValue)
            {
                model.ProgramName = string.Empty;
            }
            #endregion

            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                model.Number = string.Empty;
                model.Name = string.Empty;
                model.NameOperator = string.Empty;
                model.NameOperatorValue = string.Empty;
                model.ClientID = null;
                model.ProgramID = null;
                model.ClientName = string.Empty;
                model.ProgramName = string.Empty;
                model.ResetModelCriteria = false;
                model.PanelNameSelected = false;
                model.PanelNumberSelected = false;
                model.PanelClientSelected = false;
                model.PanelItemsSelected = true;
                model.PanelViewsSelected = true;
                model.FilterToLoadID = null;
                model.GridSortColumnName = string.Empty;
                model.GridSortOrder = string.Empty;
            }
            #endregion

            return model;
        }

        public static List<NameValuePair> GetFilterClause(this ProgramManagementSearchCriteria model)
        {
            ProgramManagementSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
          
            if (refreshModel.ClientID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClientID", Value = refreshModel.ClientID.Value.ToString() });
            }
            if (refreshModel.ProgramID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ProgramID", Value = refreshModel.ProgramID.Value.ToString() });
            }
            if (!string.IsNullOrEmpty(refreshModel.Number))
            {
                filterList.Add(new NameValuePair() { Name = "Number", Value = refreshModel.Number });
            }
            if (!string.IsNullOrEmpty(refreshModel.Name) && !(string.IsNullOrEmpty(refreshModel.NameOperator)))
            {
                filterList.Add(new NameValuePair() { Name = "Name", Value = refreshModel.Name });
                filterList.Add(new NameValuePair() { Name = "NameOperator", Value = refreshModel.NameOperator});
            }
            return filterList;
        }
    }
}
