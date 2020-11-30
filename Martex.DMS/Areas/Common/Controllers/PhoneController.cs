using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Telerik.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.Areas.Common.Controllers
{
    /// <summary>
    /// Phone Controller
    /// </summary>
    public class PhoneController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// Get the Phone Details
        /// </summary>
        /// <param name="recordId">The record id.</param>
        /// <returns></returns>
        [GridAction]
        public ActionResult _SelectPhoneDetails(string recordId)
        {
            var phoneRepository = new PhoneRepository();
            int iRecordId = 0;
            List<PhoneEntity> phoneDetails = null;
            int.TryParse(recordId, out iRecordId);
            if (iRecordId > 0)
            {
                phoneDetails = phoneRepository.GetPhoneDetails(iRecordId);
            }
            if (phoneDetails != null)
            {
                return Json(phoneDetails.Select(x => new
                {
                    PhoneType = new { ID = x.PhoneType.ID, Name = x.PhoneType.Name },
                    x.ID,
                    x.PhoneNumber
                }));
            }
            return Json(new List<AddressEntity>());
        }

        /// <summary>
        /// Get the Phone Types
        /// </summary>
        /// <param name="entityType">Type of the entity.</param>
        /// <returns></returns>
        public ActionResult _SelectPhoneTypes(string entityType)
        {
            var phoneTypes = ReferenceDataRepository.GetPhoneTypes(entityType).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return Json(phoneTypes);
        }

        /// <summary>
        /// Gets the scrollable phone list.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult GetScrollablePhoneList(int recordID, string entityName)
        {
            logger.InfoFormat("Trying to Reload Phone list for the given recordID {0} and entity name {1}", recordID, entityName);
            GenericPhoneModel model = new GenericPhoneModel()
            {
                EntityName = entityName,
                RecordID = recordID
            };
            logger.InfoFormat("Retrieved {0} no.of records", model.PhoneNumbers == null ? 0 : model.PhoneNumbers.Count());
            return PartialView("_ScrollablePhoneList", model);
        }

        /// <summary>
        /// Deletes the phone number.
        /// </summary>
        /// <param name="phoneID">The phone ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult DeletePhoneNumber(int phoneID)
        {
            var phoneRepository = new PhoneRepository();
            logger.InfoFormat("Trying to delete Phone Number for the given Phone ID {0} ", phoneID);
            OperationResult result = new OperationResult();
            phoneRepository.Delete(phoneID);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Record Deleted Successfully");
            return Json(result);
        }

        /// <summary>
        /// _s the get phone number details.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="phoneID">The phone ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        public ActionResult _GetPhoneNumberDetails(int recordID, int phoneID, string entityName)
        {
            var phoneRepository = new PhoneRepository();
            if (entityName.Equals(EntityNames.VENDOR))
            {
                string[] excludedItems = new string[] { PhoneTypeNames.BANK};
                ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(entityName, excludedItems).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            }
            else if (entityName.Equals(EntityNames.VENDOR_LOCATION))
            {
                string[] excludedItems = new string[] { PhoneTypeNames.BANK, PhoneTypeNames.Insurance };
                List<PhoneType> configuredPhoneTypeList = ReferenceDataRepository.GetPhoneTypes(entityName);
                string[] typesToMatch = configuredPhoneTypeList.Select(u => u.Name).ToArray();
                ViewData[StaticData.PhoneType.ToString()] = phoneRepository.GetPhoneTypes(entityName, excludedItems, typesToMatch, recordID, phoneID).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            }
            else
            {
                ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(entityName).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            }
            logger.InfoFormat("Trying to load Phone details for the given recordID {0} and entity name {1} and Phone ID {2}", recordID, entityName, phoneID);
            PhoneEntityExtended model = null;
            model = phoneRepository.GetGenericPhoneNumberByPhoneID(phoneID);
            if (model == null)
            {
                model = new PhoneEntityExtended();
                model.RecordID = recordID;
                model.EntityName = entityName;
                logger.InfoFormat("No record found so loading form in a new mode for the recordID {0} and entityName {1}", recordID, entityName);
            }

            logger.InfoFormat("Record found so loading form in a edit mode for the recordID {0} and entityName {1} and Phone ID {2}", recordID, entityName, phoneID);
            return PartialView("_NewPhoneNumber", model);
        }

        /// <summary>
        /// Saves the phone details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SavePhoneDetails(PhoneEntityExtended model)
        {
            var phoneRepository = new PhoneRepository();
            logger.InfoFormat("Trying to save phone details for the given RecordID {0} Entity Name {1} and Phone ID {2}", model.RecordID, model.EntityName, model.PhoneID);
            OperationResult result = new OperationResult();
            phoneRepository.Save(model.ToPhoneEntity(LoggedInUserName), model.EntityName, false);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Record Saved Successfully");
            return Json(result);
        }
        #endregion
    }
}
