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
    public partial class VerifyProgramServiceBenefit_Result
    {
        public string ProductCategoryName { get; set; }
        public Nullable<int> ProductCategoryID { get; set; }
        public string VehicleCategoryName { get; set; }
        public Nullable<int> VehicleCategoryID { get; set; }
        public int ProductID { get; set; }
        public Nullable<bool> IsServiceCoverageBestValue { get; set; }
        public Nullable<decimal> ServiceCoverageLimit { get; set; }
        public Nullable<int> CurrencyTypeID { get; set; }
        public Nullable<int> ServiceMileageLimit { get; set; }
        public string ServiceMileageLimitUOM { get; set; }
        public int IsServiceEligible { get; set; }
        public Nullable<bool> IsServiceGuaranteed { get; set; }
        public string ServiceCoverageDescription { get; set; }
        public Nullable<bool> IsReimbursementOnly { get; set; }
        public int IsPrimary { get; set; }
    }
}
