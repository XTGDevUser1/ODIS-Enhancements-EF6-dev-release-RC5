using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class RoadsideServiceQuestions
    {
        public int ProductCategoryID { get; set; }
        public string ProductCategoryName { get; set; }
        public bool IsEnabled { get; set; }
        public List<Question> Questions { get; set; }
        public bool? IsVehicleRequired { get; set; }
    }
}
