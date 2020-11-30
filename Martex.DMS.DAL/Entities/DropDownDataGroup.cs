using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class DropDownDataGroup
    {
        public int ID { get; set; }
        public string Name { get; set; }
    }

    public class DropDownRoles
    {
        public Guid RoleID { get; set; }
        public string RoleName { get; set; }
    }
  
}
