using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class BusinessHours
    {
        public int DayNumber { get; set; }
        public string DayName { get; set; }
        public TimeSpan? StartTime { get; set;}
        public TimeSpan? EndTime { get; set; }
    }
}
