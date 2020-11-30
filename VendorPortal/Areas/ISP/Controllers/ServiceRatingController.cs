using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Kendo.Mvc.UI;
using VendorPortal.Common;
using VendorPortal.Controllers;
using Martex.DMS.DAL.Common;
using VendorPortal.Models;

namespace VendorPortal.Areas.ISP.Controllers
{
    public class ServiceRatingController : BaseController
    {
        VendorPortalFacade facade = new VendorPortalFacade();

        public ActionResult Index()
        {
            return View();
        }

        public ActionResult _Service_Ratings()
        {
            RegisterUserModel userProfile = GetProfile();
            List<ServiceRatingsProductCategoryList_Result> list = new List<ServiceRatingsProductCategoryList_Result>();
            list = facade.GetServiceRatingsProductCategoryList(userProfile.VendorID);
            return View(list);
        }

        public ActionResult _GetServiceRatingProductsList([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside _GetServiceRatingProductsList of ServiceRatingController. Attempt to get all Service Rating Products List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
            if (request != null && request.Sorts != null && request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<ServiceRatingsProductList_Result> list = new List<ServiceRatingsProductList_Result>();
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (pageCriteria.EndInd <= 0)
            {
                pageCriteria.EndInd = 100;
            }
            if (pageCriteria.PageSize <= 0)
            {
                pageCriteria.PageSize = 100;
            }
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            RegisterUserModel userProfile = GetProfile();
            list = facade.GetServiceRatingsProductList(pageCriteria, userProfile.VendorID);

            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }

            result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult _GetServiceRatingList([DataSourceRequest] DataSourceRequest request, int? productCategoryID)
        {
            logger.Info("Inside _GetServiceRatingList of ServiceRatingController. Attempt to get all Service Rating List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<VendorPortalServiceRatingsList_Result> list = new List<VendorPortalServiceRatingsList_Result>();
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (pageCriteria.EndInd <= 0)
            {
                pageCriteria.EndInd = 100;
            }
            if (pageCriteria.PageSize <= 0)
            {
                pageCriteria.PageSize = 100;
            }
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            RegisterUserModel userProfile = GetProfile();
            list = facade.GetVendorPortalServiceRatings(pageCriteria, userProfile.VendorID, productCategoryID);

            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }

            result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);

            return Json(result, JsonRequestBehavior.AllowGet);
        }


        public ActionResult GetContactActionsList([DataSourceRequest] DataSourceRequest request, int? productID)
        {
            logger.Info("Inside GetContactActionsList of ServiceRatingController. Attempt to get all Contact Actions List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            RegisterUserModel userProfile = GetProfile();
            List<VendorPortalServiceContactActionsList_Result> list = facade.GetVendorPortalServiceContactActions(pageCriteria, userProfile.VendorID, productID);

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.GetValueOrDefault();
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
