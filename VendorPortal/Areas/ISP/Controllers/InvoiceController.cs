using System.Collections.Generic;
using System.Web.Mvc;
using VendorPortal.Controllers;
using Martex.DMS.BLL.Model.VendorPortal;
using VendorPortal.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;
using VendorPortal.Common;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;
using VendorPortal.ActionFilters;
using System.Web;
using System;
using System.IO;
using Martex.DMS.DAL.DAO;
using System.Linq;
using System.Configuration;
using System.Web.Script.Serialization;
using System.Text;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace VendorPortal.Areas.ISP.Controllers
{

    public class InvoiceController : BaseController
    {
        private VendorInvoiceFacade facade = new VendorInvoiceFacade();
        /// <summary>
        /// Submits the invoice.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_SUBMITINVOICE)]
        [NoCache]
        public ActionResult SubmitInvoice()
        {
            return View();
        }

        /// <summary>
        /// Gets the program configuration for po.
        /// </summary>
        /// <param name="purchaseOrderNumber">The purchase order number.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">PO_NOT_EXISTS</exception>
        public ActionResult GetProgramConfigurationForPO(string purchaseOrderNumber)
        {
            OperationResult result = new OperationResult()
            {
                Status = OperationStatus.SUCCESS
            };
            var poRepository = new PORepository();
            logger.InfoFormat("Trying to retrieve PO # {0}", purchaseOrderNumber);
            var po = poRepository.GetPOByNumber(purchaseOrderNumber != null ? purchaseOrderNumber.Trim() : string.Empty);
            if (po != null)
            {
                Case caseRecord = poRepository.GetCaseForPO(po.ID);
                ProgramMaintenanceFacade progFacade = new ProgramMaintenanceFacade();
                List<ProgramInformation_Result> pinfo = progFacade.GetProgramInfo(caseRecord.ProgramID, "vendor", "rule");
                var showInvoiceUploadOnSubmitInvoice = false;
                var requireInvoiceUploadOnSubmitInvoice = false;
                var showInvoiceUploadOnSubmitInvoiceConfig = pinfo.Where(x => x.Name == "ShowInvoiceUploadOnSubmitInvoice").FirstOrDefault();
                if (showInvoiceUploadOnSubmitInvoiceConfig != null)
                {
                    if ("yes".Equals(showInvoiceUploadOnSubmitInvoiceConfig.Value, StringComparison.InvariantCultureIgnoreCase))
                    {
                        showInvoiceUploadOnSubmitInvoice = true;
                    }
                }
                var requireInvoiceUploadOnSubmitInvoiceConfig = pinfo.Where(x => x.Name == "RequireInvoiceUploadOnSubmitInvoice").FirstOrDefault();
                if (showInvoiceUploadOnSubmitInvoiceConfig != null && requireInvoiceUploadOnSubmitInvoiceConfig != null)
                {
                    if ("yes".Equals(requireInvoiceUploadOnSubmitInvoiceConfig.Value, StringComparison.InvariantCultureIgnoreCase))
                    {
                        requireInvoiceUploadOnSubmitInvoice = true;
                    }
                }
                result.Data = new { showInvoiceUploadOnSubmitInvoice = showInvoiceUploadOnSubmitInvoice, requireInvoiceUploadOnSubmitInvoice = requireInvoiceUploadOnSubmitInvoice };
            }
            else
            {
                logger.WarnFormat("PO with number {0} doesn't exist", purchaseOrderNumber);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = "PO number was not found, please try again";
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Submits the invoice.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_SUBMITINVOICE)]
        [NoCache]
        public ActionResult SubmitInvoice(VendorInvoiceModel model, HttpPostedFileBase attachment)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            var profile = GetProfile();
            logger.InfoFormat("Processing Invoice for Vendor {0}", profile.VendorID);
            model.VendorID = profile.VendorID;

            logger.InfoFormat("Invoice Data submitted : {0}", model.ToString());

            try
            {
                facade.SubmitInvoice(model, Request.RawUrl, LoggedInUserName, Session.SessionID, "ReadyForPayment", "VendorPortal");
                logger.InfoFormat("Invoice processed successfully for vendor : {0}", profile.VendorID);
                if (attachment != null)
                {
                    DocumentFacade docfacade = new DocumentFacade();
                    var documentCategory = docfacade.GetDocumentCategory(DocumentCategoryNames.VENDOR_INVOICE);
                    Document document = new Document();
                    document.CreateDate = DateTime.Now;
                    document.CreateBy = LoggedInUserName;
                    document.Comment = string.Empty;
                    if (documentCategory != null)
                    {
                        document.DocumentCategoryID = documentCategory.ID;
                    }
                    document.Name = System.IO.Path.GetFileName(attachment.FileName);
                    document.RecordID = model.InvoiceID;
                    BinaryReader b = new BinaryReader(attachment.InputStream);
                    byte[] binData = b.ReadBytes(attachment.ContentLength);
                    document.DocumentFile = binData;

                    document.IsShownOnVendorPortal = true;

                    docfacade.AddDocument(document, EntityNames.VENDOR_INVOICE, Request.RawUrl, LoggedInUserName, Session.SessionID, model.InvoiceID);
                }
            }
            catch (DMSException dex)
            {
                logger.Warn(string.Format("Error while submitting invoices for Vendor ID", profile.VendorID), dex);
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = dex.Message;
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost, ValidateInput(false)]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_SUBMITINVOICE)]
        [NoCache]
        public ActionResult ValidateInvoice(VendorInvoiceModel model)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            var profile = GetProfile();
            logger.InfoFormat("Validating Invoice for Vendor {0}", profile.VendorID);
            model.VendorID = profile.VendorID;
            logger.InfoFormat("Invoice Data to be validated : {0}", model.ToString());
            try
            {
                InvoiceValidationResults results = facade.ValidateInvoice(model, "VendorPortal");
            }
            catch (DMSException dex)
            {
                logger.Warn(string.Format("Error while validating invoices for Vendor ID", profile.VendorID), dex);
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = dex.Message;
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_INVOICEHISTORY)]
        public ActionResult List()
        {
            return View();
        }

        /// <summary>
        /// _s the vendor_ invoice.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_INVOICEHISTORY)]
        public ActionResult _Vendor_Invoice()
        {
            List<VendorPortalInvoiceList_Result> list = new List<VendorPortalInvoiceList_Result>();
            ViewData["HistorySearchCriteriaDatePreset"] = ReferenceDataRepository.GetVendorInvoiceSearchCriteriaDatePreset().ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);
            return View(list);
        }

        /// <summary>
        /// _s the get vendor invoice list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="SearchCriteria">The search criteria.</param>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_INVOICEHISTORY)]
        public ActionResult _GetVendorInvoiceList([DataSourceRequest] DataSourceRequest request, VendorPortalInvoiceSearchCriteria searchCriteria)
        {
            logger.Info("Inside _GetVendorInvoiceList of Vendor Portal Invoice Search. Attempt to get all Vendor Invoices depending upon the GridCommand");
            int vendorID = GetProfile().VendorID.GetValueOrDefault();
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "IssueDate";
            string sortOrder = "DESC";
            if (request != null && request.Sorts != null && request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<VendorPortalInvoiceList_Result> list = new List<VendorPortalInvoiceList_Result>();
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            /*if (string.IsNullOrEmpty(searchCriteria.PONumber) && searchCriteria.DateSectionFromDate == null && searchCriteria.DateSectionToDate == null)
            {
                return Json(result);
            }*/
            List<NameValuePair> filter = GetFilterClause(searchCriteria);

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            list = facade.GetVendorPOrtalInvoiceList(pageCriteria, vendorID);

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

            //Event Log Started
            var eventLoggerFacade = new EventLoggerFacade();
            logger.Info("Logging an event for Search invoice history");
            string Description = "<PONumber> " + searchCriteria.PONumber + "</PONumber>  <DateRange> " + searchCriteria.DateSectionPresetValue + "</DateRange>  <FromDate>" + searchCriteria.DateSectionFromDate + "</FromDate>  <ToDate>" + searchCriteria.DateSectionToDate + "</ToDate>";
            long eventID = eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.SEARCH_INVOICE_HISTORY, Description, LoggedInUserName, Session.SessionID);
            eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, vendorID, EntityNames.VENDOR);
            //Event Log Completed
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the filter clause.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        private List<NameValuePair> GetFilterClause(VendorPortalInvoiceSearchCriteria model)
        {
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(model.PONumber))
            {
                filterList.Add(new NameValuePair() { Name = "PurchaseOrderNumberValue", Value = model.PONumber });
            }
            if (model.DateSectionFromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "FromDate", Value = model.DateSectionFromDate.Value.ToString() });
            }
            if (model.DateSectionToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ToDate", Value = model.DateSectionToDate.Value.ToString() });
            }
            return filterList;
        }

    }
}
