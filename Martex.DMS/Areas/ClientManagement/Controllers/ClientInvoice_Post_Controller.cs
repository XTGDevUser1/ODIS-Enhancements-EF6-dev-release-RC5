using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.Entities;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    public partial class ClientInvoiceProcessingController : BaseController
    {
        // Verify
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_POST_INVOICES)]
        public ActionResult _Verify(List<int> invoices)
        {
            OperationResult result = new OperationResult();

            var summary = facade.VerifyInvoices(invoices, Request.RawUrl, LoggedInUserName, Session.SessionID);
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
                const string Billed_Batch_ID = "BilledBatchID";
                const string Unbilled_Batch_ID = "UnbilledBatchID";
                result.Data = new { ETLExecutionLogID = ids[EXECUTION_LOG_ID], BilledBatchID = ids[Billed_Batch_ID], UnbilledBatchID = ids[Unbilled_Batch_ID], CurrentDate = DateTime.Now };
                logger.InfoFormat("Generated Log ID {0} and BatchIDs {1} & {2} ", ids[EXECUTION_LOG_ID], ids[Billed_Batch_ID], ids[Unbilled_Batch_ID]);
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

        [HttpPost]
        public ActionResult PostInvoice(int invoiceID, long billedBatchID, long unbilledBatchID, DateTime? batchTimeStamp)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Processing Invoice ID : {0}, Batch IDs : {1} - {2}, Timestamp : {3}", invoiceID, billedBatchID, unbilledBatchID, batchTimeStamp);

            facade.CreateStagingDataForInvoice(invoiceID, billedBatchID, unbilledBatchID, batchTimeStamp);

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
        [HttpPost]
        public ActionResult CreateExportFiles(List<int> invoices, long etlExecutionLogID, long billedBatchID, long unbilledBatchID)
        {
            OperationResult result = new OperationResult();

            VendorInvoiceStatusSummary summary = facade.CreateExportFiles(invoices, etlExecutionLogID, billedBatchID, unbilledBatchID, Request.RawUrl, LoggedInUserName, Session.SessionID);

            result.Data = summary;

            return Json(result, JsonRequestBehavior.AllowGet);
        }

    }
}
