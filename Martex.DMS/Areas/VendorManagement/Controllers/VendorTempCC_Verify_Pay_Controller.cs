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
    public partial class VendorTemporaryCCProcessingController : BaseController
    {
        /// <summary>
        /// Verifies the specified invoices.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <returns></returns>
        [HttpPost]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_TEMPCC_MATCH)]
        public ActionResult Verify(List<int> invoices)
        {
            OperationResult result = new OperationResult();
            var summary = facade.VerifyVendorTempCC(invoices, Request.RawUrl, LoggedInUserName, Session.SessionID);
            result.Data = summary;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Pays the specified invoices.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <returns></returns>
        [HttpPost]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_TEMPCC_POST)]
        public ActionResult VerifyBeforePay(List<int> invoices)
        {
            OperationResult result = new OperationResult();

            var summary = facade.VerifyVendorTempCC(invoices, Request.RawUrl, LoggedInUserName, Session.SessionID);
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
                const string Batch_ID = "BatchID";
                result.Data = new { BatchID = ids[Batch_ID], CurrentDate = DateTime.Now };
                logger.InfoFormat("Generated BatchID {0} ", ids[Batch_ID]);
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

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_TEMPCC_POST)]
        public ActionResult ProcessTempCCPost(int invoiceID, long batchID, DateTime? batchTimeStamp)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Processing Tempcc ID : {0}, Batch ID : {1}, Timestamp : {2}", invoiceID, batchID, batchTimeStamp);

            facade.CreateStagingDataForPost(invoiceID, batchID, batchTimeStamp,LoggedInUserName);

            result.Data = new { InvoiceID = invoiceID };

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_TEMPCC_POST)]
        public ActionResult UpdateBatchDetails(List<int> invoices, long batchID)
        {
            OperationResult result = new OperationResult();

            VendorCCStatusSummary summary = facade.UpdateBatchInvoiceStatus(invoices, batchID, Request.RawUrl, LoggedInUserName, Session.SessionID);

            result.Data = summary;
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
