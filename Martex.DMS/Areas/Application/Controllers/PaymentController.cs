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
    public class PaymentController : BaseController
    {
        #region Load Initial Stage of the data

        /// <summary>
        /// Gets the payment form.
        /// </summary>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [Authorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.Country, true)]
        [ReferenceDataFilter(StaticData.PaymentType, true)]
        [ReferenceDataFilter(StaticData.CurrencyType, true)]
        [ReferenceDataFilter(StaticData.SendRecieptType, true)]
        [ReferenceDataFilter(StaticData.PhoneType, true)]
        [ReferenceDataFilter(StaticData.CountryCode, true)]
        [HttpPost]
        public ActionResult GetPaymentForm(string mode)
        {
            ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            logger.Info("Executing Payment Controller GetPaymentForm");
            var loggedInUser = LoggedInUserName;

            PaymentInformation model = new PaymentInformation();
            ProgramMaintenanceFacade programFacade = new ProgramMaintenanceFacade();
            PaymentFacade paymentfacade = new PaymentFacade();

            model.MinimumAmount = 0.1;
            model.DispatchFee = programFacade.Get(DMSCallContext.ProgramID).DispatchFee;
            model.ISPCharge = paymentfacade.GetISPCharge(DMSCallContext.ServiceRequestID);
            model.FinalCharge = model.ISPCharge + model.DispatchFee;
            if (!mode.Equals("add"))
            {
                model.Payment = paymentfacade.Get(DMSCallContext.PaymentID, null);
                model.CardExpirationMonth = model.Payment.CCExpireDate.Value.Month;
                model.CardExpirationYear = model.Payment.CCExpireDate.Value.Year;

                int salePaymentTransactionTypeId = new CommonLookUpRepository().GetPaymentTransactionType("Sale").GetValueOrDefault();
                int paymentTransactionTypeId = model.Payment.PaymentTransactionTypeID.Value;
                if (paymentTransactionTypeId == 3)
                {
                    paymentTransactionTypeId = 2;
                }
                else if (paymentTransactionTypeId == 4)
                {
                    paymentTransactionTypeId = 1;
                }
                ViewData[StaticData.PaymentReason.ToString()] = ReferenceDataRepository.GetPaymentReasons(paymentTransactionTypeId).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
                model.PaymentStatus = new CommonLookUpRepository().GetPaymentStatusByID(model.Payment.PaymentStatusID.GetValueOrDefault());
                model.AuthorizationType = paymentfacade.GetAuthorizationType(model.Payment.ID);
                model.AuthorizationCode = paymentfacade.GetPaymentAuthorizationCode(model.Payment.ID);
                model.TransactionReference = paymentfacade.GetPaymentAuthorizationReferenceNumber(model.Payment.ID);
                if (model.Payment.BillingCountryID.HasValue)
                {
                    ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(model.Payment.BillingCountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, true);
                }
                if (mode.Equals("copy") || mode.Equals("credit"))
                {
                    model.Payment.Amount = null;
                    model.Payment.PaymentReasonID = null;
                    model.Payment.PaymentReasonOther = string.Empty;
                    model.Payment.Comments = string.Empty;
                }

                if (mode.Equals("credit"))
                {
                    PaymentRemainingBalance_Result remainingBalance = paymentfacade.GetReaminingBalance(DMSCallContext.PaymentID);
                    model.Payment.Amount = remainingBalance.RemainingBalance;
                    model.MaximunAmount = Convert.ToDouble(remainingBalance.RemainingBalance.HasValue ? remainingBalance.RemainingBalance.Value : 0);
                    model.Payment.PaymentTransactionTypeID = 2;
                    ViewData[StaticData.PaymentReason.ToString()] = ReferenceDataRepository.GetPaymentReasons(model.Payment.PaymentTransactionTypeID.Value).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
                }

                // Check the Payment Status if the Status is Approved do the following.
                model.SR_ContactMethodID = 4;// For Email
                model.SR_Email = DMSCallContext.MemberEmail;
                model.SR_PhoneNumber = DMSCallContext.StartCallData.ContactPhoneNumber;
                model.SR_PaymentID = model.Payment.ID;
            }
            else
            {

                model.Payment = new Payment();
                model.Payment.BillingCountryID = 1;
                ViewData[StaticData.PaymentReason.ToString()] = ReferenceDataRepository.GetPaymentReasons(1).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            }


            model.Payment.CurrencyTypeID = 1;
            model.Mode = mode;
            LoadDropDownValues();
            logger.Info("Finished Execution");
            return PartialView("_PaymentDetails", model);
        }



        [Authorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.Country, true)]
        [ReferenceDataFilter(StaticData.PaymentType, true)]
        [ReferenceDataFilter(StaticData.CurrencyType, true)]
        [ReferenceDataFilter(StaticData.SendRecieptType, true)]
        [ReferenceDataFilter(StaticData.PhoneType, true)]
        [ReferenceDataFilter(StaticData.CountryCode, true)]
        [HttpPost]
        public ActionResult GetMemberPaymentDetailsForm(int recordId, string mode)
        {
            ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            logger.Info("Payment Controller -> GetMemberPaymentDetailsForm() --> Executing Payment Controller GetPaymentForm");
            var loggedInUser = LoggedInUserName;

            PaymentInformation model = new PaymentInformation();
            ProgramMaintenanceFacade programFacade = new ProgramMaintenanceFacade();
            PaymentFacade paymentfacade = new PaymentFacade();

            model.MinimumAmount = 0.1;
            model.DispatchFee = programFacade.Get(DMSCallContext.ProgramID).DispatchFee;
            model.ISPCharge = paymentfacade.GetISPCharge(DMSCallContext.ServiceRequestID);
            model.FinalCharge = model.ISPCharge + model.DispatchFee;
            if (!mode.Equals("add"))
            {
                model.Payment = paymentfacade.GetPaymentForMemberPaymentMethod(recordId);
                model.CardExpirationMonth = model.Payment.CCExpireDate.Value.Month;
                model.CardExpirationYear = model.Payment.CCExpireDate.Value.Year;

                ViewData[StaticData.PaymentReason.ToString()] = ReferenceDataRepository.GetPaymentReasons(1).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
                if (model.Payment.BillingCountryID.HasValue)
                {
                    ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(model.Payment.BillingCountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, true);
                }
                if (mode.Equals("copy") || mode.Equals("credit"))
                {
                    model.Payment.Amount = null;
                    model.Payment.PaymentReasonID = null;
                    model.Payment.PaymentReasonOther = string.Empty;
                    model.Payment.Comments = string.Empty;
                }
                // Check the Payment Status if the Status is Approved do the following.
                model.SR_ContactMethodID = 4;// For Email
                model.SR_Email = DMSCallContext.MemberEmail;
                model.SR_PhoneNumber = DMSCallContext.StartCallData.ContactPhoneNumber;
            }
            model.Payment.CurrencyTypeID = 1;
            model.Mode = mode;
            LoadDropDownValues();
            logger.Info("Payment Controller -> GetMemberPaymentDetailsForm() --> Finished Execution");
            return PartialView("_PaymentDetails", model);
        }


        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.Country, true)]
        [ReferenceDataFilter(StaticData.PaymentType, true)]
        [ReferenceDataFilter(StaticData.CurrencyType, true)]
        [ReferenceDataFilter(StaticData.SendRecieptType, true)]
        [ReferenceDataFilter(StaticData.PhoneType, true)]
        [ReferenceDataFilter(StaticData.CountryCode, true)]
        public ActionResult Index()
        {
            logger.InfoFormat("PaymentController - Index()");
            ViewData[StaticData.PaymentReason.ToString()] = ReferenceDataRepository.GetPaymentReasons(1).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            CalculatePermissions();
            logger.Info("Executing Payment Controller Index");

            var loggedInUser = LoggedInUserName;

            PaymentInformation model = new PaymentInformation();
            ProgramMaintenanceFacade programFacade = new ProgramMaintenanceFacade();
            PaymentFacade paymentfacade = new PaymentFacade();

            model.MaximunAmount = paymentfacade.GetCreditCardThresholdAmount();
            model.MinimumAmount = 0.1;
            model.DispatchFee = programFacade.Get(DMSCallContext.ProgramID).DispatchFee;
            model.ISPCharge = paymentfacade.GetISPCharge(DMSCallContext.ServiceRequestID);
            model.FinalCharge = model.ISPCharge + model.DispatchFee;
            //TODO:
            model.Payment = paymentfacade.Get(0, DMSCallContext.ServiceRequestID);
            model.Mode = "view";
            if (model.Payment == null)
            {
                model.Payment = new Payment();
                model.Mode = "view";
                model.Payment.PaymentTransactionTypeID = 1;
                model.Payment.BillingCountryID = 1;
            }

            if (model.Payment != null)
            {
                string firstDigit = string.Empty;
                string lastFourDigit = string.Empty;
                string displayNumber = string.Empty;
                if (!string.IsNullOrEmpty(model.Payment.CCAccountNumber))
                {
                    firstDigit = model.Payment.CCAccountNumber.Substring(0, 1);
                    lastFourDigit = model.Payment.CCAccountNumber.Substring(model.Payment.CCAccountNumber.Length - 4, 4);
                    displayNumber = firstDigit + "XXXXXXXXXX" + lastFourDigit;
                }
                model.Payment.CCAccountNumber = displayNumber;
                if (model.Payment.CCExpireDate != null)
                {
                    model.CardExpirationMonth = model.Payment.CCExpireDate.Value.Month;
                    model.CardExpirationYear = model.Payment.CCExpireDate.Value.Year;
                }
                model.PaymentStatus = new CommonLookUpRepository().GetPaymentStatusByID(model.Payment.PaymentStatusID.GetValueOrDefault());
                ViewData[StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(model.Payment.BillingCountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, true);
                model.AuthorizationType = paymentfacade.GetAuthorizationType(model.Payment.ID);
                model.AuthorizationCode = paymentfacade.GetPaymentAuthorizationCode(model.Payment.ID);
                model.TransactionReference = paymentfacade.GetPaymentAuthorizationReferenceNumber(model.Payment.ID);

                // Check the Payment Status if the Status is Approved do the following.
                model.SR_ContactMethodID = 4;// For Email
                model.SR_Email = DMSCallContext.MemberEmail;
                model.SR_PhoneNumber = DMSCallContext.StartCallData.ContactPhoneNumber;
                model.SR_PaymentID = model.Payment.ID;
                DMSCallContext.PaymentID = model.Payment.ID;
                ViewData[StaticData.PaymentReason.ToString()] = ReferenceDataRepository.GetPaymentReasons(model.Payment.PaymentTransactionTypeID.Value == 3 ? 2 : model.Payment.PaymentTransactionTypeID.Value).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);

            }
            // Set Default value to US.
            model.Payment.CurrencyTypeID = 1;
            logger.Info("Loading payment list");
            model.PaymentDetails = paymentfacade.GetPaymentList(DMSCallContext.ServiceRequestID);
            model.MemberPaymentMethods = paymentfacade.GetMemberPaymentMethodList(DMSCallContext.MemberID, DMSCallContext.MembershipID);


            logger.Info("Loading Payment transactions");
            model.PaymentTransactions = paymentfacade.GetPaymentTransactonList(DMSCallContext.ServiceRequestID);
            logger.Info("Loading dropdowns");
            LoadDropDownValues();
            logger.Info("Finished Retrieving payment information");
            return PartialView("_Index", model);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="paymentID"></param>
        /// <returns></returns>
        public ActionResult GetPaymentID(string paymentID)
        {
            OperationResult result = new OperationResult();
            DMSCallContext.PaymentID = int.Parse(paymentID);
            logger.InfoFormat("Inside GetPaymentID() of Payment Controller. Call by the grid with the paymentID {0}, try to returns the Json object", paymentID);
            return Json(new { paymentID = paymentID }, JsonRequestBehavior.AllowGet);

        }


        /// <summary>
        /// Retrieves the contact logs.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult _GetContactLogs()
        {
            logger.InfoFormat("PaymentController - _GetContactLogs()");
            PaymentFacade facade = new PaymentFacade();
            List<PaymentSendReceiptHistory_Result> result = facade.GetPaymentSendReceiptHistory(DMSCallContext.PaymentID);
            return View(result);
        }

        /// <summary>
        /// Processes the send receipt.
        /// </summary>
        /// <param name="receipt">The receipt.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult _ProcessSendReciept(SendReceipt receipt)
        {
            logger.InfoFormat("PaymentController - _ProcessSendReciept(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                SendReceipt = receipt
            }));
            logger.Info("Processing Send Receipt");
            OperationResult result = new OperationResult();
            try
            {

                result.Status = OperationStatus.SUCCESS;
                PaymentFacade facade = new PaymentFacade();
                receipt.MemberID = DMSCallContext.MemberID;
                var clientRepository = new ClientRepository();
                Client cl = clientRepository.GetClientByProgram(DMSCallContext.ProgramID);
                facade.SendReceipt(receipt, cl != null ? cl.ID : 0, DMSCallContext.ProgramID, GetLoggedInUser().UserName, "/Request/Payment/ProcessSendReciept", HttpContext.Session.SessionID);

            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                logger.Warn(ex.Message, ex);
            }
            logger.InfoFormat("PaymentController - _ProcessSendReciept(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                OperationResult = result
            }));
            logger.Info("Finished Processing Send Receipt");
            return Json(result);
        }
        #endregion

        #region Grid Binding
        /// <summary>
        /// _Gets the payment details.
        /// </summary>
        /// <param name="command">The command.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetPaymentDetails([DataSourceRequest] DataSourceRequest command)
        {
            PaymentFacade paymentfacade = new PaymentFacade();
            List<Payment_List_Result> list = paymentfacade.GetPaymentList(DMSCallContext.ServiceRequestID);
            return Json(new DataSourceResult() { Data = list });
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetMemberPaymentMethodList([DataSourceRequest] DataSourceRequest command)
        {
            PaymentFacade paymentfacade = new PaymentFacade();
            var list = paymentfacade.GetMemberPaymentMethodList(DMSCallContext.MemberID, DMSCallContext.MembershipID);
            return Json(new DataSourceResult() { Data = list });
        }


        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetPaymentTransactionDetails([DataSourceRequest] DataSourceRequest request)
        {
            PaymentFacade paymentfacade = new PaymentFacade();
            List<PaymentTransactionList_Result> list = paymentfacade.GetPaymentTransactonList(DMSCallContext.ServiceRequestID);
            return Json(new DataSourceResult() { Data = list });
        }
        #endregion

        /// <summary>
        /// Gets the remaining balance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetRemainingBalance()
        {
            logger.InfoFormat("PaymentController - _GetRemainingBalance()");
            OperationResult result = new OperationResult();
            PaymentFacade facade = new PaymentFacade();
            PaymentRemainingBalance_Result payment = facade.GetReaminingBalance(DMSCallContext.PaymentID);
            result.Data = new { Amount = payment.RemainingBalance.HasValue ? payment.RemainingBalance.Value : 0 };
            logger.InfoFormat("PaymentController - _GetRemainingBalance(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                OperationResult = result
            }));
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #region Ajax Call to Populate Member Address
        /// <summary>
        /// Gets the member address.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.Country, true)]
        public ActionResult _GetMemberAddress()
        {
            logger.InfoFormat("PaymentController - _GetMemberAddress()");
            PaymentFacade facade = new PaymentFacade();
            AddressEntity addressEntity = facade.GetMemberAddress(DMSCallContext.MemberID, DMSCallContext.MembershipID);
            OperationResult result = new OperationResult();

            if (addressEntity == null)
            {
                result.Data = null;
            }
            else
            {
                result.Data = new
                {
                    Line1 = addressEntity.Line1,
                    Line2 = addressEntity.Line2,
                    Line3 = addressEntity.Line3,
                    City = addressEntity.City,
                    StateProvinceID = addressEntity.StateProvinceID,
                    StateProvince = addressEntity.StateProvince,
                    CountryID = addressEntity.CountryID,
                    PostalCode = addressEntity.PostalCode
                };
            }
            logger.InfoFormat("PaymentController - _GetMemberAddress(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                OperationResult = result
            }));
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion

        #region Process Credit Card Transaction
        /// <summary>
        /// Does the payment transaction.
        /// </summary>
        /// <param name="paymentModel">The payment model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [HttpPost]
        public ActionResult DoPaymentTransaction(PaymentInformation paymentModel)
        {
            paymentModel.MemberID = DMSCallContext.MemberID;
            paymentModel.ClientName = DMSCallContext.ClientName;
            logger.InfoFormat("PaymentController - DoPaymentTransaction(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                PaymentInformation = paymentModel
            }));

            CreditCardTransactionStatus status = null;
            OperationResult result = new OperationResult();
            result.OperationType = OperationStatus.SUCCESS;
            logger.Info("Executing DoPaymentTransaction");
            PaymentFacade facade = new PaymentFacade();

            paymentModel.Payment.ServiceRequestID = DMSCallContext.ServiceRequestID;
            try
            {
                status = facade.SavePaymentTransaction(paymentModel, GetLoggedInUser().UserName, DMSCallContext.PaymentID, DMSCallContext.ProgramID, HttpContext.Session.SessionID);
                result.ErrorMessage = status.Message;
                result.Data = status;
                if (status.isSuccess)
                {
                    DMSCallContext.PaymentID = status.PaymentID.GetValueOrDefault();
                }
                if (!status.isSuccess)
                {
                    result.OperationType = OperationStatus.ERROR;

                }
            }
            catch (Exception ex)
            {
                logger.Warn(ex.Message, ex);
                result.OperationType = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;

            }

            logger.Info("Finish DoPaymentTransaction");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Leaves the payment tab.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        public ActionResult LeavePaymentTab()
        {
            logger.InfoFormat("PaymentController - LeavePaymentTab()");
            OperationResult result = new OperationResult()
            {
                Status = OperationStatus.SUCCESS
            };

            var loggedInUser = LoggedInUserName;
            // Log an event that Finish tab is visited.
            PaymentFacade facade = new PaymentFacade();
            facade.UpdateServiceRequest(Request.RawUrl, loggedInUser, DMSCallContext.ServiceRequestID, HttpContext.Session.SessionID);

            return Json(result, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Calculates the permissions.
        /// </summary>
        private void CalculatePermissions()
        {
            var appConfigValue = AppConfigRepository.GetValue(AppConfigConstants.ROLES_THAT_SHOW_ADD_NEW_PAYMENT);

            if (!string.IsNullOrEmpty(appConfigValue))
            {
                string[] tokens = appConfigValue.Split(',');
                var up = GetProfile();
                bool roleMatchFound = false;
                foreach (var role in up.UserRoles)
                {
                    if (tokens.Contains(role))
                    {
                        roleMatchFound = true;
                        break;
                    }
                }
                DMSCallContext.IsShowAddPayment = roleMatchFound;
            }
            else
            {
                DMSCallContext.IsShowAddPayment = false;
            }
        }

        public ActionResult CheckSRHasPaid(int? serviceRequestID)
        {
            OperationResult result = new OperationResult();
            PaymentFacade facade = new PaymentFacade();
            bool hasSrPaid = false;
            var list = facade.GetPaymentList(serviceRequestID.GetValueOrDefault());
            if (list != null && list.Count > 0)
            {
                var approvedSalePaymentsCount = list.Where(a => a.PaymentStatus == "Approved" && a.TransactionType == "Sale").Count();
                if (approvedSalePaymentsCount > 0)
                {
                    hasSrPaid = true;
                }
            }
            if (!DMSCallContext.AllowPaymentProcessing)
            {
                hasSrPaid = true;
            }
            result.Data = new { HasSRPaid = hasSrPaid };
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

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
