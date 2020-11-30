using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Collections;

namespace Martex.DMS.Areas.Application.Models
{
    /// <summary>
    /// Icon Style
    /// </summary>
    public class IconStyle
    {
        public string Class { get; set; }
        public string Title { get; set; }
    }
    /// <summary>
    /// Vendor List Icon Config
    /// </summary>
    public class VendorListIconConfig
    {
        #region Protected Members
        /// <summary>
        /// The ht
        /// </summary>
        protected static Hashtable ht = new Hashtable();
        #endregion

        #region Static Methods
        /// <summary>
        /// Initializes the <see cref="VendorListIconConfig"/> class.
        /// </summary>
        static VendorListIconConfig()
        {
            ht.Add("NotCalled", new IconStyle() { Class = "call-status", Title = "Not Called" });
            ht.Add("Called", new IconStyle() { Class = "call-status-black", Title = "Called No Status" });
            ht.Add("Accepted", new IconStyle() { Class = "call-status-green", Title = "Call Accepted" });
            ht.Add("Rejected", new IconStyle() { Class = "call-status-red", Title = "Call Rejected" });
            ht.Add("PossibleRetry", new IconStyle() { Class = "call-status-yellow", Title = "Possible Retry" });
            ht.Add("DoNotUse", new IconStyle() { Class = "call-status-disabled", Title = "Do Not Use" });
            ht.Add("Contracted", new IconStyle() { Class = "starred", Title = "Contracted" });
            ht.Add("Not Contracted", new IconStyle() { Class = "unstarred", Title = "Not Contracted" });

        }
        #endregion

        #region Public Members
        /// <summary>
        /// Gets the icon style.
        /// </summary>
        /// <param name="key">The key.</param>
        /// <returns></returns>
        public IconStyle GetIconStyle(string key)
        {
            if (string.IsNullOrEmpty(key))
            {
                return new IconStyle();
            }
            return ht[key] as IconStyle;
        }
        #endregion
    }
}