using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class DynamicFields
    {
        public int ProgramDataItemId { get; set; }
        public int FieldSequence { get; set; }
        public string Label { get; set; }
        public string Name { get; set; }
        public bool IsRequired { get; set; }
        public DynamicFieldsControlType ControlType { get; set; }
        public DynamicFieldsDataType DataType { get; set; }
        public int? MaxLength { get; set; }
        public IEnumerable<DynamicFieldsControlDropDownValues> DropDownValues { get; set; }
        public string FieldName
        {
            get
            {
                return this.Name.Replace(" ", "") + "$" + this.ProgramDataItemId;
            }
        }
    }

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
    public enum DynamicFieldsDataType
    {
        Numeric, Text, Date, Email, Phone
    }

    public class DynamicFieldsControlDropDownValues
    {
        public string Value { get; set; }
        public string Name { get; set; }        
    }

    public class Answer : DynamicFieldsControlDropDownValues
    {
        public int QuestionID { get; set; }
        public bool IsPossibleTow { get; set; }
    }
}
