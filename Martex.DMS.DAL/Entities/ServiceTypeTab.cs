using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class ServiceTab
    {
        public int ProductCategoryID { get; set; }
        public string ProductCategoryName { get; set; }
        public bool IsEnabled { get; set; }
        public List<Question> Questions { get; set; }
        public bool? IsVehicleRequired { get; set; }
    }

    public class Question
    {
        public int ProductCategoryQuestionId { get; set; }
        public string Text { get; set; }
        public DynamicFieldsControlType ControlType { get; set; }
        public DynamicFieldsDataType DataType { get; set; }
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
