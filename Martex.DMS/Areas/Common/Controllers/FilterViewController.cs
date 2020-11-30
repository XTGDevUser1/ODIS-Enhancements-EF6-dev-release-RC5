using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.DAO.ListViewFilters;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using Martex.DMS.BLL.Model;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.DAL.Entities.Clients;
using Martex.DMS.DAL.Entities.TemporaryCC;
using Martex.DMS.DAL.DAO.Admin;
using Martex.DMS.DAL.DAO.QA;

namespace Martex.DMS.Areas.Common.Controllers
{
    [DMSAuthorize]
    public class FilterViewController : BaseController
    {
        #region Member Variables
        ListViewFilterRepository facade = new ListViewFilterRepository();
        #endregion

        /// <summary>
        /// _s the filter view list.
        /// </summary>
        /// <param name="pageName">Name of the page.</param>
        /// <returns></returns>
        public ActionResult _FilterViewList(string pageName, string eventHandlerCallBackForApply, string uniqueID, string targetSaveMethodName, string eventHandlerToCollectData)
        {
            FilterViewEntity entity = new FilterViewEntity(pageName, GetLoggedInUserId().ToString(), eventHandlerCallBackForApply, uniqueID, targetSaveMethodName, eventHandlerToCollectData);
            return PartialView(entity);
        }

        /// <summary>
        /// _s the filter view add.
        /// </summary>
        /// <returns></returns>
        public ActionResult _FilterViewAdd(string pageName, string eventHandlerCallBackForApply, string uniqueID, string targetSaveMethodName, string eventHandlerToCollectData)
        {
            FilterViewEntity entity = new FilterViewEntity(pageName, GetLoggedInUserId().ToString(), eventHandlerCallBackForApply, uniqueID, targetSaveMethodName, eventHandlerToCollectData);
            entity.NewRecord = new ListViewFilter()
            {
                PageName = pageName
            };
            return PartialView(entity);
        }

        /// <summary>
        /// Deletes the view.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult DeleteView(int recordID)
        {
            JsonResult result = new JsonResult();
            facade.Delete(recordID, LoggedInUserName);
            return Json(result);
        }

        /// <summary>
        /// Saves the filter search criteria for vendor invoices.
        /// </summary>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForVendorInvoices(VendorInvoiceSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();
            ListViewFilter model = new ListViewFilter()
            {
                PageName = "VendorInvoices",
                FilterName = searchCriteria.NewViewName,
                StoredProcedure = "dms_Vendor_Invoices_List_Get",
                WhereClauseXML = filter.GetXML(),
                SortColumn = searchCriteria.GridSortColumnName,
                SortOrder = searchCriteria.GridSortOrder,
                aspnet_UserID = GetLoggedInUserId(),
                IsActive = true,
                SerializedObject = GetBytesArray(searchCriteria)
            };
            ListViewFilterRepository repository = new ListViewFilterRepository();
            repository.Save(model, LoggedInUserName);
            result.Data = new { Operation = "Success", Message = "View Added" };
            return Json(result);
        }
        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForClaims(ClaimSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterClause();
            ListViewFilter model = new ListViewFilter()
            {
                PageName = "Claims",
                FilterName = searchCriteria.NewViewName,
                StoredProcedure = "dms_Claims_List_Get",
                WhereClauseXML = filter.GetXML(),
                SortColumn = searchCriteria.GridSortColumnName,
                SortOrder = searchCriteria.GridSortOrder,
                aspnet_UserID = GetLoggedInUserId(),
                IsActive = true,
                SerializedObject = GetBytesArray(searchCriteria)
            };
            ListViewFilterRepository repository = new ListViewFilterRepository();
            repository.Save(model, LoggedInUserName);
            result.Data = new { Operation = "Success", Message = "View Added" };
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForVendorSearch(VendorManagementSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "VendorSearch",
                    FilterName = searchCriteria.NewViewName,
                    StoredProcedure = "dms_vendor_list",
                    WhereClauseXML = filter.GetXML(),
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }
        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForACESPayment(ClaimACESPaymentSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterClause();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "ClaimACESPaymentSearch",
                    FilterName = searchCriteria.NewViewName,
                    StoredProcedure = "dms_aces_payments_list_get",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForMemberSearch(MemberManagementSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterClause();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "MemberSearch",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_MemberManagement_Search",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForClientBillableEventProcessing(ClientBillableEventProcessingSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "ClientBillableEventProcessing",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_Client_Billable_Event_Processing_List_Get",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForClientBillableEventHistory(ClientBillableEventProcessingSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "ClientBillableEventHistory",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_Client_Billable_Event_Processing_List_Get",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForClientInvoiceProcessing(ClientBillableInvoiceSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "ClientInvoiceProcessing",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_BillingManageInvoicesList",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForTempCCProcessing(TemporaryCCSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "VendorTemporaryCCProcessing",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_Vendor_CCProcessing_List_Get",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForClientInvoiceProcessingHistory(ClientBillableInvoiceSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "ClientInvoiceProcessingHistory",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_BillingManageInvoicesList",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForProgramManagement(ProgramManagementSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterClause();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "ProgramManagement",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_Program_Maintainence_List_Get",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }
        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForEventViewer(EventViewerSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterClause();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "EventViewer",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_EventLogList",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForCoachingConcerns(CoachingConcernsSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterClause();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "CoachingConcerns",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_CoachingConcerns_List",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }


        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForCustomerFeedback(CustomerFeedbackSearchCriteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterClause();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "CustomerFeedback",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_CustomerFeedback_list",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }


        [HttpPost]
        public ActionResult SaveFilterSearchCriteriaForCustomerFeedbackSurvey(CustomerFeedbackSurveySearchCirteria searchCriteria)
        {
            JsonResult result = new JsonResult();
            List<NameValuePair> filter = searchCriteria.GetFilterClause();
            if (filter.Count > 0)
            {
                ListViewFilter model = new ListViewFilter()
                {
                    PageName = "CustomerFeedbackSurvey",
                    FilterName = searchCriteria.NewViewName,
                    SortColumn = searchCriteria.GridSortColumnName,
                    SortOrder = searchCriteria.GridSortOrder,
                    StoredProcedure = "dms_CustomerFeedbackSurvey_list",
                    WhereClauseXML = filter.GetXML(),
                    aspnet_UserID = GetLoggedInUserId(),
                    IsActive = true,
                    SerializedObject = GetBytesArray(searchCriteria)
                };
                ListViewFilterRepository repository = new ListViewFilterRepository();
                repository.Save(model, LoggedInUserName);
                result.Data = new { Operation = "Success", Message = "View Added" };
            }
            else
            {
                result.Data = new { Operation = "Success", Message = "System is unable to find active search criteria on this page" };
            }
            return Json(result);
        }

        

        private byte[] GetBytesArray(object searchCriteria)
        {
            BinaryFormatter bformatter = new BinaryFormatter();
            MemoryStream memStream = new MemoryStream();
            StreamWriter sw = new StreamWriter(memStream);
            bformatter.Serialize(memStream, searchCriteria);
            return memStream.GetBuffer();

        }
    }
}
