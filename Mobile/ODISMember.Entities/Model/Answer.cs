using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class Answer : DynamicFieldsControlDropDownValues
    {
        public int QuestionID { get; set; }
        public bool IsPossibleTow { get; set; }
    }
}
