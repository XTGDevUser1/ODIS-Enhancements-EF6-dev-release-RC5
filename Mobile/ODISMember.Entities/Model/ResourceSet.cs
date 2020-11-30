using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class ResourceSet
    {
        public int EstimatedTotal { get; set; }
        public List<ResourceBing> Resources { get; set; }
    }
}
