using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using System.Collections;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.DAL.Common;
using log4net;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class PaymentRepository
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(PaymentRepository));
        /// <summary>
        /// Creates the communication queque.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <param name="contactLogID">The contact log ID.</param>
        /// <param name="contactMethodID">The contact method ID.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="phoneNumber">The phone number.</param>
        /// <param name="email">The email.</param>
        /// <param name="contactMethodName">Name of the contact method.</param>
        /// <exception cref="DMSException">
        /// Unable to retrieve template PaymentReceipt + contactMethodName
        /// or
        /// </exception>
        public void CreateCommunicationQueque(int? programID, int paymentID, int contactLogID, int contactMethodID, string userName, string phoneNumber, string email, string contactMethodName)
        {
            Template activeTemplate = null;
            PaymentReceiptValues_Result result = null;
            
            const string PAYMENT_RECEIPT_TEMPLATE = "PaymentReceiptTemplate";
            var progRepository = new ProgramMaintenanceRepository();
            var paymentReceiptConfig = progRepository.GetProgramInfo(programID, "Application", "Rule").Where(x=>x.Name == PAYMENT_RECEIPT_TEMPLATE).FirstOrDefault();
            string paymentReceiptTemplate = string.Empty;

            if (paymentReceiptConfig != null)
            {
                paymentReceiptTemplate = paymentReceiptConfig.Value;
                logger.InfoFormat("PaymentReceipt template read from ProgramConfig {0}", paymentReceiptTemplate);
            }
            else
            {
                var appConfig = AppConfigRepository.GetValue(PAYMENT_RECEIPT_TEMPLATE);
                if (!string.IsNullOrEmpty(appConfig))
                {
                    paymentReceiptTemplate = appConfig;
                    logger.InfoFormat("PaymentReceipt template read from ApplicationConfiguration {0}", paymentReceiptTemplate);
                }                
            }

            if (string.IsNullOrEmpty(paymentReceiptTemplate))
            {
                string message = "Couldn't find PaymentReceipt Template in ProgramConfig nor AppConfig";
                logger.Warn(message);
                throw new DMSException(message);
            }

            using (DMSEntities entities = new DMSEntities())
            {
                // Retrieve Template
                activeTemplate = entities.Templates.Where(t => t.Name == paymentReceiptTemplate && t.IsActive == true).FirstOrDefault<Template>();
                if (activeTemplate == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve template PaymentReceipt : {0}",paymentReceiptTemplate));
                }
                // Retrieve Payment Receipt Values
                result = entities.GetPaymentReceiptValues(paymentID).FirstOrDefault();
                if (result == null)
                {
                    throw new DMSException(String.Format("Unable to retrieve details for the Payment ID {0}", paymentID));
                }

            }
            // Create Hash Table to hold the values
            Hashtable htParams = new Hashtable();
            htParams.Add("CCOrderID", result.CCOrderID.BlankIfNull());
            htParams.Add("PaymentDate", result.PaymentDate.BlankIfNull());
            htParams.Add("Service", result.Service.BlankIfNull());
            htParams.Add("ServiceLocationAddress", result.ServiceLocationAddress.BlankIfNull());
            htParams.Add("DestinationAddress", result.DestinationAddress.BlankIfNull());
            htParams.Add("NameOnCard", result.NameOnCard.BlankIfNull());
            htParams.Add("CardType", result.CardType.BlankIfNull());
            htParams.Add("CCPartial", result.CardNumber.BlankIfNull());
            htParams.Add("ExpirationDate", result.ExpirationDate.BlankIfNull());
            htParams.Add("Amount", result.Amount.GetValueOrDefault().ToString("C"));
            htParams.Add("type", result.Type.BlankIfNull());
            htParams.Add("Program", result.Program.BlankIfNull());

            CommunicationQueue cQueue = new CommunicationQueue();
            CommunicationQueueRepository cqRepository = new CommunicationQueueRepository();

            cQueue.ContactLogID = contactLogID;
            cQueue.ContactMethodID = contactMethodID;
            cQueue.TemplateID = activeTemplate.ID;
            cQueue.MessageData = htParams.GetMessageData();

            //KB: NotificationRecipient
            if ("Phone".Equals(contactMethodName, StringComparison.InvariantCultureIgnoreCase) ||
                   "Text".Equals(contactMethodName, StringComparison.InvariantCultureIgnoreCase) ||
                   "Fax".Equals(contactMethodName, StringComparison.InvariantCultureIgnoreCase))
            {
                cQueue.NotificationRecipient = phoneNumber;
            }
            else
            {
                cQueue.NotificationRecipient = email;
            }

            cQueue.Subject = TemplateUtil.ProcessTemplate(activeTemplate.Subject, htParams);
            cQueue.MessageText = TemplateUtil.ProcessTemplate(activeTemplate.Body, htParams);
            cQueue.Attempts = 0;
            cQueue.ScheduledDate = null;
            cQueue.CreateDate = DateTime.Now;
            cQueue.CreateBy = userName;
            cqRepository.Save(cQueue);
        }

        public List<PaymentReceiptValues_Result> GetPaymentReceiptValues(int paymentID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetPaymentReceiptValues(paymentID).ToList();
            }
        }
        /// <summary>
        /// Gets the payment send receipt history.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public List<PaymentSendReceiptHistory_Result> GetPaymentSendReceiptHistory(int paymentID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetPaymentSendReceiptHistory(paymentID).ToList();
            }
        }
        /// <summary>
        /// Gets the reamining balance.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public PaymentRemainingBalance_Result GetReaminingBalance(int paymentID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetPaymentRemainingBalance(paymentID).FirstOrDefault();
            }
        }
        /// <summary>
        /// Gets the ISP charge.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public decimal GetISPCharge(int serviceRequestID)
        {
            decimal ispCharge = 0;
            using (DMSEntities entities = new DMSEntities())
            {
                PurchaseOrderStatu purchaseOrder = entities.PurchaseOrderStatus.Where(u => u.Name.Equals("Issued")).FirstOrDefault();
                if (purchaseOrder != null)
                {
                    decimal? result = 0;
                    result = entities.PurchaseOrders.Where(u => u.ServiceRequestID == serviceRequestID)
                                                    .Where(p => p.PurchaseOrderStatusID == purchaseOrder.ID)
                                                    .Sum(s => s.PurchaseOrderAmount);
                    if (!result.HasValue)
                    {
                        result = 0;
                    }
                    ispCharge = result.Value;
                }
            }
            return ispCharge;
        }
        /// <summary>
        /// Gets the payment list.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<Payment_List_Result> GetPaymentList(int serviceRequestID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetPaymentList(serviceRequestID).ToList<Payment_List_Result>(); ;
            }
        }
        /// <summary>
        /// Gets the payment transacton list.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<PaymentTransactionList_Result> GetPaymentTransactonList(int serviceRequestID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetPaymentTransactionList(serviceRequestID).ToList<PaymentTransactionList_Result>(); ;
            }
        }

        /// <summary>
        /// Gets the payment transactions.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        public List<PaymentTransaction> GetPaymentTransactions(int serviceRequestID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PaymentTransactions.Include("PaymentTransactionType").Where(a => a.ServiceRequestID == serviceRequestID).ToList();
            }
        }

        /// <summary>
        /// Gets the member payment method list.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="membershipID">The membership identifier.</param>
        /// <returns></returns>
        public List<MemberPaymentMethodList_Result> GetMemberPaymentMethodList(int? memberID, int? membershipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberPaymentMethod(memberID, membershipID).ToList();
            }
        }

        /// <summary>
        /// Gets the member address.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
        public AddressEntity GetMemberAddress(int memberID, int memberShipID)
        {
            AddressEntity address = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(n => n.Name.Contains("Member")).FirstOrDefault();

                if (entity != null)
                {
                    address = (from ae in dbContext.AddressEntities
                               join m in dbContext.Members on ae.RecordID equals m.ID
                               where ae.EntityID.Value == entity.ID
                               where ae.RecordID.Value == memberID
                               select ae).FirstOrDefault();


                }

                if (address == null)
                {
                    var member = dbContext.Entities.Where(n => n.Name.Contains("Membership")).FirstOrDefault();

                    if (member != null)
                    {
                        address = (from ae in dbContext.AddressEntities
                                   join m in dbContext.Members on ae.RecordID equals m.ID
                                   where ae.EntityID.Value == member.ID
                                   where ae.RecordID.Value == memberShipID
                                   select ae).FirstOrDefault();
                    }
                }
            }

            return address;
        }
        /// <summary>
        /// Gets the credit card threshold amount.
        /// </summary>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// ApplicationConfigurationTypes or ApplicationConfigurationCategories values are missing
        /// or
        /// ApplicationConfiguration values are missing
        /// </exception>
        public double GetCreditCardThresholdAmount()
        {
            double amount = 0;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var appConfigurationType = dbContext.ApplicationConfigurationTypes.Where(n => n.Name.Equals("WebService")).FirstOrDefault();
                var appConfigurationCategory = dbContext.ApplicationConfigurationCategories.Where(n => n.Name.Equals("CreditCard")).FirstOrDefault();

                if (appConfigurationType == null || appConfigurationCategory == null)
                {
                    throw new DMSException("ApplicationConfigurationTypes or ApplicationConfigurationCategories values are missing");
                }
                var appConfiguration = dbContext.ApplicationConfigurations.Where(n => n.Name.Equals("CreditCardThresholdAmount"))
                                                                           .Where(t => t.ApplicationConfigurationTypeID == appConfigurationType.ID)
                                                                           .Where(t => t.ApplicationConfigurationCategoryID == appConfigurationCategory.ID)
                                                                           .FirstOrDefault();
                if (appConfiguration == null)
                {
                    throw new DMSException("ApplicationConfiguration values are missing");
                }
                double.TryParse(appConfiguration.Value, out amount);
            }

            return amount;
        }
        /// <summary>
        /// Updates the payment transaction.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <exception cref="System.Exception">Unable to retrieve details for Payment Transaction</exception>
        public void UpdatePaymentTransaction(PaymentTransaction payment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                PaymentTransaction paymentDetails = dbContext.PaymentTransactions.Where(id => id.ID == payment.ID).FirstOrDefault();

                if (paymentDetails == null)
                {
                    throw new Exception("Unable to retrieve details for Payment Transaction");
                }
                paymentDetails.PaymentStatusID = payment.PaymentStatusID;
                paymentDetails.ResponseAVS = payment.ResponseAVS;
                paymentDetails.ResponseOrderNum = payment.ResponseOrderNum;
                paymentDetails.ResponseError = payment.ResponseError;
                paymentDetails.ResponseCode = payment.ResponseCode;
                paymentDetails.ResponseMessage = payment.ResponseMessage;
                paymentDetails.ResponseTime = payment.ResponseTime;
                paymentDetails.ResponseTdate = payment.ResponseTdate;
                paymentDetails.PaymentID = payment.PaymentID;
                paymentDetails.ResponseApproved = payment.ResponseApproved;
                paymentDetails.ResponseRef = payment.ResponseRef;
                paymentDetails.ResponseAuthResponse = payment.ResponseAuthResponse;
                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// Encrypts the decrypt.
        /// </summary>
        /// <param name="accountNumber">The account number.</param>
        /// <param name="isEncrypt">if set to <c>true</c> [is encrypt].</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Unable to retrieve Application Configuration values for credit card processing
        /// or
        /// Unable to retrieve Application Configuration values for encryption
        /// </exception>
        public string EncryptDecrypt(string accountNumber, bool isEncrypt)
        {
            string returnValue = string.Empty;
            if (isEncrypt)
            {
                returnValue = AES.Encrypt(accountNumber);//, passPhraze.Value, saltValue.Value, hasAlgorithm.Value, passwordIterationsInt, initVector.Value, keySizeInt);
            }
            else
            {
                returnValue = AES.Decrypt(accountNumber);//, passPhraze.Value, saltValue.Value, hasAlgorithm.Value, passwordIterationsInt, initVector.Value, keySizeInt);
            }
            return returnValue;
        }
        /// <summary>
        /// Saves the payment transaction.
        /// </summary>
        /// <param name="payment">The payment.</param>
        public void SavePaymentTransaction(PaymentTransaction payment)
        {
            //Encrypt CCAccount Number
            payment.CCAccountNumber = EncryptDecrypt(payment.CCAccountNumber, true);
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.PaymentTransactions.Add(payment);
                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// Gets the unique order from payment.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public string GetUniqueOrderFromPayment(int serviceRequestID)
        {
            int value = 1;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.Payments.Where(s => s.ServiceRequestID == serviceRequestID).Count();

                value = result + 1;

            }
            return serviceRequestID.ToString() + "-" + value.ToString();
        }
        /// <summary>
        /// Saves the payment details.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <returns></returns>
        public int SavePaymentDetails(Payment payment)
        {
            //Encrypt CCAccount Number
            payment.CCAccountNumber = EncryptDecrypt(payment.CCAccountNumber, true);
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Payments.Add(payment);
                dbContext.SaveChanges();
                return payment.ID;
            }
        }
        /// <summary>
        /// Saves the payment authorization.
        /// </summary>
        /// <param name="model">The model.</param>
        public void SavePaymentAuthorization(PaymentAuthorization model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.PaymentAuthorizations.Add(model);
                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// Gets the specified payment ID.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public Payment Get(int paymentID, int? serviceRequestID)
        {
            Payment payment = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (serviceRequestID == null)
                {
                    payment = dbContext.Payments.Where(u => u.ID == paymentID).FirstOrDefault();
                }
                else
                {
                    // Retrieve the latest transaction for the current Service Request ID
                    payment = dbContext.Payments.Where(u => u.ServiceRequestID == serviceRequestID.Value).OrderByDescending(u => u.ID).FirstOrDefault();

                }
            }

            //Sanghi : for existing record in the database, we will not have cipher text.
            //         so while decrypting in case we have any error that can be omitted
            try
            {
                //KB: Added a null check before accessing properties on the payment object.
                if (payment != null)
                {
                    payment.CCAccountNumber = EncryptDecrypt(payment.CCAccountNumber, false);
                }
            }
            catch (Exception ex)
            {
                logger.Info("Error while decrypting the account number", ex);
            }

            return payment;
        }
        /// <summary>
        /// Gets the payment authorization code.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public string GetPaymentAuthorizationCode(int paymentID)
        {
            string returnValue = string.Empty;
            using (DMSEntities dbContext = new DMSEntities())
            {
                PaymentAuthorization payment = dbContext.PaymentAuthorizations.Where(p => p.PaymentID == paymentID).FirstOrDefault();
                if (payment != null)
                {
                    returnValue = payment.AuthorizationCode;
                }
            }
            return returnValue;
        }

        /// <summary>
        /// Gets the type of the authorization.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public string GetAuthorizationType(int paymentID)
        {
            string returnValue = string.Empty;
            using (DMSEntities dbContext = new DMSEntities())
            {
                Payment paymentDetails = dbContext.Payments.Where(u => u.ID == paymentID).FirstOrDefault();
                if (paymentDetails != null)
                {
                    if (paymentDetails.PaymentTransactionType != null)
                    {
                        returnValue = paymentDetails.PaymentTransactionType.Name;
                    }
                }
            }
            return returnValue;
        }
        /// <summary>
        /// Gets the payment authorization reference number.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public string GetPaymentAuthorizationReferenceNumber(int paymentID)
        {
            string returnValue = string.Empty;
            using (DMSEntities dbContext = new DMSEntities())
            {
                PaymentAuthorization payment = dbContext.PaymentAuthorizations.Where(p => p.PaymentID == paymentID).FirstOrDefault();
                if (payment != null)
                {
                    returnValue = payment.ReferenceNumber;
                }
            }
            return returnValue;
        }

        public Payment GetLatestPaymentForEstimate(int serviceRequestID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Payments.Include("PaymentTransactionType").Where(a => a.ServiceRequestID == serviceRequestID && a.PaymentTransactionType.Name.Equals("Info", StringComparison.InvariantCultureIgnoreCase)).OrderByDescending(a => a.CreateDate).FirstOrDefault();
            }
        }

        public void SaveOrUpdatePaymentDetails(Payment payment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var paymentsForEstimate = GetLatestPaymentForEstimate(payment.ServiceRequestID.GetValueOrDefault());
                if (paymentsForEstimate != null)
                {
                    var existingPayment = dbContext.Payments.Where(a => a.ID == paymentsForEstimate.ID).FirstOrDefault();
                    existingPayment.ModifyBy = payment.CreateBy;
                    existingPayment.ModifyDate = payment.CreateDate;
                    existingPayment.PaymentStatusID = payment.PaymentStatusID;
                    existingPayment.CCNameOnCard = payment.CCNameOnCard;
                    existingPayment.CCExpireDate = payment.CCExpireDate;
                    existingPayment.BillingLine2 = payment.BillingLine2;
                    existingPayment.BillingCity = payment.BillingCity;
                    existingPayment.BillingStateProvince = payment.BillingStateProvince;
                    existingPayment.BillingStateProvinceID = payment.BillingStateProvinceID;
                    existingPayment.BillingCountryCode = payment.BillingCountryCode;
                    existingPayment.BillingCountryID = payment.BillingCountryID;
                    /*
                     * Need to ask what about CC Account Number?
                     */
                    dbContext.SaveChanges();
                }
                else
                {
                    if (payment.CCAccountNumber.ToString().Length > 0)
                    {
                        string firstDigit = payment.CCAccountNumber.Substring(0, 1);
                        string lastFourDigit = payment.CCAccountNumber.Substring(payment.CCAccountNumber.Length - 4, 4);
                        string displayNumber = firstDigit + "XXXXXXXXXX" + lastFourDigit;
                        payment.CCPartial = displayNumber;
                    }
                    SavePaymentDetails(payment);
                }
            }
        }

        /// <summary>
        /// Gets the member payment method.
        /// </summary>
        /// <param name="memberPaymentMethodId">The member payment method identifier.</param>
        /// <returns></returns>
        public MemberPaymentMethod GetMemberPaymentMethod(int memberPaymentMethodId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.MemberPaymentMethods.Where(a => a.ID == memberPaymentMethodId).FirstOrDefault();
            }
        }
    }

    internal static class StringUtils
    {
        /// <summary>
        /// Blanks if null.
        /// </summary>
        /// <param name="str">The string.</param>
        /// <returns></returns>
        public static string BlankIfNull(this string str)
        {
            if (string.IsNullOrEmpty(str))
            {
                return string.Empty;
            }
            return str;
        }
    }
}
