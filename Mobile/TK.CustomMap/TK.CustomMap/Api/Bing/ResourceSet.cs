using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TK.CustomMap.Api.Bing
{
    public class ResourceSet 
    {
        public int EstimatedTotal { get; set; }
        public List<ResourceBing> Resources { get; set; }
        
    }
}
