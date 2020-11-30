using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Text;
using Kendo.Mvc;
namespace VendorPortal.Common
{
    public class GridUtil
    {
        #region Variables
        private StringBuilder WhereClauseXml;
        #endregion

        #region Enumerators
        private enum GridFilterOperator
        {
            NoFilter = -1,
            IsNull = 0,
            NotIsNull = 1,
            EqualTo = 2,
            NotEqualTo = 3,
            StartsWith = 4,
            EndsWith = 5,
            Contains = 6,
            GreaterThan = 7,
            GreaterThanOrEqualTo = 8,
            LessThan = 9,
            LessThanOrEqualTo = 10
        }
        #endregion

        #region Constructors
        public GridUtil()
        {
        }
        #endregion

        //#region Methods
        //public string GetWhereClauseXml(IList<IFilterDescriptor> gridFilterDescriptors)
        //{
        //    WhereClauseXml = new StringBuilder();
        //    if (gridFilterDescriptors.Count > 0)
        //    {
        //        WhereClauseXml.Append("<ROW><Filter");

        //        Type filterItemType = gridFilterDescriptors[0].GetType();
        //        //SP: If it is Simple Filter
        //        if (filterItemType.Equals(typeof(FilterDescriptor)))
        //        {
        //            BuildSimpleFilterDescriptors(gridFilterDescriptors);
        //        }
        //        else if (filterItemType.Equals(typeof(Telerik.Web.Mvc.CompositeFilterDescriptor))) //SP: If it is Composite Filter
        //        {
        //            BuildCompositeFilterDescriptors(gridFilterDescriptors);
        //        }
        //        WhereClauseXml.Append("></Filter></ROW>");
        //    }
        //    return WhereClauseXml.ToString();

        //}
        //#endregion

        //#region HelperMethods
        private GridFilterOperator GetConditionalOperator(string functionName)
        {
            GridFilterOperator conditionalOperator = GridFilterOperator.NoFilter;
            switch (functionName)
            {
                case "IsEqualTo":
                    conditionalOperator = GridFilterOperator.EqualTo;
                    break;
                case "IsNotEqualTo":
                    conditionalOperator = GridFilterOperator.NotEqualTo;
                    break;

                case "IsGreaterThan":
                    conditionalOperator = GridFilterOperator.GreaterThan;
                    break;

                case "IsLessThan":
                    conditionalOperator = GridFilterOperator.LessThan;
                    break;

                case "IsGreaterThanOrEqualTo":
                    conditionalOperator = GridFilterOperator.GreaterThanOrEqualTo;
                    break;

                case "IsLessThanOrEqualTo":
                    conditionalOperator = GridFilterOperator.LessThanOrEqualTo;
                    break;

                //case "Between":
                //    conditionalOperator = GridFilterOperator.Between;
                //    break;

                //case "NotBetween":
                //    conditionalOperator = ConditionOperator.NotBetween;
                //    break;

                case "StartsWith":
                    conditionalOperator = GridFilterOperator.StartsWith;
                    break;

                case "EndsWith":
                    conditionalOperator = GridFilterOperator.EndsWith;
                    break;

                case "IsNull":
                    conditionalOperator = GridFilterOperator.IsNull;
                    break;

                case "NotIsNull":
                    conditionalOperator = GridFilterOperator.NotIsNull;
                    break;

                case "Contains":
                    conditionalOperator = GridFilterOperator.Contains;
                    break;

                //case "DoesNotContain":
                //    conditionalOperator = ConditionOperator.NotLike;
                //    break;

                default:
                    conditionalOperator = GridFilterOperator.Contains;
                    break;
            }
            return conditionalOperator;
        }

        //private void AppendFilterToWhereClause(FilterDescriptor filterItem)
        //{
        //    //SP: Append required members (Operator, value, etc.,) from the filterItem to WhereClauseXml
        //    GridFilterOperator filterOperator = GetConditionalOperator(filterItem.Operator.ToString());
        //    string filterValue = ((filterItem.Value.ToString().Replace("&", "")).Replace("<", "")).Replace("\"", "");
        //    WhereClauseXml.Append(" ");
        //    WhereClauseXml.AppendFormat("{0}Operator=\"{1}\" ", filterItem.Member, (int)filterOperator);
        //    WhereClauseXml.AppendFormat(" {0}Value=\"{1}\"", filterItem.Member, filterValue);
        //}

        //private void BuildSimpleFilterDescriptors(IList<IFilterDescriptor> filterDescriptors)
        //{
        //    //SP: Traverse each filteritem and process the filter item
        //    foreach (FilterDescriptor filterItem in filterDescriptors)
        //    {
        //        AppendFilterToWhereClause(filterItem);
        //    }
        //}

        //private string BuildSimpleFilterDescriptor(FilterDescriptor simpleFilter, string filterMember)
        //{
        //    if (string.IsNullOrEmpty(filterMember) || !filterMember.Equals(simpleFilter.Member))
        //    {
        //        AppendFilterToWhereClause(simpleFilter);
        //    }
        //    return simpleFilter.Member;
        //}

        //private void BuildCompositeFilterDescriptors(IList<IFilterDescriptor> compositeFilterDescriptors)
        //{
        //    //SP: Traverse each filter descriptior, find whether it is simple or composite and process it
        //    for (int descriptorCount = 0, descriptorLength = compositeFilterDescriptors.Count; descriptorCount < descriptorLength; ++descriptorCount)
        //    {
        //        string filterMember = string.Empty;
        //        Type filterType = compositeFilterDescriptors[descriptorCount].GetType();
        //        if (filterType.Equals(typeof(FilterDescriptor)))  //SP: if it is simple descriptor
        //        {
        //            FilterDescriptor simpleFilter = ((FilterDescriptor)(compositeFilterDescriptors[descriptorCount]));
        //            filterMember = BuildSimpleFilterDescriptor(simpleFilter, filterMember);
        //        }
        //        else if (filterType.Equals(typeof(CompositeFilterDescriptor))) //SP: if it is composite descriptor
        //        {
        //            CompositeFilterDescriptor compositeFilter = ((CompositeFilterDescriptor)(compositeFilterDescriptors[descriptorCount]));
        //            filterMember = BuildCompositeFilterDescriptor(compositeFilter, filterMember);
        //        }
        //    }
        //}

        //private string BuildCompositeFilterDescriptor(CompositeFilterDescriptor compositeFilterDescriptor, string filterMember)
        //{
        //    //SP: Traverse each filter item and process it
        //    for (int filterDescriptorCount = 0, filterDescriptorLength = compositeFilterDescriptor.FilterDescriptors.Count; filterDescriptorCount < filterDescriptorLength; ++filterDescriptorCount)
        //    {
        //        //SP: Finding the filter descriptor type
        //        Type itemType = compositeFilterDescriptor.FilterDescriptors[filterDescriptorCount].GetType();
        //        if (itemType.Equals(typeof(FilterDescriptor)))  //SP: if it is simple filter
        //        {
        //            FilterDescriptor simpleFilter = ((FilterDescriptor)(compositeFilterDescriptor.FilterDescriptors[filterDescriptorCount]));
        //            filterMember = BuildSimpleFilterDescriptor(simpleFilter, filterMember);
        //        }
        //        else if (itemType.Equals(typeof(CompositeFilterDescriptor))) //SP: if it is composite filter
        //        {
        //            CompositeFilterDescriptor compositeFilter = ((CompositeFilterDescriptor)(compositeFilterDescriptor.FilterDescriptors[filterDescriptorCount]));
        //            filterMember = BuildCompositeFilterDescriptor(compositeFilter, filterMember);
        //        }
        //    }

        //    return filterMember;
        //}


        //#endregion

        #region Kendo Helpers
        public string GetWhereClauseXml_Kendo(IList<Kendo.Mvc.IFilterDescriptor> gridFilterDescriptors)
        {
            WhereClauseXml = new StringBuilder();
            if (gridFilterDescriptors != null && gridFilterDescriptors.Count > 0)
            {
                WhereClauseXml.Append("<ROW><Filter");

                Type filterItemType = gridFilterDescriptors[0].GetType();
                //SP: If it is Simple Filter
                if (filterItemType.Equals(typeof(Kendo.Mvc.FilterDescriptor)))
                {
                    BuildSimpleFilterDescriptors_Kendo(gridFilterDescriptors);
                }
                else if (filterItemType.Equals(typeof(Kendo.Mvc.CompositeFilterDescriptor))) //SP: If it is Composite Filter
                {
                    BuildCompositeFilterDescriptors_Kendo(gridFilterDescriptors);
                }
                WhereClauseXml.Append("></Filter></ROW>");
            }
            return WhereClauseXml.ToString();

        }

        private void BuildSimpleFilterDescriptors_Kendo(IList<Kendo.Mvc.IFilterDescriptor> filterDescriptors)
        {
            //SP: Traverse each filteritem and process the filter item
            foreach (Kendo.Mvc.FilterDescriptor filterItem in filterDescriptors)
            {
                AppendFilterToWhereClause_Kendo(filterItem);
            }
        }

        private void AppendFilterToWhereClause_Kendo(Kendo.Mvc.FilterDescriptor filterItem)
        {
            //SP: Append required members (Operator, value, etc.,) from the filterItem to WhereClauseXml
            GridFilterOperator filterOperator = GetConditionalOperator(filterItem.Operator.ToString());
            string filterValue = ((filterItem.Value.ToString().Replace("&", "")).Replace("<", "")).Replace("\"", "");
            WhereClauseXml.Append(" ");
            WhereClauseXml.AppendFormat("{0}Operator=\"{1}\" ", filterItem.Member, (int)filterOperator);
            WhereClauseXml.AppendFormat(" {0}Value=\"{1}\"", filterItem.Member, filterValue);
        }

        private void BuildCompositeFilterDescriptors_Kendo(IList<Kendo.Mvc.IFilterDescriptor> compositeFilterDescriptors)
        {
            //SP: Traverse each filter descriptior, find whether it is simple or composite and process it
            for (int descriptorCount = 0, descriptorLength = compositeFilterDescriptors.Count; descriptorCount < descriptorLength; ++descriptorCount)
            {
                string filterMember = string.Empty;
                Type filterType = compositeFilterDescriptors[descriptorCount].GetType();
                if (filterType.Equals(typeof(Kendo.Mvc.FilterDescriptor)))  //SP: if it is simple descriptor
                {
                    Kendo.Mvc.FilterDescriptor simpleFilter = ((Kendo.Mvc.FilterDescriptor)(compositeFilterDescriptors[descriptorCount]));
                    filterMember = BuildSimpleFilterDescriptor_Kendo(simpleFilter, filterMember);
                }
                else if (filterType.Equals(typeof(Kendo.Mvc.CompositeFilterDescriptor))) //SP: if it is composite descriptor
                {
                    Kendo.Mvc.CompositeFilterDescriptor compositeFilter = ((Kendo.Mvc.CompositeFilterDescriptor)(compositeFilterDescriptors[descriptorCount]));
                    filterMember = BuildCompositeFilterDescriptor_Kendo(compositeFilter, filterMember);
                }
            }
        }
        private string BuildSimpleFilterDescriptor_Kendo(Kendo.Mvc.FilterDescriptor simpleFilter, string filterMember)
        {
            if (string.IsNullOrEmpty(filterMember) || !filterMember.Equals(simpleFilter.Member))
            {
                AppendFilterToWhereClause_Kendo(simpleFilter);
            }
            return simpleFilter.Member;
        }
        private string BuildCompositeFilterDescriptor_Kendo(Kendo.Mvc.CompositeFilterDescriptor compositeFilterDescriptor, string filterMember)
        {
            //SP: Traverse each filter item and process it
            for (int filterDescriptorCount = 0, filterDescriptorLength = compositeFilterDescriptor.FilterDescriptors.Count; filterDescriptorCount < filterDescriptorLength; ++filterDescriptorCount)
            {
                //SP: Finding the filter descriptor type
                Type itemType = compositeFilterDescriptor.FilterDescriptors[filterDescriptorCount].GetType();
                if (itemType.Equals(typeof(Kendo.Mvc.FilterDescriptor)))  //SP: if it is simple filter
                {
                    Kendo.Mvc.FilterDescriptor simpleFilter = ((Kendo.Mvc.FilterDescriptor)(compositeFilterDescriptor.FilterDescriptors[filterDescriptorCount]));
                    filterMember = BuildSimpleFilterDescriptor_Kendo(simpleFilter, filterMember);
                }
                else if (itemType.Equals(typeof(Kendo.Mvc.CompositeFilterDescriptor))) //SP: if it is composite filter
                {
                    Kendo.Mvc.CompositeFilterDescriptor compositeFilter = ((Kendo.Mvc.CompositeFilterDescriptor)(compositeFilterDescriptor.FilterDescriptors[filterDescriptorCount]));
                    filterMember = BuildCompositeFilterDescriptor_Kendo(compositeFilter, filterMember);
                }
            }

            return filterMember;
        }
        #endregion
    }
}