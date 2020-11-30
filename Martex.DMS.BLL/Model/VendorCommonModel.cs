using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// Vendor ACH Model
    /// </summary>
    public class VendorACHModel
    {
        public int VendorID { get; set; }
        public VendorACH VendorACHDetails { get; set; }
        public string SourceSystemName { get; set; }
        
        public bool IsVendorACHValidationRequired
        {
            get
            {
                if (this.VendorACHDetails != null)
                {
                    if (!string.IsNullOrEmpty(this.VendorACHDetails.BankPhoneNumber) && !(string.IsNullOrEmpty(this.VendorACHDetails.BankAddressLine1)))
                    {
                        return true;
                    }
                }

                return false;
            }
        }

    }

    public class VendorServiceModel
    {
        public int VendorID { get; set; }
        public List<CheckBoxLookUp> Services { get; set; }
        public List<VendorServices_Result> DBServices { get; set; }
    }

    public class VendorPortalServiceModel
    {
        public int VendorID { get; set; }
        public List<CheckBoxLookUp> Services { get; set; }
        public List<VendorPortalServicesList_Result> DBServices { get; set; }
    }

    public class VendorLocationInfoModel
    {
        public VendorLocation BasicInformation { get; set; }
        public int VendorID { get; set; }
        public int? OldVendorLocationStatusID { get; set; }
        public List<CheckBoxLookUp> PaymentTypes { get; set; }

        public AddressEntity AddressInformation { get; set; }

        public int? VendorLocationChangeReasonID { get; set; }
        public string VendorLocationChangeReasonComments { get; set; }
        public string VendorLocationChangeReasonOther { get; set; }
        public List<BusinessHours> BusinessHours { get; set; }

        public VendorLocation_GeographyLocation_Result Geography { get; set; }

        public bool IsCoachNetDealerPartner { get; set; }
        public string Indicators { get; set; }
        public decimal? VendorLocationProductRatingForCoachNetDealerPartner { get; set; }
    }

    public class VendorRatesModel
    {
        public int VendorID { get; set; }
        public string Mode { get; set; }
        public VendorRatesDetailsModel CurrentRateSchedule { get; set; }

        // List of services and rates for the current contract rate schedule.
        public List<VendorServicesAndRates_Result> ServiceRates { get; set; }
    }

}


