using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.Common;
using Martex.DMS.Common;
using Kendo.Mvc.UI;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAO;

namespace Martex.DMS.Areas.QA.Controllers
{
    public partial class CXCustomerFeedbackController
    {   
        
        public ActionResult SaveCustomerFeedback(CustomerFeedbackModel model, int? OldStatusId)
        {
            OperationResult result = new OperationResult();
            facade.UpdateCustomerFeedback(model.CustomerFeedback, model.CustomerFeedback.ServiceRequestID.GetValueOrDefault(), CustomerFeedbackStatusNames.OPEN, Request.RawUrl, Session.SessionID, LoggedInUserName, OldStatusId);
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        public ActionResult _CustomerFeedbackDetails(int customerFeedbackId, bool isLocked)
        {
            ViewData["CustomerFeedbackId"] = customerFeedbackId.ToString();
            ViewData["IsLocked"] = isLocked;
            return PartialView();
        }

        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult CustomerFeedbackDetailsList([DataSourceRequest] DataSourceRequest request, int customerFeedbackId)
        {
            logger.InfoFormat("Inside CustomerFeedbackDetailsList of CustomerFeedbackController. Attempt to get all the Customer Feedback Details depending upon the GridCommand and CustomerFeedbackID:{0}", customerFeedbackId);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ID";
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
       
            List<GetCustomerFeedbackDetails_Result> list = facade.GetCustomerFeedbackDetails(pageCriteria, customerFeedbackId);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }

        [HttpPost]
        [NoCache]
        [ReferenceDataFilter(StaticData.CustomerFeedbackType, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackInvalidReasons, true)]
        public ActionResult ShowAddCustomerFeedbackDetails(int? customerFeedbackDetailId, int? customerFeedbackId, string mode)
        {
            OperationResult result = new OperationResult();            
            CustomerFeedbackDetail detailsModel = new CustomerFeedbackDetail(); 
            var loggedInUserId = (Guid)GetLoggedInUser().ProviderUserKey;

            CustomerFeedback feedback = facade.GetCustomerFeedbackById(customerFeedbackId);
            ViewData["CustomerFeedbackId"] = customerFeedbackId.ToString();
            ViewData["ServiceRequestId"] = feedback.ServiceRequestID.HasValue?feedback.ServiceRequestID.ToString():string.Empty;
            ViewData["PoUser"] = "";
            ViewData["VendorUser"] = "";
            

            if (feedback.PurchaseOrderNumber != null)
            {
                POFacade poFacade = new POFacade();
                PurchaseOrder poData = poFacade.GetPOByNumber(feedback.PurchaseOrderNumber);
                Vendor vendorData = facade.GetVendorByPurchaseOrderNumber(feedback.PurchaseOrderNumber);

                detailsModel.VendorLocationID = poData.VendorLocationID;
                ViewData["PoUser"] = poData.CreateBy.ToString();
                ViewData["VendorUser"] = vendorData.Name.ToString();
            }            

            logger.InfoFormat("Inside ShowAddCustomerFeedbackDetails() of CXCustomerFeedbackController with the selectedUserId {0} and mode {1}", customerFeedbackDetailId, mode);

            if (mode != "add")
            {
                Vendor vendor;            
                ViewData["CustomerFeedbackDetailId"] = customerFeedbackDetailId.ToString();
                logger.InfoFormat("Try to get the customer feedback details with customerFeedbackDetailId {0}", customerFeedbackDetailId);
                detailsModel = facade.GetCustomerDetailsById(customerFeedbackDetailId.Value);

                if(detailsModel.CustomerFeedbackCategoryID == 2 && detailsModel.UserID.HasValue)
                {
                    vendor = facade.GetVendorById(detailsModel.UserID.Value);
                    ViewData["VendorUser"] = vendor.Name.ToString();
                }

                logger.InfoFormat("Got the customer feedback details with userId {0}", customerFeedbackDetailId);
            }
            else
            {                                
                ViewData["CustomerFeedbackDetailId"] = 0;               
            }
            

            ViewData["mode"] = mode;
            logger.Info("Call the partial view '_AddCustomerFeedbackDetails' ");

            return PartialView("_AddCustomerFeedbackDetails", detailsModel);

        }

        public JsonResult GetCustomerFeedbackTypes()
        {
            List<CustomerFeedbackType> customerFeedbackTypes = ReferenceDataRepository.GetCustomerFeedbackTypes();
            return Json(customerFeedbackTypes.Select(t => new { TypeId = t.ID, TypeName = t.Description }), JsonRequestBehavior.AllowGet);
        }

        public JsonResult GetCustomerFeedbackCategoryByTypeId(int? typeId)
        {
            List<CustomerFeedbackCategory> customerFeedbackCategories = ReferenceDataRepository.GetCustomerFeedbackCategoryByTypeId(typeId);

            return Json(customerFeedbackCategories.Select(c => new { CategoryId = c.ID, CategoryName = c.Description }), JsonRequestBehavior.AllowGet);
        }

        public JsonResult GetCustomerFeedbackSubCategoryByCategoryId(int? categoryId)
        {
            List<CustomerFeedbackSubCategory> customerFeedbackCategories = ReferenceDataRepository.GetCustomerFeedbackSubCategoryByCategoryId(categoryId);

            return Json(customerFeedbackCategories.Select(c => new { SubCategoryId = c.ID, SubCategoryName = c.Description }), JsonRequestBehavior.AllowGet);
        }

        public JsonResult GetUsersByCategoryName(string categoryName)
        {
            var result = facade.GetUsersOrVendors(categoryName);
            return Json(result.Select(c => new { UserId = c.Value, UserName = c.Text }), JsonRequestBehavior.AllowGet);
        }

        public ActionResult SaveCustomerFeedbackDetails(CustomerFeedbackDetail data)
        {
            OperationResult result = new OperationResult();           
            facade.SaveCustomerFeedbackDetails(data, LoggedInUserName);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult DeleteCustomerFeedbackDetails(int customerFeedbackDetailId)
        {
            OperationResult result = new OperationResult();          
            facade.DeleteCustomerFeedbackDetails(customerFeedbackDetailId);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}