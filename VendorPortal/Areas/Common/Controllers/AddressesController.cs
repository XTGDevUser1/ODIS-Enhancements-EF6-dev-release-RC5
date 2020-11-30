using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using VendorPortal.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using VendorPortal.Common;
using VendorPortal.Models;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;

namespace VendorPortal.Areas.Common.Controllers
{
    public class AddressesController : BaseController
    {
        /// <summary>
        /// Gets the scrollable address list.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult GetScrollableAddressList(int recordID, string entityName)
        {
            logger.InfoFormat("Trying to Reload address list for the given recordID {0} and entity name {1}", recordID, entityName);

            GenericAddressEntityModel model = new GenericAddressEntityModel()
            {
                EntityName = entityName,
                RecordID = recordID,
                IsVendorPortal = true
            };

            logger.InfoFormat("Retrieved {0} no.of records", model.Address == null ? 0 : model.Address.Count());
            return PartialView("_ScrollableAddressList", model);
        }

        /// <summary>
        /// _s the get address details.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="addressID">The address ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult _GetAddressDetails(int recordID, int addressID, string entityName)
        {
            var addressRepository = new AddressRepository();
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            logger.InfoFormat("Trying to load address details for the given recordID {0} and entity name {1} and addressID {2}", recordID, entityName, addressID);

            if (entityName.Equals(EntityNames.VENDOR))
            {
                string[] theArray = { AddressTypeNames.BANK, AddressTypeNames.Insurance, AddressTypeNames.DISPATCH, AddressTypeNames.LEVY };
                string[] theTypesToMatch = { AddressTypeNames.Business, AddressTypeNames.BILLING};
                ViewData[StaticData.AddressTypes.ToString()] = addressRepository.GetAddressTypes(theTypesToMatch, entityName, recordID, addressID, theArray).ToSelectListItem(u => u.ID.ToString(), y => y.Description, false);
            }
            else
            {
                ViewData[StaticData.AddressTypes.ToString()] = ReferenceDataRepository.GetAddressTypes(entityName).ToSelectListItem(u => u.ID.ToString(), y => y.Description, false);
            }
            AddressExtendedEntity model = null;
            model = addressRepository.GetGenericAddressBy(addressID);
            if (model == null)
            {
                model = new AddressExtendedEntity();
                model.RecordID = recordID;
                model.EntityName = entityName;
                logger.InfoFormat("No record found so loading form in a new mode for the recordID {0} and entityName {1}", recordID, entityName);
            }
            else
            {
                if (model.CountryID.HasValue)
                {
                    ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(model.CountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
                }
                logger.InfoFormat("Record found so loading form in a edit mode for the recordID {0} and entityName {1} and address ID {2}", recordID, entityName, addressID);
            }
            return PartialView("_ScrollableNewAddress", model);
        }

        /// <summary>
        /// Saves the address details for.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveAddressDetailsFor(AddressExtendedEntity model)
        {
            var addressRepository = new AddressRepository();
            logger.InfoFormat("Trying to save address details for the given RecordID {0} Entity Name {1} and Address ID {2}", model.RecordID, model.EntityName, model.AddressID);
            OperationResult result = new OperationResult();
            addressRepository.Save(model.ToAddressEntity(LoggedInUserName), model.EntityName, false);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Record Saved Successfully");
            return Json(result,JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Deletes the address.
        /// </summary>
        /// <param name="addressID">The address ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult DeleteAddress(int addressID)
        {
            var addressRepository = new AddressRepository();
            logger.InfoFormat("Trying to delete address for the given AddressID {0} ", addressID);
            OperationResult result = new OperationResult();
            addressRepository.Delete(addressID);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Record Deleted Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult GetLatitudeLongitude(AddressEntity model)
        {
            OperationResult result = new OperationResult();
            if (!string.IsNullOrEmpty(model.StateProvince))
            {
                model.StateProvince = model.StateProvince.Substring(0, 2);
            }
            LatitudeLongitude latLong = AddressFacade.GetLatLong(string.Join(",", model.Line1, model.Line2, model.Line3), model.City, model.StateProvince, model.PostalCode, model.CountryCode);
            result.Status = OperationStatus.ERROR;
            if (latLong != null && latLong.Latitude.HasValue && latLong.Longitude.HasValue)
            {
                if (latLong.Latitude.Value != 0 && latLong.Longitude.Value != 0)
                {
                    result.Status = OperationStatus.SUCCESS;
                    result.Data = latLong;
                }
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

    }
}
