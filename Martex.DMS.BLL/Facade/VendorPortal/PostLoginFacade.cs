using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DAO.VendorPortal;
using Martex.DMS.BLL.Model.VendorPortal;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using log4net;
using System.Transactions;
using Martex.DMS.DAL.Extensions;
using System.Collections;

namespace Martex.DMS.BLL.Facade.VendorPortal
{
    public class PostLoginFacade
    {
        protected static ILog logger = LogManager.GetLogger(typeof(PostLoginFacade));

        public PostLoginPromptModel GetVendorPostLoginDetails(int vendorId)
        {
            var model = new PostLoginPromptModel();
            var addressRepo = new AddressRepository();
            var phoneRepo = new PhoneRepository();

            var vendorPhoneNumbersList = new List<PostLoginVendorPhoneNumber>();
            var addressList = addressRepo.GetAddresses(vendorId, EntityNames.VENDOR);
            model.BillingAddress = addressList.FirstOrDefault(a => a.AddressType.Name == AddressTypeNames.BILLING);
            model.BusinessAddress = addressList.FirstOrDefault(a => a.AddressType.Name == AddressTypeNames.Business);

            var phoneList = phoneRepo.Get(vendorId, EntityNames.VENDOR);
            model.OfficePhone = phoneList.FirstOrDefault(a => a.PhoneType.Name == PhoneTypeNames.Office);

            var repository = new PostLoginRepository();
            var phoneNumbersList = repository.GetVendorPhoneNumbers(vendorId);

            var dispatchPhoneType = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).FirstOrDefault(x => x.Name == PhoneTypeNames.Dispatch);
            var faxPhoneType = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).FirstOrDefault(x => x.Name == PhoneTypeNames.Fax);

            if (dispatchPhoneType != null)
            {
                int dispatchPhoneTypeId = dispatchPhoneType.ID;
                if (faxPhoneType != null)
                {
                    int faxPhoneTypeId = faxPhoneType.ID;
                    int vendorLocaitonEntityTypeId = ReferenceDataRepository.GetEntityByName(EntityNames.VENDOR_LOCATION).ID;
                    foreach (PostLogin_VendorPhoneNumbers_Result phoneObj in phoneNumbersList)
                    {
                        var vendorPhoneNumber = new PostLoginVendorPhoneNumber();
                        vendorPhoneNumber.VendorLocationId = phoneObj.VendorLocationId;

                        var dispatch = new PhoneEntity();
                        dispatch.PhoneTypeID = dispatchPhoneTypeId;
                        dispatch.EntityID = vendorLocaitonEntityTypeId;
                        if (phoneObj.DispatchId.HasValue)
                        {
                            dispatch.RecordID = phoneObj.VendorLocationId;
                            dispatch.PhoneNumber = phoneObj.DispatchPhoneNumber;
                            dispatch.ID = phoneObj.DispatchId.Value;

                        }
                        vendorPhoneNumber.Dispatch = dispatch;

                        var fax = new PhoneEntity();
                        fax.PhoneTypeID = faxPhoneTypeId;
                        fax.EntityID = vendorLocaitonEntityTypeId;
                        if (phoneObj.FaxId.HasValue)
                        {
                            fax.RecordID = phoneObj.VendorLocationId;
                            fax.PhoneNumber = phoneObj.Fax;
                            fax.ID = phoneObj.FaxId.Value;

                        }
                        vendorPhoneNumber.Fax = fax;
                        vendorPhoneNumber.LocationAddress = phoneObj.LocationAddress;
                        vendorPhoneNumbersList.Add(vendorPhoneNumber);
                    }
                }
            }
            model.VendorPhoneNumbers = vendorPhoneNumbersList;

            return model;
        }

        /// <summary>
        /// Fills the address entity with Country code, state province abbreviation and address type
        /// </summary>
        /// <param name="address">The address.</param>
        /// <param name="addressType">Type of the address.</param>
        private static void FillAddressEntity(AddressEntity address, string addressType)
        {
            var lookupRepo = new CommonLookUpRepository();
            if (address.CountryID != null)
            {
                Country country = lookupRepo.GetCountry(address.CountryID.Value);
                address.CountryCode = country.ISOCode;
            }
            if (address.StateProvinceID != null)
            {
                StateProvince s = lookupRepo.GetStateProvince(address.StateProvinceID.Value);
                address.StateProvince = s.Abbreviation;
            }
            var addressRepo = new AddressRepository();
            var addressTypeFromDb = addressRepo.GetAddressTypeByName(addressType);
            if (addressTypeFromDb == null)
            {
                throw new DMSException(string.Format("Address type - {0} is not set up in the system", addressType));
            }
            address.AddressTypeID = addressTypeFromDb.ID;

        }

        /// <summary>
        /// Gets the phone entity.
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
        /// <param name="phoneType">Type of the phone.</param>
        /// <returns></returns>
        private static PhoneEntity GetPhoneEntity(string phoneNumber, string phoneType)
        {
            var phoneRepository = new PhoneRepository();

            var phoneTypeFromDb = phoneRepository.GetPhoneTypeByName(phoneType);

            if (phoneTypeFromDb == null)
            {
                throw new DMSException(string.Format("Phone Type - {0} is not set up in the system", phoneType));
            }

            PhoneEntity phone = null;
            //CR: 1130 - Do not create phone records when the phone number is empty
            if (!string.IsNullOrEmpty(phoneNumber))
            {
                phone = new PhoneEntity() { PhoneNumber = phoneNumber, PhoneTypeID = phoneTypeFromDb.ID };
            }
            return phone;
        }

        public void SavePostLoginValues(PostLoginPromptModel application, int vendorID, string currentUser, string eventSource, string sessionID, int? vendorUserID, Guid userID)
        {
            using (var tran = new TransactionScope())
            {
                var repository = new VendorApplicationRepository();

                #region 1. Updating Vendor Details
                VendorUser vendorUser = new VendorUser();
                vendorUser.ID = vendorUserID.GetValueOrDefault();
                vendorUser.FirstName = application.ContactFirstName;
                vendorUser.LastName = application.ContactLastName;
                repository.UpdateVendorUser(vendorID, currentUser, vendorUser);

                Vendor vendor = new Vendor();
                vendor.ID = vendorID;
                vendor.ContactFirstName = application.ContactFirstName;
                vendor.ContactLastName = application.ContactLastName;
                vendor.Email = application.Email;
                repository.UpdateVendorDetails(currentUser, vendor);

                repository.UpdateMembershipEmail(userID, application.Email);
                #endregion

                #region 2. Saving Addresses
                var addressFacade = new AddressFacade();
                List<AddressEntity> vaAddresses = new List<AddressEntity>();

                #region 1. Saving/Updating Billing Address
                FillAddressEntity(application.BillingAddress, AddressTypeNames.BILLING);
                vaAddresses.Add(application.BillingAddress);
                logger.InfoFormat("Updating Billing Address Entity for Vendor {0}", vendorID);

                if (application.BillingAddress.ID > 0)
                {
                    addressFacade.SaveAddresses(vendorID, EntityNames.VENDOR, currentUser, vaAddresses, AddressFacade.EDIT);
                }
                else
                {
                    addressFacade.SaveAddresses(vendorID, EntityNames.VENDOR, currentUser, vaAddresses, AddressFacade.ADD);
                }
                #endregion

                #region 2. Saving/Updating Business Address
                vaAddresses.Clear();
                FillAddressEntity(application.BusinessAddress, AddressTypeNames.Business);
                vaAddresses.Add(application.BusinessAddress);
                logger.InfoFormat("Updating Business Address Entity for Vendor {0}", vendorID);
                if (application.BusinessAddress.ID > 0)
                {
                    addressFacade.SaveAddresses(vendorID, EntityNames.VENDOR, currentUser, vaAddresses, AddressFacade.EDIT);
                }
                else
                {
                    addressFacade.SaveAddresses(vendorID, EntityNames.VENDOR, currentUser, vaAddresses, AddressFacade.ADD);
                }
                #endregion

                #endregion

                #region 3. Saving Phones
                var phoneFacade = new PhoneFacade();
                var phoneDispatchEntities = new List<PhoneEntity>();
                var phoneFaxEntities = new List<PhoneEntity>();
                var phoneOfficeEntities = new List<PhoneEntity>();

                #region 1. Saving/Updating Office Phone

                var officePhone = GetPhoneEntity(application.OfficePhone.PhoneNumber, PhoneTypeNames.Office);
                officePhone.ID = application.OfficePhone.ID;
                phoneOfficeEntities.Add(officePhone);
                if (application.OfficePhone.ID > 0)
                {
                    phoneFacade.SavePhoneDetails(vendorID, EntityNames.VENDOR, currentUser, phoneOfficeEntities, PhoneFacade.EDIT);
                }
                else
                {
                    phoneFacade.SavePhoneDetails(vendorID, EntityNames.VENDOR, currentUser, phoneOfficeEntities, PhoneFacade.ADD);
                }

                #endregion

                #region 2. Saving/Updating Dispatch/Fax of VendorLocations
                if (application.VendorPhoneNumbers != null)
                {
                    foreach (PostLoginVendorPhoneNumber phoneObj in application.VendorPhoneNumbers)
                    {
                        phoneDispatchEntities = new List<PhoneEntity>();
                        var dispatchPhone = GetPhoneEntity(phoneObj.Dispatch.PhoneNumber, PhoneTypeNames.Dispatch);
                        dispatchPhone.ID = phoneObj.Dispatch.ID;
                        phoneDispatchEntities.Add(dispatchPhone);
                        if (phoneObj.Dispatch.ID > 0)
                        {
                            phoneFacade.SavePhoneDetails(phoneObj.VendorLocationId, EntityNames.VENDOR_LOCATION, currentUser, phoneDispatchEntities, PhoneFacade.EDIT);
                        }
                        else
                        {
                            phoneFacade.SavePhoneDetails(phoneObj.VendorLocationId, EntityNames.VENDOR_LOCATION, currentUser, phoneDispatchEntities, PhoneFacade.ADD);
                        }

                        phoneFaxEntities = new List<PhoneEntity>();
                        var faxPhone = GetPhoneEntity(phoneObj.Fax.PhoneNumber, PhoneTypeNames.Fax);
                        faxPhone.ID = phoneObj.Fax.ID;
                        phoneFaxEntities.Add(faxPhone);
                        if (phoneObj.Fax.ID > 0)
                        {
                            phoneFacade.SavePhoneDetails(phoneObj.VendorLocationId, EntityNames.VENDOR_LOCATION, currentUser, phoneFaxEntities, PhoneFacade.EDIT);
                        }
                        else
                        {
                            phoneFacade.SavePhoneDetails(phoneObj.VendorLocationId, EntityNames.VENDOR_LOCATION, currentUser, phoneFaxEntities, PhoneFacade.ADD);
                        }
                    }
                }
                #endregion

                #endregion

                #region 4. Logging Event
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.INITIAL_LOGIN_VERIFY_DATA, "Initial Login Verify Data", currentUser, vendorID, EntityNames.VENDOR, sessionID);
                #endregion

                tran.Complete();
            }
        }

        /// <summary>
        /// Submits the sign new contracts.
        /// </summary>
        /// <param name="newContractName">New name of the contract.</param>
        /// <param name="newContractTitle">The new contract title.</param>
        /// <param name="newContractDate">The new contract date.</param>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionID">The session identifier.</param>
        /// <exception cref="DMSException">
        /// Source System- VendorPortal not setup in the system.
        /// or
        /// VendorTermsAgreement- PPS201603.pdf not setup in the system.
        /// </exception>
        public void SubmitSignNewContracts(string newContractName, string newContractTitle, DateTime? newContractDate, int vendorID, int vendorUserID, string currentUser, string eventSource, string sessionID)
        {
            using (var tran = new TransactionScope())
            {
                VendorManagementRepository repository = new VendorManagementRepository();
                VendorManagementFacade facade = new VendorManagementFacade();

                SourceSystem sourceSystem = repository.GetSourceSystem("VendorPortal");
                if (sourceSystem == null)
                {
                    throw new DMSException("Source System- VendorPortal not setup in the system.");
                }
                VendorTermsAgreement vendorTermsAgreement = ReferenceDataRepository.GetVendorTermAgreementByName("Pinnacle-Partners-Solutions_SPA_v032016.pdf");
                if (vendorTermsAgreement == null)
                {
                    throw new DMSException("VendorTermsAgreement- Pinnacle-Partners-Solutions_SPA_v032016.pdf not setup in the system.");
                }
                #region 1.Insert Contract
                Contract contract = new Contract()
                {
                    VendorID = vendorID,
                    ContractStatusID = facade.GetContractStatusID(ContractStatusNames.ACTIVE),
                    SourceSystemID = sourceSystem.ID,
                    VendorTermsAgreementID = vendorTermsAgreement.ID,
                    SignedDate = newContractDate,
                    SignedBy = newContractName,
                    SignedByTitle = newContractTitle,
                    StartDate = DateTime.Now.Date,
                    IsActive = true,
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now
                };
                repository.SaveContract(contract);
                #endregion

                #region 2. Insert ContractRateSchedule And ContractRateScheduleProducts
                repository.InsertRateScheduleAndRatesForContract(contract.ID);
                #endregion

                #region 3. Logging Event
                Hashtable ht = new Hashtable();
                ht.Add("Name", newContractName);
                ht.Add("Title", newContractTitle);
                ht.Add("Date", newContractDate);
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.SIGNED_PINNACLE_CONTRACT, "Signed Pinnacle Contract", ht.GetMessageData(), currentUser, vendorID, EntityNames.VENDOR, sessionID);
                #endregion

                #region 4.Update VendorUser
                VendorApplicationRepository appRepo = new VendorApplicationRepository();
                PostLoginPrompt prompt = new ReferenceDataRepository().GetPostLoginPromptByName(PostLoginPromptNames.SOFTWARE_ZIP_CODES);
                int? promptID = null;
                if (prompt != null)
                {
                    promptID = prompt.ID;
                }
                appRepo.UpdateVendorUserPostLoginPromptID(vendorUserID, promptID, currentUser);
                #endregion
                tran.Complete();
            }
        }


        /// <summary>
        /// Submits the vendors software zip codes.
        /// </summary>
        /// <param name="dispatchSoftwareProductID">The dispatch software product identifier.</param>
        /// <param name="dispatchSoftwareProductOther">The dispatch software product other.</param>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <param name="vendorUserID">The vendor user identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionID">The session identifier.</param>
        public void SubmitVendorsSoftwareZipCodes(Vendor vendor, int vendorUserID, string currentUser, string eventSource, string sessionID)
        {
            using (var tran = new TransactionScope())
            {
                #region 1. Update Vendor
                VendorApplicationRepository repository = new VendorApplicationRepository();
                repository.UpdateVendorProductDetails(vendor, currentUser);
                #endregion
                #region 2. Logging Event
                Hashtable ht = new Hashtable();
                ht.Add("DispatchSoftwareProductID", vendor.DispatchSoftwareProductID);
                ht.Add("DispatchSoftwareProductOther", vendor.DispatchSoftwareProductOther);
                ht.Add("DriverSoftwareProductID", vendor.DriverSoftwareProductID);
                ht.Add("DriverSoftwareProductOther", vendor.DriverSoftwareProductOther);
                ht.Add("DispatchGPSNetworkID", vendor.DispatchGPSNetworkID);
                ht.Add("DispatchGPSNetworkOther", vendor.DispatchGPSNetworkOther);
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.SOFTWARE_ZIP_CODES_PROMPT, "Software Zip Codes Prompt", ht.GetMessageData(), currentUser, vendor.ID, EntityNames.VENDOR, sessionID);
                #endregion
                #region 3.Update VendorUser
                repository.UpdateVendorUserPostLoginPromptID(vendorUserID, null, currentUser);
                #endregion
                tran.Complete();
            }
        }


        /// <summary>
        /// Gets the latest contract and TA(Terms & Agreements) for vendor.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <returns></returns>
        public LatestContractAndTAForVendor_Result GetLatestContractAndTAForVendor(int vendorID)
        {
            PostLoginRepository repo = new PostLoginRepository();
            return repo.GetLatestContractAndTAForVendor(vendorID);
        }
    }
}
