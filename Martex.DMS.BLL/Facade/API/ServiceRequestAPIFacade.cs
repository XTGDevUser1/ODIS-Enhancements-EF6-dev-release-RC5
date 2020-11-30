using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAO;
using System.Transactions;
using log4net;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Reflection;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.DataValidators;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Facade
{
    public class ServiceRequestAPIFacade
    {
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ServiceRequestAPIFacade));

        ServiceRequestRepository serviceRequestRepository = new ServiceRequestRepository();
        MemberManagementRepository memberManagementRepository = new MemberManagementRepository();
        CaseRepository caseRepository = new CaseRepository();
        VehicleRepository vehicleRepo = new VehicleRepository();
        MemberManagementFacade memberManagementFacade = new MemberManagementFacade();
        ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
        public ServiceRequestApiModel SaveServiceRequestFromWebService(ServiceRequestApiModel model)
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                //TODO : Need to add condition for Client. -- ProgramID in (Select ID From Program where ClientID = [ClientID determined by authentication])
                MemberRepository memberRepository = new MemberRepository();
                Member member = memberRepository.GetMemberByClientMemberKey(model.CustomerID, model.ClientID.GetValueOrDefault());

                ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
                var result = repository.GetProgramInfo(model.ProgramID, "ProgramInfo", "Rule");
                bool allowMemberUpdate = result.Where(x => x.Name == "AllowMemberUpdate" && x.Value.Equals("yes", StringComparison.OrdinalIgnoreCase)).Count() > 0;
                result = repository.GetProgramInfo(model.ProgramID, "Vehicle", "Rule");
                bool allowVehicleUpdate = result.Where(x => x.Name == "AllowVehicleUpdate" && x.Value.Equals("yes", StringComparison.OrdinalIgnoreCase)).Count() > 0;
                bool allowVehicleInsert = result.Where(x => x.Name == "AllowVehicleInsert" && x.Value.Equals("yes", StringComparison.OrdinalIgnoreCase)).Count() > 0;

                MemberApiModel memberModel = new MemberApiModel()
                {
                    CustomerID = model.CustomerID,
                    CustomerGroupID = model.CustomerGroupID,
                    ProgramID = model.ProgramID,
                    FirstName = model.ContactFirstName,
                    LastName = model.ContactLastName,
                    Address1 = model.HomeAddressLine1,
                    Address2 = model.HomeAddressLine2,
                    City = model.HomeAddressCity,
                    StateProvince = model.HomeAddressStateProvince,
                    PostalCode = model.HomeAddressPostalCode,
                    CountryCode = model.HomeAddressCountryCode,
                    PhoneCountryCode = model.MemberPhoneCountryCode,
                    PhoneNumber = model.MemberPhoneNumber,
                    PhoneType = model.MemberPhoneType,
                    Email = model.ContactEmail,
                    EffectiveDate = model.MemberEffectiveDate.HasValue ? model.MemberEffectiveDate.Value.Date : DateTime.Today.Date,
                    VehicleVIN = model.VehicleVIN,
                    VehicleType = model.VehicleType,
                    VehicleYear = model.VehicleYear,
                    VehicleMake = model.VehicleMake,
                    VehicleModel = model.VehicleModel,
                    VehicleColor = model.VehicleColor,
                    AltPhoneNumber = model.MemberAltPhoneNumber,
                    AltPhoneType = model.MemberAltPhoneType,
                    AltPhoneCountryCode = model.MemberAltPhoneCountryCode,

                    VehicleCategoryID = model.VehicleCategoryID,
                    RVTypeID = model.RVTypeID,

                    VehicleChassis = model.VehicleChassis,
                    VehicleEngine = model.VehicleEngine,
                    LicenseCountry = model.LicenseCountry,
                    LicenseNumber = model.LicenseNumber,
                    LicenseState = model.LicenseState,
                    CurrentUser = model.CurrentUser,
                    ExpirationDate = model.MemberExpirationDate.HasValue ? model.MemberExpirationDate.Value.Date : (DateTime?)null

                };
                if (member != null)
                {
                    model.InternalMemberID = member.ID;
                    model.InternalCustomerGroupID = member.MembershipID;

                    memberModel.InternalCustomerGroupID = member.MembershipID;
                    memberModel.InternalCustomerID = member.ID;
                    //TODO: Get SR History. If there exists an SR that is not in Canceled or Completed Status, throw an exception back saying that there already exists an active SR.
                    // Send the SR # of the Pending SR.
                    MemberFacade facade = new MemberFacade();
                    var serviceRequestList = facade.GetServiceRequestHistory(model.InternalCustomerGroupID.GetValueOrDefault());
                    if (serviceRequestList != null && serviceRequestList.Count > 0)
                    {
                        var activeRequest = serviceRequestList.Where(x => x.MemberID == member.ID && (x.Status != "Cancelled" && x.Status != "Complete")).FirstOrDefault();
                        if (activeRequest != null && activeRequest.ServiceRequestID > 0)
                        {
                            throw new DMSException(String.Format("Active Service Request Number {0} already exists for this customer.", activeRequest.ServiceRequestID));
                        }
                    }
                    var vehcilesForMember = vehicleRepo.GetMemberVehicles(member.ProgramID.GetValueOrDefault(), member.ID, member.MembershipID);
                    var vinMatchedVehicles = vehcilesForMember.Where(a => model.VehicleVIN != null && a.VIN == model.VehicleVIN).FirstOrDefault();
                    if (vinMatchedVehicles != null)
                    {
                        model.VehicleID = vinMatchedVehicles.ID;

                    }
                    else
                    {
                        string strYear = model.VehicleYear.GetValueOrDefault().ToString();
                        var vehicles = vehcilesForMember.Where(a =>
                            (a.Make == model.VehicleMake || (a.Make == "Other" && a.MakeOther == model.VehicleMake) || (model.VehicleMake == "Other" && a.MakeOther == model.VehicleMakeOther))
                            && (a.Model == model.VehicleModel || ("Other".Equals(a.Model) && a.Model == model.VehicleModel) || (model.VehicleModel == "Other" && a.ModelOther == model.VehicleModelOther))
                            && a.Year == strYear
                        ).FirstOrDefault();
                        if (vehicles != null)
                        {
                            model.VehicleID = vehicles.ID;
                        }

                    }
                    //KB: if (model.VehicleID != null && model.VehicleID > 0)
                    {
                        memberModel.VehicleID = model.VehicleID;

                        if (!string.IsNullOrEmpty(model.VehicleVIN) ||
                            (!string.IsNullOrEmpty(model.VehicleMake) && !string.IsNullOrEmpty(model.VehicleModel) && model.VehicleYear != null))
                        {
                            vehicleRepo.SaveOrUpdateVehicleTypeDetailsForWebService(memberModel, allowVehicleInsert, allowVehicleUpdate);
                            model.VehicleID = memberModel.VehicleID;

                            model.VehicleMake = memberModel.VehicleMake;
                            model.VehicleMakeOther = memberModel.VehicleMakeOther;
                            model.VehicleModel = memberModel.VehicleModel;
                            model.VehicleModelOther = memberModel.VehicleModelOther;
                            model.VehicleTypeID = memberModel.VehicleTypeID;
                            model.RVTypeID = memberModel.RVTypeID;
                            model.VehicleCategoryID = memberModel.VehicleCategoryID;
                        }
                    }

                    //SR (10/03/2016): TFS 1587 -> ODIS API - Add member effective/expiration dates to POST Service Request                    
                    memberManagementFacade.SaveMemberDetails(memberModel);
                }
                else
                {
                    memberModel.IsPrimary = false;
                    
                    if (memberModel.ExpirationDate == null)
                    {
                        int daysAddedToEffectiveDate = 0;
                        var programConfigurationList = programMaintenanceRepository.GetProgramInfo(model.ProgramID, "RegisterMember", "Validation");
                        var daysAddedToEffectiveDatePC = programConfigurationList.Where(x => (x.Name.Equals("DaysAddedToEffectiveDate", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                        if (daysAddedToEffectiveDatePC != null)
                        {
                            daysAddedToEffectiveDate = Int32.Parse(daysAddedToEffectiveDatePC.Value);
                        }
                        memberModel.ExpirationDate = DateTime.Today.AddDays(daysAddedToEffectiveDate).Date;
                    }
                    memberModel = memberManagementFacade.SaveMemberDetails(memberModel);

                    model.InternalMemberID = memberModel.InternalCustomerID;
                    model.InternalCustomerGroupID = memberModel.InternalCustomerGroupID;
                    model.VehicleID = memberModel.VehicleID;
                    model.VehicleMake = memberModel.VehicleMake;
                    model.VehicleMakeOther = memberModel.VehicleMakeOther;
                    model.VehicleModel = memberModel.VehicleModel;
                    model.VehicleModelOther = memberModel.VehicleModelOther;
                    model.VehicleTypeID = memberModel.VehicleTypeID;
                    model.RVTypeID = memberModel.RVTypeID;
                    model.VehicleCategoryID = memberModel.VehicleCategoryID;
                }

                model = caseRepository.AddCaseFromWebRequest(model);

                if ((model.LocationLongitude == null || model.LocationLatitude == null) && (model.LocationAddress != null && model.LocationCity != null && model.LocationStateProvince != null && model.LocationPostalCode != null && model.LocationCountryCode != null))
                {
                    LatitudeLongitude latLong = AddressFacade.GetLatLong(model.LocationAddress, model.LocationCity, model.LocationStateProvince, model.LocationPostalCode, model.LocationCountryCode);
                    model.LocationLatitude = latLong.Latitude;
                    model.LocationLongitude = latLong.Longitude;
                }
                if ((model.LocationAddress == null || model.LocationCity == null || model.LocationStateProvince == null || model.LocationCountryCode == null || model.LocationPostalCode == null) && (model.LocationLongitude != null && model.LocationLatitude != null))
                {
                    AddressDetails addressDetails = AddressFacade.GetAddressDetailsByLatLong(model.LocationLatitude, model.LocationLongitude);
                    model.LocationAddress = addressDetails.Address;
                    model.LocationCity = addressDetails.City;
                    model.LocationStateProvince = addressDetails.State;
                    model.LocationCountryCode = addressDetails.CountryCode;
                    model.LocationPostalCode = addressDetails.PostalCode;
                }

                if ((model.DestinationLongitude == null || model.DestinationLatitude == null) && (model.DestinationAddress != null && model.DestinationCity != null && model.DestinationStateProvince != null && model.DestinationPostalCode != null && model.DestinationCountryCode != null))
                {
                    LatitudeLongitude latLong = AddressFacade.GetLatLong(model.DestinationAddress, model.DestinationCity, model.DestinationStateProvince, model.DestinationPostalCode, model.DestinationCountryCode);
                    model.DestinationLatitude = latLong.Latitude;
                    model.DestinationLongitude = latLong.Longitude;
                }
                if ((model.DestinationAddress == null || model.DestinationCity == null || model.DestinationStateProvince == null || model.DestinationCountryCode == null || model.DestinationPostalCode == null) && (model.DestinationLongitude != null && model.DestinationLatitude != null))
                {
                    AddressDetails addressDetails = AddressFacade.GetAddressDetailsByLatLong(model.DestinationLatitude, model.DestinationLongitude);
                    model.DestinationAddress = addressDetails.Address;
                    model.DestinationCity = addressDetails.City;
                    model.DestinationStateProvince = addressDetails.State;
                    model.DestinationCountryCode = addressDetails.CountryCode;
                    model.DestinationPostalCode = addressDetails.PostalCode;
                }

                model = serviceRequestRepository.AddServiceRequestFromWebRequest(model);

                var vehicleType = ReferenceDataRepository.GetVehicleTypeByName(model.VehicleType);
                if (vehicleType == null)
                {
                    throw new DMSException(string.Format("Vehicle type {0} is not set up in the system", model.VehicleType));
                }

                logger.InfoFormat("Saving Questions against SR ID {0}", model.ServiceRequestID);

                var serviceFacade = new ServiceFacade();
                serviceFacade.Save(model.AnswersToServiceQuestions, model.CurrentUser, model.ServiceRequestID.Value, vehicleType.ID);
                serviceRequestRepository.UpdateNotesAndOtherAttributes(model.ServiceRequestID.Value, model.SourceSystem, model.ServiceRequestStatus, model.NextAction, model.NextActionScheduledDate, model.NextActionAssignedToUser, model.Note, model.CurrentUser);

                logger.InfoFormat("Updating map snapshot for SR ID {0}", model.ServiceRequestID);
                MapFacade mapFacade = new MapFacade();
                mapFacade.SetMapSnapshot(model.ServiceRequestID.Value);

                //TFS: 1361 - Process service eligibility
                var serviceRequest = serviceRequestRepository.GetById(model.ServiceRequestID.Value);
                var serviceEligibilityModel = serviceFacade.GetServiceEligibilityModel(model.ProgramID, serviceRequest.ProductCategoryID, null, vehicleType.ID, model.VehicleCategoryID, null, serviceRequest.ID, serviceRequest.CaseID, model.SourceSystem);

                model.IsServiceCovered = serviceEligibilityModel.IsPrimaryOverallCovered.GetValueOrDefault();
                model.ServiceCoverageDescription = serviceEligibilityModel.PrimaryServiceEligiblityMessage;
                model.IsServiceCoverageBestValue = serviceEligibilityModel.IsServiceCoverageBestValue.GetValueOrDefault();
                serviceFacade.UpdateServiceEligibility(model.InternalMemberID, model.ProgramID, serviceRequest.ProductCategoryID, null, vehicleType.ID, model.VehicleCategoryID, null, serviceRequest.ID, serviceRequest.CaseID, model.CurrentUser, model.SourceSystem);
                if (serviceEligibilityModel.IsPrimaryOverallCovered.GetValueOrDefault())
                {
                    /*
                    1.SR Status = 'Submitted'
                    2.ServiceRequestPriorityID = 2
                    3.IsPrimaryProductCovered = < returned from VerifyProgram sp's>
                    4.PrimaryCoverageLimit = < returned from VerifyProgram sp's>
                    5.PrimaryCoverageLimitMileage = < returned from VerifyProgram sp's>
                    6.IsServiceGuaranteed = < returned from VerifyProgram sp's>
                    7.IsReimbursementOnly = < returned from VerifyProgram sp's>
                    8.IsServiceCoverageBestValue = < returned from VerifyProgram sp's>
                    9.ProgramServiceEventLimitID = < returned from VerifyProgram sp's>
                    10.PrimaryServiceCovearegeDescription = < returned from VerifyProgram sp's>
                    11.PrimaryServiceEligibilityMessage = < returned from VerifyProgram sp's>
                    12.IsPrimaryOverallCovered = < returned from VerifyProgram sp's>
                    13.NextActionID = 'Dispatch'
                    14.NextActionAssignedToUserID = 'Dispatch User'
                    15.NextActionScheduledDate = getdate()
                   */

                    //TODO: Use the isServiceCoverageBestValue to decide whether to show the text or not (the information message).
                    // Events for submitted.
                    logger.InfoFormat("Service Covered : Updating the Next action values on SR : {0}", serviceRequest.ID);
                    serviceRequestRepository.UpdateServiceRequest(serviceRequest.ID, ServiceRequestStatusNames.SUBMITTED, "Normal", null, "Dispatch", "DispatchUser", DateTime.Now, true, null, true);
                    var eventLogRepository = new EventLogRepository();
                    eventLogRepository.LogEventForServiceRequestStatus(serviceRequest.ID, EventNames.SUBMITTED_FOR_DISPATCH, "WebService", null, null, model.CurrentUser);
                    model.ContactLogID = CreateContactLogForMobile(model, "SubmittedForDispatch");
                    logger.InfoFormat("Created a contact log [ {0} ] after updating DSE on SR : {1}", model.ContactLogID, serviceRequest.ID);
                }
                else
                {
                    logger.InfoFormat("Service Not Covered : Updating the Next action values on SR : {0}", serviceRequest.ID);
                    serviceRequestRepository.UpdateServiceRequest(serviceRequest.ID, ServiceRequestStatusNames.ENTRY, "Normal", "MobileUser", null, null, null, null, null, false);
                    // Run service estimate
                    var estimateFacade = new EstimateFacade();
                    var estimate = estimateFacade.GetServiceRequestEstimate(serviceRequest.ID);
                    ServiceRequest request = new ServiceRequest()
                    {
                        ID = serviceRequest.ID,
                        IsServiceEstimateAccepted = null,
                        ServiceEstimate = estimate.Estimate,
                        EstimatedTimeCost = estimate.EstimatedTimeCost,
                        ServiceEstimateDenyReasonID = null
                    };
                    ServiceRepository serviceRepository = new ServiceRepository();                    
                    serviceRepository.UpdateServiceRequestEstimateValues(request, model.CurrentUser);
                    logger.InfoFormat("Determined the Estimate and saved it on SR : {0}", serviceRequest.ID);
                    model.ServiceEstimate = estimate.Estimate;

                    Hashtable dseData = new Hashtable();
                    dseData.Add("ServiceEstimate", estimate != null ? estimate.Estimate.ToString("C") : string.Empty);
                    var serviceEligibilityMessages = serviceRepository.GetServiceEligibilityMessages(model.ProgramID.GetValueOrDefault(), model.SourceSystem);
                    var template = serviceEligibilityMessages.Where(x => x.Name == "MEMBER_PAY_ESTIMATE").FirstOrDefault();
                    model.ServiceEstimateMessage = TemplateUtil.ProcessTemplate(template.Message, dseData);
                }

                transaction.Complete();
            }
            return model;
        }

        public void ConfirmEstimate(int serviceRequestID, string currentUser)
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                /*
                 *  1.	Clear Case Assigned To User ID 
                    2.	Set SR Status to  'Submitted'
                    3.	Set SR.IsServiceEstimateAccepted = 1
                    4.	Next Action = 'Dispatch'
                    5.	Next Action Assigned To User ID = 'Dispatch User
                    6.	Next Action Schduled Date = getdate()

                 */
                var serviceRequestRepository = new ServiceRequestRepository();
                var serviceRequest = serviceRequestRepository.GetById(serviceRequestID);
                serviceRequestRepository.UpdateServiceRequest(serviceRequest.ID, ServiceRequestStatusNames.SUBMITTED, "Normal", null, "Dispatch", "DispatchUser", DateTime.Now, true, null, true);

                logger.InfoFormat("Updating map snapshot for SR ID {0}", serviceRequestID);
                MapFacade mapFacade = new MapFacade();
                mapFacade.SetMapSnapshot(serviceRequestID);

                CreateContactLogForMobile(new ServiceRequestApiModel() { ServiceRequestID = serviceRequestID, CurrentUser = currentUser }, "SubmittedForDispatch");

                var eventLogRepository = new EventLogRepository();
                eventLogRepository.LogEventForServiceRequestStatus(serviceRequest.ID, EventNames.SUBMITTED_FOR_DISPATCH, "WebService", null, null, currentUser);

                logger.InfoFormat("Logging next action changed event for service request ID {0}", serviceRequestID);
                serviceRequest = serviceRequestRepository.GetById(serviceRequestID);
                serviceRequestRepository.LogServiceRequestNextActionChange(serviceRequestID, null, serviceRequest.NextActionID, serviceRequest.NextActionAssignedToUserID, DateTime.Now, "WebService", null, currentUser, null);
                transaction.Complete();
            }
        }

        public void CancelEstimate(int serviceRequestID, string currentUser)
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                /*
                 *  1.	Clear Case Assigned To User ID 
                    2.	Set SR Status to  'Submitted'
                    3.	Set SR.IsServiceEstimateAccepted = 1
                    4.	Next Action = 'Dispatch'
                    5.	Next Action Assigned To User ID = 'Dispatch User
                    6.	Next Action Schduled Date = getdate()

                 */
                var serviceRequestRepository = new ServiceRequestRepository();
                var serviceRequest = serviceRequestRepository.GetById(serviceRequestID);
                logger.InfoFormat("Setting the SR {0} to Cancelled", serviceRequestID);
                serviceRequestRepository.UpdateServiceRequest(serviceRequest.ID, ServiceRequestStatusNames.CANCELLED, "Normal", null, null, null, null, false, null, null);
                logger.InfoFormat("Updating map snapshot for SR ID {0}", serviceRequestID);
                MapFacade mapFacade = new MapFacade();
                mapFacade.SetMapSnapshot(serviceRequestID);

                CreateContactLogForMobile(new ServiceRequestApiModel() { ServiceRequestID = serviceRequestID, CurrentUser = currentUser }, "RefusedServiceAsMemberCustomerPay");

                logger.InfoFormat("Logging an event - ServiceCancelled for ServiceRequestID {0}", serviceRequestID);
                var eventLogFacade = new EventLoggerFacade();
                var eventLogId = eventLogFacade.LogEvent("/api/v1/servicerequests/{id}/Estimate/Cancel", EventNames.SERVICE_CANCELLED, null, currentUser, serviceRequestID, EntityNames.SERVICE_REQUEST);

                transaction.Complete();
            }
        }
        protected int CreateContactLogForMobile(ServiceRequestApiModel model, string contactActionName)
        {
            #region 1. Create contactLog record
            var contactLogRepository = new ContactLogRepository();
            ContactLog contactLog = new ContactLog()
            {
                ContactSourceID = null,
                TalkedTo = null,
                Company = null,
                PhoneTypeID = null,
                PhoneNumber = model.MemberPhoneNumber,
                Direction = "Inbound",
                Comments = null,
                Description = "Submit from mobile",
                CreateBy = model.CurrentUser,
                CreateDate = DateTime.Now
            };

            // Get the phone Type ID
            PhoneRepository phoneRepository = new PhoneRepository();
            //TODO: Remove hardcoding for phonetype.
            PhoneType phoneType = phoneRepository.GetPhoneTypeByName("Cell");
            if (phoneType == null)
            {
                throw new DMSException("Phone type - Cell is not set up in the system");
            }

            contactLog.PhoneTypeID = phoneType.ID;
            // Get Contactcategory, method, type and Source

            ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
            ContactType memberType = staticDataRepo.GetTypeByName("Member");
            if (memberType == null)
            {
                throw new DMSException("Contact Type - Member is not set up in the system");
            }

            contactLog.ContactTypeID = memberType.ID;
            ContactMethod contactMethod = staticDataRepo.GetMethodByName("Mobile");
            if (contactMethod == null)
            {
                throw new DMSException("Contact Method - Mobile is not set up in the system");
            }
            contactLog.ContactMethodID = contactMethod.ID;

            ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("NewCall");
            if (contactCategory == null)
            {
                throw new DMSException("Contact Category - NewCall is not set up in the system");
            }

            contactLog.ContactCategoryID = contactCategory.ID;
            contactLogRepository.Save(contactLog, model.CurrentUser, model.ServiceRequestID, EntityNames.SERVICE_REQUEST);

            #endregion

            #region 2. Create ContactLogReason

            ContactReason contactReason = staticDataRepo.GetContactReason("Need Service", "NewCall");

            if (contactReason != null)
            {
                ContactLogReasonRepository contactLogReasonRepo = new ContactLogReasonRepository();
                ContactLogReason reason = new ContactLogReason()
                {
                    ContactLogID = contactLog.ID,
                    ContactReasonID = contactReason.ID
                };
                contactLogReasonRepo.Save(reason, model.CurrentUser);
            }
            else
            {
                throw new DMSException("ContactReason - Need Service for category = NewCall is not set up in the system");
            }

            #endregion

            #region 3. Create ContactLogAction

            ContactAction contactAction = staticDataRepo.GetContactActionByName(contactActionName);

            if (contactAction != null)
            {
                ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                ContactLogAction logAction = new ContactLogAction()
                {
                    ContactLogID = contactLog.ID,
                    ContactActionID = contactAction.ID
                };

                logActionRepo.Save(logAction, model.CurrentUser);
            }
            else
            {
                throw new DMSException(string.Format("ContactAction - {0} is not set up in the system", contactActionName));
            }

            #endregion

            return contactLog.ID;
        }

        public List<APISearchSRListModel> GetAPIServiceRequestList(ServiceRequestSearchModel model)
        {
            logger.Info("START: Calling sp - GetAPIServiceRequestList");
            var list = serviceRequestRepository.GetAPIServiceRequestList(model);
            logger.Info("DONE: Calling sp - GetAPIServiceRequestList");

            List<APISearchSRListModel> returnList = new List<APISearchSRListModel>();
            foreach (var sr in list)
            {
                var newSr = new APISearchSRListModel()
                {
                    RequestNumber = sr.RequestNumber,
                    CaseID = sr.CaseID,
                    ProgramID = sr.ProgramID,
                    Program = sr.Program,
                    ClientID = sr.ClientID,
                    Client = sr.Client,
                    MemberName = sr.MemberName,
                    MemberNumber = sr.MemberNumber,
                    CreateDate = sr.CreateDate,
                    POCreateBy = sr.POCreateBy,
                    POModifyBy = sr.POModifyBy,
                    SRCreateBy = sr.SRCreateBy,
                    SRModifyBy = sr.SRModifyBy,
                    VIN = sr.VIN,
                    VehicleTypeID = sr.VehicleTypeID,
                    VehicleType = sr.VehicleType,
                    ServiceTypeID = sr.ServiceTypeID,
                    ServiceType = sr.ServiceType,
                    ServiceLocationAddress = sr.ServiceLocationAddress,
                    ServiceLocationDescription = sr.ServiceLocationDescription,
                    DestinationAddress = sr.DestinationAddress,
                    DestinationDescription = sr.DestinationDescription,
                    StatusID = sr.StatusID,
                    Status = sr.Status,
                    PriorityID = sr.PriorityID,
                    Priority = sr.Priority,
                    ISPName = sr.ISPName,
                    VendorNumber = sr.VendorNumber,
                    PONumber = sr.PONumber,
                    PurchaseOrderStatusID = sr.PurchaseOrderStatusID,
                    PurchaseOrderStatus = sr.PurchaseOrderStatus,
                    PurchaseOrderAmount = sr.PurchaseOrderAmount,
                    AssignedToUserID = sr.AssignedToUserID,
                    NextActionAssignedToUserID = sr.NextActionAssignedToUserID,
                    IsGOA = sr.IsGOA,
                    IsRedispatched = sr.IsRedispatched,
                    IsPossibleTow = sr.IsPossibleTow,
                    VehicleYear = sr.VehicleYear,
                    VehicleMake = sr.VehicleMake,
                    VehicleModel = sr.VehicleModel,
                    PaymentByCard = sr.PaymentByCard,
                    TrackerID = sr.TrackerID.ToString(),
                    MapSnapshot = sr.MapSnapshot
                };

                returnList.Add(newSr);
            }
            logger.Info("DONE: Building the list of custom objects");
            return returnList;
        }

        public APISearchSRModel GetServiceRequestByIDForAPI(int? serviceReqeustID)
        {
            APISearchSRModel model = null;
            var list = serviceRequestRepository.GetAPIServiceRequest(serviceReqeustID);
            if (list.Count == 0)
            {
                throw new DMSException(string.Format("No ServiceRequests found for ID : {0}", serviceReqeustID));
            }
            //TODO: Iterate through the list to modify the list into single SR.

            var sr = list.FirstOrDefault();
            if (sr != null)
            {
                model = new APISearchSRModel()
                {
                    IsDeliveryDriver = sr.IsDeliveryDriver,
                    RequestNumber = sr.RequestNumber,
                    Status = sr.Status,
                    Priority = sr.Priority,
                    CreateDate = sr.CreateDate,
                    CreateBy = sr.CreateBy,
                    ModifyDate = sr.ModifyDate,
                    ModifyBy = sr.ModifyBy,
                    NextAction = sr.NextAction,
                    NextActionScheduledDate = sr.NextActionScheduledDate,
                    NextActionAssignedTo = sr.NextActionAssignedTo,
                    ClosedLoop = sr.ClosedLoop,
                    ClosedLoopNextSend = sr.ClosedLoopNextSend,
                    ServiceCategory = sr.ServiceCategory,
                    Elapsed = sr.Elapsed,
                    PoMaxIssueDate = sr.PoMaxIssueDate,
                    PoMaxETADate = sr.PoMaxETADate,
                    DataTransferDate = sr.DataTransferDate,
                    ClientMemberType = sr.ClientMemberType,
                    Member = sr.Member,
                    MembershipNumber = sr.MembershipNumber,
                    MemberStatus = sr.MemberStatus,
                    Client = sr.Client,
                    ProgramID = sr.ProgramID,
                    ProgramName = sr.ProgramName,
                    MemberSince = sr.MemberSince,
                    ExpirationDate = sr.ExpirationDate,
                    ClientReferenceNumber = sr.ClientReferenceNumber,
                    CallbackPhoneType = sr.CallbackPhoneType,
                    CallbackNumber = sr.CallbackNumber,
                    AlternatePhoneType = sr.AlternatePhoneType,
                    AlternateNumber = sr.AlternateNumber,
                    Line1 = sr.Line1,
                    Line2 = sr.Line2,
                    Line3 = sr.Line3,
                    MemberCityStateZipCountry = sr.MemberCityStateZipCountry,
                    YearMakeModel = sr.YearMakeModel,
                    VehicleTypeAndCategory = sr.VehicleTypeAndCategory,
                    VehicleColor = sr.VehicleColor,
                    VehicleVIN = sr.VehicleVIN,
                    License = sr.License,
                    VehicleDescription = sr.VehicleDescription,
                    RVType = sr.RVType,
                    VehicleChassis = sr.VehicleChassis,
                    VehicleEngine = sr.VehicleEngine,
                    VehicleTransmission = sr.VehicleTransmission,
                    Mileage = sr.Mileage,
                    ServiceLocationAddress = sr.ServiceLocationAddress,
                    ServiceLocationDescription = sr.ServiceLocationDescription,
                    DestinationAddress = sr.DestinationAddress,
                    DestinationDescription = sr.DestinationDescription,
                    ServiceCategorySection = sr.ServiceCategorySection,
                    CoverageLimit = sr.CoverageLimit,
                    Safe = sr.Safe,
                    PrimaryProductID = sr.PrimaryProductID,
                    PrimaryProductName = sr.PrimaryProductName,
                    PrimaryServiceEligiblityMessage = sr.PrimaryServiceEligiblityMessage,
                    SecondaryProductID = sr.SecondaryProductID,
                    SecondaryProductName = sr.SecondaryProductName,
                    SecondaryServiceEligiblityMessage = sr.SecondaryServiceEligiblityMessage,
                    IsPrimaryOverallCovered = sr.IsPrimaryOverallCovered,
                    IsSecondaryOverallCovered = sr.IsSecondaryOverallCovered,
                    IsPossibleTow = sr.IsPossibleTow,
                    ContractStatus = sr.ContractStatus,
                    AssignedTo = sr.AssignedTo,
                    AssignedToID = sr.AssignedToID,
                    TrackerID = sr.TrackerID.ToString()
                };

                var polist = list.Where(a => a.RequestNumber == sr.RequestNumber).ToList();
                List<APISearchSRPOModel> poListForSR = new List<APISearchSRPOModel>();
                foreach (var po in polist)
                {
                    var newPO = new APISearchSRPOModel()
                    {
                        VendorName = po.VendorName,
                        VendorID = po.VendorID,
                        VendorNumber = po.VendorNumber,
                        VendorLocationPhoneNumber = po.VendorLocationPhoneNumber,
                        VendorLocationLine1 = po.VendorLocationLine1,
                        VendorLocationLine2 = po.VendorLocationLine2,
                        VendorLocationLine3 = po.VendorLocationLine3,
                        VendorCityStateZipCountry = po.VendorCityStateZipCountry,
                        PONumber = po.PONumber,
                        LegacyReferenceNumber = po.LegacyReferenceNumber,
                        POStatus = po.POStatus,
                        CancelReason = po.CancelReason,
                        POAmount = po.POAmount,
                        ServiceType = po.ServiceType,
                        IssueDate = po.IssueDate,
                        ETADate = po.ETADate,
                        ExtractDate = po.ExtractDate,
                        InvoiceDate = po.InvoiceDate,
                        PaymentType = po.PaymentType,
                        PaymentAmount = po.PaymentAmount,
                        PaymentDate = po.PaymentDate,
                        CheckClearedDate = po.CheckClearedDate,
                        ProductProvider = po.ProductProvider,
                        ProductProviderNumber = po.ProductProviderNumber,
                        ProviderClaimNumber = po.ProviderClaimNumber
                    };
                    poListForSR.Add(newPO);
                }
                model.POList = poListForSR;
            }

            return model;
        }

    }
}
