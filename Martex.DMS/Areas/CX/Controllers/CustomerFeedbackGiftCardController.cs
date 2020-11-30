using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Kendo.Mvc.UI;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Common;
using Martex.DMS.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.QA.Controllers
{
    public partial class CXCustomerFeedbackController
    {
        //
        // GET: /CX/CustomerFeedbackGiftCard/

        public ActionResult _CustomerFeedback_GiftCard(int? id)
        {
            ViewData["CustomerFeedbackId"] = id.ToString();
            return PartialView();
        }


        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult CustomerFeedbackGiftCardList([DataSourceRequest] DataSourceRequest request, int customerFeedbackId)
        {
            logger.InfoFormat("Inside CustomerFeedbackGiftCardList of CustomerFeedbackController. Attempt to get all the Customer Feedback Gift Card depending upon the GridCommand and CustomerFeedbackID:{0}", customerFeedbackId);
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

            List<GetCustomerFeedbackGiftCard_Result> list = facade.GetCustomerFeedbackGiftCard(pageCriteria, customerFeedbackId);
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
        public ActionResult ShowAddEditCustomerFeedbackGiftCard(int? customerFeedbackGiftCardId, int? customerFeedbackId, string mode)
        {
            OperationResult result = new OperationResult();
            CustomerFeedbackGiftCard giftCard = new CustomerFeedbackGiftCard();
            ViewData["mode"] = mode;
            ViewData["CustomerFeedbackId"] = customerFeedbackId.ToString();
            ViewData[StaticData.WorkedByUsers.ToString()] = facade.GetUsersByAppConfigSettings(AppConfigConstants.ROLES_THAT_CAN_REQUEST_GIFT_CARD).ToSelectListItem<dms_Users_By_Appconfig_Role_Setting_Get_Result>(x => x.ID.ToString(), y => y.FirstName + " " + y.LastName, true);

            if (mode != "add" && customerFeedbackGiftCardId > 0)
            {                
                ViewData["CustomerFeedbackGiftCardId"] = customerFeedbackGiftCardId.ToString();
                logger.InfoFormat("Try to get the customer feedback gift card with customerFeedbackGiftCardId {0}", customerFeedbackGiftCardId);
                giftCard = facade.GetCustomerFeedbackGiftCardById(customerFeedbackGiftCardId.Value);
                
                logger.InfoFormat("Got the customer feedback gift card with customerFeedbackGiftCardId {0}", customerFeedbackGiftCardId);
            }
            else
            {
                ViewData["CustomerFeedbackGiftCardId"] = 0;
            }
            
            return PartialView("_AddEditCustomerFeedbackGiftCard", giftCard);

        }

        public ActionResult AddCustomerFeedbackGiftCard(CustomerFeedbackGiftCard data)
        {
            OperationResult result = new OperationResult();           
            facade.AddCustomerFeedbackGiftCard(data, LoggedInUserName, Request.RawUrl, Session.SessionID);           

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult UpdateCustomerFeedbackGiftCard(CustomerFeedbackGiftCard data)
        {
            OperationResult result = new OperationResult();
            facade.UpdateCustomerFeedbackGiftCard(data, LoggedInUserName, Request.RawUrl, Session.SessionID);       

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        

        public ActionResult DeleteCustomerFeedbackGiftCard(int customerFeedbackGiftCardId)
        {
            OperationResult result = new OperationResult();
            facade.DeleteCustomerFeedbackGiftCard(customerFeedbackGiftCardId, LoggedInUserName, Request.RawUrl, Session.SessionID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
