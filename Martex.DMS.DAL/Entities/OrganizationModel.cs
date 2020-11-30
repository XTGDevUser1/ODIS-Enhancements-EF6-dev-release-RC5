using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;
using  Martex.DMS.DAL;

namespace Martex.DMS.Models
{
    public class OrganizationModel
    {
        
        public Organization Organization { get; set; }
        // List of addresses - Original values.
        public List<AddressEntity> Addresses { get; set; }

        // Values obtained from the view.
        public List<AddressEntity> InsertedAddresses { get; set; }
        public List<AddressEntity> UpdatedAddresses { get; set; }
        public List<AddressEntity> DeletedAddresses { get; set; }

        // List of phone details
        public List<PhoneEntity> PhoneDetails { get; set; }

        // Values obtained from the view.
        public List<PhoneEntity> InsertedPhoneDetails { get; set; }
        public List<PhoneEntity> UpdatedPhoneDetails { get; set; }
        public List<PhoneEntity> DeletedPhoneDetails { get; set; }

        public int[] OrganizationClientsValues { get; set; }
        public Guid[] OrganizationRolesValues { get; set; }
        public string LastUpdateInformation { get; set; }
       
    }
}