#region Copyright

// <copyright  project="Churpit" company="Churpit">Copyright (c) 2014.All rights reserved</copyright>
// <summary></summary>
// <author>Kiran Kumar Banda</author>
// <createdon>2014-06-20 3:04 PM</createdon>
// <modifiedon></modifiedon>
// <modifiedby></modifiedby>
// <changelog>
// 
// </changelog>

#endregion

using Microsoft.CSharp.RuntimeBinder;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using System.Web.Mvc.Ajax;

namespace MemberAPI.Common
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
        public static string ToDelimitedString<S, T>(this IEnumerable<S> lst, Func<S, T> selector,
            string separator = ",")
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
        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this List<T> list, Func<T, string> key,
            Func<T, string> val, bool addDefault = false)
        {
            var selectListItems = new List<SelectListItem>();
            if (addDefault)
            {
                selectListItems.Add(new SelectListItem { Text = "Select", Value = "", Selected = true });
            }

            if (list != null)
                list.ForEach(x => selectListItems.Add(new SelectListItem { Value = key(x), Text = val(x) }));

            return selectListItems.AsEnumerable();
        }

        /// <summary>
        /// To the select list item.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="list">The list.</param>
        /// <param name="key">The key.</param>
        /// <param name="val">The val.</param>
        /// <param name="selectedItem">The selected item.</param>
        /// <returns></returns>
        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this List<T> list, Func<T, string> key,
            Func<T, string> val, string selectedItem)
        {
            var selectListItems = new List<SelectListItem>();

            if (list != null)
                list.ForEach(
                    x => selectListItems.Add(new SelectListItem
                    {
                        Value = key(x),
                        Text = val(x),
                        Selected = (selectedItem == key(x) ? true : false)
                    }));

            return selectListItems.AsEnumerable();
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
        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this IEnumerable<T> list, Func<T, string> key,
            Func<T, string> val, bool addDefault = false, bool addDefaultToZero = false)
        {
            var selectListItems = new List<SelectListItem>();
            if (addDefault)
            {
                selectListItems.Add(new SelectListItem { Text = "Select", Value = "" });
            }
            if (!addDefault && addDefaultToZero)
            {
                selectListItems.Add(new SelectListItem { Text = "Select", Value = "0" });
            }

            if (list != null)
                list.ForEach(x => selectListItems.Add(new SelectListItem { Value = key(x), Text = val(x) }));

            return selectListItems.AsEnumerable();
        }

        /// <summary>
        /// To the select list item.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="list">The list.</param>
        /// <param name="key">The key.</param>
        /// <param name="val">The val.</param>
        /// <param name="selectedItem">The selected item.</param>
        /// <returns></returns>
        public static IEnumerable<SelectListItem> ToSelectListItem<T>(this IEnumerable<T> list, Func<T, string> key,
            Func<T, string> val, string selectedItem)
        {
            var selectListItems = new List<SelectListItem>();

            if (list != null)
                list.ForEach(
                    x => selectListItems.Add(new SelectListItem
                    {
                        Value = key(x),
                        Text = val(x),
                        Selected = (selectedItem == key(x) ? true : false)
                    }));

            return selectListItems.AsEnumerable();
        }


        /// <summary>
        /// Render raw action link.
        /// </summary>
        /// <param name="ajaxHelper">The ajax helper.</param>
        /// <param name="linkText">The link text.</param>
        /// <param name="actionName">Name of the action.</param>
        /// <param name="controllerName">Name of the controller.</param>
        /// <param name="routeValues">The route values.</param>
        /// <param name="ajaxOptions">The ajax options.</param>
        /// <param name="htmlAttributes">The HTML attributes.</param>
        /// <returns></returns>
        public static MvcHtmlString RawActionLink(this AjaxHelper ajaxHelper, string linkText, string actionName,
            string controllerName, object routeValues, AjaxOptions ajaxOptions, object htmlAttributes)
        {
            var repId = Guid.NewGuid().ToString();
            var lnk = ajaxHelper.ActionLink(repId, actionName, controllerName, routeValues, ajaxOptions, htmlAttributes);
            return MvcHtmlString.Create(lnk.ToString().Replace(repId, linkText));
        }

        /// <summary>
        /// Gets the bytes from an underlying stream
        /// </summary>
        /// <param name="stream">The stream.</param>
        /// <returns>byte array</returns>
        public static byte[] GetBytes(this Stream stream)
        {
            byte[] bytes = null;
            using (var ms = new MemoryStream())
            {
                stream.CopyTo(ms);
                bytes = ms.ToArray();
                ms.Close();
            }
            return bytes;
        }

        /// <summary>
        /// Cast source class object to destination class object
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="obj"></param>
        /// <returns></returns>
        public static T Cast<T>(this Object obj)
        {
            Type objectType = obj.GetType();
            Type target = typeof(T);
            var x = Activator.CreateInstance(target, false);
            var z = from source in objectType.GetMembers().ToList()
                    where source.MemberType == MemberTypes.Property
                    select source;
            var d = from source in target.GetMembers().ToList()
                    where source.MemberType == MemberTypes.Property
                    select source;
            List<MemberInfo> members = d.Where(memberInfo => d.Select(c => c.Name)
               .ToList().Contains(memberInfo.Name)).ToList();
            PropertyInfo propertyInfo;
            object value;
            foreach (var memberInfo in members)
            {
                propertyInfo = typeof(T).GetProperty(memberInfo.Name);

                if (obj.GetType().GetProperty(memberInfo.Name) != null)
                {
                    value = obj.GetType().GetProperty(memberInfo.Name).GetValue(obj, null);

                    propertyInfo.SetValue(x, value, null);
                }
            }
            return (T)x;
        }

        public static string ChangeImahePath(this string text, string imageLocation)
        {
            Regex regex = new Regex("<img.+?src=[\"'](?<srclink>.+?)[\"'].*?>");
            Match match = regex.Match(text);

            while (match.Success)
            {
                string str = match.Groups["srclink"].Value;
                int pos = str.LastIndexOf("/") + 1;
                text = text.Replace(str, string.Format("{0}{1}", imageLocation, str.Substring(pos)));
                match = match.NextMatch();
            }

            return text;
        }

        /// <summary>
        /// Toes the select list item.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="dictionary">The dictionary.</param>
        /// <param name="addDefaultSelectItem">if set to <c>true</c> [add default select item].</param>
        /// <returns></returns>
        public static IEnumerable<SelectListItem> ToSelectListItem<T, T1>(this Dictionary<T, T1> dictionary, bool addDefaultSelectItem = true)
        {
            IEnumerator enumerator = dictionary.GetEnumerator();
            List<SelectListItem> list = new List<SelectListItem>();
            if (addDefaultSelectItem)
            {
                list.Add(new SelectListItem() { Text = "Select", Value = string.Empty });
            }
            while (enumerator.MoveNext())
            {
                KeyValuePair<string, string> currentItem = (KeyValuePair<string, string>)enumerator.Current;
                list.Add(new SelectListItem() { Text = currentItem.Value, Value = currentItem.Key });
            }

            return list;
        }


        /// <summary>
        /// To get the stream from image
        /// </summary>
        /// <param name="image"></param>
        /// <param name="format"></param>
        /// <returns></returns>
        public static Stream ToStream(this Image image, ImageFormat format)
        {
            var stream = new System.IO.MemoryStream();
            image.Save(stream, format);
            stream.Position = 0;
            return stream;
        }
        #endregion
    }
}