using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model.VendorPortal
{
    public class PostLoginPromptModel
    {
        public string ContactFirstName { get; set; }
        public string ContactLastName { get; set; }
        public AddressEntity BillingAddress { get; set; }
        public AddressEntity BusinessAddress { get; set; }
        public string Email { get; set; }
        public PhoneEntity OfficePhone { get; set; }
        public List<PostLoginVendorPhoneNumber> VendorPhoneNumbers { get; set; }
    }

    public class PostLoginVendorPhoneNumber
    {
        public PhoneEntity Dispatch { get; set; }
        public PhoneEntity Fax { get; set; }
        public int VendorLocationId { get; set; }
        public string LocationAddress { get; set; }

    }
}
