using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using System.Runtime.InteropServices;

namespace Martex.DMS.DAL.Entities
{
    [Serializable]
    public class QueueSearchCriteria : ListFilterViewCommonAttributes
    {
        public int? IDSectionType { get; set; }
        public string IDSectionTypeValue { get; set; }

        public string IDSectionID { get; set; }

        public int? NameSectionType { get; set; }
        public string NameSectionTypeValue { get; set; }

        public string NameSectionTypeISP { get; set; }
        public string NameSectionTypeUser { get; set; }

        public string NameSectionTypeMemberFirstName { get; set; }
        public string NameSectionTypeMemberLastName { get; set; }

        public int? NameSectionFilter { get; set; }
        public string NameSectionFilterValue { get; set; }

        public List<CheckBoxLookUp> ServiceRequestStatus { get; set; }

        public int? ClosedLoopStatus { get; set; }
        public string ClosedLoopStatusValue { get; set; }

        public int? NextAction { get; set; }
        public string NextActionValue { get; set; }

        public int? Priority { get; set; }
        public string PriorityValue { get; set; }

        public int? ServiceType { get; set; }
        public string ServiceTypeValue { get; set; }

        public int? AssignedTo { get; set; }
        public string AssignedToValue { get; set; }
    }

    public static class QueueSearchCriteria_Extension
    {
        private static string ToDelimitedString_<S, T>(this IEnumerable<S> lst, Func<S, T> selector, string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }
        public static List<NameValuePair> GetFilterSearchCritera(this QueueSearchCriteria model)
        {
            QueueSearchCriteria searchCriteria = GetModelForSearchCriteria(model);
            List<NameValuePair> filterList = new List<NameValuePair>();
            // ID Section
            if (searchCriteria.IDSectionType.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "IDType", Value = searchCriteria.IDSectionTypeValue });
            }
            if (!string.IsNullOrEmpty(searchCriteria.IDSectionID))
            {
                filterList.Add(new NameValuePair() { Name = "IDValue", Value = searchCriteria.IDSectionID });
            }
            // Name Section
            if (searchCriteria.NameSectionType.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "NameType", Value = searchCriteria.NameSectionTypeValue });
            }
            if (!string.IsNullOrEmpty(searchCriteria.NameSectionTypeISP))
            {
                filterList.Add(new NameValuePair() { Name = "NameValue", Value = searchCriteria.NameSectionTypeISP });
            }
            if (!string.IsNullOrEmpty(searchCriteria.NameSectionTypeUser))
            {
                filterList.Add(new NameValuePair() { Name = "NameValue", Value = searchCriteria.NameSectionTypeUser });
            }
            if (!string.IsNullOrEmpty(searchCriteria.NameSectionTypeMemberFirstName))
            {
                filterList.Add(new NameValuePair() { Name = "NameValue", Value = searchCriteria.NameSectionTypeMemberFirstName });
            }
            if (!string.IsNullOrEmpty(searchCriteria.NameSectionTypeMemberLastName))
            {
                filterList.Add(new NameValuePair() { Name = "LastName", Value = searchCriteria.NameSectionTypeMemberLastName });
            }
            if (searchCriteria.NameSectionFilter.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "FilterType", Value = searchCriteria.NameSectionFilterValue });
            }

            //Service Type Section
            if (searchCriteria.ServiceRequestStatus != null && searchCriteria.ServiceRequestStatus.Count > 0)
            {
                List<CheckBoxLookUp> result = searchCriteria.ServiceRequestStatus.Where(u => u.Selected == true).ToList();
                if (result != null && result.Count > 0)
                {
                    var serviceType = result.ToDelimitedString_(u => u.ID);
                    filterList.Add(new NameValuePair() { Name = "ServiceTypes", Value = serviceType });
                }
            }

            return filterList;
        }

        private static QueueSearchCriteria GetModelForSearchCriteria(QueueSearchCriteria model)
        {
            throw new NotImplementedException();
        }
    }

}
