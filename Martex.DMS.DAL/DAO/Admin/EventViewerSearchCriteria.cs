using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.DAL.DAO.Admin
{
    [Serializable]
    public class EventViewerSearchCriteria : ListFilterViewCommonAttributes
    {
        #region Search Criteria
        public string UserName { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }

        public int? EventCategoryID { get; set; }
        public string EventCategoryName { get; set; }

        public int? EventTypeID { get; set; }
        public string EventTypeName { get; set; }

        public int? EventID { get; set; }
        public string EventName { get; set; }

        public string ApplicationName { get; set; }

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

        public bool? PanelUsersSelected { get; set; }
        public bool? PanelDateRangeSelected { get; set; }
        public bool? PanelEventSelected { get; set; }

        #endregion
    }

    public static class EventViewerSearchCriteriaExtended
    {
        public static EventViewerSearchCriteria GetModelForSearchCriteria(this EventViewerSearchCriteria model)
        {
            #region Check When Model is Null
            if (model == null)
            {
                model = new EventViewerSearchCriteria();
                model.PanelViewsSelected = true;
                model.PanelItemsSelected = true;
            }
            #endregion

            #region Verify Inputs
            if (string.IsNullOrEmpty(model.UserName))
            {
                model.ApplicationName = string.Empty;
            }

            if (!model.EventCategoryID.HasValue)
            {
                model.EventCategoryName = string.Empty;
            }
            if (!model.EventTypeID.HasValue)
            {
                model.EventTypeName = string.Empty;
            }
            if (!model.EventID.HasValue)
            {
                model.EventName = string.Empty;
            }
            if (!model.FromDate.HasValue)
            {
                model.ToDate = null;
            }
            #endregion

            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                model.FilterToLoadID = null;
                model.ResetModelCriteria = false;

                model.UserName = string.Empty;
                model.ApplicationName = string.Empty;

                model.FromDate = null;
                model.ToDate = null;

                model.EventCategoryID = null;
                model.EventCategoryName = string.Empty;

                model.EventTypeID = null;
                model.EventTypeName = string.Empty;

                model.EventID = null;
                model.EventName = string.Empty;
            }
            #endregion

            return model;
        }

        public static List<NameValuePair> GetFilterClause(this EventViewerSearchCriteria model)
        {
            EventViewerSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(refreshModel.UserName))
            {
                filterList.Add(new NameValuePair() { Name = "UserName", Value = refreshModel.UserName });
            }
            if (refreshModel.FromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "FromDate", Value = refreshModel.FromDate.GetValueOrDefault().ToShortDateString() });
            }
            if (refreshModel.ToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ToDate", Value = refreshModel.ToDate.GetValueOrDefault().ToShortDateString() });
            }
            if (refreshModel.EventCategoryID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "EventCategoryID", Value = refreshModel.EventCategoryID.GetValueOrDefault().ToString() });
            }
            if (refreshModel.EventTypeID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "EventTypeID", Value = refreshModel.EventTypeID.GetValueOrDefault().ToString() });
            }
            if (refreshModel.EventID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "EventID", Value = refreshModel.EventID.GetValueOrDefault().ToString() });
            }
            return filterList;
        }
    }
}
