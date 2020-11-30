using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;
using System.IO;
using System.Text;

namespace Martex.DMS.Areas.Application.Models
{
    /// <summary>
    /// Vendor Search Filters
    /// </summary>
    [Serializable]
    public class VendorSearchFilters
    {
        /// <summary>
        /// Gets or sets from.
        /// </summary>
        /// <value>
        /// From.
        /// </value>
        public string From { get; set; }

        /// <summary>
        /// Gets or sets the radius.
        /// </summary>
        /// <value>
        /// The radius.
        /// </value>
        public int Radius { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether [show called].
        /// </summary>
        /// <value>
        ///   <c>true</c> if [show called]; otherwise, <c>false</c>.
        /// </value>
        public bool ShowCalled { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether [show not called].
        /// </summary>
        /// <value>
        ///   <c>true</c> if [show not called]; otherwise, <c>false</c>.
        /// </value>
        public bool ShowNotCalled { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether [show do not use].
        /// </summary>
        /// <value>
        ///   <c>true</c> if [show do not use]; otherwise, <c>false</c>.
        /// </value>
        public bool ShowDoNotUse { get; set; }

        /// <summary>
        /// Gets or sets the product options.
        /// </summary>
        /// <value>
        /// The product options.
        /// </value>
        public string ProductOptions { get; set; }

        /// <summary>
        /// Returns a <see cref="System.String" /> that represents this instance.
        /// </summary>
        /// <returns>
        /// A <see cref="System.String" /> that represents this instance.
        /// </returns>
        public override string ToString()
        {   
            StringWriter writer = new StringWriter();
            XmlSerializer ser = new XmlSerializer(typeof(VendorSearchFilters));
            ser.Serialize(writer, this);
            return writer.ToString();
        }

    }
}