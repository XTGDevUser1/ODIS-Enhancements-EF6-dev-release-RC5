using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    public class VendorLocationServiceAreaModel
    {
        public int VendorLocationID { get; set; }
        public bool IsAbleToCrossStateLines { get; set; }
        public bool IsUsingZipCodes { get; set; }
        public bool IsAbleToCrossNationalBorders { get; set; }
        public bool IsVirtualLocationEnabled { get; set; }
        public string PrimaryZipCodesAsCSV { get; set; }
        public string SecondaryZipCodesAsCSV { get; set; }

        public List<VendorLocationVirtual_Result> VirtualLocations { get; set; }

        public AddressEntity BusinessAddress { get; set; }
        
    }
}
