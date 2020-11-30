using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
//using Telerik.Web.Mvc;
using ClientPortal.Common;
using Kendo.Mvc.UI;
using Kendo.Mvc.Extensions;
using ClientPortal.Models;


namespace ClientPortal.Areas.Common.Controllers
{
    public class AddressesController : BaseController
    {
        #region Public Methods
        public ActionResult Index()
        {
            return View();
        }
        #endregion

        #region For Address and Phone grids
        /// <summary>
        /// Get the address Details
        /// </summary>
        /// <param name="recordId"></param>
        /// <param name="entityName"></param>
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
        /// <param name="entityType"></param>
        /// <returns></returns>
        public ActionResult _SelectAddressTypes(string entityType)
        {
            var addressTypes = ReferenceDataRepository.GetAddressTypes(entityType).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return Json(addressTypes);
        }
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
        [HttpPost]
        public ActionResult _UpdateAddress([DataSourceRequest] DataSourceRequest request,  [Bind(Prefix = "models")]IEnumerable<AddressEntity> addresses)
        {
            return Json(ModelState.ToDataSourceResult());
        }
        [HttpPost]
        public ActionResult _DeleteAddress([DataSourceRequest] DataSourceRequest request, [Bind(Prefix = "models")]IEnumerable<AddressEntity> addresses)
        {
            return Json(ModelState.ToDataSourceResult());
        }
        #endregion
    }
}
