using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;

namespace Martex.DMS.DAL.Entities
{
    [Serializable]
    public class MemberManagementSearchCriteria : ListFilterViewCommonAttributes
    {
        public string MemberNumber { get; set; }
        
        public string FirstName { get; set; }
        public int? FirstNameNameOperator { get; set; }
        public string FirstNameOperatorValue { get; set; }

        public string LastName { get; set; }
        public int? LastNameOperator { get; set; }
        public string LastNameOperatorValue { get; set; }

        public string City { get; set; }

        public int? StateProvinceID { get; set; }
        public string StateProvince { get; set; }

        public string Country { get; set; }
        public int? CountryID { get; set; }
        public string PostalCode { get; set; }

        public string PhoneNumber { get; set; }

        public string VIN { get; set; }

        public int? SearchClientID { get; set; }
        public string SearchClientName { get; set; }

        public int? SearchProgramID { get; set; }
        public string SearchProgramName { get; set; }

        public List<CheckBoxLookUp> Status { get; set; }

        public bool PanelViewsSelected { get; set; }
        public bool PanelItemsSelected { get; set; }
        public bool? PanelIDSelected { get; set; }
        public bool? PanelNameSelected { get; set; }
        public bool PanelAddressSelected { get; set; }
        public bool PanelStatusSelected { get; set; }
        public bool PanelPhoneNumberSelected { get; set; }
        public bool PanelVINSelected { get; set; }
        public bool PanelClientProgramSelected { get; set; }

        public bool ResetModelCriteria { get; set; }

        // Helpers
        public int? FilterToLoadID { get; set; }
        public string NewViewName { get; set; }
        public string GridSortColumnName { get; set; }
        public string GridSortOrder { get; set; }
    }

    public static class MemberManagementSearchCriteria_Extension
    {
        public static MemberManagementSearchCriteria GetModelForSearchCriteria(this MemberManagementSearchCriteria model)
        {
            if (model == null)
            {
                model = new MemberManagementSearchCriteria();
            }

            #region Member Status
            List<CheckBoxLookUp> memberStatus = new List<CheckBoxLookUp>();
            List<DropDownEntityForString> memberStatuslist = ReferenceDataRepository.GetMemberManagementStatus();

            if (model.Status == null)
            {
                foreach (DropDownEntityForString status in memberStatuslist)
                {
                    memberStatus.Add(new CheckBoxLookUp()
                    {
                        Name = status.Text,
                        Selected = false
                    });
                }
                model.Status = memberStatus;
            }
            #endregion

            #region State & Country
            if (!model.CountryID.HasValue)
            {
                model.StateProvinceID = null;
                model.StateProvince = string.Empty;
                model.Country = string.Empty;
            }

            #endregion

            #region Name Filter Section
            if (string.IsNullOrEmpty(model.FirstName))
            {
                model.FirstNameNameOperator = null;
                model.FirstNameOperatorValue = string.Empty;
            }
            if (string.IsNullOrEmpty(model.LastName))
            {
                model.LastNameOperator = null;
                model.LastNameOperatorValue = string.Empty;
            }
            #endregion

            #region Client and Program Section
            if (!model.SearchClientID.HasValue)
            {
                model.SearchProgramID = null;
                model.SearchProgramName = string.Empty;
            }
            #endregion

            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                foreach (CheckBoxLookUp lookup in model.Status)
                {
                    lookup.Selected = false;
                }

                model.MemberNumber = string.Empty;
                model.FirstName = string.Empty;
                model.FirstNameNameOperator = null;
                model.FirstNameOperatorValue = string.Empty;
                model.LastName = null;
                model.LastNameOperator = null;
                model.LastNameOperatorValue = string.Empty;
                model.City = string.Empty;
                model.Country = string.Empty;
                model.CountryID = null;
                model.StateProvince = string.Empty;
                model.StateProvinceID = null;
                model.PostalCode = string.Empty;
                model.PhoneNumber = string.Empty;
                model.VIN = string.Empty;
                model.SearchClientID = null;
                model.SearchClientName = string.Empty;
                model.SearchProgramID = null;
                model.SearchProgramName = string.Empty;

                model.PanelIDSelected = true;
                model.PanelNameSelected = true;
                model.ResetModelCriteria = false;
            }
            #endregion

            return model;
        }

        private static string ToDelimitedStringForMember<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }

        public static List<NameValuePair> GetFilterClause(this MemberManagementSearchCriteria model)
        {
            MemberManagementSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(refreshModel.MemberNumber))
            {
                filterList.Add(new NameValuePair() { Name = "MemberNumberValue", Value = refreshModel.MemberNumber });
                filterList.Add(new NameValuePair() { Name = "MemberNumberOperator", Value = "6" });
            }
            if (!string.IsNullOrEmpty(refreshModel.FirstName) && refreshModel.FirstNameNameOperator.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "FirstNameValue", Value = refreshModel.FirstName });
                filterList.Add(new NameValuePair() { Name = "FirstNameOperator", Value = refreshModel.FirstNameNameOperator.Value.ToString() });
            }
            if (!string.IsNullOrEmpty(refreshModel.LastName) && refreshModel.LastNameOperator.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "LastNameValue", Value = refreshModel.LastName });
                filterList.Add(new NameValuePair() { Name = "LastNameOperator", Value = refreshModel.LastNameOperator.Value.ToString() });
            }
         
            if (refreshModel.CountryID.HasValue && refreshModel.StateProvinceID.HasValue && !string.IsNullOrEmpty(refreshModel.City))
            {
                filterList.Add(new NameValuePair() { Name = "CountryIDValue", Value = refreshModel.CountryID.Value.ToString() });
                filterList.Add(new NameValuePair() { Name = "CountryIDOperator", Value = "2" });

                filterList.Add(new NameValuePair() { Name = "StateProvinceIDValue", Value = refreshModel.StateProvinceID.Value.ToString() });
                filterList.Add(new NameValuePair() { Name = "StateProvinceIDOperator", Value = "2" });

                filterList.Add(new NameValuePair() { Name = "CityValue", Value = refreshModel.City });
                filterList.Add(new NameValuePair() { Name = "CityOperator", Value = "6" });
            }
            if (!string.IsNullOrEmpty(refreshModel.PostalCode))
            {
                filterList.Add(new NameValuePair() { Name = "PostalCodeValue", Value = refreshModel.PostalCode });
                filterList.Add(new NameValuePair() { Name = "PostalCodeOperator", Value = "6" });
            }
            if (!string.IsNullOrEmpty(refreshModel.PhoneNumber))
            {
                filterList.Add(new NameValuePair() { Name = "PhoneNumberValue", Value = refreshModel.PhoneNumber });
                filterList.Add(new NameValuePair() { Name = "PhoneNumberOperator", Value = "6" });
            }
            if (!string.IsNullOrEmpty(refreshModel.VIN))
            {
                filterList.Add(new NameValuePair() { Name = "VINValue", Value = refreshModel.VIN });
                filterList.Add(new NameValuePair() { Name = "VINOperator", Value = "6" });
            }
            if (model.SearchClientID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ClientIDValue", Value = refreshModel.SearchClientID.Value.ToString() });
                filterList.Add(new NameValuePair() { Name = "ClientIDOperator", Value = "2" });
            }
            if (model.SearchProgramID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ProgramIDValue", Value = refreshModel.SearchProgramID.Value.ToString() });
                filterList.Add(new NameValuePair() { Name = "ProgramIDOperator", Value = "2" });
            }
            // Status Section
            if (refreshModel.Status != null && refreshModel.Status.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.Status.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    // Which means at least one search criteria is selected above
                    if (filterList.Count > 0)
                    {
                        var memberStatus = result.ToDelimitedStringForMember(u => u.Name);
                        filterList.Add(new NameValuePair() { Name = "MemberStatusValue", Value = memberStatus });
                        filterList.Add(new NameValuePair() { Name = "MemberStatusOperator", Value = "6" });
                    }
                }
            }
            return filterList;
        }
    }
}
