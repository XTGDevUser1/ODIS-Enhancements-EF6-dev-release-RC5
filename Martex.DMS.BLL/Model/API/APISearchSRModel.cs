using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL
{
    public class APISearchSRModel
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
        public List<APISearchSRPOModel> POList { get; set; }

    }

    public class APISearchSRPOModel
    {
        public int? PONumber { get; set; }
        public string LegacyReferenceNumber { get; set; }
        public string POStatus { get; set; }
        public string CancelReason { get; set; }
        public decimal? POAmount { get; set; }
        public string ServiceType { get; set; }
        public DateTime? IssueDate { get; set; }
        public DateTime? ETADate { get; set; }
        public DateTime? ExtractDate { get; set; }

        public DateTime? InvoiceDate { get; set; }
        public string PaymentType { get; set; }
        public decimal? PaymentAmount { get; set; }
        public DateTime? PaymentDate { get; set; }
        public DateTime? CheckClearedDate { get; set; }
        public string ProductProvider { get; set; }
        public string ProductProviderNumber { get; set; }
        public string ProviderClaimNumber { get; set; }

        public string VendorName { get; set; }
        public int? VendorID { get; set; }
        public string VendorNumber { get; set; }
        public string VendorLocationPhoneNumber { get; set; }
        public string VendorLocationLine1 { get; set; }
        public string VendorLocationLine2 { get; set; }
        public string VendorLocationLine3 { get; set; }
        public string VendorCityStateZipCountry { get; set; }
    }

    public class APISearchSRListModel
    {
        public int RequestNumber { get; set; }
        public int CaseID { get; set; }
        public Nullable<int> ProgramID { get; set; }
        public string Program { get; set; }
        public Nullable<int> ClientID { get; set; }
        public string Client { get; set; }
        public string MemberName { get; set; }
        public string MemberNumber { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string POCreateBy { get; set; }
        public string POModifyBy { get; set; }
        public string SRCreateBy { get; set; }
        public string SRModifyBy { get; set; }
        public string VIN { get; set; }
        public Nullable<int> VehicleTypeID { get; set; }
        public string VehicleType { get; set; }
        public Nullable<int> ServiceTypeID { get; set; }
        public string ServiceType { get; set; }
        public string ServiceLocationAddress { get; set; }
        public string ServiceLocationDescription { get; set; }
        public string DestinationAddress { get; set; }
        public string DestinationDescription { get; set; }
        public Nullable<int> StatusID { get; set; }
        public string Status { get; set; }
        public Nullable<int> PriorityID { get; set; }
        public string Priority { get; set; }
        public string ISPName { get; set; }
        public string VendorNumber { get; set; }
        public string PONumber { get; set; }
        public Nullable<int> PurchaseOrderStatusID { get; set; }
        public string PurchaseOrderStatus { get; set; }
        public Nullable<decimal> PurchaseOrderAmount { get; set; }
        public Nullable<int> AssignedToUserID { get; set; }
        public Nullable<int> NextActionAssignedToUserID { get; set; }
        public Nullable<bool> IsGOA { get; set; }
        public Nullable<bool> IsRedispatched { get; set; }
        public Nullable<bool> IsPossibleTow { get; set; }
        public Nullable<int> VehicleYear { get; set; }
        public string VehicleMake { get; set; }
        public string VehicleModel { get; set; }
        public Nullable<bool> PaymentByCard { get; set; }
        public string TrackerID { get; set; }
        public string MapSnapshot { get; set; }
    }
}
