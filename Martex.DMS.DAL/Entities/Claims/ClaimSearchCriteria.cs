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

namespace Martex.DMS.DAL.Entities.Claims
{
    /// <summary>
    /// 
    /// </summary>
    [Serializable]
    public class ClaimSearchCriteria : ListFilterViewCommonAttributes
    {
        #region Search Criteria
        public string LookUpTypeName { get; set; }
        public string LookUpTypeValue { get; set; }

        public string NameTypeName { get; set; }
        public string NameTypeValue { get; set; }
        public string NameOperator { get; set; }
        public string NameOperatorValue { get; set; }

        public List<CheckBoxLookUp> ClaimTypes { get; set; }

        public List<CheckBoxLookUp> ClaimStatus { get; set; }

        public List<CheckBoxLookUp> ClaimCategory { get; set; }

        public List<CheckBoxLookUp> ACESStatus { get; set; }

        public int? ClientID { get; set; }
        public string ClientIDValue { get; set; }

        public int? ProgramID { get; set; }
        public string ProgramIDValue { get; set; }

        public DateTime? ClaimDateFrom { get; set; }
        public DateTime? ClaimDateTo { get; set; }

        public int? Preset { get; set; }

        public DateTime? ClaimDateReadyForPayment { get; set; }

        public double? ClaimAmountStart { get; set; }
        public double? ClaimAmountEnd { get; set; }

        public string CheckNumber { get; set; }
        public DateTime? CheckFromDate { get; set; }
        public DateTime? CheckToDate { get; set; }

        public int? ExportBatchID { get; set; }
        public string ExportBatchName { get; set; }


        public DateTime? ReadyForPaymentStartDate { get; set; }
        public DateTime? ReadyForPaymentEndDate { get; set; }

        public DateTime? ACESSubmitFromDate { get; set; }
        public DateTime? ACESSubmitToDate { get; set; }

        public DateTime? ReceivedFromDate { get; set; }
        public DateTime? ReceivedToDate { get; set; }

        public DateTime? ACESClearedFromDate { get; set; }
        public DateTime? ACESClearedToDate { get; set; }
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
        public bool PanelClaimTypeSelected { get; set; }
        public bool PanelACESClearedDateSelected { get; set; }
        public bool PanelACESSubmitDateSelected { get; set; }
        public bool PanelClaimStatusSelected { get; set; }
        public bool PanelClaimCategorySelected { get; set; }
        public bool PanelClientProgramSelected { get; set; }
        public bool PanelClaimDateRangeSelected { get; set; }
        public bool PanelClaimAmountRangeSelected { get; set; }
        public bool PanelCheckInformationSelected { get; set; }
        public bool PanelExportBatchSelected { get; set; }
        public bool PanelReadyForPaymentDateRange { get; set; }
        public bool PanelACESClaimStatus { get; set; }
        public bool PanelReceivedDateSelected { get; set; }
        #endregion
    }

    public static class ClaimSearchCriteria_Extension
    {
        public static ClaimSearchCriteria GetModelForSearchCriteria(this ClaimSearchCriteria model)
        {
            int defaultDaysInteger = 0;
            string defaultDays = AppConfigRepository.GetValue("DefaultClaimListDays");//KB: No need to use type while looking up appconfig, ApplicationConfigurationTypes.SYSTEM);
            int.TryParse(defaultDays, out defaultDaysInteger);

            #region Check When Model is Null
            if (model == null)
            {
                model = new ClaimSearchCriteria();
                model.PanelIDSelected = true;
                model.PanelNameSelected = true;
                model.ClaimDateTo = DateTime.Now;
                model.ClaimDateFrom = DateTime.Now.AddDays(-defaultDaysInteger);
            }
            #endregion

            #region Claim Types
            List<CheckBoxLookUp> claimTypes = new List<CheckBoxLookUp>();
            List<ClaimType> claimTypeDetails = ReferenceDataRepository.GetClaimTypes();

            if (model.ClaimTypes == null)
            {
                foreach (var status in claimTypeDetails)
                {
                    claimTypes.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.ClaimTypes = claimTypes;
            }
            #endregion

            #region Claim Status
            List<CheckBoxLookUp> claimStatus = new List<CheckBoxLookUp>();
            List<ClaimStatu> claimStatusDetails = ReferenceDataRepository.GetClaimStatus();

            if (model.ClaimStatus == null)
            {
                foreach (var status in claimStatusDetails)
                {
                    claimStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.ClaimStatus = claimStatus;
            }
            #endregion

            #region Claim Category
            List<CheckBoxLookUp> claimCategory = new List<CheckBoxLookUp>();
            List<ClaimCategory> claimCategoryDetails = ReferenceDataRepository.GetClaimCategories();

            if (model.ClaimCategory == null)
            {
                foreach (var status in claimCategoryDetails)
                {
                    claimCategory.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.ClaimCategory = claimCategory;
            }
            #endregion

            #region ACES Status
            List<CheckBoxLookUp> acesStatus = new List<CheckBoxLookUp>();
            List<ACESClaimStatu> acesStatusList = ReferenceDataRepository.GetAcesClaimStatus();

            if (model.ACESStatus == null)
            {
                foreach (var status in acesStatusList)
                {
                    acesStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Description,
                        Selected = false
                    });
                }
                model.ACESStatus = acesStatus;
            }
            #endregion

            #region Verfying Inputs
            if (string.IsNullOrEmpty(model.LookUpTypeName))
            {
                model.LookUpTypeValue = string.Empty;
            }

            if (string.IsNullOrEmpty(model.NameTypeName))
            {
                model.NameTypeValue = string.Empty;
                model.NameOperator = string.Empty;
                model.NameOperatorValue = string.Empty;
            }

            if (string.IsNullOrEmpty(model.NameTypeValue))
            {
                model.NameOperator = string.Empty;
                model.NameOperatorValue = string.Empty;
            }

            if (!model.ClientID.HasValue)
            {
                model.ProgramID = null;
                model.ProgramIDValue = string.Empty;
                model.ClientIDValue = string.Empty;
            }
            #endregion

            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                model.FilterToLoadID = null;
                model.ResetModelCriteria = false;

                model.ExportBatchID = null;
                model.ExportBatchName = string.Empty;

                model.ClaimDateTo = null;
                model.ClaimDateFrom = null;

                model.CheckNumber = string.Empty;
                model.CheckFromDate = null;
                model.CheckToDate = null;


                model.ClaimAmountEnd = null;
                model.ClaimAmountStart = null;

                model.ClaimDateFrom = null;
                model.ClaimDateTo = null;
                model.Preset = null;

                model.ClientID = null;
                model.ProgramID = null;

                model.ClientIDValue = string.Empty;
                model.ProgramIDValue = string.Empty;

                model.ReadyForPaymentEndDate = null;
                model.ReadyForPaymentStartDate = null;

                model.ACESSubmitFromDate = null;
                model.ACESSubmitToDate = null;

                model.ACESClearedFromDate = null;
                model.ACESClearedToDate = null;

                model.ReceivedFromDate = null;
                model.ReceivedToDate = null;

                foreach (CheckBoxLookUp item in model.ClaimCategory)
                {
                    item.Selected = false;
                }
                foreach (CheckBoxLookUp item in model.ClaimStatus)
                {
                    item.Selected = false;
                }
                foreach (CheckBoxLookUp item in model.ClaimTypes)
                {
                    item.Selected = false;
                }

                foreach (CheckBoxLookUp item in model.ACESStatus)
                {
                    item.Selected = false;
                }

                model.NameTypeName = string.Empty;
                model.NameTypeValue = string.Empty;
                model.NameOperator = string.Empty;
                model.NameOperatorValue = string.Empty;

                model.LookUpTypeName = string.Empty;
                model.LookUpTypeValue = string.Empty;

                model.PanelItemsSelected = false;
                model.PanelViewsSelected = false;
                model.PanelIDSelected = true;
                model.PanelNameSelected = true;
                model.PanelClaimTypeSelected = false;
                model.PanelClaimStatusSelected = false;
                model.PanelClaimCategorySelected = false;
                model.PanelClientProgramSelected = false;
                model.PanelClaimDateRangeSelected = false;
                model.PanelClaimAmountRangeSelected = false;
                model.PanelCheckInformationSelected = false;
                model.PanelExportBatchSelected = false;
                model.PanelReadyForPaymentDateRange = false;
                model.PanelACESSubmitDateSelected = false;
                model.PanelACESClearedDateSelected = false;
                model.PanelACESClaimStatus = false;
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
    
        public static List<NameValuePair> GetFilterClause(this ClaimSearchCriteria model)
        {
            ClaimSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(refreshModel.LookUpTypeName))
            {
                filterList.Add(new NameValuePair() { Name = "IDType", Value = refreshModel.LookUpTypeName });
            }
            if (!string.IsNullOrEmpty(refreshModel.LookUpTypeValue))
            {
                filterList.Add(new NameValuePair() { Name = "IDValue", Value = refreshModel.LookUpTypeValue });
            }
            if (!string.IsNullOrEmpty(refreshModel.NameTypeName))
            {
                filterList.Add(new NameValuePair() { Name = "NameType", Value = refreshModel.NameTypeName });
            }
            if (!string.IsNullOrEmpty(refreshModel.NameTypeValue))
            {
                filterList.Add(new NameValuePair() { Name = "NameValue", Value = refreshModel.NameTypeValue });
            }
            if (!string.IsNullOrEmpty(refreshModel.NameOperator))
            {
                filterList.Add(new NameValuePair() { Name = "NameOperator", Value = refreshModel.NameOperator });
            }
            // Claim Types
            if (refreshModel.ClaimTypes != null && refreshModel.ClaimTypes.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.ClaimTypes.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var claimTypes = result.ToDelimitedStringForClaim(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "ClaimTypes", Value = claimTypes });
                }
            }
            // Claim Status
            if (refreshModel.ClaimStatus != null && refreshModel.ClaimStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.ClaimStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var claimStatus = result.ToDelimitedStringForClaim(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "ClaimStatuses", Value = claimStatus });
                }
            }

            // ACES Status
            if (refreshModel.ACESStatus != null && refreshModel.ACESStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.ACESStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var acesStatus = result.ToDelimitedStringForClaim(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "ACESStatus", Value = acesStatus });
                }
            }

            // Claim Category
            if (refreshModel.ClaimCategory != null && refreshModel.ClaimCategory.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.ClaimCategory.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var claimCategories = result.ToDelimitedStringForClaim(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "ClaimCategories", Value = claimCategories });
                }
            }
            if (refreshModel.ClientID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClientID", Value = refreshModel.ClientID.Value.ToString() });
            }
            if (refreshModel.ProgramID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ProgramID", Value = refreshModel.ProgramID.Value.ToString() });
            }
            if (refreshModel.ClaimDateFrom.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClaimDateFrom", Value = refreshModel.ClaimDateFrom.Value.ToShortDateString() });
            }
            if (refreshModel.ClaimDateTo.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClaimDateTo", Value = refreshModel.ClaimDateTo.Value.ToShortDateString() });
            }

            if (refreshModel.ClaimAmountStart.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClaimAmountFrom", Value = refreshModel.ClaimAmountStart.ToString() });
            }
            if (refreshModel.ClaimAmountEnd.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClaimAmountTo", Value = refreshModel.ClaimAmountEnd.ToString() });
            }
            if (refreshModel.Preset.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "Preset", Value = refreshModel.Preset.Value.ToString() });
            }
            if (refreshModel.CheckFromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "CheckDateFrom", Value = refreshModel.CheckFromDate.Value.ToShortDateString() });
            }
            if (refreshModel.CheckToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "CheckDateTo", Value = refreshModel.CheckToDate.Value.ToShortDateString() });
            }
            if (!string.IsNullOrEmpty(refreshModel.CheckNumber))
            {
                filterList.Add(new NameValuePair() { Name = "CheckNumber", Value = refreshModel.CheckNumber });
            }
            if (model.ExportBatchID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ExportBatchID", Value = refreshModel.ExportBatchID.Value.ToString() });
            }
            // TFS : 2020
            //if (model.ReadyForPaymentStartDate.HasValue)
            //{
            //    filterList.Add(new NameValuePair() { Name = "ReadyForPaymentStartDate", Value = refreshModel.ReadyForPaymentStartDate.Value.ToString() });
            //}
            //if (model.ReadyForPaymentEndDate.HasValue)
            //{
            //    filterList.Add(new NameValuePair() { Name = "ReadyForPaymentEndDate", Value = refreshModel.ReadyForPaymentEndDate.Value.ToString() });
            //}

            if (refreshModel.ACESSubmitFromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ACESSubmitFromDate", Value = refreshModel.ACESSubmitFromDate.Value.ToShortDateString() });
            }
            if (refreshModel.ACESSubmitToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ACESSubmitToDate", Value = refreshModel.ACESSubmitToDate.Value.ToShortDateString() });
            }

            if (refreshModel.ACESClearedFromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ACESClearedFromDate", Value = refreshModel.ACESClearedFromDate.Value.ToShortDateString() });
            }
            if (refreshModel.ACESClearedToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ACESClearedToDate", Value = refreshModel.ACESClearedToDate.Value.ToShortDateString() });
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

        private static string ToDelimitedStringForClaim<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }
    }
}
