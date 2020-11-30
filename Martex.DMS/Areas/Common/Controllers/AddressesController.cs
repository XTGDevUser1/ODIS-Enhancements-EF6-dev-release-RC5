using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Telerik.Web.Mvc;
using Martex.DMS.Common;
using Kendo.Mvc.UI;
using Kendo.Mvc.Extensions;
using Martex.DMS.Models;
using Martex.DMS.DAL.Entities;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DMSBaseException;


namespace Martex.DMS.Areas.Common.Controllers
{
    /// <summary>
    /// Addresses Controller
    /// </summary>
    public class AddressesController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        public ActionResult Index()
        {
            return View();
        }
        #endregion

        #region For Address and Phone grids
        /// <summary>
        /// Get the address Details
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="recordId">The record id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        public ActionResult _SelectAddress([DataSourceRequest] DataSourceRequest request, string recordId, string entityName)
        {
            var addressRepository = new AddressRepository();
            int iRecordId = 0;
            List<AddressEntity> addresses = null;
            int.TryParse(recordId, out iRecordId);
            if (iRecordId > 0)
            {
                addresses = addressRepository.GetAddresses(iRecordId, entityName);
            }
            if (addresses != null)
            {
                return Json(new DataSourceResult()
                {
                    Data = addresses.Select(x => new
                                            {
                                                x.AddressTypeID,
                                                AddressType = new { ID = x.AddressType.ID, Name = x.AddressType.Name },
                                                x.ID,
                                                x.Line1,
                                                x.Line2,
                                                x.Line3,
                                                x.City,
                                                x.PostalCode,
                                                x.CountryID,
                                                Country = new
                                                {
                                                    ID = (x.Country != null) ? x.Country.ID : 0,
                                                    ISOCode = (x.Country != null) ? x.Country.ISOCode : null,
                                                    Name = (x.Country != null) ? x.Country.Name : null
                                                },
                                                x.StateProvinceID,
                                                StateProvince1 = new
                                                {
                                                    ID = (x.StateProvince1 != null) ? x.StateProvince1.ID : 0,
                                                    Name = (x.StateProvince1 != null) ? string.Format("{0} - {1}", x.StateProvince1.Abbreviation.Trim(), x.StateProvince1.Name) : null
                                                }
                                            })

                }, JsonRequestBehavior.AllowGet);

            }
            return Json(new DataSourceResult() { Data = new List<AddressEntity>() }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Get the  Address Types
        /// </summary>
        /// <param name="entityType">Type of the entity.</param>
        /// <returns></returns>
        public ActionResult _SelectAddressTypes(string entityType)
        {
            var addressTypes = ReferenceDataRepository.GetAddressTypes(entityType).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return Json(addressTypes);
        }

        /// <summary>
        /// Inserts the address.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="addresses">The addresses.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _InsertAddress([DataSourceRequest] DataSourceRequest request, [Bind(Prefix = "models")]IEnumerable<AddressEntity> addresses)
        {
            var address = addresses.FirstOrDefault();
            return Json(new[] { new 
                    
                         {
                            AddressTypeID = address.AddressTypeID,
                            AddressType = new { ID = address.AddressType.ID, Name = address.AddressType.Name },
                            ID = address.ID,
                            Line1 = address.Line1,
                            Line2 = address.Line2,
                            Line3 = address.Line3,
                            City = address.City,
                            PostalCode = address.PostalCode,
                            CountryID = address.CountryID,
                            Country = new
                            {
                                ID = (address.Country != null) ? address.Country.ID : 0,
                                ISOCode = (address.Country != null) ? address.Country.ISOCode : null,
                                Name = (address.Country != null) ? address.Country.Name : null
                            },
                            StateProvinceID = address.StateProvinceID,
                            StateProvince1 = new
                            {
                                ID = (address.StateProvince1 != null) ? address.StateProvince1.ID : 0,
                                Name = (address.StateProvince1 != null) ? address.StateProvince1.Name : null
                            }
                                           
                         }
            }.ToDataSourceResult(request, ModelState));
        }

        /// <summary>
        /// Updates the address.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="addresses">The addresses.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _UpdateAddress([DataSourceRequest] DataSourceRequest request, [Bind(Prefix = "models")]IEnumerable<AddressEntity> addresses)
        {
            return Json(ModelState.ToDataSourceResult());
        }

        /// <summary>
        /// Deletes the address.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="addresses">The addresses.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _DeleteAddress([DataSourceRequest] DataSourceRequest request, [Bind(Prefix = "models")]IEnumerable<AddressEntity> addresses)
        {
            return Json(ModelState.ToDataSourceResult());
        }

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
                RecordID = recordID
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
                string[] theArray = { AddressTypeNames.BANK, AddressTypeNames.Insurance };
                string[] theTypesToMatch = { AddressTypeNames.Business, AddressTypeNames.BILLING };
                ViewData[StaticData.AddressTypes.ToString()] = addressRepository.GetAddressTypes(theTypesToMatch, entityName, recordID,addressID, theArray).ToSelectListItem(u => u.ID.ToString(), y => y.Description, false);
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
            return Json(result);
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
            return Json(result);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult GetLatitudeLongitude(AddressEntity model)
        {
            try
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
                return Json(result);
            }
            catch (DMSException ex)
            {
                EventLoggerFacade facade = new EventLoggerFacade();
                Dictionary<string, string> eventDetails = new Dictionary<string, string>();
                eventDetails.Add("Service", "Bing Map Service Down");
                facade.LogEvent(Request.RawUrl, EventNames.BING_MAP_SERVICE_DOWN, eventDetails, User.Identity.Name, HttpContext.Session.SessionID);
                throw ex;
            }
            
        }
        #endregion
    }
}
