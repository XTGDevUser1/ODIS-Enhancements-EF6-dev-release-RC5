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
    public partial class ServiceRequest
    {
    	public ServiceRequest()
        {
            this.Payments = new HashSet<Payment>();
            this.PaymentTransactions = new HashSet<PaymentTransaction>();
            this.ServiceRequestDetails = new HashSet<ServiceRequestDetail>();
            this.ServiceRequestExceptions = new HashSet<ServiceRequestException>();
            this.ServiceRequestVehicleDiagnosticCodes = new HashSet<ServiceRequestVehicleDiagnosticCode>();
            this.PurchaseOrders = new HashSet<PurchaseOrder>();
            this.CustomerFeedbacks = new HashSet<CustomerFeedback>();
        }
    
        public int ID { get; set; }
        public Nullable<int> ServiceRequestStatusID { get; set; }
        public Nullable<int> ProductCategoryID { get; set; }
        public Nullable<int> PrimaryProductID { get; set; }
        public Nullable<int> SecondaryProductID { get; set; }
        public int CaseID { get; set; }
        public Nullable<int> NextActionID { get; set; }
        public Nullable<int> NextActionAssignedToUserID { get; set; }
        public Nullable<int> VehicleCategoryID { get; set; }
        public Nullable<int> ServiceRequestPriorityID { get; set; }
        public Nullable<int> ClosedLoopStatusID { get; set; }
        public Nullable<System.DateTime> ClosedLoopNextSend { get; set; }
        public Nullable<bool> IsPrimaryProductCovered { get; set; }
        public Nullable<bool> IsSecondaryProductCovered { get; set; }
        public Nullable<int> MemberPaymentTypeID { get; set; }
        public Nullable<int> PassengersRidingWithServiceProvider { get; set; }
        public Nullable<bool> IsEmergency { get; set; }
        public Nullable<bool> IsAccident { get; set; }
        public Nullable<bool> IsPossibleTow { get; set; }
        public string ServiceLocationAddress { get; set; }
        public string ServiceLocationDescription { get; set; }
        public string ServiceLocationCrossStreet1 { get; set; }
        public string ServiceLocationCrossStreet2 { get; set; }
        public string ServiceLocationCity { get; set; }
        public string ServiceLocationStateProvince { get; set; }
        public string ServiceLocationPostalCode { get; set; }
        public string ServiceLocationCountryCode { get; set; }
        public Nullable<decimal> ServiceLocationLatitude { get; set; }
        public Nullable<decimal> ServiceLocationLongitude { get; set; }
        public string DestinationAddress { get; set; }
        public string DestinationDescription { get; set; }
        public string DestinationCrossStreet1 { get; set; }
        public string DestinationCrossStreet2 { get; set; }
        public string DestinationCity { get; set; }
        public string DestinationStateProvince { get; set; }
        public string DestinationPostalCode { get; set; }
        public string DestinationCountryCode { get; set; }
        public Nullable<decimal> DestinationLatitude { get; set; }
        public Nullable<decimal> DestinationLongitude { get; set; }
        public Nullable<int> DestinationVendorLocationID { get; set; }
        public Nullable<decimal> ServiceMiles { get; set; }
        public Nullable<decimal> ServiceTimeInMinutes { get; set; }
        public string DealerIDNumber { get; set; }
        public Nullable<bool> IsDirectTowDealer { get; set; }
        public Nullable<decimal> CallFee { get; set; }
        public Nullable<bool> IsRedispatched { get; set; }
        public Nullable<bool> IsDispatchThresholdReached { get; set; }
        public Nullable<bool> IsWorkedByTech { get; set; }
        public Nullable<System.DateTime> NextActionScheduledDate { get; set; }
        public string LegacyReferenceNumber { get; set; }
        public Nullable<System.DateTime> ReadyForExportDate { get; set; }
        public Nullable<System.DateTime> DataTransferDate { get; set; }
        public Nullable<int> StartTabStatus { get; set; }
        public Nullable<int> MemberTabStatus { get; set; }
        public Nullable<int> VehicleTabStatus { get; set; }
        public Nullable<int> ServiceTabStatus { get; set; }
        public Nullable<int> MapTabStatus { get; set; }
        public Nullable<int> DispatchTabStatus { get; set; }
        public Nullable<int> POTabStatus { get; set; }
        public Nullable<int> PaymentTabStatus { get; set; }
        public Nullable<int> ActivityTabStatus { get; set; }
        public Nullable<int> FinishTabStatus { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public Nullable<int> AccountingInvoiceBatchID { get; set; }
        public Nullable<System.DateTime> StatusDateModified { get; set; }
        public string PartsAndAccessoryCode { get; set; }
        public Nullable<int> CurrencyTypeID { get; set; }
        public Nullable<decimal> PrimaryCoverageLimit { get; set; }
        public Nullable<decimal> SecondaryCoverageLimit { get; set; }
        public string MileageUOM { get; set; }
        public Nullable<int> PrimaryCoverageLimitMileage { get; set; }
        public Nullable<int> SecondaryCoverageLimitMileage { get; set; }
        public Nullable<bool> IsServiceGuaranteed { get; set; }
        public Nullable<bool> IsReimbursementOnly { get; set; }
        public Nullable<bool> IsServiceCoverageBestValue { get; set; }
        public Nullable<int> ProgramServiceEventLimitID { get; set; }
        public string PrimaryServiceCoverageDescription { get; set; }
        public string SecondaryServiceCoverageDescription { get; set; }
        public string PrimaryServiceEligiblityMessage { get; set; }
        public string SecondaryServiceEligiblityMessage { get; set; }
        public Nullable<bool> IsPrimaryOverallCovered { get; set; }
        public Nullable<bool> IsSecondaryOverallCovered { get; set; }
        public string ProviderClaimNumber { get; set; }
        public Nullable<int> ProviderID { get; set; }
        public System.Guid TrackerID { get; set; }
        public Nullable<decimal> ServiceEstimate { get; set; }
        public Nullable<bool> IsServiceEstimateAccepted { get; set; }
        public Nullable<int> ServiceEstimateDenyReasonID { get; set; }
        public string EstimateDeclinedReasonOther { get; set; }
        public Nullable<int> EstimateTabStatus { get; set; }
        public Nullable<int> ExportBatchID { get; set; }
        public Nullable<decimal> EstimatedTimeCost { get; set; }
        public string MapSnapshot { get; set; }
        public Nullable<bool> IsShowOnMobile { get; set; }
    
        public virtual Case Case { get; set; }
        public virtual ClosedLoopStatu ClosedLoopStatu { get; set; }
        public virtual CurrencyType CurrencyType { get; set; }
        public virtual NextAction NextAction { get; set; }
        public virtual ICollection<Payment> Payments { get; set; }
        public virtual ICollection<PaymentTransaction> PaymentTransactions { get; set; }
        public virtual PaymentType PaymentType { get; set; }
        public virtual Product Product { get; set; }
        public virtual Product Product1 { get; set; }
        public virtual ProductCategory ProductCategory { get; set; }
        public virtual ServiceRequestDeclineReason ServiceRequestDeclineReason { get; set; }
        public virtual ServiceRequestPriority ServiceRequestPriority { get; set; }
        public virtual ICollection<ServiceRequestDetail> ServiceRequestDetails { get; set; }
        public virtual ServiceRequestStatu ServiceRequestStatu { get; set; }
        public virtual VehicleCategory VehicleCategory { get; set; }
        public virtual ICollection<ServiceRequestException> ServiceRequestExceptions { get; set; }
        public virtual ICollection<ServiceRequestVehicleDiagnosticCode> ServiceRequestVehicleDiagnosticCodes { get; set; }
        public virtual User User { get; set; }
        public virtual ICollection<PurchaseOrder> PurchaseOrders { get; set; }
        public virtual ICollection<CustomerFeedback> CustomerFeedbacks { get; set; }
    }
}