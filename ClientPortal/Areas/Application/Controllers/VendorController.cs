using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using ClientPortal.Areas.Application.Models;
using ClientPortal.Models;
using ClientPortal.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;

namespace ClientPortal.Areas.Application.Controllers
{
    public class VendorController : Controller
    {
        #region Public Methods
        /// <summary>
        /// Search Vendor List
        /// </summary>
        /// <param name="searchTerm"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult Search(string searchTerm)
        {
            VendorRepository repository = new VendorRepository();
            PageCriteria pg = new PageCriteria() { StartInd = 1, EndInd = 25, PageSize = 25 };
            List<VendorSearch_Result> list = repository.Search(searchTerm,pg);
            var emptyItem = new VendorSearch_Result()
            {
                City = string.Empty,
                StateProvince = string.Empty,
                VendorNumber = string.Empty,

            };
            if (string.IsNullOrEmpty(searchTerm))
            {
                emptyItem.VendorName = "Please enter something to search on";
                list.Clear();
                list.Add(emptyItem);
            }
            else if (searchTerm.Length < 4)
            {
                emptyItem.VendorName = "Please enter at least 4 characters to search";
                list.Clear();
                list.Add(emptyItem);
            }
            else
            {
                if (list.Count == 0)
                {
                    emptyItem.VendorName = "No vendors found.Please adjust the search criteria and try again";
                    list.Clear();
                    list.Add(emptyItem);                    
                }
            }

            ComboGridModel gridModel = new ComboGridModel()
            {
                Count = list.Count,
                records = list.Count,
                total = list.Count,
                rows = list.ToArray<VendorSearch_Result>()
            };
            return Json(gridModel,JsonRequestBehavior.AllowGet);
        }
        #endregion
    }
}
