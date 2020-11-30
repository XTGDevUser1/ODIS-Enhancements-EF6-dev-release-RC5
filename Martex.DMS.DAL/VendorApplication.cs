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
    using System.Collections.Generic;
    
    [Serializable] 
    public partial class VendorApplication
    {
    	public VendorApplication()
        {
            this.VendorApplicationBusinessHours = new HashSet<VendorApplicationBusinessHour>();
            this.VendorApplicationPaymentTypes = new HashSet<VendorApplicationPaymentType>();
            this.VendorApplicationPostalCodes = new HashSet<VendorApplicationPostalCode>();
            this.VendorApplicationProducts = new HashSet<VendorApplicationProduct>();
        }
    
        public int ID { get; set; }
        public Nullable<int> VendorID { get; set; }
        public string Name { get; set; }
        public string CorporationName { get; set; }
        public Nullable<int> VendorApplicationReferralSourceID { get; set; }
        public string Website { get; set; }
        public string Email { get; set; }
        public string ContactFirstName { get; set; }
        public string ContactLastName { get; set; }
        public Nullable<bool> IsOpen24Hours { get; set; }
        public string BusinessHours { get; set; }
        public string DepartmentOfTransportationNumber { get; set; }
        public string MotorCarrierNumber { get; set; }
        public Nullable<bool> IsEmployeeBackgroundChecked { get; set; }
        public Nullable<bool> IsEmployeeDrugTested { get; set; }
        public Nullable<bool> IsDriverUniformed { get; set; }
        public Nullable<bool> IsEachServiceTruckMarked { get; set; }
        public Nullable<bool> IsElectronicDispatch { get; set; }
        public Nullable<bool> IsFaxDispatch { get; set; }
        public Nullable<bool> IsEmailDispatch { get; set; }
        public Nullable<bool> IsTextDispatch { get; set; }
        public Nullable<int> MaxTowingGVWR { get; set; }
        public string TaxClassification { get; set; }
        public string TaxClassificationOther { get; set; }
        public string InsuranceCarrierName { get; set; }
        public string ApplicationSignedByName { get; set; }
        public string ApplicationSignedByTitle { get; set; }
        public string ApplicationComments { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public string TaxEIN { get; set; }
        public string TaxSSN { get; set; }
        public string W9SignedBy { get; set; }
        public Nullable<int> TotalServiceVehicleCount { get; set; }
        public Nullable<bool> IsKeyDropAvailable { get; set; }
        public Nullable<bool> IsOvernightStayAllowed { get; set; }
        public string InsuranceCertificateFileName { get; set; }
        public Nullable<int> DispatchSoftwareProductID { get; set; }
        public string DispatchSoftwareProductOther { get; set; }
        public Nullable<int> DriverSoftwareProductID { get; set; }
        public Nullable<int> DispatchGPSNetworkID { get; set; }
        public string DriverSoftwareProductOther { get; set; }
        public string DispatchGPSNetworkOther { get; set; }
        public Nullable<System.DateTime> ApplicationSignedDate { get; set; }
    
        public virtual DispatchGPSNetwork DispatchGPSNetwork { get; set; }
        public virtual DispatchSoftwareProduct DispatchSoftwareProduct { get; set; }
        public virtual DispatchSoftwareProduct DispatchSoftwareProduct1 { get; set; }
        public virtual Vendor Vendor { get; set; }
        public virtual VendorApplicationReferralSource VendorApplicationReferralSource { get; set; }
        public virtual ICollection<VendorApplicationBusinessHour> VendorApplicationBusinessHours { get; set; }
        public virtual ICollection<VendorApplicationPaymentType> VendorApplicationPaymentTypes { get; set; }
        public virtual ICollection<VendorApplicationPostalCode> VendorApplicationPostalCodes { get; set; }
        public virtual ICollection<VendorApplicationProduct> VendorApplicationProducts { get; set; }
    }
}