using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using System.Runtime.InteropServices;

namespace Martex.DMS.DAL.Entities
{
    /// <summary>
    /// Vendor Management Search Criteria
    /// </summary>
    [Serializable]
    public class VendorManagementSearchCriteria : ListFilterViewCommonAttributes
    {
        public string VendorNumber { get; set; }

        public string City { get; set; }
        public string PostalCode { get; set; }
        public int? StateProvinceID { get; set; }
        public string StateProvince { get; set; }

        public string Country { get; set; }
        public int? CountryID { get; set; }

        public List<CheckBoxLookUp> VendorStatus { get; set; }
        public List<CheckBoxLookUp> VendorRegion { get; set; }

        public string VendorName { get; set; }

        public int? VendorNameOperator { get; set; }
        public string VendorNameOperatorValue { get; set; }
        public bool? IsLevy { get; set; }
      
        public bool? HasPo { get; set; }
        public bool? IsFordDirectTow { get; set; }
        public bool? IsCNETDirectPartner { get; set; }

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
        public bool? PanelCityStateSelected { get; set; }
        public bool PanelStatusSelected { get; set; }
        public bool PanelRegionSelected { get; set; }
        public bool PanelLevySelected { get; set; }
        #endregion
    }

    public static class VendorManagementSearchCriteria_Extension
    {
        private static string ToDelimitedString_<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }

        public static List<NameValuePair> GetFilterSearchCritera(this VendorManagementSearchCriteria model)
        {
            VendorManagementSearchCriteria refreshModel = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(refreshModel.VendorNumber))
            {
                filterList.Add(new NameValuePair() { Name = "VendorNumber", Value = refreshModel.VendorNumber });
            }
            if (!string.IsNullOrEmpty(refreshModel.VendorName) && refreshModel.VendorNameOperator.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "VendorName", Value = refreshModel.VendorName });
                filterList.Add(new NameValuePair() { Name = "VendorNameOperator", Value = refreshModel.VendorNameOperatorValue });
            }
            if (refreshModel.CountryID.HasValue && refreshModel.StateProvinceID.HasValue && !string.IsNullOrEmpty(refreshModel.City))
            {
                filterList.Add(new NameValuePair() { Name = "CountryID", Value = refreshModel.CountryID.Value.ToString() });
                filterList.Add(new NameValuePair() { Name = "StateProvinceID", Value = refreshModel.StateProvinceID.Value.ToString() });
                filterList.Add(new NameValuePair() { Name = "City", Value = refreshModel.City });
            }
            if (!string.IsNullOrEmpty(refreshModel.PostalCode))
            {
                filterList.Add(new NameValuePair() { Name = "PostalCode", Value = refreshModel.PostalCode });
            }
            // Vendor Status Section
            if (refreshModel.VendorStatus != null && refreshModel.VendorStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.VendorStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var vendorStatus = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "VendorStatus", Value = vendorStatus });
                }
            }
            //Vendor Region Section
            if (refreshModel.VendorRegion != null && refreshModel.VendorRegion.Count > 0)
            {
                List<CheckBoxLookUp> result = refreshModel.VendorRegion.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var vendorRegion = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "VendorRegion", Value = vendorRegion });
                }
            }

            if (model.IsLevy.HasValue && model.IsLevy.Value)
            {
                filterList.Add(new NameValuePair() { Name = "IsLevy", Value = refreshModel.IsLevy.Value.ToString() });
            }
            if (model.HasPo.HasValue && model.HasPo.Value)
            {
                filterList.Add(new NameValuePair() { Name = "HasPo", Value = refreshModel.HasPo.Value.ToString() });
            }
            if (model.IsFordDirectTow.HasValue && model.IsFordDirectTow.Value)
            {
                filterList.Add(new NameValuePair() { Name = "IsFordDirectTow", Value = refreshModel.IsFordDirectTow.Value.ToString() });
            }
            if (model.IsCNETDirectPartner.HasValue && model.IsCNETDirectPartner.Value)
            {
                filterList.Add(new NameValuePair() { Name = "IsCNETDirectPartner", Value = refreshModel.IsCNETDirectPartner.Value.ToString() });
            }
            return filterList;
        }
       
        public static VendorManagementSearchCriteria GetModelForSearchCriteria(this VendorManagementSearchCriteria model)
        {
            #region Check When Model is null
            if (model == null)
            {
                model = new VendorManagementSearchCriteria();
                model.PanelIDSelected = true;
                model.PanelNameSelected = true;
                model.PanelCityStateSelected = true;
            }
            #endregion

            #region Needs to review
            if (!model.PanelCityStateSelected.HasValue)
            {
                model.PanelIDSelected = true;
                model.PanelNameSelected = true;
                model.PanelCityStateSelected = true;
            }
            #endregion

            #region Vendor Status
            List<CheckBoxLookUp> vendorStatus = new List<CheckBoxLookUp>();
            List<VendorStatu> vendorStatuslist = ReferenceDataRepository.GetVendorStatus();

            if (model.VendorStatus == null)
            {
                foreach (VendorStatu status in vendorStatuslist)
                {
                    vendorStatus.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.VendorStatus = vendorStatus;
            }
            #endregion

            #region Vendor Region
            List<CheckBoxLookUp> vendorRegion = new List<CheckBoxLookUp>();
            List<VendorRegion> vendorRegionList = ReferenceDataRepository.GetVendorRegion();

            if (model.VendorRegion == null)
            {
                foreach (VendorRegion region in vendorRegionList)
                {
                    vendorRegion.Add(new CheckBoxLookUp()
                    {
                        ID = region.ID,
                        Name = region.Name,
                        Selected = false
                    });
                }
                model.VendorRegion = vendorRegion;
            }
            #endregion

            #region State & Country
            if (!model.CountryID.HasValue)
            {
                model.StateProvinceID = null;
                model.StateProvince = string.Empty;
                model.Country = string.Empty;
                model.City = string.Empty;
            }

            #endregion

            #region Name Filter Section
            if (string.IsNullOrEmpty(model.VendorName))
            {
                model.VendorNameOperator = null;
            }
            #endregion
         
            #region Reset Critera
            if (model.ResetModelCriteria)
            {
                foreach (CheckBoxLookUp lookup in model.VendorStatus)
                {
                    lookup.Selected = false;
                }
                foreach (CheckBoxLookUp lookup in model.VendorRegion)
                {
                    lookup.Selected = false;
                }
                model.PostalCode = string.Empty;
                model.VendorNumber = string.Empty;
                model.VendorName = string.Empty;
                model.VendorNameOperator = null;
                model.VendorNameOperatorValue = string.Empty;
                model.City = string.Empty;
                model.Country = string.Empty;
                model.CountryID = null;
                model.StateProvince = string.Empty;
                model.IsLevy = null;
                model.HasPo = null;
                model.StateProvinceID = null;
                model.ResetModelCriteria = false;
                model.PanelIDSelected = true;
                model.PanelNameSelected = true;
                model.PanelCityStateSelected = true;
                model.PanelLevySelected = false;
                model.PanelRegionSelected = false;
                model.IsFordDirectTow = null;
                model.IsCNETDirectPartner = null;
            }
            #endregion

            return model;
        }
    }
}
