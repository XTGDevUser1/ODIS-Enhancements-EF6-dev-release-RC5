using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.Common.Controllers
{
    public class VINController : BaseController
    {
        [DMSAuthorize]
        [NoCache]
        public ActionResult Search(string searchTerm)
        {
            VehicleFacade facade = new VehicleFacade();
            PageCriteria pg = new PageCriteria() { StartInd = 1, EndInd = 25, PageSize = 25 };
            List<VINSearch_Result> list = facade.SearchByVIN(searchTerm, pg);
            var emptyItem = new VINSearch_Result()
            {
                

            };
            if (string.IsNullOrEmpty(searchTerm))
            {
                emptyItem.VIN = "Please enter something to search on";
                list.Clear();
                list.Add(emptyItem);
            }

            else if (searchTerm.Length < 4)
            {
                emptyItem.VIN = "Please enter at least 4 characters to search";
                list.Clear();
                list.Add(emptyItem);
            }
            else
            {
                if (list.Count == 0)
                {
                    emptyItem.VIN = "No vehicles found.Please adjust the search criteria and try again";
                    list.Clear();
                    list.Add(emptyItem);
                }
            }

            ComboGridModel gridModel = new ComboGridModel()
            {
                Count = list.Count,
                records = list.Count,
                total = list.Count,
                rows = list.ToArray<VINSearch_Result>()
            };
            return Json(gridModel, JsonRequestBehavior.AllowGet);
        }

    }
}
