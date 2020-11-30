using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class SecurableModel
    {
        public List<SecurableModelItems> Items { get; set; }
        public Securable Securable { get; set; }
       
    }

    public class SecurableModelItems
    {
        public string RoleName { get; set; }
        public string AccessTypeName { get; set; }
        public int? AccessTypeID { get; set; }
        public Guid? RoleID { get; set; }
    }
}
