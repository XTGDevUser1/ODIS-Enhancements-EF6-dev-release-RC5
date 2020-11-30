using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Models;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Entities;

using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.Areas.Claims.Controllers
{
    public partial class ClaimController 
    {
        [HttpPost]
        //[DMSAuthorize]
        public ActionResult VerifyForReadyForPayment(List<int> claims, string useraction)
        {
            OperationResult result = new OperationResult();
            ClaimStatusSummary summary = null;
            logger.Info("Trying to Verify Claims for Ready for Payment");
            if (claims == null)
            {
                logger.Info("Error due to model binding");
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = "Unable to get the list of Claims";
            }
            else
            {
                logger.Info("Verifying claims");
                summary = facade.VerifyClaimsReadyForPayment(LoggedInUserName, Session.SessionID, claims, Request.RawUrl,useraction);
                result.Data = summary;
            }
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
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.VENDOR_BUTTON_PAY_INVOICES)]
        public ActionResult ProcessClaim(int claimID, long batchID, DateTime? batchTimeStamp)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Processing Claim ID : {0}, Batch ID : {1}, Timestamp : {2}", claimID, batchID, batchTimeStamp);

            facade.CreateStagingDataForClaim(claimID, batchID, batchTimeStamp, LoggedInUserName);

            result.Data = new { ClaimID = claimID };

            return Json(result, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Creates the export files.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <param name="etlExecutionLogID">The etl execution log unique identifier.</param>
        /// <param name="batchID">The batch unique identifier.</param>
        /// <returns></returns>
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.VENDOR_BUTTON_PAY_INVOICES)]
        public ActionResult CreateExportFiles(List<int> claims, long etlExecutionLogID, long batchID)
        {
            OperationResult result = new OperationResult();

            ClaimStatusSummary summary = facade.CreateExportFiles(claims, etlExecutionLogID, batchID, Request.RawUrl, LoggedInUserName, Session.SessionID);

            result.Data = summary;

            return Json(result, JsonRequestBehavior.AllowGet);
        }

    }
}
