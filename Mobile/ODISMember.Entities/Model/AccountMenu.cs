using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
   public class AccountMenu
    {
       public ODISMember.Entities.Constants.accountProfileMenu Id { get; set; }
        public string MenuTitle { get; set; }
        public bool isOn { get; set; }
    }
}
