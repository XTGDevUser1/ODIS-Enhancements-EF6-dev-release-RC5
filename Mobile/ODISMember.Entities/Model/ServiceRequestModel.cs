using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class ServiceRequestModel
    {
        public string CustomerID { get; set; }
        public string CustomerGroupID { get; set; }
        public int? ProgramID { get; set; }
        public string ReferenceNumber { get; set; }
        public string Language { get; set; }
        public string ContactFirstName { get; set; }
        public string ContactLastName { get; set; }
        public string ContactEmail { get; set; }        
        public string MemberPhoneNumber { get; set; }        
        public string MemberPhoneType { get; set; }
        public string MemberPhoneCountryCode { get; set; }        
        public string MemberAltPhoneNumber { get; set; }        
        public string MemberAltPhoneType { get; set; }
        public string MemberAltPhoneCountryCode { get; set; }
        public bool IsSMSAvailable { get; set; }
        public string VehicleVIN { get; set; }
        public string VehicleType { get; set; }
        public string VehicleCategory { get; set; }
        public string RVType { get; set; }
        public int? VehicleYear { get; set; }
        public string VehicleMake { get; set; }
        public string VehicleModel { get; set; }
        public string VehicleColor { get; set; }
        public bool IsEmergency { get; set; }
        public bool IsAccident { get; set; }
        public string ServiceType { get; set; }
        public bool IsPossibleTow { get; set; }
        public decimal? LocationLatitude { get; set; }
        public decimal? LocationLongitude { get; set; }
        public string LocationAddress { get; set; }
        public string ServiceLocationDescription { get; set; }
        public string LocationCity { get; set; }
        public string LocationStateProvince { get; set; }
        public string LocationPostalCode { get; set; }
        public string LocationCountryCode { get; set; }
        public int? ContactPhoneTypeID { get; set; }
        public string ContactPhoneNumber { get; set; }

        public int? AltContactPhoneTypeID { get; set; }
        public string ContactAltPhoneNumber { get; set; }
        public int? InternalCustomerGroupID { get; set; }
        public int? InternalMemberID { get; set; }
        public int? VehicleID { get; set; }
        public int? CaseID { get; set; }
        public int? ServiceRequestID { get; set; }
        public int? VehicleCategoryID { get; set; }
        public int? ClientID { get; set; }
        public List<NameValuePair> AnswersToServiceQuestions { get; set; }
        public string SourceSystem { get; set; }
        public string ServiceRequestStatus { get; set; }
        public string NextAction { get; set; }
        public DateTime? NextActionScheduledDate { get; set; }
        public string NextActionAssignedToUser { get; set; }
        public string Note { get; set; }
        public string TrackerID { get; set; }

        public decimal? DestinationLatitude { get; set; }
        public decimal? DestinationLongitude { get; set; }
        public string DestinationAddress { get; set; }
        public string DestinationDescription { get; set; }
        public string DestinationCity { get; set; }
        public string DestinationStateProvince { get; set; }
        public string DestinationPostalCode { get; set; }
        public string DestinationCountryCode { get; set; }
        public string HomeAddressLine1 { get; set; }
        public string HomeAddressLine2 { get; set; }
        public string HomeAddressCity { get; set; }
        public string HomeAddressStateProvince { get; set; }
        public string HomeAddressPostalCode { get; set; }
        public string HomeAddressCountryCode { get; set; }
        public bool IsServiceCovered { get; set; }
        public string ServiceCoverageDescription { get; set; }
        public string ServiceEstimateMessage { get; set; }
        public int ContactLogID { get; set; }
        public decimal? ServiceEstimate { get; set; }
        public bool IsServiceCoverageBestValue { get; set; }
        public string VehicleChassis { get; set; }
        public string VehicleEngine { get; set; }
        public string LicenseState { get; set; }
        public string LicenseNumber { get; set; }
        public string LicenseCountry { get; set; }

        public DateTime? MemberEffectiveDate { get; set; }
        public DateTime? MemberExpirationDate { get; set; }

        #region Extra Properties
        public string YearMakeModel
        {
            get
            {
                string yearMakeModel = string.Empty;
                yearMakeModel = yearMakeModel+(VehicleYear != null ? VehicleYear.Value.ToString() : string.Empty);
                yearMakeModel = yearMakeModel +" "+ VehicleMake;
                yearMakeModel = yearMakeModel + " " + VehicleModel;
                return yearMakeModel;
            }
        }
        public string FullSourceAddress
        {
            get
            {
                string address = string.Empty;

                address = LocationLatitude.ToString() + ", " + LocationLongitude.ToString();

                return address;
            }
        }
        public string FullDestinationAddress
        {
            get
            {
                string address = string.Empty;

                address = DestinationLatitude.ToString() + ", " + DestinationLongitude.ToString();

                return address;
            }
        }
        public string SourceLocationDescription { get; set; }
        #endregion
    }

    public class NameValuePair
    {
        public string Name { get; set; }
        public string Value { get; set; }
    }
}
