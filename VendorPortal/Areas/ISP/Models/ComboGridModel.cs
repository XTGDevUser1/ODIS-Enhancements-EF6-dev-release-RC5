using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace VendorPortal.Areas.ISP.Models
{
    /// <summary>
    /// Combo Grid Model
    /// </summary>
    public class ComboGridModel
    {
        /// <summary>
        /// Gets or sets the records.
        /// </summary>
        /// <value>
        /// The records.
        /// </value>
        public int records { get; set; }

        /// <summary>
        /// Gets or sets the total.
        /// </summary>
        /// <value>
        /// The total.
        /// </value>
        public int total { get; set; }

        /// <summary>
        /// Gets or sets the count.
        /// </summary>
        /// <value>
        /// The count.
        /// </value>
        public int Count { get; set; }

        /// <summary>
        /// Gets or sets the rows.
        /// </summary>
        /// <value>
        /// The rows.
        /// </value>
        public object[] rows { get; set; }
    }
}