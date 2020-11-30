using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Model;
using Martex.DMS.ActionFilters;
using Martex.DMS.Models;
using Martex.DMS.BLL.Model.VendorPortal;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using System.IO;
using Martex.DMS.DAO;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    /// <summary>
    /// Vendor Invoices Controller
    /// </summary>
    public partial class VendorInvoicesController
    {

        /// <summary>
        /// Gets the vendor invoice details.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public ActionResult _VendorInvoiceDetails(int? vendorInvoiceID, int? vendorID)
        {
            if (vendorInvoiceID != null)
            {
                //Code for Edit Goes here
                ViewData["VendorID"] = vendorID.ToString();
                ViewData["PurchaseOrderNumber"] = facade.GetPurchaseOrderNumber(vendorInvoiceID.GetValueOrDefault());
                ViewData["VendorName"] = facade.GetVendorName(vendorInvoiceID.GetValueOrDefault());
            }
            else
            {
                //Code for Add goes here
                ViewData["VendorID"] = "0";
                vendorInvoiceID = 0;
                ViewData["PurchaseOrderNumber"] = "";
                ViewData["VendorName"] = "";
            }

            return View(vendorInvoiceID);
        }

        /// <summary>
        /// Gets the vendor_ invoices_ information.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.PODetailsUOM, false)]
        [ReferenceDataFilter(StaticData.PODetailsProduct, false)]
        [ReferenceDataFilter(StaticData.ETA)]
        [ReferenceDataFilter(StaticData.ContactMethodForVendor)]
        [ReferenceDataFilter(StaticData.VendorInvoiceStatus)]
        [ReferenceDataFilter(StaticData.VendorInvoicePaymentDifferenceReasonCode)]
        public ActionResult _Vendor_Invoices_Information(int? vendorInvoiceID, int? vendorID)
        {
            VendorInvoiceInfoCommonModel invoiceDetails = new VendorInvoiceInfoCommonModel();
            if (vendorInvoiceID > 0)
            {
                invoiceDetails = facade.GetVendorInvoiceDetails(vendorInvoiceID.GetValueOrDefault());
            }

            return View(invoiceDetails);
        }

        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveVendorInvoiceInformation(VendorInvoiceInfoCommonModel model, HttpPostedFileBase attachment)
        {
            OperationResult result = new OperationResult();

            VendorInvoiceModel vendorInvoiceModel = GetVendorInvoiceModel(model);
            var sourceSystemText = "BackOffice";
            var contactMethodText = Request.Params["VendorInvoiceDetails.ReceiveContactMethodID_input"];
            var invoiceStatus = Request.Params["VendorInvoiceDetails.VendorInvoiceStatusID_input"];
            result.Status = OperationStatus.SUCCESS;
            int? vendorInvoiceID = null;
            bool vendorInvoiceAddOrUpdate = false;
            try
            {
                if (model.VendorInvoiceDetails.ID == 0)
                {
                    logger.Info("Adding invoice");
                    VendorInvoice justAdded = facade.SubmitInvoice(vendorInvoiceModel, Request.RawUrl, LoggedInUserName, Session.SessionID, invoiceStatus, sourceSystemText, contactMethodText);
                    result.Data = new { VendorInvoiceID = justAdded.ID, InvoiceNumber = justAdded.InvoiceNumber, VendorID = justAdded.VendorID };
                    vendorInvoiceID = justAdded.ID;
                    vendorInvoiceAddOrUpdate = true;
                }
                else
                {
                    logger.Info("Updating invoice");
                    var vendorInvoiceStatusID = model.VendorInvoiceDetails.VendorInvoiceStatusID;
                    var vendorInvoiceStatus = ReferenceDataRepository.GetVendorInvoiceStatusById(vendorInvoiceStatusID.GetValueOrDefault());
                    if (vendorInvoiceStatus != null && !"paid".Equals(vendorInvoiceStatus.Name.ToLower()))
                    {
                        facade.UpdateInvoice(vendorInvoiceModel, Request.RawUrl, LoggedInUserName, Session.SessionID, invoiceStatus, sourceSystemText, contactMethodText);
                    }
                    result.Data = new { VendorInvoiceID = vendorInvoiceModel.InvoiceID, InvoiceNumber = vendorInvoiceModel.InvoiceNumber, VendorID = vendorInvoiceModel.VendorID };
                    vendorInvoiceID = vendorInvoiceModel.InvoiceID;
                    vendorInvoiceAddOrUpdate = true;
                }
            }
            catch (DMSException dex)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = dex.Message;
            }

            if (vendorInvoiceAddOrUpdate && attachment != null)
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
                document.RecordID = vendorInvoiceID;
                BinaryReader b = new BinaryReader(attachment.InputStream);
                byte[] binData = b.ReadBytes(attachment.ContentLength);
                document.DocumentFile = binData;

                document.IsShownOnVendorPortal = true;

                docfacade.AddDocument(document, EntityNames.VENDOR_INVOICE, Request.RawUrl, LoggedInUserName, Session.SessionID, vendorInvoiceID.GetValueOrDefault());

            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [ValidateInput(false)]
        public ActionResult ValidateInvoice(VendorInvoiceInfoCommonModel model)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            VendorInvoiceModel vendorInvoiceModel = GetVendorInvoiceModel(model);
            var sourceSystemText = "BackOffice";
            try
            {
                var vendorInvoiceStatusID = model.VendorInvoiceDetails.VendorInvoiceStatusID;
                var vendorInvoiceStatus = ReferenceDataRepository.GetVendorInvoiceStatusById(vendorInvoiceStatusID.GetValueOrDefault());
                if (vendorInvoiceStatus != null && !"paid".Equals(vendorInvoiceStatus.Name.ToLower()))
                {
                    InvoiceValidationResults results = facade.ValidateInvoice(vendorInvoiceModel, sourceSystemText);
                }
            }
            catch (DMSException dex)
            {
                logger.Warn(string.Format("Error while validating invoices for Vendor ID", vendorInvoiceModel.VendorID), dex);
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = dex.Message;
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the vendor invoice model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        private VendorInvoiceModel GetVendorInvoiceModel(VendorInvoiceInfoCommonModel model)
        {
            var invoiceData = model.VendorInvoiceDetails;
            var vendorInvoiceModel = new VendorInvoiceModel()
            {
                Hours = invoiceData.ETAHours,
                InvoiceAmount = invoiceData.InvoiceAmount.GetValueOrDefault(),
                InvoiceNumber = invoiceData.InvoiceNumber,
                Mileage = invoiceData.VehicleMileage,
                Minutes = invoiceData.ActualETAMinutes,
                PONumber = model.VendorInvoicePODetails.PONumber,
                VIN = invoiceData.Last8OfVIN,
                //NP 02/03: Changed to refer VendorID from invoice Bug: #2164
                VendorID = invoiceData.VendorID,//.VendorInvoiceVendorLocationBillingDetails.ID,
                InvoiceDate = invoiceData.InvoiceDate,
                ReceivedDate = invoiceData.ReceivedDate,
                ToBePaidDate = invoiceData.ToBePaidDate,
                InvoiceID = invoiceData.ID,
                AllowLapsedPOs = model.AllowLapsedPOs,
                AllowLowerPOAmount = model.AllowLowerPOAmount,
                PayAmount = invoiceData.PaymentAmount,
                VendorInvoicePaymentDifferenceReasonCodeID = invoiceData.VendorInvoicePaymentDifferenceReasonCodeID
            };

            return vendorInvoiceModel;

        }

        /// <summary>
        /// Get the PO details.
        /// </summary>
        /// <param name="poNumber">The position number.</param>
        /// <returns></returns>
        [HttpPost]
        [ReferenceDataFilter(StaticData.PODetailsUOM, false)]
        [ReferenceDataFilter(StaticData.PODetailsProduct, false)]
        [ReferenceDataFilter(StaticData.ETA)]
        public ActionResult _PODetails(string poNumber)
        {
            var poDetails = facade.GetPODetails(poNumber);
            var model = new VendorInvoiceInfoCommonModel() { VendorInvoicePODetails = poDetails };

            return PartialView("_Vendor_Invoices_PODetails", model);

        }

        /// <summary>
        /// Get the billing details.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location unique identifier.</param>
        /// <param name="poNumber">The position number.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _BillingDetails(int? vendorLocationID, int? poID)
        {
            var billingDetails = facade.GetVendorLocationBillingDetails(vendorLocationID.GetValueOrDefault(), poID.GetValueOrDefault());
            var vendorLocationDetails = facade.GetVendorLocationDetails(vendorLocationID.GetValueOrDefault());
            var model = new VendorInvoiceInfoCommonModel() { VendorInvoiceVendorLocationBillingDetails = billingDetails, VendorInvoiceVendorLocationDetails = vendorLocationDetails };
            return PartialView("_Vendor_Invoices_Vendor_Details", model);
        }

    }
}
