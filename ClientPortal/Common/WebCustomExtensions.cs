using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace ClientPortal.Common
{
    public static class WebCustomExtensions
    {
        public static string ToDelimitedString<S, T>(this IEnumerable<S> lst, Func<S, T> selector,string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }
        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this List<T> list, Func<T, string> key, Func<T, string> val, bool addDefault = false)
        {
            List<SelectListItem> selectListItems = new List<SelectListItem>();
            if (addDefault)
            {
                selectListItems.Add(new SelectListItem() { Text = "Select", Value = "",Selected = true });
            }

            list.ForEach(x =>
            {
                selectListItems.Add(new SelectListItem() { Value = key(x), Text = val(x) });
            });

            return selectListItems.AsEnumerable<SelectListItem>();
        }

        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this List<T> list, Func<T, string> key, Func<T, string> val, string SelectedItem)
        {
            List<SelectListItem> selectListItems = new List<SelectListItem>();

            list.ForEach(x =>
            {
                selectListItems.Add(new SelectListItem() { Value = key(x), Text = val(x), Selected = (SelectedItem == key(x) ? true : false) });
            });

            return selectListItems.AsEnumerable<SelectListItem>();
        }

        public static void ForEach<T>(this IEnumerable<T> enumerable, Action<T> action)
        {
            if (enumerable != null)
            {
                foreach (var cur in enumerable)
                {
                    action(cur);
                }

            }
        }

        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this IEnumerable<T> list, Func<T, string> key, Func<T, string> val, bool addDefault = false)
        {
            List<SelectListItem> selectListItems = new List<SelectListItem>();
            if (addDefault)
            {
                selectListItems.Add(new SelectListItem() { Text = "Select", Value = "" });
            }

            list.ForEach(x =>
            {
                selectListItems.Add(new SelectListItem() { Value = key(x), Text = val(x) });
            });

            return selectListItems.AsEnumerable<SelectListItem>();
        }

        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this IEnumerable<T> list, Func<T, string> key, Func<T, string> val, string SelectedItem)
        {
            List<SelectListItem> selectListItems = new List<SelectListItem>();

            list.ForEach(x =>
            {
                selectListItems.Add(new SelectListItem() { Value = key(x), Text = val(x), Selected = (SelectedItem == key(x) ? true : false) });
            });

            return selectListItems.AsEnumerable<SelectListItem>();
        }
        
    }
}