using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using System.Text;
using Martex.DMS.ActionFilters;
using Martex.DMS.Models;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    /// <summary>
    /// Vendor Invoices Controller
    /// </summary>
    public partial class VendorInvoicesController
    {

        /// <summary>
        /// Checks if PO exists or not.
        /// </summary>
        /// <param name="PONumber">The PO number.</param>
        /// <returns></returns>
        public ActionResult CheckIfPOExistsOrNot(string PONumber)
        {
            OperationResult result = new OperationResult();
            if (!string.IsNullOrEmpty(PONumber))
            {
                PONumber = PONumber.Trim();
            }
            PurchaseOrder po = facade.GetPO(PONumber);
            if (po != null && po.IsActive.HasValue && !po.IsActive.Value)
            {
                result.Status = "PODeleted";
                return Json(result, JsonRequestBehavior.AllowGet);
            }

            if (po != null)
            {
                logger.InfoFormat("Found a PO with number = {0}", PONumber);
                int vendorInvoiceID = 0;
                PurchaseOrderStatu pos = facade.GetPOStatus(po.PurchaseOrderStatusID);
                List<VendorInvoice> vi = facade.GetVendorInvoiceListforPO(po.ID);
                if (vi != null && vi.Count > 0)
                {
                    logger.InfoFormat("PO {0} has invoices", po.ID);
                    vendorInvoiceID = vi[0].ID;
                }
                if (pos.Name != "Issued")
                {
                    logger.InfoFormat("PO {0} status = {1}", po.ID, pos.Name);
                    result.Status = "POStatusNotIssued";
                }
                else
                {
                    List<VendorInvoice> list = facade.GetVendorInvoiceListforPO(po.ID);
                    if (list.Count > 0)
                    {
                        result.Status = "POContainsInvoice";
                    }
                    /* TFS 150 - Need to consider PayStatusCode on PurchaseOrder */
                    /*//NP 02/24: Issue 137(NMC) : It should just check the IsPaybyCompanyCreditCard = 1
                    else if (po.IsPayByCompanyCreditCard.HasValue && po.IsPayByCompanyCreditCard.Value) //&& !string.IsNullOrEmpty(po.CompanyCreditCardNumber))
                    {
                        logger.InfoFormat("PO {0} was paid by CC", po.ID);
                        result.Status = "PO_PAID_BY_CC";
                    }

                    //TFS: 1718

                    else if (po.PurchaseOrderAmount.GetValueOrDefault() == 0 && po.TotalServiceAmount.GetValueOrDefault() == po.MemberServiceAmount.GetValueOrDefault())
                    {
                        logger.InfoFormat("PO {0} already paid by member", po.ID);
                        result.Status = "PO_ALREADY_PAID";
                    }*/
                    var paidByCCStatusCode = ReferenceDataRepository.GetPurchaseOrderPayStatusCodeByName("PaidByCC");
                    string errorMessage = string.Empty;
                    if (paidByCCStatusCode == null)
                    {
                        errorMessage = "PurchaseOrderStatusCode - PaidByCC is not set up in the system";
                        logger.Error(errorMessage);
                        throw new DMSException(errorMessage);
                    }

                    var paidByMemberStatusCode = ReferenceDataRepository.GetPurchaseOrderPayStatusCodeByName("PaidByMember");
                    if (paidByMemberStatusCode == null)
                    {
                        errorMessage = "PurchaseOrderStatusCode - PaidByMember is not set up in the system";
                        logger.Error(errorMessage);
                        throw new DMSException(errorMessage);
                    }
                    if (po.PayStatusCodeID != null && po.PayStatusCodeID == paidByCCStatusCode.ID)
                    {
                        logger.WarnFormat("PO [ ID : {0} ] paid by CC", po.ID);
                        result.Status = "PO_PAID_BY_CC";
                    }
                    else if (po.PayStatusCodeID != null && po.PayStatusCodeID == paidByMemberStatusCode.ID)
                    {
                        logger.WarnFormat("PO [ ID : {0} ] paid by member", po.ID);
                        result.Status = "PO_ALREADY_PAID";
                    }
                    else
                    {
                        result.Status = "Success";
                    }
                }

                // Check if the Vendor status = "Temporary".
                if("Success".Equals(result.Status, StringComparison.InvariantCultureIgnoreCase))
                {
                    var vendorID = po.VendorLocation.VendorID;
                    var vendorFacade = new VendorManagementFacade();
                    var vendor = vendorFacade.Get(vendorID);

                    var vendorStatus = vendor.VendorStatu.Name;
                    logger.InfoFormat("PO {0}s Vendor Status = {1}", po.ID, vendorStatus);
                    if ("Temporary".Equals(vendorStatus, StringComparison.InvariantCultureIgnoreCase))
                    {
                        result.Status = "Cannot add an invoice - PO is for a temporary vendor";//string.Format("The Vendor Status = {0}. Invoices cannot be entered.", vendorStatus);
                    }
                }
                logger.InfoFormat("PO {0} cleared validations around status, vendor status and vendor invoices", po.ID);
                result.Data = new { POID = po.ID, VendorLocationID = po.VendorLocationID, Status = pos.Name, VendorInvoiceID = vendorInvoiceID };
            }
            else
            {
                logger.InfoFormat("PO # {0} not found", PONumber);
                result.Status = "PONotFound";
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

    }
}
