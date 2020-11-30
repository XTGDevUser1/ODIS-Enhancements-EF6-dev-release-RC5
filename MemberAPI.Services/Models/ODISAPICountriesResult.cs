using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services.Models
{

    /// <summary>
    /// Class holds properties related to country result
    /// </summary>
    public class ODISAPICountriesResult
    {
        public int? Id { get; set; }
        public string ISOCode { get; set; }
        public string Name { get; set; }
        public string TelephoneCode { get; set; }
        public int? Sequence { get; set; }
        public bool? IsActive { get; set; }
        public string IsoCode3 { get; set; }       
    }
}
