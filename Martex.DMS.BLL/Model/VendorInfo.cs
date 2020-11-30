using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.BLL.Facade;

namespace Martex.DMS.Areas.Application.Models
{
    /// <summary>
    /// VendorInfo
    /// </summary>
    public class VendorInfo
    {
        //All the properties are prefixed with Vendor. This is to avoid ID conflicts for the associated html elements on the form.
        public string VendorName { get; set; }
        public string VendorAddress1 { get; set; }
        public string VendorAddress2 { get; set; }
        public string VendorAddress3 { get; set; }
        public string VendorCity { get; set; }
        public int? VendorState { get; set; }
        public int? VendorCountry { get; set; }
        public string VendorPostalCode { get; set; }
        public string VendorDispatchNumber { get; set; }
        public string VendorFaxNumber { get; set; }
        public string VendorOfficeNumber { get; set; }
        public string VendorEmail { get; set; }
        public double? enrouteMiles { get; set; }
        public int VendorID { get; set; }
        public int VendorLocationID { get; set; }
        public bool VendorIsDispatchOrServiceLocation { get; set; }
        public string vendorNumber { get; set; }
        public string Email { get; set; }
        public string VendorSource { get; set; }
        public string VendorSourceValue { get; set; }
        public DateTime? VendorDateApplication { get; set; }

        // Extended the class with latitude and longitude
        public LatitudeLongitude LatLong { get; set; }
        
    }
}