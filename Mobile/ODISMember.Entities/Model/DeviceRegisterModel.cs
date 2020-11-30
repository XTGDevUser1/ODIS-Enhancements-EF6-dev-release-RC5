using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class DeviceRegisterModel
    {        
        public string DeviceOS { get; set; }
        public List<string> Tags { get; set; }
    }
}
