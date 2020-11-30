using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using System.Transactions;
using Martex.DMS.Areas.Application.Models;
using log4net;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade.VendorManagement.VendorBase;
namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Vendor Management Facade
    /// </summary>
    public partial class VendorManagementFacade : VendorManagement_Base
    {

        #region Public Methods
        /// <summary>
        /// Searches the specified criteria.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<VendorManagementList_Result> Search(PageCriteria criteria)
        {
            return repository.Search(criteria);
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
            return repository.GetVendorMatch(pageCriteria, DispatchNum, OfficeNum, vendorName);
        }

        /// <summary>
        /// Gets the vendor summary location rates.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <returns></returns>
        public List<VendorSummaryLocationRates_Result> GetVendorSummaryLocationRates(PageCriteria pageCriteria, int vendorID)
        {
            return repository.GetVendorSummaryLocationRates(pageCriteria, vendorID);
        }

        /// <summary>
        /// Gets the contract status.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <returns></returns>
        public string GetContractStatus(int vendorID)
        {
            string contractStatus = repository.GetVendorContractStatus(vendorID);
            return contractStatus;
        }

        /// <summary>
        /// Gets the vendor indicators.
        /// </summary>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="recordID">The record unique identifier.</param>
        /// <returns></returns>
        public string GetVendorIndicators(string entityName, int recordID)
        {
            return repository.GetVendorIndicators(entityName, recordID);
        }

        /// <summary>
        /// Gets the is vendor coach net dealer partner.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <returns></returns>
        public bool GetIsVendorCoachNetDealerPartner(int vendorID)
        {
            return repository.GetIsVendorCoachNetDealerPartner(vendorID);
        }

        /// <summary>
        /// Gets the vendor contract status.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public int? GetVendorContractStatus(int vendorID)
        {
            ContractStatu contractStaus = repository.GetVendorContractStatusID(vendorID);
            if (contractStaus == null)
            {
                return null;
            }
            return contractStaus.ID;
        }

        /// <summary>
        /// Adds the vendor.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="relatedRecord">The related record.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionId">The session id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Vendor location type - Physical is not set up in the system
        /// or
        /// Contact Type - Vendor is not set up in the system
        /// or
        /// Contact Category - VendorManagement is not set up in the system
        /// or
        /// ContactReason - SubmitApplication is not set up for category - VendorManagement
        /// </exception>
        public VendorInfo AddVendor(VendorInfo model, string eventSource, int? relatedRecord, string currentUser, string sessionId)
        {
            var addressFacade = new AddressFacade();
            var phoneFacade = new PhoneFacade();
            var lookUpRepo = new CommonLookUpRepository();
            VendorRegion region = null;

            using (TransactionScope tran = new TransactionScope())
            {
                #region 0. Get the Vendor Region Associated with this Address
                if (model.VendorState.HasValue)
                {
                    region = lookUpRepo.GetVendorRegionByStateID(model.VendorState.Value);
                }
                else
                {
                    throw new DMSException(string.Format("State selection is required"));
                }
                #endregion

                #region 1. Add Vendor
                Vendor v = new Vendor()
                {
                    Name = model.VendorName,
                    AdministrativeRating = 20,
                    //KB: Column dropped as per Tim's latest changes for VendorApplication
                    //ApplicationDate = model.VendorDateApplication,
                    Email = model.VendorEmail,
                    // Sanghi : TFS Request 1529 Set Is Active to True
                    IsActive = true,
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    //NP: Taken StateID into VendorNumber, because in the Model there is no variable to assign StateID.
                    VendorNumber = model.VendorState.ToString(),
                    VendorRegionID = region.ID
                };

                logger.Info("Adding Vendor");

                model.vendorNumber = repository.AddVendor(v);
                int vendorId = v.ID;
                model.VendorID = vendorId;
                #endregion

                #region 2. Add Vendor Status Log
                VendorStatusLog vsl = new VendorStatusLog()
                {
                    VendorID = vendorId,
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    VendorStatusReasonID = null
                };

                logger.Info("Adding Vendor Status Log");
                repository.AddVendorStatusLog(vsl);
                #endregion

                #region 3. Add Address Entity
                List<AddressEntity> vendorOfficeAddresses = new List<AddressEntity>();
                // Sanghi : TFS Request 1529 use Business instead of office
                AddressEntity vendorBusinessAddress = GetAddressEntity(model, "Business");
                AddressEntity vendorBillingAddress = GetAddressEntity(model, "Billing");
                vendorOfficeAddresses.Add(vendorBusinessAddress);
                vendorOfficeAddresses.Add(vendorBillingAddress);
                logger.Info("Adding Address Entities - Business and Billing");

                addressFacade.SaveAddresses(vendorId, EntityNames.VENDOR, currentUser, vendorOfficeAddresses, AddressFacade.ADD);
                #endregion

                #region 4. Add Phone Entity
                PhoneEntity vendorOfficePhone = GetPhoneEntity(model.VendorOfficeNumber, "Office");
                logger.Info("Adding Phone Entity");

                List<PhoneEntity> vendorOfficePhones = new List<PhoneEntity>();
                vendorOfficePhones.Add(vendorOfficePhone);
                phoneFacade.SavePhoneDetails(vendorId, EntityNames.VENDOR, currentUser, vendorOfficePhones, PhoneFacade.ADD);
                #endregion

                #region 5,6,7. Add Vendor Location,Address Entity,Phone Entity
                if (model.VendorIsDispatchOrServiceLocation == true)
                {
                    LatitudeLongitude latLong = AddressFacade.GetLatLong(string.Join(",", model.VendorAddress1, model.VendorAddress2, model.VendorAddress3), model.VendorCity, vendorBusinessAddress.StateProvince, model.VendorPostalCode, vendorBusinessAddress.CountryCode);
                    #region 5. Add Vendor Location
                    VendorLocation vlc = new VendorLocation()
                    {
                        VendorID = vendorId,
                        CreateBy = currentUser,
                        CreateDate = DateTime.Now,
                        Latitude = latLong.Latitude,
                        Longitude = latLong.Longitude,
                        IsActive = true
                    };
                    VendorRepository vendorRepo = new VendorRepository();

                    var vendorLocationStatus = vendorRepo.GetVendorLocationStatus("Pending");
                    if (vendorLocationStatus == null)
                    {
                        throw new DMSException("VendorLocationStatus - Pending is not set up in the system");
                    }
                    vlc.VendorLocationStatusID = vendorLocationStatus.ID;

                    //TODO: Fix VendorLocationType
                    repository.AddVendorLocation(vlc);
                    logger.InfoFormat("Updating Geography type for VL {0}", vlc.ID);
                    var addressRepo = new AddressRepository();
                    addressRepo.UpdateGeographyType(vlc.ID, EntityNames.VENDOR_LOCATION);
                    #endregion

                    #region 6. Add Vendor Location Address Entity
                    AddressEntity dispatchAddressEntity = GetAddressEntity(model, "Business");
                    List<AddressEntity> dispatchAddresses = new List<AddressEntity>();
                    dispatchAddresses.Add(dispatchAddressEntity);
                    logger.Info("Adding Vendor Location Address Entity for Business");
                    addressFacade.SaveAddresses(vlc.ID, EntityNames.VENDOR_LOCATION, currentUser, dispatchAddresses, AddressFacade.ADD);
                    #endregion

                    #region 7. Add Vendor Location Phone Entity
                    //TFS : 1689 - No Phone details to be inserted for VendorLocation.
                    //PhoneEntity dispatchOfficePhone = GetPhoneEntity(model.VendorOfficeNumber, "Office");
                    //logger.Info("Adding Phone Entity");

                    //List<PhoneEntity> dispatchOfficePhones = new List<PhoneEntity>();
                    //dispatchOfficePhones.Add(dispatchOfficePhone);
                    //phoneFacade.SavePhoneDetails(vendorId, EntityNames.VENDOR_LOCATION, currentUser, dispatchOfficePhones, PhoneFacade.ADD);
                    #endregion
                }
                #endregion

                #region 8. Create ContactLog and Link record

                var contactLogRepository = new ContactLogRepository();

                ContactLog contactLog = new ContactLog()
                {
                    ContactSourceID = null,
                    ContactMethodID = int.Parse(model.VendorSource),
                    Company = model.VendorName,
                    Email = model.VendorEmail,
                    PhoneTypeID = null,
                    Direction = "Inbound",
                    Description = "Enter Vendor Application",
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    ModifyBy = currentUser,
                    ModifyDate = DateTime.Now
                };

                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactType vendorType = staticDataRepo.GetTypeByName("Vendor");
                if (vendorType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }

                contactLog.ContactTypeID = vendorType.ID;


                ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("VendorManagement");
                if (contactCategory == null)
                {
                    throw new DMSException("Contact Category - VendorManagement is not set up in the system");
                }

                contactLog.ContactCategoryID = contactCategory.ID;

                contactLogRepository.Save(contactLog, currentUser, relatedRecord, EntityNames.VENDOR);

                #endregion

                #region 9. Create a contactLogReason record

                ContactLogReasonRepository contactLogReasonRepo = new ContactLogReasonRepository();
                ContactLogReason reason = new ContactLogReason()
                {
                    ContactLogID = contactLog.ID
                };

                ContactReason contactReason = staticDataRepo.GetContactReason("SubmitApplication", "VendorManagement");
                if (contactReason == null)
                {
                    throw new DMSException("ContactReason - SubmitApplication is not set up for category - VendorManagement");
                }
                reason.ContactReasonID = contactReason.ID;

                contactLogReasonRepo.Save(reason, currentUser);

                #endregion

                #region 10. Create a contactLogAction record.

                ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                ContactLogAction logAction = new ContactLogAction()
                {
                    ContactLogID = contactLog.ID

                };
                ContactAction contactAction = staticDataRepo.GetContactActionByName("ReceivedApplication", "VendorManagement");
                logAction.ContactActionID = contactAction.ID;
                logActionRepo.Save(logAction, currentUser);

                #endregion

                tran.Complete();
            }
            return model;
        }


        #region Vendor ACH Section
        /// <summary>
        /// Updates the vendor information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void UpdateVendorACHInformation(VendorACHModel model, string userName)
        {
            VendorACH vedorACH = model.VendorACHDetails;
            vedorACH.VendorID = model.VendorID;

            #region Fill Country and State
            var lookUP = new CommonLookUpRepository();
            if (model.VendorACHDetails.BankAddressCountryID.HasValue)
            {
                model.VendorACHDetails.BankAddressCountryCode = lookUP.GetCountry(model.VendorACHDetails.BankAddressCountryID.Value).ISOCode;
            }
            if (model.VendorACHDetails.BankAddressStateProvinceID.HasValue)
            {
                model.VendorACHDetails.BankAddressStateProvince = lookUP.GetStateProvince(model.VendorACHDetails.BankAddressStateProvinceID.Value).Abbreviation;
            }
            #endregion

            logger.InfoFormat("Trying to save Vendor ACH Details for the Vendor ID {0}", vedorACH.VendorID);
            repository.SaveVendoACHDetails(vedorACH, userName);
            logger.InfoFormat("Saved successfully Vendor ACH Details for the Vendor ID {0}", vedorACH.VendorID);

        }

        /// <summary>
        /// Gets the vendor ACH details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorACHModel GetVendorACHDetails(int vendorID)
        {
            VendorACHModel model = new VendorACHModel();
            var vendorRepository = new VendorManagementRepository();
            var commonRepository = new CommonLookUpRepository();
            model.VendorID = vendorID;

            #region Retrieve Vendor ACH Information
            logger.InfoFormat("Trying to retrieve Vendor ACH Details for the ID {0}", vendorID);
            model.VendorACHDetails = vendorRepository.GetVendorACHDetails(vendorID);
            logger.InfoFormat("Retrieve Vendor ACH Details finished and found {0} records", model.VendorACHDetails == null ? 0 : 1);
            #endregion

            #region If no record found it's a new Record
            if (model.VendorACHDetails == null)
            {
                model.VendorACHDetails = new VendorACH();
            }
            #endregion

            #region Get the Source System Name if it's exists
            if (model.VendorACHDetails.SourceSystemID.HasValue)
            {
                model.SourceSystemName = commonRepository.GetSourceSystem(model.VendorACHDetails.SourceSystemID.Value).Description;
            }
            #endregion

            return model;
        }

        #endregion



        #region Vendor Locations
        /// <summary>
        /// Gets the vendor locations.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorLocations_Result> GetVendorLocations(PageCriteria pageCriteria, int? vendorID, bool isVendorDetails = false)
        {
            return repository.GetVendorLocations(pageCriteria, vendorID, isVendorDetails);

        }

        /// <summary>
        /// Deletes the vendor location.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        public void DeleteVendorLocation(int vendorLocationID)
        {
            repository.DeleteVendorLocation(vendorLocationID);
        }

        /// <summary>
        /// Gets the vendor location address.
        /// </summary>
        /// <param name="vendorLocatioID">The vendor location ID.</param>
        /// <returns></returns>
        public VendorLocationModel GetVendorLocationAddress(int vendorLocationID)
        {
            VendorLocationModel vla = new VendorLocationModel();
            VendorLocationAddress_Result Add = repository.GetVendorLocationAddress(vendorLocationID);
            vla.LocationAddress1 = Add.LocationAddress1;
            vla.LocationAddress2 = Add.LocationAddress2;
            vla.LocationAddress3 = Add.LocationAddress3;
            vla.LocationCity = Add.LocationCity;
            vla.LocationCountry = Add.LocationCountry;
            vla.LocationDispatchNumber = Add.LocationDispatchNumber;
            vla.LocationFaxNumber = Add.LocationFaxNumber;
            vla.LocationPostalCode = Add.LocationPostalCode;
            vla.LocationState = Add.LocationState;

            vla.LocationStateValue = repository.GetStateName(Add.LocationState);
            return vla;
        }

        /// <summary>
        /// Saves the vendor location address.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="vendorId">The vendor id.</param>
        /// <param name="currentUser">The current user.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Vendor location type - Physical is not set up in the system
        /// or
        /// Vendor location status - Pending is not set up in the system
        /// </exception>
        public int SaveVendorLocationAddress(VendorLocationModel model, int vendorId, string currentUser)
        {
            var addressFacade = new AddressFacade();
            var phoneFacade = new PhoneFacade();
            using (TransactionScope tran = new TransactionScope())
            {
                string countryCode = "";
                string stateProvince = "";
                CommonLookUpRepository lookupRepo = new CommonLookUpRepository();
                if (model.LocationCountry != null)
                {
                    Country country = lookupRepo.GetCountry(model.LocationCountry.Value);
                    countryCode = country.ISOCode;
                }
                if (model.LocationState != null)
                {
                    StateProvince s = lookupRepo.GetStateProvince(model.LocationState.Value);
                    stateProvince = s.Abbreviation;
                }

                //string stateCode=
                LatitudeLongitude latLong = AddressFacade.GetLatLong(string.Join(",", model.LocationAddress1, model.LocationAddress2, model.LocationAddress3), model.LocationCity, stateProvince, model.LocationPostalCode, countryCode);
                #region 1. Add Vendor Location
                VendorLocation vlc = new VendorLocation()
                {
                    VendorID = vendorId,
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    Latitude = latLong.Latitude,
                    Longitude = latLong.Longitude,
                    IsActive = true
                };

                VendorRepository vendorRepo = new VendorRepository();
                //TODO: Fix VendorLocationType
                VendorLocationStatu vls = vendorRepo.GetVendorLocationStatus("Pending");
                if (vls == null)
                {
                    throw new DMSException("Vendor location status - Pending is not set up in the system");
                }
                vlc.VendorLocationStatusID = vls.ID;
                repository.AddVendorLocation(vlc);
                int VendorLocationID = vlc.ID;

                var addressRepo = new AddressRepository();
                addressRepo.UpdateGeographyType(VendorLocationID, EntityNames.VENDOR_LOCATION);

                #endregion

                #region 2. Add Vendor Location Address Entity
                VendorInfo VIModel = new VendorInfo()
                {
                    VendorAddress1 = model.LocationAddress1,
                    VendorAddress2 = model.LocationAddress2,
                    VendorAddress3 = model.LocationAddress3,
                    VendorCity = model.LocationCity,
                    VendorState = model.LocationState,
                    VendorCountry = model.LocationCountry,
                    VendorPostalCode = model.LocationPostalCode

                };
                AddressEntity businessAddressEntity = GetAddressEntity(VIModel, "Business");
                List<AddressEntity> businessAddresses = new List<AddressEntity>();
                businessAddresses.Add(businessAddressEntity);
                logger.Info("Adding Vendor Location Address Entity");
                addressFacade.SaveAddresses(vlc.ID, EntityNames.VENDOR_LOCATION, currentUser, businessAddresses, AddressFacade.ADD);
                #endregion

                #region 3. Add Vendor Location Phone Entity
                PhoneEntity dispatchPhone = GetPhoneEntity(model.LocationDispatchNumber, "Dispatch");
                PhoneEntity faxPhone = GetPhoneEntity(model.LocationFaxNumber, "Fax");
                logger.Info("Adding Phone Entity");

                List<PhoneEntity> businessOfficePhones = new List<PhoneEntity>();
                businessOfficePhones.Add(dispatchPhone);
                businessOfficePhones.Add(faxPhone);
                phoneFacade.SavePhoneDetails(VendorLocationID, EntityNames.VENDOR_LOCATION, currentUser, businessOfficePhones, PhoneFacade.ADD);
                #endregion

                addressRepo.UpdateGeographyType(vlc.ID, EntityNames.VENDOR_LOCATION);

                tran.Complete();

                return VendorLocationID;
            }

        }

        /// <summary>
        /// Gets the vendor locations list.
        /// </summary>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorLocationsList_Result> GetVendorLocationsList(int VendorID)
        {
            return repository.GetVendorLocationsList(VendorID);
        }
        #endregion

        /// <summary>
        /// Gets the vendor user.
        /// </summary>
        /// <param name="aspnetUserID">The aspnet user ID.</param>
        /// <returns></returns>
        public VendorUser GetVendorUser(Guid aspnetUserID)
        {
            return repository.GetVendorUser(aspnetUserID);
        }

        #region Vendor PO
        /// <summary>
        /// Gets the vendor PO details.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorPOList_Result> GetVendorPODetails(PageCriteria pageCriteria, int VendorID)
        {
            return repository.GetVendorPODetails(pageCriteria, VendorID);
        }
        #endregion

        #region Vendor Location PO

        /// <summary>
        /// Gets the vendor location PO details.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationPOList_Result> GetVendorLocationPODetails(PageCriteria pageCriteria, int VendorLocationID)
        {
            return repository.GetVendorLocationPODetails(pageCriteria, VendorLocationID);
        }
        #endregion

        #region Vendor Activity
        /// <summary>
        /// Gets the vendor activity list.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<VendorActivityList_Result> GetVendorActivityList(int? vendorID, PageCriteria pc)
        {
            return repository.GetVendorActivityList(vendorID, pc);
        }

        /// <summary>
        /// Saves the vendor activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="currentuser">The current user.</param>
        public void SaveVendorActivityComments(int CommentType, string Comments, int vendorID, string currentuser)
        {
            Comment comment = new Comment();
            comment.RecordID = vendorID;
            comment.CommentTypeID = CommentType;
            comment.Description = Comments;
            comment.CreateBy = currentuser;
            comment.CreateDate = DateTime.Now;
            repository.SaveVendorActivityComments(comment);
        }

        public void SaveVendorActivityContact(Activity_AddContact model, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactLogRepository contactRepository = new ContactLogRepository();
                VendorInvoiceRepository vendorInvoiceRepo = new VendorInvoiceRepository();
                string direction = "";
                if (model.IsInbound)
                {
                    direction = "Inbound";
                }
                else
                {
                    direction = "Outbound";
                }
                ContactType contactType = staticDataRepo.GetTypeByName("Vendor");
                if (contactType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }
                ContactLog contactLog = new ContactLog();
                contactLog.ContactCategoryID = model.ContactCategory;
                contactLog.ContactTypeID = contactType.ID;
                contactLog.ContactMethodID = model.ContactMethod;
                contactLog.TalkedTo = model.TalkedTo;
                contactLog.PhoneNumber = model.PhoneNumber;
                if (model.PhoneNumberType > 0)
                {
                    contactLog.PhoneTypeID = model.PhoneNumberType;
                }
                contactLog.Email = model.Email;
                contactLog.Direction = direction;
                contactLog.Description = "Vendor Management";
                contactLog.Comments = model.Notes;
                contactLog.CreateBy = currentUser;
                contactLog.CreateDate = DateTime.Now;

                vendorInvoiceRepo.SaveContactLog(contactLog);
                int contactLogID = contactLog.ID;
                foreach (var reasonRecord in model.ContactReasonID)
                {
                    ContactLogReason contactLogReason = new ContactLogReason();
                    contactLogReason.ContactLogID = contactLogID;
                    if (reasonRecord.HasValue)
                    {
                        contactLogReason.ContactReasonID = reasonRecord.GetValueOrDefault();
                    }
                    contactLogReason.CreateBy = currentUser;
                    contactLogReason.CreateDate = DateTime.Now;
                    vendorInvoiceRepo.SaveContactLogReason(contactLogReason);
                }

                foreach (var actionRecord in model.ContactActionID)
                {
                    ContactLogAction contactLogAction = new ContactLogAction();
                    contactLogAction.ContactLogID = contactLogID;
                    if (actionRecord.HasValue)
                    {
                        contactLogAction.ContactActionID = actionRecord.GetValueOrDefault();
                    }
                    contactLogAction.CreateBy = currentUser;
                    contactLogAction.CreateDate = DateTime.Now;
                    vendorInvoiceRepo.SaveContactLogAction(contactLogAction);
                }
                contactRepository.CreateLinkRecord(contactLogID, EntityNames.VENDOR, model.VendorID);
                tran.Complete();
            }
        }
        #endregion

        #region Vendor Location Activity
        /// <summary>
        /// Gets the vendor location activity list.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<VendorLocationActivityList_Result> GetVendorLocationActivityList(int? vendorLocationID, PageCriteria pc)
        {
            return repository.GetVendorLocationActivityList(vendorLocationID, pc);
        }

        /// <summary>
        /// Saves the vendor location activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="currentuser">The current user.</param>
        public void SaveVendorLocationActivityComments(int CommentType, string Comments, int vendorLocationID, string currentuser)
        {
            Comment comment = new Comment();
            comment.RecordID = vendorLocationID;
            comment.CommentTypeID = CommentType;
            comment.Description = Comments;
            comment.CreateBy = currentuser;
            comment.CreateDate = DateTime.Now;
            repository.SaveVendorLocationActivityComments(comment);
        }

        public void SaveVendorLocationActivityContact(Activity_AddContact model, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactLogRepository contactRepository = new ContactLogRepository();
                VendorInvoiceRepository vendorInvoiceRepo = new VendorInvoiceRepository();
                string direction = "";
                if (model.IsInbound)
                {
                    direction = "Inbound";
                }
                else
                {
                    direction = "Outbound";
                }
                ContactType contactType = staticDataRepo.GetTypeByName("Vendor");
                if (contactType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }
                ContactLog contactLog = new ContactLog();
                contactLog.ContactCategoryID = model.ContactCategory;
                contactLog.ContactTypeID = contactType.ID;
                contactLog.ContactMethodID = model.ContactMethod;
                contactLog.TalkedTo = model.TalkedTo;
                contactLog.PhoneNumber = model.PhoneNumber;
                if (model.PhoneNumberType > 0)
                {
                    contactLog.PhoneTypeID = model.PhoneNumberType;
                }
                contactLog.Email = model.Email;
                contactLog.Direction = direction;
                contactLog.Description = "Vendor Location Management";
                contactLog.Comments = model.Notes;
                contactLog.CreateBy = currentUser;
                contactLog.CreateDate = DateTime.Now;

                vendorInvoiceRepo.SaveContactLog(contactLog);
                int contactLogID = contactLog.ID;
                foreach (var reasonRecord in model.ContactReasonID)
                {
                    ContactLogReason contactLogReason = new ContactLogReason();
                    contactLogReason.ContactLogID = contactLogID;
                    if (reasonRecord.HasValue)
                    {
                        contactLogReason.ContactReasonID = reasonRecord.GetValueOrDefault();
                    }
                    contactLogReason.CreateBy = currentUser;
                    contactLogReason.CreateDate = DateTime.Now;
                    vendorInvoiceRepo.SaveContactLogReason(contactLogReason);
                }

                foreach (var actionRecord in model.ContactActionID)
                {
                    ContactLogAction contactLogAction = new ContactLogAction();
                    contactLogAction.ContactLogID = contactLogID;
                    if (actionRecord.HasValue)
                    {
                        contactLogAction.ContactActionID = actionRecord.GetValueOrDefault();
                    }
                    contactLogAction.CreateBy = currentUser;
                    contactLogAction.CreateDate = DateTime.Now;
                    vendorInvoiceRepo.SaveContactLogAction(contactLogAction);
                }
                contactRepository.CreateLinkRecord(contactLogID, EntityNames.VENDOR_LOCATION, model.VendorLocationID);
                contactRepository.CreateLinkRecord(contactLogID, EntityNames.VENDOR, model.VendorID);
                tran.Complete();
            }
        }
        #endregion

        #region Vendor Service
        /// <summary>
        /// Gets the vendor service details.
        /// </summary>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorServiceModel GetVendorServiceDetails(int VendorID)
        {
            List<VendorServices_Result> VendorServiceList = repository.GetVendorServices(VendorID);
            VendorServiceModel vsModel = new VendorServiceModel();
            vsModel.VendorID = VendorID;
            vsModel.DBServices = VendorServiceList;
            return vsModel;
        }

        /// <summary>
        /// Gets the vendor service details.
        /// </summary>
        /// <param name="VendorID">The vendor identifier.</param>
        /// <returns></returns>
        public VendorPortalServiceModel GetVendorPortalServiceDetails(int VendorID)
        {
            List<VendorPortalServicesList_Result> VendorServiceList = repository.GetVendorPortalServices(VendorID);
            VendorPortalServiceModel vsModel = new VendorPortalServiceModel();
            vsModel.VendorID = VendorID;
            vsModel.DBServices = VendorServiceList;
            return vsModel;
        }

        /// <summary>
        /// Saves the vendor services.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveVendorServices(VendorServiceModel model, string currentUser)
        {
            List<string> productIDs = new List<string>();
            if (model.Services != null && model.Services.Count > 0)
            {
                productIDs = model.Services.Where(u => u.Selected == true).Select(u => u.ID.ToString()).ToList();
            }
            logger.InfoFormat("Saving {0} Products against Vendor {1}", productIDs.Count, model.VendorID);
            repository.SaveVendorServices(model.VendorID, productIDs, DateTime.Now, currentUser);
        }
        #endregion

        #endregion

        #region Private Methods
        /// <summary>
        /// Gets the address entity.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="addressType">Type of the address.</param>
        /// <returns></returns>
        private static AddressEntity GetAddressEntity(VendorInfo model, string addressType)
        {
            AddressEntity address = new AddressEntity()
            {
                Line1 = model.VendorAddress1,
                Line2 = model.VendorAddress2,
                Line3 = model.VendorAddress3,
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
            var addressTypeFromDB = addressRepo.GetAddressTypeByName(addressType);
            if (addressTypeFromDB == null)
            {
                throw new DMSException(string.Format("Address type - {0} is not set up in the system", addressType));
            }
            address.AddressTypeID = addressTypeFromDB.ID;
            return address;
        }


        /// <summary>
        /// Gets the phone entity.
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
        /// <param name="phoneType">Type of the phone.</param>
        /// <returns></returns>
        private static PhoneEntity GetPhoneEntity(string phoneNumber, string phoneType)
        {
            PhoneRepository phoneRepository = new PhoneRepository();

            var phoneTypeFromDB = phoneRepository.GetPhoneTypeByName(phoneType);

            if (phoneTypeFromDB == null)
            {
                throw new DMSException(string.Format("Phone Type - {0} is not set up in the system", phoneType));
            }

            PhoneEntity phone = null;
            //CR: 1130 - Do not create phone records when the phone number is empty
            if (!string.IsNullOrEmpty(phoneNumber))
            {
                phone = new PhoneEntity() { PhoneNumber = phoneNumber, PhoneTypeID = phoneTypeFromDB.ID };
            }
            return phone;
        }
        #endregion



    }


}
