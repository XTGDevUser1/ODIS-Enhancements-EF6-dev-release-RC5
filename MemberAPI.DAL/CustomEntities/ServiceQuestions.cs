using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.DAL.CustomEntities
{
    [Serializable]
    public class QuestionsCriteria
    {
        public int ProgramID { get; set; }
        [Required, MaxLength(50)]
        public string ProductCategory { get; set; }
        [Required, MaxLength(50)]
        public string VehicleCategory { get; set; }
        [Required, MaxLength(50)]
        public string VehicleType { get; set; }
        [Required, MaxLength(50)]
        public string SourceSystem { get; set; }
    }
    [Serializable]
    public class ServiceQuestions
    {
        public int ProductCategoryID { get; set; }
        public string ProductCategoryName { get; set; }
        public bool IsEnabled { get; set; }
        public List<Question> Questions { get; set; }
        public bool? IsVehicleRequired { get; set; }
    }
    [Serializable]
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
    [Serializable]
    public enum DynamicFieldsControlType
    {
        Textbox,
        Dropdown,
        Combobox,
        Phone,
        Textarea,
        Datepicker,//TODO: Review and remove this.
        DatePicker,
        TirePicker,
        Checkbox,
        Radio
    }
    [Serializable]
    public enum DynamicFieldsDataType
    {
        Numeric, Text, Date, Email, Phone
    }
    [Serializable]
    public class DynamicFieldsControlDropDownValues
    {
        public string Value { get; set; }
        public string Name { get; set; }
    }
    [Serializable]
    public class Answer : DynamicFieldsControlDropDownValues
    {
        public int QuestionID { get; set; }
        public bool IsPossibleTow { get; set; }
    }
}
