using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using System.Transactions;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;

namespace Martex.DMS.BLL.Facade
{
    public partial class ClaimsFacade
    {
        /// <summary>
        /// Gets the claim information.
        /// </summary>
        /// <param name="claimID">The claim ID.</param>
        /// <returns></returns>
        public ClaimInformationModel GetClaimInformation(int claimID)
        {
            ClaimInformationModel model = new ClaimInformationModel();
            CommonLookUpRepository lookUp = new CommonLookUpRepository();

            var repository = new ClaimsRepository();
            if (claimID > 0)
            {
                model.Claim = repository.GetClaim(claimID);
            }

            #region Setting Values
            if (model.Claim == null)
            {
                model.Claim = new DAL.Claim();
            }
            if (model.Claim.SourceSystemID.HasValue)
            {
                model.SourceSystemName = lookUp.GetSourceSystem(model.Claim.SourceSystemID.Value).Description;
            }
            if (model.Claim.PaymentTypeID.HasValue)
            {
                model.PaymentTypeName = lookUp.GetPaymentType(model.Claim.PaymentTypeID.Value).Description;
            }
            if (model.Claim.ClaimTypeID.HasValue)
            {
                ClaimType claimType = lookUp.GetClaimType(model.Claim.ClaimTypeID.Value);
                if (claimType.IsFordACES.GetValueOrDefault())
                {
                    model.IsFordACES = true;
                }
                model.ClaimTypeName = claimType.Name;
            }
            if (model.Claim.ClaimStatusID.HasValue)
            {
                ClaimStatu claimStatus = lookUp.GetClaimStatus(model.Claim.ClaimStatusID.Value);
                model.ClaimStatusName = claimStatus.Description;
            }

            if (model.Claim.MemberID.HasValue)
            {
                MemberRepository memberRepository = new MemberRepository();
                MembsershipInformation_Result membershipDetails = memberRepository.GetMembershipInformation(model.Claim.MemberID.Value);
                Member memberDetails = memberRepository.Get(model.Claim.MemberID.Value);
                if (membershipDetails == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Member Details {0}", model.Claim.MemberID.Value));
                }
                model.MembershipNumber = membershipDetails.MemberNumber;
                model.MemberName = string.Join(" ", memberDetails.FirstName, memberDetails.MiddleName, memberDetails.LastName, memberDetails.Suffix);

                if (model.Claim.ProgramID.HasValue)
                {
                    Program programDetails = lookUp.GetProgram(model.Claim.ProgramID.Value);
                    model.ProgramName = programDetails.Name;
                }
            }
            if (model.Claim.VendorID.HasValue)
            {
                Vendor vendorDetails = new VendorRepository().GetByID(model.Claim.VendorID.Value);
                if (vendorDetails == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Vendor Details {0}", model.Claim.VendorID.Value));
                }
                model.VendorNumber = vendorDetails.VendorNumber;
                model.VendorName = vendorDetails.Name;
            }
            #endregion

            #region Enable and Disable Tabs based on the Claim Type ID
            if (model.Claim.ClaimTypeID.HasValue)
            {
                ClaimType claimType = lookUp.GetClaimType(model.Claim.ClaimTypeID.Value);
                model.ClaimTypeName = claimType.Description;
                // When the Claim Type is Ford QFC Status Update is not allowed.
                model.IsClaimStatusUpdateAllowed = claimType.Name.Equals("FordQFC") ? false : true;
            }
            #endregion

            #region Retrieve Maximum Claim Amount Threshold
            string amount = AppConfigRepository.GetValue("MaximumClaimAmountThreshold"); //KB: No need to use type while looking up appconfig, ApplicationConfigurationTypes.VENDOR_INVOICE);
            decimal decimalAmount = 0;
            decimal.TryParse(amount, out decimalAmount);
            model.MaximumClaimAmountThreshold = decimalAmount;
            #endregion

            #region Fill ACES Claim Status
            if (model.Claim.ACESClaimStatusID.HasValue)
            {
                ACESClaimStatu acesStatus = lookUp.GetACESClaimStatus(model.Claim.ACESClaimStatusID.Value);
                model.ACESClaimStatusName = acesStatus.Name;
            }
            #endregion

            var serviceDetails = GetServiceDetails(claimID);
            model.PreviousComments = serviceDetails.PreviousComments;
            model.DiagnosticCodes = serviceDetails.DiagnosticCodes;

            return model;
        }

        /// <summary>
        /// Saves the claim information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public DAL.Claim SaveClaimInformation(ClaimInformationModel model, string userName, string sessionID)
        {
            //  Validate Warranty fields based on the OwnerProgram selected.
            if (model.OwnerProgram != null)
            {
                logger.InfoFormat("Finding out ProgramConfig for Program = {0}", model.OwnerProgram);
                var progRepository = new ProgramMaintenanceRepository();
                var programInfo = progRepository.GetProgramInfo(model.OwnerProgram, "Claim", "Validation");

                if (programInfo != null && programInfo.Where(x => x.Name == "IsWarrantyRequired" && x.Value == "Yes").Count() > 0)
                {
                    logger.InfoFormat("Warranty fields are required for this program {0}", model.OwnerProgram);
                    var currentClaim = model.Claim;
                    if (currentClaim.WarrantyMiles == null || currentClaim.WarrantyYears == null || currentClaim.WarrantyStartDate == null || currentClaim.CurrentMiles == null)
                    {
                        throw new DMSException("Please fill warranty information");
                    }
                    logger.Info("Warranty information is available");
                }
            }

            bool isNewRecord = model.Claim.ID == 0 ? true : false;
            var repository = new ClaimsRepository();
            CommonLookUpRepository lookUp = new CommonLookUpRepository();
            var contactLogRepo = new ContactLogRepository();
            var eventLogRepo = new EventLogRepository();

            #region ACES Claim Status Section
            if (model.Claim.ACESClearedDate.HasValue)
            {
                ACESClaimStatu acesStatus = lookUp.GetACESClaimStatus("Cleared");
                ClaimType claimType = lookUp.GetClaimType(model.Claim.ClaimTypeID.Value);
                ClaimStatu claimStatus = lookUp.GetClaimStatus(model.Claim.ClaimStatusID.Value);
                if (claimStatus.Name.Equals("ReadyForPayment") && claimType.IsFordACES.GetValueOrDefault())
                {
                    model.Claim.ACESClaimStatusID = acesStatus.ID;
                }
            }
            #endregion

            #region Fill address LookUp
            // Fill the Address LookUp
            if (model.Claim.PaymentAddressCountryID.HasValue)
            {
                model.Claim.PaymentAddressCountryCode = lookUp.GetCountry(model.Claim.PaymentAddressCountryID.Value).ISOCode;
            }
            if (model.Claim.PaymentAddressStateProvinceID.HasValue)
            {
                model.Claim.PaymentAddressStateProvince = lookUp.GetStateProvince(model.Claim.PaymentAddressStateProvinceID.Value).Abbreviation;
            }
            #endregion

            #region When it's a new Claim
            if (isNewRecord)
            {
                model.Claim.SourceSystemID = lookUp.GetSourceSystem(SourceSystemName.BACK_OFFICE).ID;
                model.Claim.PaymentAmount = model.Claim.AmountApproved;

                if (PayeeTypeName.MEMBER.Equals(model.Claim.PayeeType, StringComparison.InvariantCultureIgnoreCase))
                {
                    Member memberDetails = new MemberRepository().GetMemberDetailsbyID(model.Claim.MemberID.Value);
                    if (memberDetails == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve Member Details for the given ID {0}", model.Claim.MemberID.Value));
                    }
                    // Get the Program ID and SET it to Model
                    model.Claim.ProgramID = memberDetails.ProgramID;
                }
            }
            #endregion

            using (TransactionScope transaction = new TransactionScope())
            {
                // Update Claim Information
                logger.InfoFormat("Trying to Update Claim Information for the ID {0}", model.Claim.ID);
                DAL.Claim dbClaimDetails = null;
                bool isClaimStatusChanged = false;
                bool isACESStatusChanged = false;

                if (model.Claim.ID > 0)
                {
                    dbClaimDetails = repository.GetClaim(model.Claim.ID);
                    if (dbClaimDetails.ClaimStatusID != model.Claim.ClaimStatusID)
                    {
                        isClaimStatusChanged = true;
                    }
                    if (dbClaimDetails.ACESClaimStatusID != model.Claim.ACESClaimStatusID)
                    {
                        isACESStatusChanged = true;
                    }
                }
                repository.SaveClaimInformation(model.Claim, userName);

                // Update Claim Reference Number When Member ID Has Value and It's a new Calim
                if (model.Claim.MemberID.HasValue)
                {
                    logger.InfoFormat("Trying to Updare Claim Reference Number for the Memeber ID {0}", model.Claim.MemberID.Value);
                    repository.UpdateMemberClaimReferenceNumber(model.Claim.MemberID.Value, userName);
                }

                // Creating Contact Log When it's a new Claim
                if (isNewRecord)
                {
                    #region Contact Log Related Entries
                    ContactCategory contactCategory = lookUp.GetContactCategory("Claim");
                    ContactType contactType = lookUp.GetContactType(model.Claim.PayeeType);
                    ContactReason contactReason = lookUp.GetContactReason(ContactReasonName.SUBMIT_CLAIM, contactCategory.ID);
                    ContactAction contactAction = lookUp.GetContactAction(ContactReasonName.RECEIVED_CLAIM, contactCategory.ID);
                    if (contactCategory == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve Contact Category {0}", "VendorManagement"));
                    }
                    if (contactType == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve Contact Type {0}", model.Claim.PayeeType));
                    }
                    if (contactReason == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve Contact Reason {0}", "Submit Claim"));
                    }
                    if (contactAction == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve Contact Action {0}", "Received Claim"));
                    }
                    ContactLog contactLog = new ContactLog()
                    {
                        ContactCategoryID = contactCategory.ID,
                        ContactTypeID = contactType.ID,
                        ContactMethodID = model.Claim.ReceiveContactMethodID,
                        ContactSourceID = null,
                        Company = model.Claim.PayeeType.Equals(PayeeTypeName.VENDOR) ? model.VendorName : "",
                        TalkedTo = model.Claim.ContactName,
                        PhoneTypeID = null,
                        PhoneNumber = model.Claim.ContactPhoneNumber,
                        Email = model.Claim.ContactEmailAddress,
                        Direction = "Inbound",
                        Description = "Enter Claim",
                        Comments = null,
                        CreateBy = userName,
                        CreateDate = DateTime.Now,
                        ModifyBy = null,
                        ModifyDate = null,
                    };

                    logger.Info("Trying to Create Contact Log either Member or Vendor");
                    contactLogRepo.Save(contactLog, userName);

                    ContactLogReason contactLogReaosn = new ContactLogReason()
                    {
                        ContactLogID = contactLog.ID,
                        ContactReasonID = contactReason.ID,
                        CreateBy = userName,
                        CreateDate = DateTime.Now
                    };
                    logger.Info(string.Format("Trying to Create Contact Log Reason for Contact Log {0}", contactLog.ID));
                    contactLogRepo.CreateContactLogReason(contactLogReaosn);

                    ContactLogAction contactLogAction = new ContactLogAction()
                    {
                        ContactLogID = contactLog.ID,
                        CreateBy = userName,
                        CreateDate = DateTime.Now,
                        ContactActionID = contactAction.ID
                    };
                    logger.Info(string.Format("Trying to Create Contact Action for Contact Log {0}", contactLog.ID));
                    contactLogRepo.CreateContactLogAction(contactLogAction);

                    logger.Info(string.Format("Trying to Create Link Record for Contact Log ID {0}", contactLog.ID));
                    contactLogRepo.CreateLinkRecord(contactLog.ID, EntityNames.CLAIM, model.Claim.ID);

                    logger.Info(string.Format("Trying to Create Contact Link Record for Contact Log ID {0} with either Member or Vendor", contactLog.ID));
                    if (model.Claim.PayeeType == PayeeTypeName.VENDOR)
                    {
                        contactLogRepo.CreateLinkRecord(contactLog.ID, EntityNames.VENDOR, model.Claim.VendorID);
                    }
                    else if (model.Claim.PayeeType == PayeeTypeName.MEMBER)
                    {
                        contactLogRepo.CreateLinkRecord(contactLog.ID, EntityNames.MEMBER, model.Claim.MemberID);
                    }
                    #endregion

                    #region Event Log Related Entries When Adding Claim
                    Event eventName = lookUp.GetEvent(EventNames.SUBMIT_CLAIM);
                    ClaimStatu claimStatus = lookUp.GetClaimStatus(model.Claim.ClaimStatusID.Value);
                    EventLog eventLogRecord = new EventLog()
                    {
                        Source = model.Claim.PayeeType,
                        EventID = eventName.ID,
                        Description = "Status : " + claimStatus.Description,
                        NotificationQueueDate = null,
                        CreateDate = DateTime.Now,
                        CreateBy = userName,
                        SessionID = sessionID

                    };
                    logger.InfoFormat("Trying to log the event {0}", EventNames.SUBMIT_CLAIM);
                    long evetLogLinkID = eventLogRepo.Add(eventLogRecord, model.Claim.ID, EntityNames.CLAIM);
                    logger.Info(string.Format("Trying to Create Event Log Link Record for Event Log ID {0} with either Member or Vendor", evetLogLinkID));
                    if (model.Claim.PayeeType == PayeeTypeName.VENDOR)
                    {
                        eventLogRepo.CreateLinkRecord(evetLogLinkID, EntityNames.VENDOR, model.Claim.VendorID);
                    }
                    else if (model.Claim.PayeeType == PayeeTypeName.MEMBER)
                    {
                        eventLogRepo.CreateLinkRecord(evetLogLinkID, EntityNames.MEMBER, model.Claim.MemberID);
                    }

                    #endregion
                }
                //Create Event Log Link Records when Trying to Update Claims
                else
                {
                    #region Event Log Related Entries When Updating Claim
                    Event eventName = lookUp.GetEvent(EventNames.UPDATE_CLAIM);
                    ClaimStatu claimStatus = lookUp.GetClaimStatus(model.Claim.ClaimStatusID.Value);
                    EventLog eventLogRecord = new EventLog()
                    {
                        Source = model.Claim.PayeeType,
                        EventID = eventName.ID,
                        Description = "Status : " + claimStatus.Description,
                        NotificationQueueDate = null,
                        CreateDate = DateTime.Now,
                        CreateBy = userName,
                        SessionID = sessionID

                    };
                    logger.InfoFormat("Trying to log the event {0}", EventNames.UPDATE_CLAIM);
                    long evetLogLinkID = eventLogRepo.Add(eventLogRecord, model.Claim.ID, EntityNames.CLAIM);
                    logger.Info(string.Format("Trying to Create Event Log Link Record for Event Log ID {0} with either Member or Vendor", evetLogLinkID));

                    if (model.Claim.PayeeType == PayeeTypeName.VENDOR)
                    {
                        eventLogRepo.CreateLinkRecord(evetLogLinkID, EntityNames.VENDOR, model.Claim.VendorID);
                    }
                    else if (model.Claim.PayeeType == PayeeTypeName.MEMBER)
                    {
                        eventLogRepo.CreateLinkRecord(evetLogLinkID, EntityNames.MEMBER, model.Claim.MemberID);
                    }

                    #endregion

                    #region Create Event Log When There is Changes in Claim Status

                    if (isClaimStatusChanged)
                    {
                        if (dbClaimDetails.ClaimStatusID.HasValue)
                        {
                            ClaimStatu beforeStatus = lookUp.GetClaimStatus(dbClaimDetails.ClaimStatusID.Value);
                            ClaimStatu afterStatus = lookUp.GetClaimStatus(model.Claim.ClaimStatusID.Value);

                            EventLog eventLogRecordForClaimStatus = new EventLog()
                            {
                                Source = null,
                                EventID = eventName.ID,
                                Description = "Status change:  Before = " + beforeStatus.Description + " After = " + afterStatus.Description,
                                NotificationQueueDate = null,
                                CreateDate = DateTime.Now,
                                CreateBy = userName,
                                SessionID = sessionID

                            };
                            logger.InfoFormat("Trying to log the event {0}", EventNames.UPDATE_CLAIM);
                            eventLogRepo.Add(eventLogRecordForClaimStatus, model.Claim.ID, EntityNames.CLAIM);
                        }
                    }
                    #endregion


                    #region Create Event Log When There is Changes in ACES Status

                    if (isACESStatusChanged)
                    {
                        ACESClaimStatu beforeStatus = null;
                        if (dbClaimDetails.ACESClaimStatusID.HasValue)
                        {
                            beforeStatus = lookUp.GetACESClaimStatus(dbClaimDetails.ACESClaimStatusID.Value);
                        }
                        ACESClaimStatu afterStatus = null;
                        if (model.Claim.ACESClaimStatusID.HasValue)
                        {
                            afterStatus = lookUp.GetACESClaimStatus(model.Claim.ACESClaimStatusID.Value);
                        }
                        if (beforeStatus == null) { beforeStatus = new ACESClaimStatu(); }
                        if (afterStatus == null) { afterStatus = new ACESClaimStatu(); }

                        EventLog eventLogRecordForACESStatus = new EventLog()
                        {
                            Source = null,
                            EventID = eventName.ID,
                            Description = "ACES Status change:  Before = " + beforeStatus.Description + " After = " + afterStatus.Description,
                            NotificationQueueDate = null,
                            CreateDate = DateTime.Now,
                            CreateBy = userName,
                            SessionID = sessionID

                        };
                        logger.InfoFormat("Trying to log the event {0}", EventNames.UPDATE_CLAIM);
                        eventLogRepo.Add(eventLogRecordForACESStatus, model.Claim.ID, EntityNames.CLAIM);

                    }
                    #endregion
                }
                transaction.Complete();
            }
            return model.Claim;
        }

    }
}
