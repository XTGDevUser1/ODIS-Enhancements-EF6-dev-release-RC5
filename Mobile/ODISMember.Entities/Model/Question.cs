using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class Question
    {
        public int ProductCategoryQuestionId { get; set; }
        public string Text { get; set; }
        public ODISMember.Entities.Constants.DynamicFieldsControlType ControlType { get; set; }
        public ODISMember.Entities.Constants.DynamicFieldsDataType DataType { get; set; }
        public List<Answer> DropDownValues { get; set; }
        public int? RelatedQuestionId { get; set; }
        public string AnswerToTriggerRelatedQuestion { get; set; }
        public string HelpText { get; set; }
        public int? Sequence { get; set; }
        public bool IsRequired { get; set; }
        public string AnswerValue { get; set; }
        public bool IsEnabled { get; set; }
        public int? VehicleCategoryId { get; set; }
    }
}
