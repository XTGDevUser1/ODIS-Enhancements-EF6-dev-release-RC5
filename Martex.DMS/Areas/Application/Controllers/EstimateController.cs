using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Model;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.Models;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Kendo.Mvc.UI;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application.Controllers
{
    public class EstimateController : BaseController
    {
        EstimateFacade facade = new EstimateFacade();
        //
        // GET: /Application/Estimate/
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.Country, true)]
        [ReferenceDataFilter(StaticData.PaymentType, true)]
        [ReferenceDataFilter(StaticData.CurrencyType, true)]
        [ReferenceDataFilter(StaticData.SendRecieptType, true)]
        [ReferenceDataFilter(StaticData.PhoneType, true)]
        [ReferenceDataFilter(StaticData.CountryCode, true)]
        [ReferenceDataFilter(StaticData.ServiceRequestDeclineReason, true)]
        public ActionResult Index()
        {
            var errors = CheckRequiredAttributes();

            if (logger.IsInfoEnabled)
            {
                logger.InfoFormat("EstimateController - Index() - Missing Required attributes - {0}", errors.Count);
                var index = 1;
                if (errors.Count > 0)
                {
                    logger.InfoFormat("EstimateController - Index() - Missing information and cannot calculate the estimate.  Need ");
                    foreach (var error in errors)
                    {
                        logger.InfoFormat("{0} - {1}", index, error);
                        index++;
                    }
                }
            }

            ViewData[StringConstants.REQUIRED_FIELDS_FOR_ESTIMATE] = errors;

            //TFS: 1218
            EstimateModel model = new EstimateModel();
            var srfacade = new ServiceFacade();
            ServiceRequest sr = srfacade.GetServiceRequestById(DMSCallContext.ServiceRequestID);
            var mode = "edit";
            var srStatus = sr.ServiceRequestStatu.Name;
            List<PurchaseOrder> issuedPurchaseOrders = new PORepository().GetIssuedPOsForSR(DMSCallContext.ServiceRequestID);

            if (srStatus == ServiceRequestStatusNames.CANCELLED || srStatus == ServiceRequestStatusNames.COMPLETE)
            {
                mode = "view";
            }
            else if (issuedPurchaseOrders != null && issuedPurchaseOrders.Count > 0)
            {
                mode = "view";
            }

            var programFacade = new ProgramMaintenanceFacade();
            List<ProgramInformation_Result> estimateInstructions = programFacade.GetProgramInfo(DMSCallContext.ProgramID, "InstructionScript", "Estimate").OrderBy(x => x.Sequence).ToList();
            model.EstimateInstructions = estimateInstructions;
            model.IsServiceEstimateAccepted = null;
            if (sr != null && sr.IsServiceEstimateAccepted != null)
            {
                model.IsServiceEstimateAccepted = sr.IsServiceEstimateAccepted;
                model.ServiceEstimateDenyReasonID = sr.ServiceEstimateDenyReasonID;
                model.EstimateDeclinedReasonOther = sr.EstimateDeclinedReasonOther;
            }
            // TFS : 1218 && NP : TFS 1239 - Do not run SP dms_ServiceRequestEstimate when selecting Save
            if ((sr != null && sr.ServiceEstimate.HasValue && sr.ServiceEstimate > 0) || "view".Equals(mode) || errors.Count > 0)
            {
                logger.Info("Not calling the Estimate sp - using the value from the SR");
                model.ServiceEstimate = sr.ServiceEstimate.GetValueOrDefault();
            }
            else
            {
                logger.Info("Calling the SP - ServiceRequestEstimate");
                var estimate = facade.GetServiceRequestEstimate(DMSCallContext.ServiceRequestID);
                model.ServiceEstimate = (estimate != null ? estimate.Estimate : 0);
                model.EstimatedTimeCost = estimate.EstimatedTimeCost;
            }

            if (sr != null && sr.ServiceEstimate != null && sr.ServiceEstimate != 0)
            {
                DMSCallContext.ServiceEstimateFee = sr.ServiceEstimate;
            }


            model.PaymentMode = mode;
            model.PaymentInformation = ProcessPaymentDetails(model.PaymentMode);
            return View(model);
        }

        [NoCache]
        [ReferenceDataFilter(StaticData.Country, true)]
        [ReferenceDataFilter(StaticData.PaymentType, true)]
        [ReferenceDataFilter(StaticData.CurrencyType, true)]
        [ReferenceDataFilter(StaticData.SendRecieptType, true)]
        [ReferenceDataFilter(StaticData.PhoneType, true)]
        [ReferenceDataFilter(StaticData.CountryCode, true)]
        public ActionResult PaymentDetails(string mode)
        {
            PaymentInformation paymentModel = ProcessPaymentDetails(mode);
            return PartialView(paymentModel);
        }

        public ActionResult SaveEstimate(EstimateModel model)
        {
            OperationResult result = new OperationResult();
            facade.SaveEstimate(model, DMSCallContext.ServiceRequestID, LoggedInUserName, Request.RawUrl, Session.SessionID, DMSCallContext.PrimaryProductID, DMSCallContext.ServiceMiles);
            DMSCallContext.ServiceEstimateFee = model.ServiceEstimate;
            result.Status = "Success";
            result.Data = new { ServiceEstimateFee = DMSCallContext.ServiceEstimateFee };
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        private PaymentInformation ProcessPaymentDetails(string mode)
        {
            ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            logger.Info("Executing Payment Controller GetPaymentForm");
            var loggedInUser = LoggedInUserName;

            PaymentInformation paymentModel = new PaymentInformation();
            ProgramMaintenanceFacade programFacade = new ProgramMaintenanceFacade();
            PaymentFacade paymentfacade = new PaymentFacade();

            paymentModel.MinimumAmount = 0.1;
            paymentModel.DispatchFee = programFacade.Get(DMSCallContext.ProgramID).DispatchFee;

            paymentModel.Payment = paymentfacade.GetPaymentTransaction(DMSCallContext.ServiceRequestID);
            if (paymentModel.Payment != null)
            {
                paymentModel.CardExpirationMonth = paymentModel.Payment.CCExpireDate.Value.Month;
                paymentModel.CardExpirationYear = paymentModel.Payment.CCExpireDate.Value.Year;
                //paymentModel.PaymentStatus = new CommonLookUpRepository().GetPaymentStatusByID(paymentModel.Payment.PaymentStatusID.GetValueOrDefault());
                if (paymentModel.Payment.BillingCountryID.HasValue)
                {
                    ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(paymentModel.Payment.BillingCountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, true);
                }
            }
            else
            {
                paymentModel.Payment = new Payment();
                paymentModel.Payment.BillingCountryID = 1;
                ViewData[StaticData.PaymentReason.ToString()] = ReferenceDataRepository.GetPaymentReasons(1).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            }
            paymentModel.Mode = mode;
            LoadDropDownValues();
            logger.Info("Finished Execution");
            return paymentModel;
        }

        public ActionResult LeaveTab(bool validationstatus)
        {
            logger.Info("Processing leave estimate tab");
            OperationResult result = new OperationResult();
            facade.LeaveEstimateTab(Request.RawUrl, LoggedInUserName, Session.SessionID, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, validationstatus);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        protected List<string> CheckRequiredAttributes()
        {
            List<string> missingFields = new List<string>();
            if (DMSCallContext.ProductCategoryName != "Home Locksmith" && DMSCallContext.VehicleTypeID == null)
            {
                missingFields.Add("Vehicle (Vehicle tab)");
            }
            if (DMSCallContext.ProductCategoryName != "Home Locksmith" && DMSCallContext.VehicleCategoryID == null)
            {
                missingFields.Add("Vehicle Category (Vehicle tab)");
            }
            if (DMSCallContext.ProductCategoryID == null)
            {
                missingFields.Add("Service (Service tab)");
            }

            if (DMSCallContext.ServiceLocationLatitude == null || DMSCallContext.ServiceLocationLongitude == null)
            {
                missingFields.Add("Location (Map tab)");
            }
            if (DMSCallContext.ProductCategoryName == "Tow" && (DMSCallContext.DestinationLatitude == null || DMSCallContext.DestinationLongitude == null))
            {
                missingFields.Add("Destination (Map tab)");
            }
            return missingFields;
        }



        #region Bind Drop Down
        /// <summary>
        /// Loads the drop down values.
        /// </summary>
        private void LoadDropDownValues()
        {
            ViewData[StaticData.CreditCardExpirationYear.ToString()] = GetCreditCardExpirationYear();
            ViewData[StaticData.CreditCardExpirationMonths.ToString()] = GetCreditCardExpirationMonths();
        }
        #endregion

        #region Drop Down Methods
        /// <summary>
        /// Gets the credit card expiration year.
        /// </summary>
        /// <returns></returns>
        protected IEnumerable<SelectListItem> GetCreditCardExpirationYear()
        {
            List<SelectListItem> years = new List<SelectListItem>();
            int currentYear = DateTime.Now.Year;
            string sYear = string.Empty;
            years.Add(new SelectListItem() { Text = "Select", Value = string.Empty, Selected = true });
            for (int i = 1; i <= 10; i++)
            {
                sYear = currentYear.ToString();
                years.Add(new SelectListItem() { Text = sYear, Value = sYear });
                currentYear++;
            }

            return years;
        }

        /// <summary>
        /// Gets the credit card expiration months.
        /// </summary>
        /// <returns></returns>
        protected IEnumerable<SelectListItem> GetCreditCardExpirationMonths()
        {
            List<SelectListItem> months = new List<SelectListItem>();
            months.Add(new SelectListItem() { Text = "Select", Value = string.Empty, Selected = true });
            months.Add(new SelectListItem() { Text = "01-January", Value = "1" });
            months.Add(new SelectListItem() { Text = "02-February", Value = "2" });
            months.Add(new SelectListItem() { Text = "03-March", Value = "3" });
            months.Add(new SelectListItem() { Text = "04-April", Value = "4" });
            months.Add(new SelectListItem() { Text = "05-May", Value = "5" });
            months.Add(new SelectListItem() { Text = "06-June", Value = "6" });
            months.Add(new SelectListItem() { Text = "07-July", Value = "7" });
            months.Add(new SelectListItem() { Text = "08-August", Value = "8" });
            months.Add(new SelectListItem() { Text = "09-September", Value = "9" });
            months.Add(new SelectListItem() { Text = "10-October", Value = "10" });
            months.Add(new SelectListItem() { Text = "11-November", Value = "11" });
            months.Add(new SelectListItem() { Text = "12-December", Value = "12" });
            return months;
        }
        #endregion
    }
}
