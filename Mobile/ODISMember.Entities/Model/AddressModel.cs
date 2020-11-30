using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class AddressModel
    {
        public string Address1 { get; set; }
        public string Address2 { get; set; }
        public string Address3 { get; set; }
        public string City { get; set; }
        public string PostalCode { get; set; }
        public string State { get; set; }
        public long SystemIdentifier { get; set; }
        public int CountryCodeID { get; set; }
        public string CountryCode { get; set; }
        public ODISMember.Entities.Constants.enumAddressType AddressType { get; set; }

        public string AddressLineString2
        {
            get { return City + ", " + State + " " + PostalCode; }
        }

        public string FullAddress
        {
            get
            {
                return (!string.IsNullOrEmpty(Address1) ? Address1 + ", " : string.Empty)
                  + (!string.IsNullOrEmpty(Address2) ? Address2 + ", " : string.Empty)
                  + (!string.IsNullOrEmpty(City) ? City + ", " : string.Empty)
                  + (!string.IsNullOrEmpty(State) ? State + ", " : string.Empty)
                  + (!string.IsNullOrEmpty(PostalCode) ? PostalCode + ", " : string.Empty);
            }
        }
    }
}
