using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Model;
using System.Text;
using System.Xml;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Common
{
    /// <summary>
    /// Web Custom Extensions
    /// </summary>
    public static class WebCustomExtensions
    {
        #region Public Methods
        /// <summary>
        /// To the delimited string.
        /// </summary>
        /// <typeparam name="S"></typeparam>
        /// <typeparam name="T"></typeparam>
        /// <param name="lst">The LST.</param>
        /// <param name="selector">The selector.</param>
        /// <param name="separator">The separator.</param>
        /// <returns></returns>
        public static string ToDelimitedString<S, T>(this IEnumerable<S> lst, Func<S, T> selector,string separator = ",")
        {
            return string.Join(separator, lst.Select(selector));
        }

        /// <summary>
        /// To the select list item.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="list">The list.</param>
        /// <param name="key">The key.</param>
        /// <param name="val">The val.</param>
        /// <param name="addDefault">if set to <c>true</c> [add default].</param>
        /// <returns></returns>
        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this List<T> list, Func<T, string> key, Func<T, string> val, bool addDefault = false)
        {
            List<SelectListItem> selectListItems = new List<SelectListItem>();
            if (addDefault)
            {
                selectListItems.Add(new SelectListItem() { Text = "Select", Value = "", Selected = true });
            }

            list.ForEach(x =>
            {
                selectListItems.Add(new SelectListItem() { Value = key(x), Text = val(x) });
            });

            return selectListItems.AsEnumerable<SelectListItem>();
        }

        /// <summary>
        /// To the select list item.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="list">The list.</param>
        /// <param name="key">The key.</param>
        /// <param name="val">The val.</param>
        /// <param name="SelectedItem">The selected item.</param>
        /// <returns></returns>
        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this List<T> list, Func<T, string> key, Func<T, string> val, string SelectedItem)
        {
            List<SelectListItem> selectListItems = new List<SelectListItem>();

            list.ForEach(x =>
            {
                selectListItems.Add(new SelectListItem() { Value = key(x), Text = val(x), Selected = (SelectedItem == key(x) ? true : false) });
            });

            return selectListItems.AsEnumerable<SelectListItem>();
        }

        /// <summary>
        /// Fors the each.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="enumerable">The enumerable.</param>
        /// <param name="action">The action.</param>
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

        /// <summary>
        /// To the select list item.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="list">The list.</param>
        /// <param name="key">The key.</param>
        /// <param name="val">The val.</param>
        /// <param name="addDefault">if set to <c>true</c> [add default].</param>
        /// <returns></returns>
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

        /// <summary>
        /// To the select list item.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="list">The list.</param>
        /// <param name="key">The key.</param>
        /// <param name="val">The val.</param>
        /// <param name="SelectedItem">The selected item.</param>
        /// <returns></returns>
        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this IEnumerable<T> list, Func<T, string> key, Func<T, string> val, string SelectedItem)
        {
            List<SelectListItem> selectListItems = new List<SelectListItem>();

            list.ForEach(x =>
            {
                selectListItems.Add(new SelectListItem() { Value = key(x), Text = val(x), Selected = (SelectedItem == key(x) ? true : false) });
            });

            return selectListItems.AsEnumerable<SelectListItem>();
        }

        public static string GetXML(this List<NameValuePair> list)
        {
            string returnValue = string.Empty;
            if (list.Count > 0)
            {
                StringBuilder sbParams = new StringBuilder();

                XmlWriterSettings settings = new XmlWriterSettings();
                settings.Indent = true;
                settings.OmitXmlDeclaration = true;
                using (XmlWriter writer = XmlWriter.Create(sbParams, settings))
                {
                    writer.WriteStartElement("ROW");
                    writer.WriteStartElement("Filter");
                    foreach (NameValuePair item in list)
                    {
                        writer.WriteAttributeString(item.Name, item.Value);
                    }
                    writer.WriteEndElement();
                    writer.WriteEndElement();
                    writer.Close();
                }
                returnValue = sbParams.ToString();
            }
            return returnValue;
        }
        #endregion        
    }
}