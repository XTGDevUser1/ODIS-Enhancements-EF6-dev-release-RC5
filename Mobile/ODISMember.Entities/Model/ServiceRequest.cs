using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class ServiceRequest
    {
        public bool IsDeliveryDriver { get; set; }
        public int RequestNumber { get; set; }
        public string Status { get; set; }
        public string Priority { get; set; }
        public DateTime? CreateDate { get; set; }
        public string CreateBy { get; set; }
        public DateTime? ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public string NextAction { get; set; }
        public DateTime? NextActionScheduledDate { get; set; }
        public string NextActionAssignedTo { get; set; }
        public string ClosedLoop { get; set; }
        public DateTime? ClosedLoopNextSend { get; set; }
        public string ServiceCategory { get; set; }
        public string Elapsed { get; set; }
        public DateTime? PoMaxIssueDate { get; set; }
        public DateTime? PoMaxETADate { get; set; }
        public DateTime? DataTransferDate { get; set; }
        public string ClientMemberType { get; set; }
        public string Member { get; set; }
        public string MembershipNumber { get; set; }
        public string MemberStatus { get; set; }
        public string Client { get; set; }
        public int? ProgramID { get; set; }
        public string ProgramName { get; set; }
        public string MemberSince { get; set; }
        public string ExpirationDate { get; set; }
        public string ClientReferenceNumber { get; set; }
        public string CallbackPhoneType { get; set; }
        public string CallbackNumber { get; set; }
        public string AlternatePhoneType { get; set; }
        public string AlternateNumber { get; set; }
        public string Line1 { get; set; }
        public string Line2 { get; set; }
        public string Line3 { get; set; }
        public string MemberCityStateZipCountry { get; set; }
        public string YearMakeModel { get; set; }
        public string VehicleTypeAndCategory { get; set; }
        public string VehicleColor { get; set; }
        public string VehicleVIN { get; set; }
        public string License { get; set; }
        public string VehicleDescription { get; set; }
        public string RVType { get; set; }
        public string VehicleChassis { get; set; }
        public string VehicleEngine { get; set; }
        public string VehicleTransmission { get; set; }
        public int? Mileage { get; set; }
        public string ServiceLocationAddress { get; set; }
        public string ServiceLocationDescription { get; set; }
        public string DestinationAddress { get; set; }
        public string DestinationDescription { get; set; }
        public string ServiceCategorySection { get; set; }
        public decimal? CoverageLimit { get; set; }
        public string Safe { get; set; }
        public int? PrimaryProductID { get; set; }
        public string PrimaryProductName { get; set; }
        public string PrimaryServiceEligiblityMessage { get; set; }
        public int? SecondaryProductID { get; set; }
        public string SecondaryProductName { get; set; }
        public string SecondaryServiceEligiblityMessage { get; set; }
        public bool? IsPrimaryOverallCovered { get; set; }
        public bool? IsSecondaryOverallCovered { get; set; }
        public bool? IsPossibleTow { get; set; }
        public string ContractStatus { get; set; }

        public string ServiceType { get; set; }
        public string AssignedTo { get; set; }
        public int? AssignedToID { get; set; }
        public string TrackerID { get; set; }
        public string MapSnapshot { get; set; }
    }
}
