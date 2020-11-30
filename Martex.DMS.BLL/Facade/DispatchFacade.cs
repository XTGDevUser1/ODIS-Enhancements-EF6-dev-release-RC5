using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.BLL.Model;
using System.Transactions;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.BLL.BINGServices;
using log4net;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class DispatchFacade
    {
        #region Protected Methods
        
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(DispatchFacade));

        #endregion

        #region Public Methods

        /// <summary>
        /// Initializes a new instance of the <see cref="DispatchFacade"/> class.
        /// </summary>
        public DispatchFacade()
        {

        }

        /// <summary>
        /// Gets the ISps.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="actualServiceMiles">The actual service miles.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <param name="vehicleCategoryID">The vehicle category ID.</param>
        /// <param name="searchRadiusMiles">The search radius miles.</param>
        /// <param name="includeDoNotUse">if set to <c>true</c> [include do not use].</param>
        /// <param name="searchFrom">The search from.</param>
        /// <param name="serviceLocationLatitude">The service location latitude.</param>
        /// <param name="serviceLocationLongitude">The service location longitude.</param>
        /// <param name="showCalled">if set to <c>true</c> [show called].</param>
        /// <param name="showNotCalled">if set to <c>true</c> [show not called].</param>
        /// <param name="productIDs">The product I ds.</param>
        /// <returns></returns>
        public List<ISPs_Result> GetISPs(int serviceRequestID,
            decimal? actualServiceMiles,
            int vehicleTypeID,
            int vehicleCategoryID,
            int? searchRadiusMiles,
            bool includeDoNotUse,
            string searchFrom,
            decimal? serviceLocationLatitude,
            decimal? serviceLocationLongitude,
            bool showCalled = true,
            bool showNotCalled = false,
            string productIDs = null)
        {
            string sAdminWeight = AppConfigRepository.GetValue(AppConfigConstants.ADMIN_WEIGHT);
            string sPerfWeight = AppConfigRepository.GetValue(AppConfigConstants.PERFORMANCE_WEIGHT);
            string sCostWeight = AppConfigRepository.GetValue(AppConfigConstants.COST_WEIGHT);

            // Get all weights from programconfiguration
            ProgramMaintenanceRepository programRepository = new ProgramMaintenanceRepository();

            int iSearchRadiusMiles = searchRadiusMiles ?? 0;
            decimal dAdminWeight, dPerfWeight, dCostWeight;
            dAdminWeight = dPerfWeight = dCostWeight = 0;
            if (iSearchRadiusMiles == 0)
            {
                string sSearchRadiusMiles = AppConfigRepository.GetValue(AppConfigConstants.SEARCH_RADIUS_MILES);
                int.TryParse(sSearchRadiusMiles, out iSearchRadiusMiles);
            }
            decimal.TryParse(sAdminWeight, out dAdminWeight);
            decimal.TryParse(sPerfWeight, out dPerfWeight);
            decimal.TryParse(sCostWeight, out dCostWeight);

            var dispatchRepository = new DispatchRepository();
            var list = dispatchRepository.GetISPs(
                    serviceRequestID,
                    actualServiceMiles,
                    vehicleTypeID,
                    vehicleCategoryID,
                    iSearchRadiusMiles,
                    dAdminWeight,
                    dPerfWeight,
                    dCostWeight,
                    includeDoNotUse,
                    searchFrom,
                    showCalled,
                    showNotCalled,
                    productIDs);

            return list;
        }


        /// <summary>
        /// Rejects the specified vendor.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="relatedRecord">The related record.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <exception cref="DMSException">
        /// Contact Type - Vendor is not set up in the system
        /// or
        /// Contact Method - Phone is not set up in the system
        /// or
        /// Contact Category - VendorSelection is not set up in the system
        /// or
        /// Contact Source - Vendor for category : VendorSelection is not set up in the system
        /// or
        /// ContactReason - ISP selection is not set up for category - VendorSelection
        /// </exception>
        public static void Reject(RejectVendorModel model, string currentUser, int? relatedRecord, string entityName, int? LastVendorcontactID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                #region 1. Create ContactLog and Link record for service request
                var contactLogRepository = new ContactLogRepository();
                ContactLog contactLog = new ContactLog();
                if (LastVendorcontactID == null)
                {
                    contactLog.ContactSourceID = null;
                    contactLog.TalkedTo = model.TalkedTo;
                    contactLog.Company = model.VendorName;
                    contactLog.PhoneTypeID = null;
                    contactLog.PhoneNumber = model.PhoneNumber;
                    contactLog.Direction = "Outbound";
                    contactLog.Comments = model.RejectComments;
                    contactLog.IsPossibleCallback = model.PossibleRetry;
                    contactLog.CreateBy = currentUser;
                    contactLog.CreateDate = DateTime.Now;           
                } else
                {
                    contactLog.ID = LastVendorcontactID.GetValueOrDefault();
                    contactLog.ContactSourceID = null;
                    contactLog.TalkedTo = model.TalkedTo;
                    contactLog.Company = model.VendorName;
                    contactLog.PhoneTypeID = null;
                    contactLog.PhoneNumber = model.PhoneNumber;
                    contactLog.Direction = "Outbound";
                    contactLog.Comments = model.RejectComments;
                    contactLog.IsPossibleCallback = model.PossibleRetry;
                    contactLog.CreateBy = currentUser;
                    contactLog.CreateDate = DateTime.Now;
                }
                
                // Get the phone Type ID
                PhoneRepository phoneRepository = new PhoneRepository();
                PhoneType phoneType = phoneRepository.GetPhoneTypeByName(model.PhoneType);
                if (phoneType == null)
                {
                    throw new DMSException(string.Format("Phone type - {0} is not set up in the system", model.PhoneType));
                }

                contactLog.PhoneTypeID = phoneType.ID;
                // Get Contactcategory, method, type and Source

                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactType vendorType = staticDataRepo.GetTypeByName("Vendor");
                if (vendorType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }

                contactLog.ContactTypeID = vendorType.ID;
                ContactMethod contactMethod = staticDataRepo.GetMethodByName("Phone");
                if (contactMethod == null)
                {
                    throw new DMSException("Contact Method - Phone is not set up in the system");
                }
                contactLog.ContactMethodID = contactMethod.ID;

                ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("VendorSelection");
                if (contactCategory == null)
                {
                    throw new DMSException("Contact Category - VendorSelection is not set up in the system");
                }

                contactLog.ContactCategoryID = contactCategory.ID;

                ContactSource contactSource = staticDataRepo.GetContactSourceByName("VendorData", "VendorSelection");
                if (contactSource == null)
                {
                    throw new DMSException("Contact Source - Vendor for category : VendorSelection is not set up in the system");
                }
                contactLog.ContactSourceID = contactSource.ID;


                contactLogRepository.Save(contactLog, currentUser, relatedRecord, entityName);

                #endregion

                #region 2. Add a link record to VendorLocation
                contactLogRepository.CreateLinkRecord(contactLog.ID, EntityNames.VENDOR_LOCATION, model.VendorLocationID);

                #endregion

                #region 3. Create a contactLogReason record

                ContactLogReasonRepository contactLogReasonRepo = new ContactLogReasonRepository();
                ContactLogReason reason = new ContactLogReason()
                {
                    ContactLogID = contactLog.ID
                };

                ContactReason contactReason = staticDataRepo.GetContactReason("ISP selection", "VendorSelection");
                if (contactReason == null)
                {
                    throw new DMSException("ContactReason - ISP selection is not set up for category - VendorSelection");
                }
                reason.ContactReasonID = contactReason.ID;

                contactLogReasonRepo.Save(reason, currentUser);

                #endregion

                #region 4. Create a contactLogAction record.

                ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                ContactLogAction logAction = new ContactLogAction()
                {
                    ContactLogID = contactLog.ID,
                    ContactActionID = model.ContactAction
                };

                logActionRepo.Save(logAction, currentUser);

                #endregion

                tran.Complete();
            }
        }


        /// <summary>
        /// Saves the service request
        /// </summary>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionId">The session id.</param>
        /// <param name="relatedRecord">The related record.</param>
        /// <param name="entityName">Name of the entity.</param>
        public static void Save(string eventSource, string currentUser, string sessionId, int relatedRecord, string entityName)
        {
            ServiceRequestRepository serviceRepository = new ServiceRequestRepository();
            serviceRepository.UpdateTabStatus(relatedRecord, TabConstants.DispatchTab, currentUser);
        }

        /// <summary>
        /// Gets the product options.
        /// </summary>
        /// <param name="productCategoryID">The product category ID.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <param name="vehicleCategoryID">The vehicle category ID.</param>
        /// <returns></returns>
        public static List<Product> GetProductOptions(int? productCategoryID, int? vehicleTypeID, int? vehicleCategoryID)
        {
            var repository = new OptionsRepository();
            return repository.GetProductOptions(productCategoryID, vehicleTypeID, vehicleCategoryID);
        }

        #endregion
    }
}
