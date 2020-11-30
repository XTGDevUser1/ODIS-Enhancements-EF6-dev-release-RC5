using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.Areas.Application.Models
{
    /// <summary>
    /// PO Search Criteria
    /// </summary>
    public class POSearchCriteria
    {
        /// <summary>
        /// Gets or sets the PO number.
        /// </summary>
        /// <value>
        /// The PO number.
        /// </value>
        public string PONumber { get; set; } 

        /// <summary>
        /// Gets or sets the name of the user.
        /// </summary>
        /// <value>
        /// The name of the user.
        /// </value>
        public string UserName { get; set; }

        /// <summary>
        /// Gets or sets the vendor number.
        /// </summary>
        /// <value>
        /// The vendor number.
        /// </value>
        public string VendorNumber { get; set; }

        /// <summary>
        /// Gets or sets the time.
        /// </summary>
        /// <value>
        /// The time.
        /// </value>
        public string Time { get; set; }        
    }
}