using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Model.VendorPortal
{
    public class VendorLocationAccountModel
    {
        public VendorLocation BasicInformation { get; set; }
        public int VendorID { get; set; }
        public List<CheckBoxLookUp> PaymentTypes { get; set; }
        public AddressEntity AddressInformation { get; set; }
        public List<BusinessHours> BusinessHours { get; set; }
        public string VendorLocationStatusName { get; set; }
    }
}
