using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using Newtonsoft.Json;

namespace Martex.DMS.DAL.Entities
{
    public class ServiceRequestApiModel
    {
        [Required, MaxLength(25)]
        public string CustomerID { get; set; }
        [MaxLength(25)]
        public string CustomerGroupID { get; set; }
        [Required, Range(0, 9999999999)]
        public int? ProgramID { get; set; }
        [MaxLength(50)]
        public string ReferenceNumber { get; set; }
        [MaxLength(50)]
        public string Language { get; set; }
        [Required, MaxLength(50)]
        public string ContactFirstName { get; set; }
        [Required, MaxLength(50)]
        public string ContactLastName { get; set; }
        [MaxLength(100)]
        public string ContactEmail { get; set; }
        [Required]
        public string MemberPhoneNumber { get; set; }
        [MaxLength(20)]
        public string MemberPhoneType { get; set; }
        public string MemberPhoneCountryCode { get; set; }
        //[RegularExpression(@"\d{10}")]
        public string MemberAltPhoneNumber { get; set; }
        [MaxLength(20)]
        public string MemberAltPhoneType { get; set; }
        public string MemberAltPhoneCountryCode { get; set; }
        public bool IsSMSAvailable { get; set; }
        [MaxLength(17)]
        public string VehicleVIN { get; set; }
        [MaxLength(20)]
        public string VehicleType { get; set; }
        [MaxLength(50)]
        public string VehicleCategory { get; set; }
        [MaxLength(50)]
        public string RVType { get; set; }

        [Range(0, 9999)]
        public int? VehicleYear { get; set; }
        [MaxLength(50)]
        public string VehicleMake { get; set; }
        [MaxLength(50)]
        public string VehicleModel { get; set; }
        [MaxLength(50)]
        public string VehicleColor { get; set; }
        public bool IsEmergency { get; set; }
        public bool IsAccident { get; set; }
        [MaxLength(50)]
        public string ServiceType { get; set; }

        public bool IsPossibleTow { get; set; }

        public decimal? LocationLatitude { get; set; }
        public decimal? LocationLongitude { get; set; }
        public string LocationAddress { get; set; }
        public string ServiceLocationDescription { get; set; }
        public string LocationCity { get; set; }
        [MaxLength(2)]
        public string LocationStateProvince { get; set; }
        [MaxLength(20)]
        public string LocationPostalCode { get; set; }
        [MaxLength(2)]
        public string LocationCountryCode { get; set; }

        public decimal? DestinationLatitude { get; set; }
        public decimal? DestinationLongitude { get; set; }
        public string DestinationAddress { get; set; }
        public string DestinationDescription { get; set; }
        public string DestinationCity { get; set; }
        [MaxLength(2)]
        public string DestinationStateProvince { get; set; }
        [MaxLength(20)]
        public string DestinationPostalCode { get; set; }
        [MaxLength(2)]
        public string DestinationCountryCode { get; set; }

        public int? ContactPhoneTypeID { get; set; }
        public string ContactPhoneNumber { get; set; }

        public int? AltContactPhoneTypeID { get; set; }
        public string ContactAltPhoneNumber { get; set; }

        public int? InternalCustomerGroupID { get; set; }
        public int? InternalMemberID { get; set; }
        [JsonIgnore]
        public int? VehicleID { get; set; }
        [JsonIgnore]
        public int? CaseID { get; set; }
        public int? ServiceRequestID { get; set; }
        [JsonIgnore]
        public int? VehicleCategoryID { get; set; }

        [JsonIgnore]
        public int? RVTypeID { get; set; }

        public int? ClientID { get; set; }

        public List<NameValuePair> AnswersToServiceQuestions { get; set; }

        //TFS 1126
        public string SourceSystem { get; set; }
        public string ServiceRequestStatus { get; set; }
        public string NextAction { get; set; }
        public DateTime? NextActionScheduledDate { get; set; }
        public string NextActionAssignedToUser { get; set; }
        public string Note { get; set; }

        public string CurrentUser { get; set; }

        public string TrackerID { get; set; }

        // TFS 1339 - Member Address details
        public string HomeAddressLine1 { get; set; }
        public string HomeAddressLine2 { get; set; }
        public string HomeAddressCity { get; set; }
        public string HomeAddressStateProvince { get; set; }
        public string HomeAddressPostalCode { get; set; }
        public string HomeAddressCountryCode { get; set; }
        public bool IsServiceCovered { get; set; }
        public string ServiceCoverageDescription { get; set; }
        public int ContactLogID { get; set; }
        public decimal? ServiceEstimate { get; set; }
        public bool IsServiceCoverageBestValue { get; set; }
        public string ServiceEstimateMessage { get; set; }

        public string VehicleMakeOther { get; set; }
        public string VehicleModelOther { get; set; }
        [JsonIgnore]
        public int? VehicleTypeID { get; set; }

        // Additional vehicle fields
        public string VehicleChassis { get; set; }
        public string VehicleEngine { get; set; }
        public string LicenseState { get; set; }
        public string LicenseNumber { get; set; }
        public string LicenseCountry { get; set; }

        public DateTime? MemberEffectiveDate { get; set; }
        public DateTime? MemberExpirationDate { get; set; }

    }

    public class ServiceRequestSearchModel
    {
        [MaxLength(25)]
        public string CustomerGroupID { get; set; }

        [MaxLength(25)]
        public string CustomerID { get; set; }

        [Required, Range(0, 9999999999)]
        public int? ProgramID { get; set; }

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }

        public Guid? userID { get; set; }
        public string SourceSystem { get; set; }
        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (EndDate != null && StartDate != null && EndDate < StartDate)
            {
                yield return new ValidationResult("EndDate must be greater than StartDate");
            }
        }
    }

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
}
