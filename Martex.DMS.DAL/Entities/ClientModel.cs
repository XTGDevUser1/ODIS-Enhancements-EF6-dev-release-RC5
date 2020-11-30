using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;
using Martex.DMS.DAL;

namespace Martex.DMS.Models
{
    public class ClientModel
    {
        public Client Client { get; set; }
        public int[] ClientOrganizationsValues { get; set; }
        public string[] ClientOrganizationsString { get; set; }
        public string LastUpdateInformation { get; set; }
        public bool isActive { get; set;  }
    }
}
