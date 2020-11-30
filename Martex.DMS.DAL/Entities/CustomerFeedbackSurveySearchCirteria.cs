using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO.ListViewFilters;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using System.Runtime.InteropServices;

namespace Martex.DMS.DAL.Entities
{
    [Serializable]
    public class CustomerFeedbackSurveySearchCirteria : ListFilterViewCommonAttributes
    {
        #region Search Criteria
        public int? CustomerFeedbackID { get; set; }
        public string NumberType { get; set; }
        public string NumberValue { get; set; }
        public string NameType { get; set; }
        public string NameTypeOperator { get; set; }
        public string NameValue { get; set; }
        public string NameValueOperator { get; set; }

        public DateTime? ContactFromDate { get; set; }
        public DateTime? ContactToDate { get; set; }

        public DateTime? DispatchFromDate { get; set; }
        public DateTime? DispatchToDate { get; set; }

       public List<CheckBoxLookUp> FeedbackStatus { get; set; }


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
        public bool? PanelNameSelected { get; set; }
        public bool? PanelNumberSelected { get; set; }
        public bool PanelContactDateSelected { get; set; }
        #endregion


    }

    public static class CustomerFeedbackSurveySearchCirteria_Extension
    {


        public static List<NameValuePair> GetFilterSearchCritera(this CustomerFeedbackSurveySearchCirteria model)
        {
            CustomerFeedbackSurveySearchCirteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(refreshModel.NumberType))
            {
                filterList.Add(new NameValuePair() { Name = "NumberType", Value = refreshModel.NumberType });
                filterList.Add(new NameValuePair() { Name = "NumberValue", Value = refreshModel.NumberValue });
            }
            if (!string.IsNullOrEmpty(refreshModel.NameType) && (!string.IsNullOrEmpty(refreshModel.NameTypeOperator)) && (!string.IsNullOrEmpty(refreshModel.NameTypeOperator)))
            {
                filterList.Add(new NameValuePair() { Name = "NameType", Value = refreshModel.NameType });
                filterList.Add(new NameValuePair() { Name = "NameTypeOperator", Value = refreshModel.NameTypeOperator });
                filterList.Add(new NameValuePair() { Name = "NameValue", Value = refreshModel.NameValue });
            }

           

            if (refreshModel.ContactFromDate != null)
            {
                filterList.Add(new NameValuePair() { Name = "ContactFromDate", Value = refreshModel.ContactFromDate.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.ContactToDate != null)
            {
                filterList.Add(new NameValuePair() { Name = "ContactToDate", Value = refreshModel.ContactToDate.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.DispatchFromDate != null)
            {
                filterList.Add(new NameValuePair() { Name = "DispatchFromDate", Value = refreshModel.DispatchFromDate.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.DispatchToDate != null)
            {
                filterList.Add(new NameValuePair() { Name = "DispatchToDate", Value = refreshModel.DispatchToDate.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.FeedbackStatus != null && refreshModel.FeedbackStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.FeedbackStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var feedbackStatus = result.ToDelimitedStringForFeedback(u => u.Name);
                    filterList.Add(new NameValuePair() { Name = "FeedbackStatus", Value = feedbackStatus });
                }
            }

            return filterList;
        }

        private static string ToDelimitedStringForFeedback<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }

        public static CustomerFeedbackSurveySearchCirteria GetModelForSearchCriteria(this CustomerFeedbackSurveySearchCirteria model)
        {

            #region Check When Model is Null
            if (model == null)
            {
                model = new CustomerFeedbackSurveySearchCirteria();
                model.PanelIDSelected = true;
                model.ContactToDate = DateTime.Now;
            }
            #endregion


          

            #region Verfying Inputs
            if (string.IsNullOrEmpty(model.NumberType))
            {
                model.NumberValue = string.Empty;
            }

            if (string.IsNullOrEmpty(model.NameType))
            {
                model.NameValue = string.Empty;
                model.NameTypeOperator = string.Empty;
            }



            #endregion

            #region Customer Feedback Status
            List<CheckBoxLookUp> customerfeedbackstatus = new List<CheckBoxLookUp>();
            List<CheckBoxLookUp> customerfeedbackstatusDetail = new List<CheckBoxLookUp>();
            customerfeedbackstatusDetail = ReferenceDataRepository.GetCustomerSurveyFeedbackStatus();

            if (model.FeedbackStatus == null)
            {
                foreach (var status in customerfeedbackstatusDetail)
                {
                    customerfeedbackstatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = (status.Name.Equals("Closed") ? false : true)
                    });
                }
                model.FeedbackStatus = customerfeedbackstatus;
            }
            #endregion

            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                model.FilterToLoadID = null;
                model.ResetModelCriteria = false;

                model.NameValue = string.Empty;
                model.NameType = string.Empty;
                model.NameTypeOperator = string.Empty;

                model.NumberType = string.Empty;
                model.NumberValue = string.Empty;

                model.ContactFromDate = null;
                model.ContactToDate = null;

                model.DispatchFromDate = null;
                model.DispatchToDate = null;

                foreach (CheckBoxLookUp item in model.FeedbackStatus)
                {
                    item.Selected = false;
                }

                model.PanelItemsSelected = false;
                model.PanelViewsSelected = false;
                model.PanelIDSelected = false;
                model.PanelNameSelected = false;
                model.PanelNumberSelected = true;
                model.PanelContactDateSelected = false;


            }
            #endregion
            return model;
        }


        public static List<NameValuePair> GetFilterClause(this CustomerFeedbackSurveySearchCirteria model)
        {
            CustomerFeedbackSurveySearchCirteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(refreshModel.NameType))
            {
                filterList.Add(new NameValuePair() { Name = "NameType", Value = refreshModel.NameType });
            }
            if (!string.IsNullOrEmpty(refreshModel.NameValue))
            {
                filterList.Add(new NameValuePair() { Name = "NameValue", Value = refreshModel.NameValue });
            }
            if (!string.IsNullOrEmpty(refreshModel.NameTypeOperator))
            {
                filterList.Add(new NameValuePair() { Name = "NameTypeOperator", Value = refreshModel.NameTypeOperator });
            }
            if (!string.IsNullOrEmpty(refreshModel.NumberType))
            {
                filterList.Add(new NameValuePair() { Name = "NumberType", Value = refreshModel.NumberType });
            }
            if (!string.IsNullOrEmpty(refreshModel.NumberValue))
            {
                filterList.Add(new NameValuePair() { Name = "NumberValue", Value = refreshModel.NumberValue });
            }

            if (refreshModel.ContactFromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ContactFromDate", Value = refreshModel.ContactFromDate.Value.ToShortDateString() });
            }
            if (refreshModel.ContactToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ContactToDate", Value = refreshModel.ContactToDate.Value.ToShortDateString() });
            }


            if (refreshModel.FeedbackStatus != null && refreshModel.FeedbackStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.FeedbackStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var FeedbackStatus = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "FeedbackStatus", Value = FeedbackStatus });
                }
            }

            return filterList;
        }
    }
}
