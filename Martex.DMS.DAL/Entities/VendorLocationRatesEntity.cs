using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel.DataAnnotations;

namespace Martex.DMS.DAL
{
    [MetadataType(typeof(VendorLocationRatesAndServicesMetaData))]
    public partial class VendorLocationRatesAndServices_Result
    {

    }

    public partial class VendorLocationRatesAndServicesMetaData
    {
        [UIHint("Service"), Required]
        [Display(Name = "Service")]
        [Range(1, (double)decimal.MaxValue, ErrorMessage = "Please select a value from ComboBox")]
        public AddressType ProductID
        {
            get;
            set;
        }
    }
}
