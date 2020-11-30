using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using VendorPortal.Common;

namespace VendorPortal.Areas.Common.Controllers
{
    public class ReferenceDataController : Controller
    {

        /// <summary>
        /// Method user for Phone Control
        /// </summary>
        /// <returns></returns>
        public ActionResult GetCountryExceptPR()
        {
            List<Country> list = ReferenceDataRepository.GetCountryTelephoneCode(false);
            return Json(list.ToSelectListItem(x => x.ID.ToString(), y => y.ISOCode.Trim()), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the state province with ID.
        /// </summary>
        /// <param name="countryID">The country ID.</param>
        /// <returns></returns>
        public ActionResult GetStateProvinceWithID(int? countryID)
        {
            List<StateProvince> list = ReferenceDataRepository.GetStateProvinces(countryID.GetValueOrDefault());
            List<SelectListItem> listItem = null;
            if (list != null)
            {
                listItem = list.ToSelectListItem(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim())).ToList();
            }
            if (listItem == null)
            {
                listItem = new List<SelectListItem>();
            }
            listItem.Insert(0, new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            return Json(listItem, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// Get List of State
        /// </summary>
        /// <param name="countryId">The country id.</param>
        /// <returns></returns>
        public ActionResult StateProvinceRelatedToCountry(string countryId)
        {
            int iCountryId = 0;
            int.TryParse(countryId, out iCountryId);
            
            List<StateProvince> list = new List<StateProvince>();
            if (iCountryId > 0)
            {
                list = ReferenceDataRepository.GetStateProvinces(iCountryId);
            }            
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), false);
            return new JsonResult { Data = new SelectList(selectList, "Value", "Text") };
        }

        public ActionResult StateProvinceRelatedToCountryWithSelect(string countryId)
        {
            int iCountryId = 0;
            int.TryParse(countryId, out iCountryId);

            List<StateProvince> list = new List<StateProvince>();
            if (iCountryId > 0)
            {
                list = ReferenceDataRepository.GetStateProvinces(iCountryId);
            }
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            return new JsonResult { Data = new SelectList(selectList, "Value", "Text") };
        }

    }
}
