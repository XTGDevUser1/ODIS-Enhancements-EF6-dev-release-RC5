using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.Common;
using Kendo.Mvc.UI;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.Admin.Controllers
{
    public class SecurableAccessControlController : BaseController
    {
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT)]
        public ActionResult Index()
        {
            logger.Info("Executing Securable Access Control");
            return View();
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT)]
        public ActionResult SecurablesAccessList([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside Securables Access List of Securable Access Controlller");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "SecurableID";
            string sortOrder = "ASC";
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
            SecurablesRepositories repositories = new SecurablesRepositories();
            List<SecurablesList_Result> list = repositories.GetSecurablesList(pageCriteria);
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

            return Json(result);
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT)]
        public ActionResult View(int securableID)
        {
            logger.Info("Executing View for Manage Securable");
            SecurablesRepositories repository = new SecurablesRepositories();
            SecurableModel model = repository.GetSecurbalePermissions(securableID);
            return PartialView(model);
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT)]
        [HttpPost]
        public ActionResult Save(SecurableModel model)
        {
            CommonLookUpRepository lookUp = new CommonLookUpRepository();
            OperationResult result = new OperationResult();
            SecurablesRepositories repository = new SecurablesRepositories();

            try
            {
                #region Verify Inputs
                model.Items = model.Items.Where(u => !u.AccessTypeName.Equals("None")).ToList();
                Martex.DMS.DAL.AccessType denied = lookUp.GetAccessType("Denied");
                Martex.DMS.DAL.AccessType readOnly = lookUp.GetAccessType("ReadOnly");
                Martex.DMS.DAL.AccessType readWrite = lookUp.GetAccessType("ReadWrite");
                if (denied == null || readOnly == null || readWrite == null)
                {
                    throw new Exception("Access Type is not availbale in System");
                }
                model.Items.ForEach(x =>
                {
                    if (x.AccessTypeName.Equals(denied.Name, StringComparison.OrdinalIgnoreCase))
                    {
                        x.AccessTypeID = denied.ID;
                    }
                    if (x.AccessTypeName.Equals(readOnly.Name, StringComparison.OrdinalIgnoreCase))
                    {
                        x.AccessTypeID = readOnly.ID;
                    }
                    if (x.AccessTypeName.Equals(readWrite.Name, StringComparison.OrdinalIgnoreCase))
                    {
                        x.AccessTypeID = readWrite.ID;
                    }
                    if (!x.RoleID.HasValue)
                    {
                        throw new Exception(string.Format("Role Id is not available for {0}", x.RoleName));
                    }
                });
                #endregion

                repository.Save(model);
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.InnerException == null ? ex.Message : ex.InnerException.Message;
            }
            
            return Json(result);
        }

    }
}
