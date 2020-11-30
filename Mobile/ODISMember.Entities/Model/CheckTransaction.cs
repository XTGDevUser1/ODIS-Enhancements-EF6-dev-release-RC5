using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
   public class CheckTransaction
    {
        public string ABANumber { get; set; }
        public string AccountNumber { get; set; }
        public string CheckNumber { get; set; }
    }
}
