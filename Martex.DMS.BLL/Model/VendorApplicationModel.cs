using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;

namespace VendorPortal.BLL.Models
{
    public class VendorApplicationModel
    {
        
        public int? HeardFrom { get; set; }

        // Business Information
        public string DBA { get; set; }
        public string CorporateName { get; set; }
        public string Website { get; set; }
        public string ContactFirstName { get; set; }
        public string ContactLastName { get; set; }

        public string Email { get; set; }
        public AddressEntity PhysicalAddress { get; set; }
        public bool IsBillingAddressDifferent { get; set; }
        public bool IsW9DifferentThanBilling { get; set; }

        public AddressEntity BillingAddress { get; set; }
        public AddressEntity BusinessAddress { get; set; }
        public PhoneEntity OfficePhone { get; set; }
        public PhoneEntity DispatchPhone { get; set; }
        public PhoneEntity FaxPhone { get; set; }
        public PhoneEntity BusinessCellPhone { get; set; }

        public bool Open24X7 { get; set; }

        

        public string DotNumber { get; set; }
        public string MotorCarrierNumber { get; set; }

        public bool PreEmploymentBackgroundCheck { get; set; }
        public bool RandomDrugTesting { get; set; }
        public bool HasUniformedDrivers { get; set; }
        public bool VehiclesDisplayCompanyName { get; set; }
        public bool SupportForElectronicDispatch { get; set; }
        public bool SupportForFax { get; set; }
        public bool SupportForEmail { get; set; }
        public bool SupportForText { get; set; }

        public bool Cash { get; set; }
        public bool PersonalCheck { get; set; }
        public bool Visa { get; set; }
        public bool MasterCard { get; set; }
        public bool AmericanExpress { get; set; }
        public bool Discover { get; set; }

        // Service Information

        public int MaxGVW { get; set; }
        public int TotalNumberOfVehicles { get; set; }
        public bool IsKeyDropAvailable { get; set; }
        public bool IsOvernightStayAllowed { get; set; }
        public string[] Services { get; set; }

        public string PrimaryZipCodesAsCSV { get; set; }
        public string SecondaryZipCodesAsCSV { get; set; }

        // Tax Payer Information

        //public bool IsTaxPayerAnIndividual { get; set; }
        //public bool IsTaxPayerACorporation { get; set; }
        //public bool IsTaxPayerAPartnership { get; set; }
        //public bool IsTaxPayerOther { get; set; }
        public string TaxClassification { get; set; }
        public string OtherTaxPayerDescription { get; set; }

        public AddressEntity W9Address { get; set; }
        public string EmployerIdentificationNumber { get; set; }
        public string SSN { get; set; }
        public string ElectronicSignature { get; set; }

        // Insurance
        public string InsuranceCarrierName { get; set; }
        public PhoneEntity InsurancePhoneNumber { get; set; }

        public HttpPostedFileBase CertificateOfInsurance { get; set; }

        // Agreement signature
        public bool AgreementToTerms { get; set; }
        public string WitnessName { get; set; }
        public string WitnessTitle { get; set; }

        public List<BusinessHours> BusinessHours { get; set; }

        public string ApplicationComments { get; set; }


        public int? DispatchSoftwareProductID { get; set; }
        public string DispatchSoftwareProductOther { get; set; }
        public int? DriverSoftwareProductID { get; set; }
        public int? DispatchGPSNetworkID { get; set; }
        public string DriverSoftwareProductOther { get; set; }
        public string DispatchGPSNetworkOther { get; set; }

        public bool IsAbleToCrossStateLines { get; set; }
        public bool IsAbleToCrossNationalBorders { get; set; }

        public DateTime? SignedDate { get; set; }
    }
}