using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.ActionFilters;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Models;
using Martex.DMS.DAL.DMSBaseException;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.BLL.Model.Claims;

namespace Martex.DMS.Areas.Claims.Controllers
{
    public partial class ClaimController
    {
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.ClaimStatus, true)]
        [ReferenceDataFilter(StaticData.ClaimCategory, true)]
        [ReferenceDataFilter(StaticData.ContactMethodForVendor, true)]
        [ReferenceDataFilter(StaticData.ClaimRejectReason, true)]
        [ReferenceDataFilter(StaticData.NextAction, true)]
        [ReferenceDataFilter(StaticData.FinishUsers, true)]
        [NoCache]
        public ActionResult _Claims_Information(int suffixClaimID, int? claimTypeID = null)
        {
            var facade = new ClaimsFacade();
            ClaimInformationModel model = facade.GetClaimInformation(suffixClaimID);

            ViewData["OwnerPrograms"] = ReferenceDataRepository.GetOwnerProgramsForClaim().ToSelectListItem(x=>x.ID.ToString(), y=>y.Name.ToString());
            return View(model);
        }

        public ClaimInformationModel InitlizeClaimInformationDetails(int claimID)
        {
            var facade = new ClaimsFacade();
            ClaimInformationModel model = facade.GetClaimInformation(claimID);
            return model;
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveClaimInformation(ClaimInformationModel model)
        {
            var facade = new ClaimsFacade();
            string mode = model.Claim.ID > 0 ? "Edit" : "Add";
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            ValidateInputs(model);
            facade.SaveClaimInformation(model, LoggedInUserName,Session.SessionID);
            result.Data = new { Mode = mode, ClaimID = model.Claim.ID };
            return Json(result);
        }


        #region Validate Inputs
        private void ValidateInputs(ClaimInformationModel model)
        {

            bool isValid = true;
            StringBuilder sb = new StringBuilder();

            #region Validate Payee Types and Values Except Ford QFC
            if (!"Ford QFC".Equals(model.ClaimTypeName, StringComparison.InvariantCultureIgnoreCase))
            {
                if (string.IsNullOrEmpty(model.Claim.PayeeType))
                {
                    sb.AppendLine("Payee Type is required.");
                    sb.AppendLine("<br/>");
                    isValid = false;
                }
            }
           
            if (PayeeTypeName.MEMBER.Equals(model.Claim.PayeeType, StringComparison.InvariantCultureIgnoreCase))
            {
                bool isValidSection = false;
                if (model.Claim.PurchaseOrderID.HasValue)
                {
                    isValidSection = true;
                }
                else if (model.Claim.MemberID.HasValue)
                {
                    isValidSection = true;
                }
                if (!isValidSection)
                {
                    sb.AppendLine("Payee Type Member : Member ID is not supplied Properly.");
                    sb.AppendLine("<br/>");
                    isValid = false;
                }
            }
            if (PayeeTypeName.VENDOR.Equals(model.Claim.PayeeType))
            {
                if (!model.Claim.VendorID.HasValue)
                {
                    sb.AppendLine("Payee Type Vendor ID Value is not supplied.");
                    sb.AppendLine("<br/>");
                    isValid = false;
                }
            }
            if (!model.Claim.ClaimTypeID.HasValue)
            {
                sb.AppendLine("Claim Type is required.");
                sb.AppendLine("<br/>");
                isValid = false;
            }
            #endregion

            #region Verified Fileds which should not be updated 
            if(!model.Claim.ClaimStatusID.HasValue)
            {
                sb.AppendLine("Claim Status is required.");
                sb.AppendLine("<br/>");
                isValid = false;
            }
            if (!model.Claim.ClaimCategoryID.HasValue)
            {
                sb.AppendLine("Claim Category is required.");
                sb.AppendLine("<br/>");
                isValid = false;
            }

            if (!model.Claim.AmountRequested.HasValue)
            {
                sb.AppendLine("Requested Amount is required.");
                sb.AppendLine("<br/>");
                isValid = false;
            }
            #endregion

            #region When Status is Not Approved or Approved Following fields are required

            if (string.IsNullOrEmpty(model.Claim.ContactName))
            {
                sb.AppendLine("Missing payee name");
                sb.AppendLine("<br/>");
                isValid = false;
            }
            
            #endregion

            #region Address Validation Except for the Ford QFC
            if (!"Ford QFC".Equals(model.ClaimTypeName, StringComparison.InvariantCultureIgnoreCase))
            {
                if (string.IsNullOrEmpty(model.Claim.PaymentAddressLine1) ||
                    string.IsNullOrEmpty(model.Claim.PaymentAddressCity) ||
                    string.IsNullOrEmpty(model.Claim.PaymentAddressPostalCode) ||
                    !model.Claim.PaymentAddressCountryID.HasValue ||
                    !model.Claim.PaymentAddressStateProvinceID.HasValue)
                {
                    sb.AppendLine("Missing claim address.");
                    sb.AppendLine("<br/>");
                    isValid = false;
                }
            }
            #endregion

            #region When Status is Approved Following Fields are required
            if (model.Claim.ClaimStatusID.HasValue)
            {
                Claim claimFromDB = new ClaimsRepository().GetClaim(model.Claim.ID);
                ClaimStatu claimStatus = new CommonLookUpRepository().GetClaimStatus(model.Claim.ClaimStatusID.GetValueOrDefault());
                ClaimStatu claimStatusFromDb = new CommonLookUpRepository().GetClaimStatus(claimFromDB.ClaimStatusID.GetValueOrDefault());
                
                if (claimStatus.ID != claimStatusFromDb.ID)
                {
                    if (claimStatus.Name.Equals("ReadyForPayment"))
                    {
                        var repository = new ClaimsRepository();
                        if (!repository.IsSecurableAccessible(DMSSecurityProviderFriendlyName.CLAIMS_STATUS_READYFORPAYMENT, GetLoggedInUserId()))
                        {
                            sb.AppendLine("Access denied to set Claim status as Ready For Payment");
                            sb.AppendLine("<br/>");
                            isValid = false;
                        }
                    }
                }
            }
            #endregion

            #region Validate Approved Amount

            //KB: TFS : 2463 -   IF Status IN (‘In-Process’,’AuthorizationIssued’) THEN ApprovedAmount can be = $0,All other cases the ApprovedAmount must be > $0
            //KB: TFS : 132 - Added Cancelled and Denied statuses to the list that can allow 0 approved amount.
            if (!("In-Process".Equals(model.ClaimStatusName, StringComparison.InvariantCultureIgnoreCase) ||
                "Authorization Issued".Equals(model.ClaimStatusName, StringComparison.InvariantCultureIgnoreCase) ||
                "Cancelled".Equals(model.ClaimStatusName, StringComparison.InvariantCultureIgnoreCase) ||
                "Denied".Equals(model.ClaimStatusName, StringComparison.InvariantCultureIgnoreCase))
                &&
                (model.Claim.AmountApproved == null || model.Claim.AmountApproved <= 0))
            {
                sb.AppendLine("Amount Approved should be greater than $0");
                sb.AppendLine("<br/>");
                isValid = false;
            }

            if (model.Claim.AmountApproved.HasValue)
            {
                if (model.Claim.AmountApproved.Value > model.Claim.AmountRequested.GetValueOrDefault())
                {
                    sb.AppendLine("Amount Approved should not exceed requested amount");
                    sb.AppendLine("<br/>");
                    isValid = false;
                }

                
            }
            #endregion

            #region Validate ACES Claim Type
            if (model.Claim.ClaimTypeID.HasValue && model.Claim.ClaimStatusID.HasValue)
            {
                var lookup = new CommonLookUpRepository();
                ClaimType claimType = lookup.GetClaimType(model.Claim.ClaimTypeID.Value);
                ClaimStatu claimStatus = lookup.GetClaimStatus(model.Claim.ClaimStatusID.Value);
                if (claimType.IsFordACES.GetValueOrDefault())
                {
                    if (claimStatus.Name.Equals("ReadyForPayment") && !model.Claim.ACESClearedDate.HasValue)
                    {
                        sb.AppendLine("ACES claim cannot be set to ReadyForPayment until the ACES Cleared Date is set");
                        sb.AppendLine("<br/>");
                        isValid = false;
                    }
                }
            }
            #endregion

            #region Validate Mileage - Required when Program = "Ford" or ClaimType = Motorhome or roadside or payee is vendor or member or claim status is one of {Approved, Authorization Issued,Ready For Payment, Paid }
            if ("Ford".Equals(model.ProgramName, StringComparison.InvariantCultureIgnoreCase) &&
                ("Motorhome Reimbursement".Equals(model.ClaimTypeName, StringComparison.InvariantCultureIgnoreCase) 
                ||
                "Roadside Reimbursement".Equals(model.ClaimTypeName, StringComparison.InvariantCultureIgnoreCase)
                ) &&
                (new string[] { "Authorization Issued", "Approved", "Ready For Payment", "Paid" }).Contains(model.ClaimStatusName))
            {
                if (model.Claim.CurrentMiles == null)
                {
                    sb.AppendLine("Mileage is required.");
                    sb.AppendLine("<br/>");
                    isValid = false;

                }
            }


            #endregion

            #region TFS 132 : ReceivedDate is mandatory

            if (model.Claim.ReceivedDate == null)
            {
                sb.AppendLine("Receive Date is missing.");
                sb.AppendLine("<br/>");
                isValid = false;
            }

            #endregion
            if (!isValid)
            {
                throw new DMSException(sb.ToString());
            }

        }
        #endregion

        [HttpPost]
        public ActionResult Add(ClaimInput model)
        {
            OperationResult result = new OperationResult();
            int claimID = facade.CreateClaim(model,LoggedInUserName);
            result.Data = claimID;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

    }
}
