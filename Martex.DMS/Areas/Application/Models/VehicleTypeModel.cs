using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.Areas.Application.Models
{   

    /// <summary>
    /// Vehicle Type Model
    /// </summary>
    public class VehicleTypeModel
    {

        /// <summary>
        /// Gets or sets a value indicating whether this instance is auto.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is auto; otherwise, <c>false</c>.
        /// </value>
        public bool IsAuto
        {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is RV.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is RV; otherwise, <c>false</c>.
        /// </value>
        public bool IsRV
        {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets a value indicating whether this <see cref="VehicleTypeModel"/> is motorcycle.
        /// </summary>
        /// <value>
        ///   <c>true</c> if motorcycle; otherwise, <c>false</c>.
        /// </value>
        public bool Motorcycle
        {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets a value indicating whether this <see cref="VehicleTypeModel"/> is trailer.
        /// </summary>
        /// <value>
        ///   <c>true</c> if trailer; otherwise, <c>false</c>.
        /// </value>
        public bool Trailer
        {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets the record count.
        /// </summary>
        /// <value>
        /// The record count.
        /// </value>
        public int RecordCount
        {
            get;
            set;
        }
    }
}