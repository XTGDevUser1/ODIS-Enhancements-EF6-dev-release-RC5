using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.Areas.Application.Models;
using System.Transactions;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using log4net;
using Martex.DMS.DAO;
using membershipProvider = System.Web.Security;
using System.Web.Security;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Manage Vendors
    /// </summary>
    public class VendorFacade
    {
        #region Protected Methods
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorFacade));
        #endregion

        #region Public Methods
        /// <summary>
        /// Adds the temporary vendor.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="relatedRecord">The related record.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionId">The session id.</param>
        /// <exception cref="DMSException">Vendor location type - Physical is not set up in the system</exception>
        public void AddTemporaryVendor(VendorInfo model, string eventSource, int? relatedRecord, string currentUser, string sessionId)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                //1. Add Vendor and VendorLocation
                Vendor v = new Vendor()
                {
                    Name = model.VendorName,
                    Email = model.VendorEmail,
                    IsActive = true,
                    CreateBy = currentUser,
                    ModifyBy = currentUser,
                    CreateDate = DateTime.Now,
                    ModifyDate = DateTime.Now

                };

                #region 0. Get the Vendor Region Associated with this Address
                CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
                VendorRegion vendorRegion = null;
                if (model.VendorState.HasValue)
                {
                    vendorRegion = lookUpRepo.GetVendorRegionByStateID(model.VendorState.Value);
                }
                else
                {
                    throw new DMSException(string.Format("State selection is required"));
                }

                v.VendorRegionID = vendorRegion.ID;

                #endregion

                VendorRepository vendorRepo = new VendorRepository();

                VendorManagementRepository vmRepo = new VendorManagementRepository();
                v.VendorNumber = model.VendorState.GetValueOrDefault().ToString(); // Passing state ID as VendorNumber gets generated and appended to the state code.

                vmRepo.AddVendor(v, "Dispatch", "Temporary");


                //2. Address records
                var addressFacade = new AddressFacade();
                AddressEntity businessAddress = GetAddressEntity(model, "Business");
                AddressEntity billingAddress = GetAddressEntity(model, "Billing");
                logger.Info("Adding business and billing addresses for Vendor");
                addressFacade.SaveAddresses(v.ID, EntityNames.VENDOR, currentUser, new List<AddressEntity>() { businessAddress, billingAddress }, AddressFacade.ADD);

                businessAddress = GetAddressEntity(model, "Business");

                VendorLocation vl = new VendorLocation()
                {
                    VendorID = v.ID,
                    Sequence = 0, // CR : 1253
                    Email = model.VendorEmail,
                    IsActive = false,
                    CreateBy = currentUser,
                    ModifyBy = currentUser,
                    CreateDate = DateTime.Now,
                    ModifyDate = DateTime.Now
                };




                LatitudeLongitude latLong = AddressFacade.GetLatLong(string.Join(",", businessAddress.Line1, businessAddress.Line2, businessAddress.Line3),
                                                                                        businessAddress.City,
                                                                                        businessAddress.StateProvince,
                                                                                        businessAddress.PostalCode,
                                                                                        businessAddress.CountryCode);

                vl.Latitude = latLong.Latitude;
                vl.Longitude = latLong.Longitude;

                //TFS : 2055
                vl.IsActive = true;
                VendorLocationStatu vlStatus = vmRepo.GetVendorLocationStatusByName("Active");
                if (vlStatus == null)
                {
                    string warnMessage = "VendorLocationStatus - Active is not set up in the system";
                    logger.Warn(warnMessage);
                    throw new DMSException(warnMessage);
                }
                vl.VendorLocationStatusID = vlStatus.ID;

                logger.Info("Adding Vendor Location");
                vendorRepo.AddVendorLocation(vl);

                logger.InfoFormat("Updating Geo types on VendorLocation {0}", vl.ID);

                AddressRepository addressRepository = new AddressRepository();
                addressRepository.UpdateGeographyType(vl.ID, EntityNames.VENDOR_LOCATION);

                logger.Info("Adding business address for Vendor location");
                addressFacade.SaveAddresses(vl.ID, EntityNames.VENDOR_LOCATION, currentUser, new List<AddressEntity>() { businessAddress }, AddressFacade.ADD);


                //3. Phone records
                var phoneRepository = new PhoneRepository();
                List<PhoneEntity> phones = GetPhoneEntities(model, phoneRepository);

                var phoneFacade = new PhoneFacade();
                logger.Info("Adding Phone records for Vendor");
                phoneFacade.SavePhoneDetails(v.ID, EntityNames.VENDOR, currentUser, phones, PhoneFacade.ADD);
                phones = GetPhoneEntities(model, phoneRepository);
                logger.Info("Adding Phone records for Vendor location");
                phoneFacade.SavePhoneDetails(vl.ID, EntityNames.VENDOR_LOCATION, currentUser, phones, PhoneFacade.ADD);
                //4. Add Event log records
                var eventLoggerFacade = new EventLoggerFacade();
                logger.Info("Logging an event for Create temporary vendor");
                eventLoggerFacade.LogEvent(eventSource, EventNames.CREATE_TEMPORARY_VENDOR, "Create Temporary Vendor", currentUser, relatedRecord, EntityNames.SERVICE_REQUEST, sessionId);
                // Event Log REcored Added

                tran.Complete();

                model.VendorID = v.ID;
                model.VendorLocationID = vl.ID;

                /* Update model so that the latitude and longitude values can be used by the caller */
                model.LatLong = latLong;

            }

        }

        /// <summary>
        /// Gets the vendor match.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="DispatchNum">The dispatch num.</param>
        /// <param name="OfficeNum">The office num.</param>
        /// <param name="vendorName">Name of the vendor.</param>
        /// <returns></returns>
        public List<GetVendorInfoSearch_Result> GetVendorMatch(PageCriteria pageCriteria, string DispatchNum, string OfficeNum, string vendorName)
        {
            var vendorRepository = new VendorRepository();
            return vendorRepository.GetVendorMatch(pageCriteria, DispatchNum, OfficeNum, vendorName);
        }

        /// <summary>
        /// Vendors the details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="searchFrom">The search from.</param>
        /// <returns></returns>
        public VendorInfo VendorDetails(int vendorID, int vendorLocationID, int serviceRequestID, string searchFrom)
        {
            VendorRepository rep = new VendorRepository();
            VendorInfo vi = new VendorInfo();
            GetVendorDetails_Result vendor = rep.VendorDetails(vendorID, vendorLocationID, serviceRequestID, searchFrom);
            if (vendor != null)
            {
                vi.VendorAddress1 = vendor.VendorAddress1;
                vi.VendorAddress2 = vendor.VendorAddress2;
                vi.VendorCity = vendor.VendorCity;
                vi.VendorCountry = vendor.VendorCountry;
                vi.VendorDispatchNumber = vendor.VendorDispatchNumber;
                vi.VendorOfficeNumber = vendor.VendorOfficeNumber;
                vi.VendorPostalCode = vendor.VendorPostalCode;
                vi.VendorState = vendor.VendorState;
                vi.VendorEmail = vendor.VendorEmail;
                vi.VendorFaxNumber = vendor.VendorFaxNumber;
                vi.VendorID = vendorID;
                vi.VendorLocationID = vendorLocationID;
                vi.VendorName = vendor.VendorName;
                vi.enrouteMiles = vendor.EnrouteMiles;
            }
            return vi;
        }

        /// <summary>
        /// Gets the vendor call history.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorCallHistory_Result> GetVendorCallHistory(int serviceRequestID, int vendorLocationID)
        {
            var vendorRepository = new VendorRepository();
            return vendorRepository.GetCallHistory(serviceRequestID, vendorLocationID);
        }

        /// <summary>
        /// Gets the vendor notes.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<Comment> GetVendorNotes(int vendorLocationID)
        {
            var commentRepository = new CommentRepository();
            return commentRepository.Get(vendorLocationID, "VendorLocation");
        }

        /// <summary>
        /// Verifies the vendor.
        /// </summary>
        /// <param name="vendorNumber">The vendor number.</param>
        /// <param name="taxID">The tax ID.</param>
        /// <returns></returns>
        public int? VerifyVendor(string vendorNumber, string phoneNumber)
        {
            VendorRepository repository = new VendorRepository();
            return repository.GetVendorIDByNumberAndPhone(vendorNumber, phoneNumber);
        }

        /// <summary>
        /// Determines whether [is vendor registered] [the specified vendor ID].
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns>
        ///   <c>true</c> if [is vendor registered] [the specified vendor ID]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsVendorRegistered(int vendorID)
        {
            VendorRepository repository = new VendorRepository();
            return repository.IsVendorRegistered(vendorID);
        }

        /// <summary>
        /// Registers the vendor.
        /// </summary>
        /// <param name="vendorData">The vendor data.</param>
        public MembershipUser RegisterVendor(aspnet_Users aspNetUser, VendorUser vendorUser, string eventSource, Dictionary<string, string> eventDetails, string user, string sessionID, bool isVendorTransition = false)
        {

            MembershipCreateStatus mcreationStatus = MembershipCreateStatus.Success;
            try
            {
                MembershipUser membershipUser = membershipProvider.Membership.CreateUser(aspNetUser.UserName,
                                                          aspNetUser.aspnet_Membership.Password,
                                                          aspNetUser.aspnet_Membership.Email,
                                                          null,
                                                          null,
                                                          aspNetUser.aspnet_Membership.IsApproved,
                                                          out mcreationStatus);
                switch (mcreationStatus)
                {
                    case MembershipCreateStatus.Success:
                        Roles.AddUserToRoles(aspNetUser.UserName, new string[] { "VendorAdmin" });
                        using (TransactionScope tran = new TransactionScope())
                        {
                            VendorRepository vendorRepository = new VendorRepository();
                            vendorUser.aspnet_UserID = (Guid)membershipUser.ProviderUserKey;
                            vendorUser.ReceiveNotification = true;
                            // 1. Write to VendorUser table.
                            logger.Info("Adding a record to VendorUser");
                            vendorRepository.AddVendorUser(vendorUser, user, false);

                            if (isVendorTransition)
                            {
                                //2. Event Logs.
                                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                                logger.Info("Logging an event to EventLog table");
                                long eventID = eventLogFacade.LogEvent(eventSource, EventNames.TRANSITION_REGISTRATION, eventDetails, user, sessionID);
                                eventLogFacade.CreateRelatedLogLinkRecord(eventID, vendorUser.VendorID, EntityNames.VENDOR);
                                LogContactForVendorTransitionRegistration(vendorUser.VendorID.GetValueOrDefault(), aspNetUser.aspnet_Membership.Email, vendorUser.FirstName, vendorUser.LastName);
                            }
                            else
                            {
                                //2. Event Logs.
                                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                                logger.Info("Logging an event to EventLog table");
                                long eventID = eventLogFacade.LogEvent(eventSource, EventNames.WEB_REGISTRATION, eventDetails, user, sessionID);
                                eventLogFacade.CreateRelatedLogLinkRecord(eventID, vendorUser.VendorID, EntityNames.VENDOR);
                                //eventLogFacade.CreateRelatedLogLinkRecord(eventID, programId, EntityNames.PROGRAM);
                                //eventLogFacade.CreateRelatedLogLinkRecord(eventID, clientId, EntityNames.CLIENT);
                            }
                            tran.Complete();
                        }
                        //TODO: Event logs.
                        return membershipUser;

                    case MembershipCreateStatus.DuplicateUserName:
                        throw new DMSException("That User name already exists");

                    case MembershipCreateStatus.InvalidPassword:
                        throw new DMSException("Password is not in proper format");

                    case MembershipCreateStatus.DuplicateEmail:
                        throw new DMSException("That email address has already been registered.  Please try another email address.");

                    case MembershipCreateStatus.InvalidUserName:
                    case MembershipCreateStatus.InvalidEmail:
                    case MembershipCreateStatus.UserRejected:
                        throw new DMSException(mcreationStatus.ToString());

                    default:
                        throw new DMSException("User Creation Error");

                }
            }
            catch (Exception ex)
            {
                if (mcreationStatus == MembershipCreateStatus.Success)
                    membershipProvider.Membership.DeleteUser(aspNetUser.UserName, true);
                throw ex;
            }
        }

        /// <summary>
        /// Logs the contact for registration.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="email">The email.</param>
        /// <param name="logdata">The logdata.</param>
        /// <param name="firstName">The first name.</param>
        /// <param name="lastName">The last name.</param>
        public void LogContactForRegistration(int vendorID, string email, string firstName, string lastName)
        {
            #region 1. Create contactLog record
            VendorRepository vendorRepository = new VendorRepository();
            var vendor = vendorRepository.GetByID(vendorID);

            if (vendor == null)
            {
                logger.WarnFormat("No vendor found for the id {0}", vendorID);
                throw new DMSException("Vendor not found for the given ID");
            }
            var contactLogRepository = new ContactLogRepository();
            ContactLog contactLog = new ContactLog()
            {
                ContactSourceID = null,
                TalkedTo = null,
                Company = vendor.Name,
                PhoneTypeID = null,
                PhoneNumber = null,
                Email = email,
                Direction = "Outbound",
                Data = string.Format("{0} {1}", firstName, lastName),
                Comments = null,
                Description = "Send Web Registration Authentication Email",
                CreateBy = "system",
                CreateDate = DateTime.Now
            };

            ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
            ContactType systemType = staticDataRepo.GetTypeByName("System");
            if (systemType == null)
            {
                throw new DMSException("Contact Type - System is not set up in the system");
            }

            contactLog.ContactTypeID = systemType.ID;
            ContactMethod contactMethod = staticDataRepo.GetMethodByName("Email");
            if (contactMethod == null)
            {
                throw new DMSException("Contact Method - Email is not set up in the system");
            }
            contactLog.ContactMethodID = contactMethod.ID;

            ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("VendorManagement");
            if (contactCategory == null)
            {
                throw new DMSException("Contact Category - VendorManagement is not set up in the system");
            }

            contactLog.ContactCategoryID = contactCategory.ID;
            string source = "VendorData";

            ContactSource contactSource = staticDataRepo.GetContactSourceByName(source, "VendorManagement");
            if (contactSource == null)
            {
                throw new DMSException(string.Format("Contact Source - {0} for category : VendorManagement is not set up in the system", source));
            }
            contactLog.ContactSourceID = contactSource.ID;

            logger.Info("Saving contact logs");

            contactLogRepository.Save(contactLog, "system");

            #endregion
        }

        /// <summary>
        /// Logs the contact for vendor transition registration.
        /// </summary>
        /// <param name="vendorId">The vendor identifier.</param>
        /// <param name="email">The email.</param>
        /// <param name="firstName">The first name.</param>
        /// <param name="lastName">The last name.</param>
        /// <exception cref="DMSException">
        /// Vendor not found for the given ID
        /// or
        /// Contact Category - VendorPortal is not set up in the system
        /// or
        /// Contact Type - Vendor is not set up in the system
        /// or
        /// Contact Method - Email is not set up in the system
        /// or
        /// Contact Reason - WebsiteRegistrationConfirmation is not set up in the system
        /// or
        /// Contact Action - ProcessedRegistration is not set up in the system
        /// </exception>
        private void LogContactForVendorTransitionRegistration(int vendorId, string email, string firstName, string lastName)
        {
            #region 1. Create contactLog record
            VendorRepository vendorRepository = new VendorRepository();
            var vendor = vendorRepository.GetByID(vendorId);

            if (vendor == null)
            {
                logger.WarnFormat("No vendor found for the id {0}", vendorId);
                throw new DMSException("Vendor not found for the given ID");
            }

            CommonLookUpRepository lookUpRepository = new CommonLookUpRepository();
            ContactCategory contactCategory = lookUpRepository.GetContactCategory("VendorPortal");
            if (contactCategory == null)
            {
                throw new DMSException("Contact Category - VendorPortal is not set up in the system");
            }

            var contactLogRepository = new ContactLogRepository();
            ContactLog contactLog = new ContactLog()
            {
                ContactCategoryID = contactCategory.ID,
                ContactSourceID = null,
                TalkedTo = null,
                Company = vendor.Name,
                PhoneTypeID = null,
                PhoneNumber = null,
                Email = email,
                Direction = "Outbound",
                Comments = null,
                Description = "Website Transition Registration Confirmation",
                CreateBy = "system",
                CreateDate = DateTime.Now,
                ModifyBy = "system",
                ModifyDate = DateTime.Now
            };

            ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
            ContactType systemType = staticDataRepo.GetTypeByName("Vendor");
            if (systemType == null)
            {
                throw new DMSException("Contact Type - Vendor is not set up in the system");
            }

            contactLog.ContactTypeID = systemType.ID;

            ContactMethod contactMethod = staticDataRepo.GetMethodByName("Email");
            if (contactMethod == null)
            {
                throw new DMSException("Contact Method - Email is not set up in the system");
            }
            contactLog.ContactMethodID = contactMethod.ID;

            logger.Info("Saving contact logs");

            #endregion

            #region 2. Create Contact Log Reason record
            ContactLogReason contactLogReason = new ContactLogReason()
            {
                CreateDate = DateTime.Now,
                CreateBy = "system"
            };
            ContactReason reason = staticDataRepo.GetContactReason("WebsiteRegistrationConfirmation", "VendorPortal");
            if (reason == null)
            {
                throw new DMSException("Contact Reason - WebsiteRegistrationConfirmation is not set up in the system");
            }
            contactLogReason.ContactReasonID = reason.ID;
            #endregion

            #region 3. Create Contact Log action record
            ContactLogAction contactLogAction = new ContactLogAction()
            {
                CreateDate = DateTime.Now,
                CreateBy = "system"
            };

            ContactAction contactAction = staticDataRepo.GetContactActionByName("ProcessedRegistration", "VendorPortal");
            if (contactAction == null)
            {
                throw new DMSException("Contact Action - ProcessedRegistration is not set up in the system");
            }
            contactLogAction.ContactActionID = contactAction.ID;
            #endregion

            #region 4. Create Communicate Queue Record
            //CommunicationQueueRepository communication = new CommunicationQueueRepository();
            //Template template = new TemplateRepository().GetTemplateByName(TemplateNames.VENDOR_PORTAL_TRANSITION_REGISTRATION_CONFIRMATION);
            //if (template == null)
            //{
            //    throw new DMSException("Template - TransitionRegistrationConfirmation is not set up in the system");
            //}
            //CommunicationQueue communicationQueque = new CommunicationQueue()
            //{
            //    CreateBy = null,
            //    CreateDate = DateTime.Now,
            //    ScheduledDate = DateTime.Now,
            //    Attempts = null,
            //    MessageText = null,
            //    Subject = template.Subject,
            //    Email = email,
            //    PhoneNumber = null,
            //    MessageData = null,
            //    TemplateID = template.ID,
            //    ContactMethodID = contactMethod.ID


            //};
            #endregion

            #region Save details in Transaction
            // Creating Contact Log
            contactLogRepository.Save(contactLog, "system");

            // Creating Contact Log Reason
            contactLogReason.ContactLogID = contactLog.ID;
            contactLogRepository.CreateContactLogReason(contactLogReason);

            // Creating Contact Log Action
            contactLogAction.ContactLogID = contactLog.ID;
            contactLogRepository.CreateContactLogAction(contactLogAction);

            // Insert Contact Log Link Record
            contactLogRepository.CreateLinkRecord(contactLog.ID, EntityNames.VENDOR, vendorId);

            // Insert Communication Record
            //communicationQueque.ContactLogID = contactLog.ID;
            //communication.Save(communicationQueque);
            #endregion

        }

        /// <summary>
        /// Gets the vendor.
        /// </summary>
        /// <param name="vendorId">The vendor identifier.</param>
        /// <returns></returns>
        public Vendor GetVendor(int vendorId)
        {
            var vendorRepository = new VendorRepository();

            return vendorRepository.GetByID(vendorId);
        }

        public VendorLocation GetVendorLocation(int id)
        {
            var vendorRepository = new VendorRepository();

            return vendorRepository.GetVendorLocationByID(id);
        }

        /// <summary>
        /// Gets the vendor locations list for vendor number.
        /// </summary>
        /// <param name="vendorNumber">The vendor number.</param>
        /// <returns></returns>
        public List<VendorLocationsListForVendorNumber_Result> GetVendorLocationsListForVendorNumber(string vendorNumber)
        {
            var vendorRepository = new VendorRepository();
            return vendorRepository.GetVendorLocationsListForVendorNumber(vendorNumber);
        }

        #endregion

        #region Private Methods
        /// <summary>
        /// Gets the phone entities.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="phoneRepository">The phone repository.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Phone Type - Dispatch is not set up in the system
        /// or
        /// Phone Type - Fax is not set up in the system
        /// or
        /// Phone Type - Office is not set up in the system
        /// </exception>
        private static List<PhoneEntity> GetPhoneEntities(VendorInfo model, PhoneRepository phoneRepository)
        {
            var dispatchType = phoneRepository.GetPhoneTypeByName("Dispatch");
            var faxType = phoneRepository.GetPhoneTypeByName("Fax");
            var officeType = phoneRepository.GetPhoneTypeByName("Office");
            if (dispatchType == null)
            {
                throw new DMSException("Phone Type - Dispatch is not set up in the system");
            }
            if (faxType == null)
            {
                throw new DMSException("Phone Type - Fax is not set up in the system");
            }
            if (officeType == null)
            {
                throw new DMSException("Phone Type - Office is not set up in the system");
            }

            List<PhoneEntity> phones = new List<PhoneEntity>();
            //CR: 1130 - Do not create phone records when the phone number is empty
            if (!string.IsNullOrEmpty(model.VendorDispatchNumber))
            {
                phones.Add(new PhoneEntity() { PhoneNumber = model.VendorDispatchNumber, PhoneTypeID = dispatchType.ID });
            }
            if (!string.IsNullOrEmpty(model.VendorFaxNumber))
            {
                phones.Add(new PhoneEntity() { PhoneNumber = model.VendorFaxNumber, PhoneTypeID = faxType.ID });
            }
            if (!string.IsNullOrEmpty(model.VendorOfficeNumber))
            {
                phones.Add(new PhoneEntity() { PhoneNumber = model.VendorOfficeNumber, PhoneTypeID = officeType.ID });
            }
            return phones;
        }

        /// <summary>
        /// Gets the address entity.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Address type - Business is not set up in the system</exception>
        private static AddressEntity GetAddressEntity(VendorInfo model, string typeOfAddress)
        {
            AddressEntity address = new AddressEntity()
            {
                Line1 = model.VendorAddress1,
                Line2 = model.VendorAddress2,
                City = model.VendorCity,
                StateProvinceID = model.VendorState,
                CountryID = model.VendorCountry,
                PostalCode = model.VendorPostalCode
            };
            CommonLookUpRepository lookupRepo = new CommonLookUpRepository();
            if (model.VendorCountry != null)
            {
                Country country = lookupRepo.GetCountry(model.VendorCountry.Value);
                address.CountryCode = country.ISOCode;
            }
            if (model.VendorState != null)
            {
                StateProvince s = lookupRepo.GetStateProvince(model.VendorState.Value);
                address.StateProvince = s.Abbreviation;
            }
            AddressRepository addressRepo = new AddressRepository();
            var addressType = addressRepo.GetAddressTypeByName(typeOfAddress);
            if (addressType == null)
            {
                throw new DMSException("Address type - Business is not set up in the system");
            }
            address.AddressTypeID = addressType.ID;
            return address;
        }
        #endregion
    }
}