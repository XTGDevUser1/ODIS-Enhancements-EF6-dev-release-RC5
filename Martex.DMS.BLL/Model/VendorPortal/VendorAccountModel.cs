using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model.VendorPortal
{
    public class VendorAccountModel
    {
        public Vendor VendorDetails { get; set; }
        public int VendorLocationID { get; set; }
    }
}
