using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// Vendor Location Model
    /// </summary>
    public class VendorLocationModel
    {
        public int VendorID { get; set; }
        public int? LocationList { get; set; }
        public string LocationListValue { get; set; }

        public string LocationName { get; set; }
        public string LocationAddress1 { get; set; }
        public string LocationAddress2 { get; set; }
        public string LocationAddress3 { get; set; }

        public string LocationCity { get; set; }

        public int? LocationCountry { get; set; }
        public string LocationCountryValue { get; set; }

        public int? LocationState { get; set; }
        public string LocationStateValue { get; set; }

        public string LocationPostalCode { get; set; }
        public string LocationDispatchNumber { get; set; }
        public string LocationFaxNumber { get; set; }
        public string LocationOfficeNumber { get; set; }

    }

    public class VendorLocationServiceModel
    {
        public int VendorID { get; set; }
        public int VendorLocationID { get; set; }
        public List<CheckBoxLookUp> Services { get; set; }
        public List<VendorLocationServices_Result> DBServices { get; set; }
    }

    public class VendorPortalLocationServiceModel
    {
        public int VendorID { get; set; }
        public int VendorLocationID { get; set; }
        public List<CheckBoxLookUp> Services { get; set; }
        public List<VendorPortalLocationServicesList_Result> DBServices { get; set; }
    }
}
