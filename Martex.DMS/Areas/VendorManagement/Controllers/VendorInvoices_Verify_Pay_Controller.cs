using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Models;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    /// <summary>
    /// Vendor Invoices Controller
    /// </summary>
    public partial class VendorInvoicesController : BaseController
    {
        /// <summary>
        /// Verifies the specified invoices.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult Verify(List<int> invoices)
        {
            OperationResult result = new OperationResult();

            var summary = facade.VerifyInvoices(invoices, Request.RawUrl, LoggedInUserName, Session.SessionID);
            result.Data = summary;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Pays the specified invoices.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <returns></returns>
        [HttpPost]
        [DMSAuthorize(Securable=DMSSecurityProviderFriendlyName.VENDOR_BUTTON_PAY_INVOICES)]
        public ActionResult VerifyBeforePay(List<int> invoices)
        {
            OperationResult result = new OperationResult();

            var summary = facade.VerifyInvoices(invoices, Request.RawUrl, LoggedInUserName, Session.SessionID,true);
            result.Data = summary;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the etl execution log unique identifier.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        public ActionResult GetETLExecutionLogID()
        {
            OperationResult result = new OperationResult();

            try
            {
                var ids = facade.GetETLExecutionLogID(string.Empty, LoggedInUserName);
                const string EXECUTION_LOG_ID = "ETLExecutionLogID";
                const string Batch_ID = "BatchID";
                result.Data = new { ETLExecutionLogID = ids[EXECUTION_LOG_ID], BatchID = ids[Batch_ID], CurrentDate = DateTime.Now };
                logger.InfoFormat("Generated Log ID {0} and BatchID {1} ", ids[EXECUTION_LOG_ID], ids[Batch_ID]);
                return Json(result, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                logger.Warn(ex.Message, ex);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
                return Json(result, JsonRequestBehavior.AllowGet);
            }
        }

        /// <summary>
        /// Processes the invoice.
        /// </summary>
        /// <param name="invoiceID">The invoice unique identifier.</param>
        /// <param name="batchID">The batch unique identifier.</param>
        /// <param name="batchTimeStamp">The batch time stamp.</param>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.VENDOR_BUTTON_PAY_INVOICES)]
        public ActionResult ProcessInvoice(int invoiceID, long batchID, DateTime? batchTimeStamp)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Processing Invoice ID : {0}, Batch ID : {1}, Timestamp : {2}", invoiceID, batchID, batchTimeStamp);

            facade.CreateStagingDataForInvoice(invoiceID, batchID, batchTimeStamp);

            result.Data = new { InvoiceID = invoiceID };

            return Json(result, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Creates the export files.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <param name="etlExecutionLogID">The etl execution log unique identifier.</param>
        /// <param name="batchID">The batch unique identifier.</param>
        /// <returns></returns>
        [DMSAuthorize(Securable=DMSSecurityProviderFriendlyName.VENDOR_BUTTON_PAY_INVOICES)]
        public ActionResult CreateExportFiles(List<int> invoices, long etlExecutionLogID, long batchID)
        {
            OperationResult result = new OperationResult();

            VendorInvoiceStatusSummary summary = facade.CreateExportFiles(invoices,etlExecutionLogID, batchID, Request.RawUrl, LoggedInUserName, Session.SessionID);

            result.Data = summary;

            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
