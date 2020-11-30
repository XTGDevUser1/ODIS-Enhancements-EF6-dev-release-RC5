using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.DAL.CustomEntities
{
    [Serializable]
    public partial class RoadsideServices_Result
    {
        public string ProgramService { get; set; }
        public string ProgramServiceDescription { get; set; }
        public string Limit { get; set; }
        public Nullable<int> IsLightDuty { get; set; }
        public Nullable<int> IsMediumDuty { get; set; }
        public Nullable<int> IsHeavyDuty { get; set; }
    }
}
