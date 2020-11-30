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
    public class CustomerFeedbackSearchCriteria : ListFilterViewCommonAttributes
    {

        #region Search Criteria

        public int? CustomerFeedbackID { get; set; }
        public string NumberType { get; set; }
        public string NumberValue { get; set; }
        public string NameType { get; set; }
        public string NameTypeOperator { get; set; }
        public string NameValue { get; set; }
        public string NameValueOperator { get; set; }
        public List<CheckBoxLookUp> Statuses { get; set; }
        public List<CheckBoxLookUp> Sources { get; set; }
        public List<CheckBoxLookUp> FeedbackTypes { get; set; }
        public List<CheckBoxLookUp> Priority { get; set; }
        public int? Client { get; set; }
        public string ClientValue { get; set; }
        public int? Program { get; set; }
        public string ProgramValue { get; set; }
        public DateTime? ReceivedFromDate { get; set; }
        public DateTime? ReceivedToDate { get; set; }
        public int? NextAction { get; set; }
        public string NextActionValue { get; set; }

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
        public bool PanelStatusesSelected { get; set; }
        public bool PanelSourcesSelected { get; set; }
        public bool PanelFeedbackTypesSelected { get; set; }
        public bool PanelPrioritySelected { get; set; }
        public bool PanelClientSelected { get; set; }
        public bool PanelProgramSelected { get; set; }
        public bool PanelNextActionSelected { get; set; }
        public bool PanelReceivedDateSelected { get; set; }
        #endregion



    }
    public static class CustomerFeedbackSearchCriteria_Extension
    {

        public static List<NameValuePair> GetFilterSearchCritera(this CustomerFeedbackSearchCriteria model)
        {
            CustomerFeedbackSearchCriteria refreshModel = GetModelForSearchCriteria(model);
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

            if (refreshModel.Statuses != null && refreshModel.Statuses.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.Statuses.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var vendorStatus = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "Statuses", Value = vendorStatus });
                }
            }

            if (refreshModel.Sources != null && refreshModel.Sources.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.Sources.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var vendorSources = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "Sources", Value = vendorSources });
                }
            }

            if (refreshModel.FeedbackTypes != null && refreshModel.FeedbackTypes.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.FeedbackTypes.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var vendorFeedbackTypes = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "FeedbackTypes", Value = vendorFeedbackTypes });
                }
            }

            if (refreshModel.Priority != null && refreshModel.Priority.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.Priority.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var vendorPriority = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "Priorities", Value = vendorPriority });
                }
            }

            if (refreshModel.Client.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "Client", Value = Convert.ToString(refreshModel.Client.Value) });
            }
            if (refreshModel.Program.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "Program", Value = Convert.ToString(refreshModel.Program.Value) });

            }
            if (refreshModel.NextAction.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "NextAction", Value = Convert.ToString(refreshModel.NextAction.Value) });
            }

            if (refreshModel.ReceivedFromDate != null)
            {
                filterList.Add(new NameValuePair() { Name = "ReceivedFromDate", Value = refreshModel.ReceivedFromDate.Value.ToString("yyyy-MM-dd") });
            }

            if (refreshModel.ReceivedToDate != null)
            {
                filterList.Add(new NameValuePair() { Name = "ReceivedToDate", Value = refreshModel.ReceivedToDate.Value.ToString("yyyy-MM-dd") });
            }


            return filterList;
        }


        public static CustomerFeedbackSearchCriteria GetModelForSearchCriteria(this CustomerFeedbackSearchCriteria model)
        {
            
            #region Check When Model is Null
            if (model == null)
            {
                model = new CustomerFeedbackSearchCriteria();
                model.PanelIDSelected = true;
                //model.PanelNameSelected = true;
                model.ReceivedToDate = DateTime.Now;
                //model.ReceivedFromDate = DateTime.Now.AddDays(-defaultDaysInteger);
            }
            #endregion

            #region Customer Feedback Status
            List<CheckBoxLookUp> customerfeedbackstatus = new List<CheckBoxLookUp>();
            List<CustomerFeedbackStatu> CustomerFeedbackStatusDetails = ReferenceDataRepository.GetCustomerFeedbackStatus();

            if (model.Statuses == null)
            {
                foreach (var status in CustomerFeedbackStatusDetails)
                {
                    customerfeedbackstatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = (status.Name.Equals("Closed") ? false : true)
                    });
                }
                model.Statuses = customerfeedbackstatus;
            }
            #endregion

            #region customer Feedback Source
            List<CheckBoxLookUp> CustomerFeedbackSource = new List<CheckBoxLookUp>();
            List<CustomerFeedbackSource> customerFeedbackSourcedetails = ReferenceDataRepository.GetCustomerFeedbackSources();

            if (model.Sources == null)
            {
                foreach (var status in customerFeedbackSourcedetails)
                {
                    CustomerFeedbackSource.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.Sources = CustomerFeedbackSource;
            }
            #endregion

            #region Feedback Types
            List<CheckBoxLookUp> FeedbackTypes = new List<CheckBoxLookUp>();
            List<CustomerFeedbackType> CustomerFeedbackTypesDetails = ReferenceDataRepository.GetCustomerFeedbackTypes();

            if (model.FeedbackTypes == null)
            {
                foreach (var status in CustomerFeedbackTypesDetails)
                {
                    FeedbackTypes.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.FeedbackTypes = FeedbackTypes;
            }
            #endregion

            #region Customer Feedback Priority
            List<CheckBoxLookUp> Priority = new List<CheckBoxLookUp>();
            List<CustomerFeedbackPriority> PriorityList = ReferenceDataRepository.GetCustomerFeedbackPrioritys();

            if (model.Priority == null)
            {
                foreach (var status in PriorityList)
                {
                    Priority.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.Priority = Priority;
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


            //if (!model.ClientID.HasValue)
            //{
            //    model.ProgramID = null;
            //    model.ProgramIDValue = string.Empty;
            //    model.ClientIDValue = string.Empty;
            //}
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

                model.ReceivedFromDate = null;
                model.ReceivedToDate = null;

                foreach (CheckBoxLookUp item in model.Sources)
                {
                    item.Selected = false;
                }
                foreach (CheckBoxLookUp item in model.Statuses)
                {
                    item.Selected = false;
                }
                foreach (CheckBoxLookUp item in model.Priority)
                {
                    item.Selected = false;
                }

                foreach (CheckBoxLookUp item in model.FeedbackTypes)
                {
                    item.Selected = false;
                }

                model.Client = null;
                model.Program = null;
                model.ReceivedFromDate = null;
                model.ReceivedToDate = null;
                model.NextAction = null;



                model.PanelItemsSelected = false;
                model.PanelViewsSelected = false;
                model.PanelIDSelected = false;
                model.PanelNameSelected = false;
                model.PanelNumberSelected = true;
                model.PanelStatusesSelected = true;
                model.PanelSourcesSelected = false;
                model.PanelFeedbackTypesSelected = false;
                model.PanelPrioritySelected = false;
                model.PanelClientSelected = false;
                model.PanelProgramSelected = false;
                model.PanelNextActionSelected = false;
                model.PanelReceivedDateSelected = false;


            }
            #endregion

            #region Check when From Date or To Date is Null
            //Request #1853 
            //if (!model.ClaimDateFrom.HasValue && !model.ClaimDateTo.HasValue)
            //{
            //    model.ClaimDateTo = DateTime.Now;
            //    model.ClaimDateFrom = DateTime.Now.AddDays(-defaultDaysInteger);
            //}

            //if (!model.ClaimDateFrom.HasValue && model.ClaimDateTo.HasValue)
            //{
            //    model.ClaimDateFrom = model.ClaimDateTo.Value.AddDays(-defaultDaysInteger);
            //}
            //if (model.ClaimDateFrom.HasValue && !model.ClaimDateTo.HasValue)
            //{
            //    model.ClaimDateTo = model.ClaimDateFrom.Value.AddDays(defaultDaysInteger);
            //}
            #endregion

            return model;
        }

        public static List<NameValuePair> GetFilterClause(this CustomerFeedbackSearchCriteria model)
        {
            CustomerFeedbackSearchCriteria refreshModel = GetModelForSearchCriteria(model);
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

            // Statuses
            if (refreshModel.Statuses != null && refreshModel.Statuses.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.Statuses.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var Statuses = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "Statuses", Value = Statuses });
                }
            }
            // Sources
            if (refreshModel.Sources != null && refreshModel.Sources.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.Sources.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var Sources = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "Sources", Value = Sources });
                }
            }

            // Sources
            if (refreshModel.FeedbackTypes != null && refreshModel.FeedbackTypes.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.Sources.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var FeedbackTypes = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "FeedbackTypes", Value = FeedbackTypes });
                }
            }

            // Priority
            if (refreshModel.Priority != null && refreshModel.Priority.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.Sources.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var Priority = result.ToDelimitedStringForFeedback(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "Priority", Value = Priority });
                }
            }


            if (refreshModel.Client.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "Client", Value = refreshModel.Client.Value.ToString() });
            }
            if (refreshModel.Program.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "Program", Value = refreshModel.Program.Value.ToString() });
            }

            if (refreshModel.NextAction.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "NextAction", Value = refreshModel.NextAction.Value.ToString() });
            }

            if (refreshModel.ReceivedFromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ReceivedFromDate", Value = refreshModel.ReceivedFromDate.Value.ToShortDateString() });
            }
            if (refreshModel.ReceivedToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ReceivedToDate", Value = refreshModel.ReceivedToDate.Value.ToShortDateString() });
            }
            return filterList;
        }

        private static string ToDelimitedStringForFeedback<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }
    }
}
