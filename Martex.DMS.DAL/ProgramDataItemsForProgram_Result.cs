//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Martex.DMS.DAL
{
    using System;
    
    [Serializable] 
    public partial class ProgramDataItemsForProgram_Result
    {
        public Nullable<int> QuestionID { get; set; }
        public string QuestionText { get; set; }
        public string ControlType { get; set; }
        public string DataType { get; set; }
        public Nullable<bool> IsRequired { get; set; }
        public Nullable<int> MaxLength { get; set; }
        public Nullable<int> SubQuestionID { get; set; }
        public string RelatedAnswer { get; set; }
        public Nullable<int> Sequence { get; set; }
    }
}