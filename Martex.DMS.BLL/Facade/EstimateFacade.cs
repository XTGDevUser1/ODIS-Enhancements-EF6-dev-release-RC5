using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Model;
using log4net;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Newtonsoft.Json;


namespace Martex.DMS.BLL.Facade
{
    public class EstimateFacade
    {
        EstimateRepository repo = new EstimateRepository();
        protected static readonly ILog logger = LogManager.GetLogger(typeof(EstimateFacade));

        /// <summary>
        /// Gets the service request estimate.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="productID">The product identifier.</param>
        /// <returns></returns>
        public ServiceRequestEstimate_Result GetServiceRequestEstimate(int serviceRequestID)
        {
            return repo.GetServiceRequestEstimate(serviceRequestID);
        }


        /// <summary>
        /// Saves the estimate.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionID">The session identifier.</param>
        /// <param name="productID">The product identifier.</param>
        /// <param name="serviceMiles">The service miles.</param>
        /// <param name="?">The ?.</param>
        public void SaveEstimate(EstimateModel model, int serviceRequestID, string loggedInUserName, string eventSource, string sessionID, int? productID, decimal? serviceMiles)
        {
            var decision = "Declined";
            logger.InfoFormat("Saving Estimate : SR {0}, ProductID {1}, ServiceMiles {2}", serviceRequestID, productID.GetValueOrDefault(), serviceMiles.GetValueOrDefault());

            string declineReason = string.Empty;
            if (model.IsServiceEstimateAccepted.GetValueOrDefault())
            {
                decision = "Accepted";
                ServiceRequest request = new ServiceRequest()
                {
                    ID = serviceRequestID,
                    IsServiceEstimateAccepted = true,
                    ServiceEstimate = model.ServiceEstimate,
                    EstimatedTimeCost = model.EstimatedTimeCost,
                    ServiceEstimateDenyReasonID = null
                };
                ServiceRepository serviceRepository = new ServiceRepository();
                serviceRepository.UpdateServiceRequestEstimateValues(request, loggedInUserName);
                List<ApplicationConfiguration> appConfiguration = new AppConfigRepository().GetApplicationConfigurationList("WebService", "CreditCard");
                if (appConfiguration == null)
                {
                    throw new DMSException("Unable to retrieve Application Configuration values for credit card processing");
                }
                ApplicationConfiguration storeID = appConfiguration.Where(u => u.Name.Equals("StoreID")).FirstOrDefault();
                string countryCode = string.Empty;
                string stateProvince = string.Empty;
                if (model.PaymentInformation.Payment.BillingCountryID != null)
                {
                    var lookupRepository = new CommonLookUpRepository();
                    var country = lookupRepository.GetCountry(model.PaymentInformation.Payment.BillingCountryID.Value);
                    if (country != null)
                    {
                        countryCode = country.ISOCode;
                    }
                }

                if (!string.IsNullOrEmpty(model.PaymentInformation.Payment.BillingStateProvince))
                {
                    stateProvince = model.PaymentInformation.Payment.BillingStateProvince.Split('-')[0].Trim();
                }
                int? paymentReasonID = null;
                var otherPaymentReasons = new CommonLookUpRepository().GetPaymentReasonsByName("Other");
                if (otherPaymentReasons != null && otherPaymentReasons.Count > 0)
                {
                    var paymentReasonTranTypeInfo = otherPaymentReasons.Where(a => a.PaymentTransactionTypeID == new CommonLookUpRepository().GetPaymentTransactionType("Info")).FirstOrDefault();
                    if(paymentReasonTranTypeInfo!=null)
                    {
                        paymentReasonID = paymentReasonTranTypeInfo.ID;
                    }
                }
                int? currencyTypeID = null;
                var currencyTypes = ReferenceDataRepository.GetCurrencyTypes();
                if(currencyTypes!=null && currencyTypes.Count>0)
                {
                    var USDollarCurrencyType = currencyTypes.Where(a=>a.Name == "US Dollar").FirstOrDefault();
                    if(USDollarCurrencyType !=null)
                    {
                        currencyTypeID = USDollarCurrencyType.ID;
                    }
                }
                Payment payment = new Payment()
                {
                    ServiceRequestID = serviceRequestID,
                    PaymentTypeID = model.PaymentInformation.Payment.PaymentTypeID,
                    PaymentStatusID = new CommonLookUpRepository().GetPaymentStatus("Unknown"),
                    PaymentTransactionTypeID = new CommonLookUpRepository().GetPaymentTransactionType("Info"),
                    PaymentReasonID = paymentReasonID,
                    PaymentReasonOther = "Collected on estimate",
                    PaymentDate = DateTime.Now,
                    Amount = null,
                    CurrencyTypeID = currencyTypeID,
                    CCAccountNumber = model.PaymentInformation.Payment.CCAccountNumber,
                    CCNameOnCard = model.PaymentInformation.Payment.CCNameOnCard,
                    CCExpireDate = new DateTime(model.PaymentInformation.CardExpirationYear, model.PaymentInformation.CardExpirationMonth, DateTime.DaysInMonth(model.PaymentInformation.CardExpirationYear, model.PaymentInformation.CardExpirationMonth)),
                    BillingLine1 = model.PaymentInformation.Payment.BillingLine1,
                    BillingLine2 = model.PaymentInformation.Payment.BillingLine2,
                    BillingCity = model.PaymentInformation.Payment.BillingCity,
                    BillingStateProvince = stateProvince,
                    BillingStateProvinceID = model.PaymentInformation.Payment.BillingStateProvinceID,
                    BillingPostalCode = model.PaymentInformation.Payment.BillingPostalCode,
                    BillingCountryCode = countryCode,
                    BillingCountryID = model.PaymentInformation.Payment.BillingCountryID,
                    CreateBy = loggedInUserName,
                    CreateDate = DateTime.Now
                };
                PaymentRepository payRepo = new PaymentRepository();
                payRepo.SaveOrUpdatePaymentDetails(payment);
            }
            else
            {
                ServiceRequest request = new ServiceRequest()
                {
                    ID = serviceRequestID,
                    IsServiceEstimateAccepted = false,
                    ServiceEstimate = model.ServiceEstimate,
                    EstimatedTimeCost = model.EstimatedTimeCost,
                    ServiceEstimateDenyReasonID = model.ServiceEstimateDenyReasonID,
                    EstimateDeclinedReasonOther = model.EstimateDeclinedReasonOther
                };
                ServiceRequestDeclineReason reason = repo.GetServiceRequestDeclineReasonById(model.ServiceEstimateDenyReasonID);
                if (reason != null)
                {
                    declineReason = reason.Description;
                }
                ServiceRepository serviceRepository = new ServiceRepository();
                serviceRepository.UpdateServiceRequestEstimateValues(request, loggedInUserName);
            }
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();

            Hashtable ht = new Hashtable();
            ht.Add("Estimate", model.ServiceEstimate.GetValueOrDefault().ToString("C"));
            ht.Add("ProductID", productID);
            ht.Add("ServiceMiles", serviceMiles);
            ht.Add("Decision", decision);
            ht.Add("DeclineReason", declineReason == "Other" ? "Other - " + model.EstimateDeclinedReasonOther : declineReason);
            EventLoggerFacade eventLogFacade = new EventLoggerFacade();
            long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.CAPTURE_ESTIMATE, ht.GetEventDetail(), null, loggedInUserName, serviceRequestID, EntityNames.SERVICE_REQUEST, sessionID);
            logger.InfoFormat("Event Log created for Event = {0} ID = {1}", EventNames.CAPTURE_ESTIMATE, eventLogId);
        }

        public void LeaveEstimateTab(string source, string currentUser, string sessionId, int relatedRecord, string enityName, bool validationstatus)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ServiceRequestRepository serviceRepository = new ServiceRequestRepository();
                serviceRepository.UpdateTabStatus(relatedRecord, TabConstants.EstimateTab, currentUser, validationstatus ? 1 : 2);

                tran.Complete();
            }
        }
    }
}
