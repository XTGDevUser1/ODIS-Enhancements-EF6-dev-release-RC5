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
    public partial class CustomerSurveySample
    {
        public int ID { get; set; }
        public Nullable<int> BatchID { get; set; }
        public Nullable<int> ServiceRequestID { get; set; }
        public string PurchaseOrderNumber { get; set; }
        public string OrgID { get; set; }
        public string MemberNumber { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string EmailAddress { get; set; }
        public string HomePhone { get; set; }
        public string EmailDomain { get; set; }
        public string CCEmailAddress { get; set; }
        public string SourceID { get; set; }
        public string Prefix { get; set; }
        public string MiddleName { get; set; }
        public string Nickname { get; set; }
        public string Designation { get; set; }
        public string Company { get; set; }
        public string Title { get; set; }
        public string ContactType { get; set; }
        public string ConfirmedOptedIn { get; set; }
        public string OptedOut { get; set; }
        public string LinkedInURL { get; set; }
        public string TwitterURL { get; set; }
        public string FacebookURL { get; set; }
        public string PrimaryAddress { get; set; }
        public string WorkAddress1 { get; set; }
        public string WorkAddress2 { get; set; }
        public string WorkAddress3 { get; set; }
        public string Gender { get; set; }
        public string WorkCity { get; set; }
        public string WorkStateCode { get; set; }
        public string WorkState { get; set; }
        public string WorkPostalCode { get; set; }
        public string WorkCountryCode { get; set; }
        public string WorkCountry { get; set; }
        public string HomeAddress1 { get; set; }
        public string HomeAddress2 { get; set; }
        public string HomeAddress3 { get; set; }
        public string HomeCity { get; set; }
        public string HomeStateCode { get; set; }
        public string HomeState { get; set; }
        public string HomePostalCode { get; set; }
        public string HomeCountryCode { get; set; }
        public string HomeCountry { get; set; }
        public string PrimaryAddress1 { get; set; }
        public string PrimaryAddress2 { get; set; }
        public string PrimaryAddress3 { get; set; }
        public string PrimaryCity { get; set; }
        public string PrimaryStateCode { get; set; }
        public string PrimaryState { get; set; }
        public string PrimaryPostalCode { get; set; }
        public string PrimaryCountryCode { get; set; }
        public string WorkPhone { get; set; }
        public string HomeFax { get; set; }
        public string WorkFax { get; set; }
        public string MobilePhone { get; set; }
        public string PagerNumber { get; set; }
        public string SocialSecurityNumber { get; set; }
        public string NationalIdentificationNumber { get; set; }
        public string PassportNumber { get; set; }
        public string PassportCountry { get; set; }
        public string DateofBirth { get; set; }
        public string VehicleVIN { get; set; }
        public string VehicleYear { get; set; }
        public string VehicleModel { get; set; }
        public string VehicleMake { get; set; }
        public string ServiceCode { get; set; }
        public string ServiceCodeDescription { get; set; }
        public string IsTechFlag { get; set; }
        public string DispatchDate { get; set; }
        public string DispatchTime { get; set; }
        public string PurchaseOrderReferenceNumber { get; set; }
        public string ContactDate { get; set; }
        public string ContactTime { get; set; }
        public string ETA { get; set; }
        public string RepairDealerID { get; set; }
        public string Agent { get; set; }
        public string CallBackNumber { get; set; }
        public string AltCallBackNumber { get; set; }
        public string InvitedBy { get; set; }
        public string ResponseMethod { get; set; }
        public string InvitedDate { get; set; }
        public string StartedOn { get; set; }
        public string CompletedOn { get; set; }
        public string LastModifiedBy { get; set; }
        public string LastModifiedOn { get; set; }
        public string ReferenceID { get; set; }
        public string TargetedList { get; set; }
        public string Language { get; set; }
        public string RespondentIP { get; set; }
        public string OnsiteServiceProvider { get; set; }
        public string VendorStateProvince { get; set; }
        public string PhoneProfessionalismGrade { get; set; }
        public string PhoneListeningGrade { get; set; }
        public string PhoneKnowledgeGrade { get; set; }
        public string TechProfessionalismGrade { get; set; }
        public string TechKnowledgeGrade { get; set; }
        public string TechWaitGrade { get; set; }
        public string ISPProfessionalismGrade { get; set; }
        public string ISPMeetNeedsGrade { get; set; }
        public string ISPTimelinessArrivalGrade { get; set; }
        public string ISPKnowledgeGrade { get; set; }
        public string ISPQuotedAssistTime { get; set; }
        public string ISPAssistTime { get; set; }
        public string HowLikelyToRecommend { get; set; }
        public string AdditionalComments { get; set; }
        public string PublishingApproval { get; set; }
        public string AreYouPersonWhoCalled { get; set; }
        public string OverallSatisfaction { get; set; }
        public string DecidedBy { get; set; }
        public Nullable<System.DateTime> DecidedDate { get; set; }
        public Nullable<int> CustomerFeedbackID { get; set; }
        public Nullable<bool> IsIgnore { get; set; }
    
        public virtual CustomerFeedback CustomerFeedback { get; set; }
    }
}
