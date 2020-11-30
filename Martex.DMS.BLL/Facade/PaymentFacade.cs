using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Model;
using Martex.DMS.BLL.WSCreditCardService;
using System.ServiceModel;
using System.Transactions;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DMSBaseException;
using log4net;
using Martex.DMS.BLL.Common;
using System.Security.Principal;
using System.Runtime.InteropServices;
using System.Collections;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Manage Payments
    /// </summary>
    public class PaymentFacade
    {
        #region enum

        enum LogonType
        {
            Interactive = 2,
            Network = 3,
            Batch = 4,
            Service = 5,
            Unlock = 7,
            NetworkClearText = 8,
            NewCredentials = 9
        }
        #endregion

        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(PaymentFacade));
        #endregion

        #region Public Methods

        /// <summary>
        /// Logons the user.
        /// </summary>
        /// <param name="lpszUsername">The LPSZ username.</param>
        /// <param name="lpszDomain">The LPSZ domain.</param>
        /// <param name="lpszPassword">The LPSZ password.</param>
        /// <param name="dwLogonType">Type of the dw logon.</param>
        /// <param name="dwLogonProvider">The dw logon provider.</param>
        /// <param name="phToken">The ph token.</param>
        /// <returns></returns>
        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

        /// <summary>
        /// Closes the handle.
        /// </summary>
        /// <param name="token">The token.</param>
        /// <returns></returns>
        [DllImport("kernel32.dll")]
        public static extern bool CloseHandle(IntPtr token);

        /// <summary>
        /// Gets the payment send receipt history.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public List<PaymentSendReceiptHistory_Result> GetPaymentSendReceiptHistory(int paymentID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetPaymentSendReceiptHistory(paymentID);
        }

        /// <summary>
        /// Gets the reamining balance.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public PaymentRemainingBalance_Result GetReaminingBalance(int paymentID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetReaminingBalance(paymentID);
        }

        /// <summary>
        /// Gets the ISP charge.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public decimal GetISPCharge(int serviceRequestID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetISPCharge(serviceRequestID);
        }

        /// <summary>
        /// Gets the payment list.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<Payment_List_Result> GetPaymentList(int serviceRequestID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            var list = paymentRepository.GetPaymentList(serviceRequestID);
            UpdateTotalPayment(list);
            return list;
        }

        /// <summary>
        /// Gets the member payment method list.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="membershipID">The membership identifier.</param>
        /// <returns></returns>
        public List<MemberPaymentMethodList_Result> GetMemberPaymentMethodList(int? memberID, int? membershipID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetMemberPaymentMethodList(memberID, membershipID);
        }

        /// <summary>
        /// Gets the payment transaction list.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<PaymentTransactionList_Result> GetPaymentTransactonList(int serviceRequestID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetPaymentTransactonList(serviceRequestID);
        }

        /// <summary>
        /// Gets the member address.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
        public AddressEntity GetMemberAddress(int memberID, int memberShipID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetMemberAddress(memberID, memberShipID);
        }

        /// <summary>
        /// Gets the credit card threshold amount.
        /// </summary>
        /// <returns></returns>
        public double GetCreditCardThresholdAmount()
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetCreditCardThresholdAmount();
        }

        /// <summary>
        /// Updates the service request.
        /// </summary>
        /// <param name="eventSource">The event source.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="sessionID">The session ID.</param>
        public void UpdateServiceRequest(string eventSource, string loggedInUser, int serviceRequestID, string sessionID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ServiceRequestRepository serviceRepository = new ServiceRequestRepository();
                serviceRepository.UpdateTabStatus(serviceRequestID, TabConstants.PaymentTab, loggedInUser);
                tran.Complete();
            }
        }

        /// <summary>
        /// Sends the receipt.
        /// </summary>
        /// <param name="receipt">The receipt.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <exception cref="DMSException">
        /// ContactCategory - ContactCustomer is not set up in the system
        /// or
        /// ContactType - Member is not set up in the system
        /// or
        /// ContactSource - ServiceRequest for category - ContactCustomer is not set up in the system
        /// or
        /// Contact Reason - PaymentReceipt is not set up in the system
        /// or
        /// Contact Action - Sent Payment Receipt is not set up for the category - ContactCustomer
        /// </exception>
        public void SendReceipt(SendReceipt receipt, int? clientID, int? programID,
                                string loggedInUser,
                                string eventSource,
                                string sessionID)
        {
            if (receipt.PhoneTypeID == 0)
            {
                receipt.PhoneTypeID = null;
            }
            DateTime now = DateTime.Now;

            using (TransactionScope tran = new TransactionScope())
            {
                #region 1. Create contact log and link records [ for payment and member ]
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                var contactCategory = staticDataRepo.GetContactCategoryByName("ContactCustomer");
                if (contactCategory == null)
                {
                    throw new DMSException("ContactCategory - ContactCustomer is not set up in the system");
                }
                var contactType = staticDataRepo.GetTypeByName("Member");
                if (contactType == null)
                {
                    throw new DMSException("ContactType - Member is not set up in the system");
                }
                var contactSource = staticDataRepo.GetContactSourceByName("ServiceRequest", "ContactCustomer");
                if (contactSource == null)
                {
                    throw new DMSException("ContactSource - ServiceRequest for category - ContactCustomer is not set up in the system");
                }

                ContactLog contactLog = new ContactLog()
                {
                    ContactCategoryID = contactCategory.ID,
                    ContactTypeID = contactType.ID,
                    ContactSourceID = contactSource.ID,
                    ContactMethodID = receipt.ContactMethodID,
                    Direction = "Outbound",
                    Description = "Send Payment Receipt to Member",
                    CreateDate = now,
                    CreateBy = loggedInUser,
                    ModifyDate = now,
                    ModifyBy = loggedInUser
                };

                if ("text".Equals(receipt.ContactMethodName, StringComparison.InvariantCultureIgnoreCase))
                {
                    contactLog.PhoneTypeID = receipt.PhoneTypeID;
                    contactLog.PhoneNumber = receipt.PhoneNumber;
                }
                else
                {
                    contactLog.Email = receipt.Email;
                }
                ContactLogRepository clogRepo = new ContactLogRepository();
                clogRepo.Save(contactLog, loggedInUser, receipt.PaymentID, EntityNames.PAYMENT);
                clogRepo.CreateLinkRecord(contactLog.ID, EntityNames.MEMBER, receipt.MemberID);
                logger.Info("Created ContactLog and link records");

                #endregion

                #region 2. Create ContactLogReason record

                var contactReason = staticDataRepo.GetContactReason("PaymentReceipt", "ContactCustomer");
                if (contactReason == null)
                {
                    throw new DMSException("Contact Reason - PaymentReceipt is not set up in the system");
                }
                ContactLogReason cLogReason = new ContactLogReason()
                {
                    ContactLogID = contactLog.ID,
                    ContactReasonID = contactReason.ID,
                    CreateBy = loggedInUser,
                    CreateDate = now
                };

                ContactLogReasonRepository cLogReasonRepo = new ContactLogReasonRepository();
                cLogReasonRepo.Save(cLogReason, loggedInUser);
                logger.Info("Created ContactLogReason record");

                #endregion

                #region 3. Create ContactLogAction record
                var contactAction = staticDataRepo.GetContactActionByName("Sent Payment Receipt", "ContactCustomer");
                if (contactAction == null)
                {
                    throw new DMSException("Contact Action - Sent Payment Receipt is not set up for the category - ContactCustomer");
                }

                ContactLogAction cLogAction = new ContactLogAction()
                {
                    ContactLogID = contactLog.ID,
                    ContactActionID = contactAction.ID,
                    CreateBy = loggedInUser,
                    CreateDate = now
                };
                ContactLogActionRepository cLogActionRepo = new ContactLogActionRepository();
                cLogActionRepo.Save(cLogAction, loggedInUser);

                logger.Info("Created ContactLogAction record");

                #endregion

                #region 4. Insert CommunicationQueue record
                PaymentRepository paymentRepo = new PaymentRepository();
                paymentRepo.CreateCommunicationQueque(programID, receipt.PaymentID, contactLog.ID, receipt.ContactMethodID, loggedInUser, receipt.PhoneNumber, receipt.Email, receipt.ContactMethodName);
                #endregion

                #region 5. Insert EventLog and link records [ for payment and member ]
                //TFS #1319
                var paymentID = receipt.PaymentID;
                PaymentReceiptValues_Result paymentReceiptValues = (new PaymentRepository()).GetPaymentReceiptValues(paymentID).FirstOrDefault();
                if (paymentReceiptValues == null)
                {
                    throw new DMSException(String.Format("Unable to retrieve details for the Payment ID {0}", paymentID));
                }
                // Create Hash Table to hold the values
                Hashtable htParams = new Hashtable();
                htParams.Add("CCOrderID", paymentReceiptValues.CCOrderID.BlankIfNull());
                htParams.Add("PaymentDate", paymentReceiptValues.PaymentDate.BlankIfNull());
                htParams.Add("Service", paymentReceiptValues.Service.BlankIfNull());
                htParams.Add("ServiceLocationAddress", paymentReceiptValues.ServiceLocationAddress.BlankIfNull());
                htParams.Add("DestinationAddress", paymentReceiptValues.DestinationAddress.BlankIfNull());
                htParams.Add("NameOnCard", paymentReceiptValues.NameOnCard.BlankIfNull());
                htParams.Add("CardType", paymentReceiptValues.CardType.BlankIfNull());
                htParams.Add("CCPartial", paymentReceiptValues.CardNumber.BlankIfNull());
                htParams.Add("ExpirationDate", paymentReceiptValues.ExpirationDate.BlankIfNull());
                htParams.Add("Amount", paymentReceiptValues.Amount.GetValueOrDefault().ToString("C"));
                htParams.Add("type", paymentReceiptValues.Type.BlankIfNull());
                htParams.Add("Program", paymentReceiptValues.Program.BlankIfNull());


                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.SEND_PAYMENT_RECEIPT, "Send Payment Receipt", htParams.GetMessageData(), loggedInUser, paymentID, EntityNames.PAYMENT, sessionID);
                //long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.SEND_PAYMENT_RECEIPT, "Send Payment Receipt", loggedInUser, receipt.PaymentID, EntityNames.PAYMENT, sessionID);

                eventLogFacade.CreateRelatedLogLinkRecord(eventLogId, receipt.MemberID, EntityNames.MEMBER);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogId, clientID, EntityNames.CLIENT);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogId, programID, EntityNames.PROGRAM);

                logger.Info("Created Event log and link records");
                #endregion

                tran.Complete();
            }
        }

        /// <summary>
        /// Saves the payment transaction.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="existingPaymentID">The existing payment ID.</param>
        /// <param name="SessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Unable to retrieve Application Configuration values for credit card processing
        /// or
        /// Unable to retrieve details for the Payment ID : + existingPaymentID.GetValueOrDefault().ToString()
        /// </exception>
        public CreditCardTransactionStatus SavePaymentTransaction(PaymentInformation payment, string userName, int? existingPaymentID, int programID, string SessionID)
        {
            if (!payment.Payment.PaymentReasonID.HasValue)
            {
                throw new DMSException("Payment reason is required");
            }

            ProgramMaintenanceRepository progMainRepo = new ProgramMaintenanceRepository();
            var progStoreValue = string.Empty;
            var programConfigurationList = progMainRepo.GetProgramInfo(programID, "WebService", "CreditCard");
            if (programConfigurationList != null && programConfigurationList.Count > 0)
            {
                var progStoreID = programConfigurationList.Where(x => (x.Name.Equals("StoreID", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                progStoreValue = progStoreID != null ? progStoreID.Value : string.Empty;
                logger.InfoFormat("Read the StoreID from ProgramConfiguration - {0}", string.IsNullOrEmpty(progStoreValue) ? "No" : "Yes");
            }
            if (string.IsNullOrEmpty(progStoreValue))
            {
                List<ApplicationConfiguration> appConfiguration = new AppConfigRepository().GetApplicationConfigurationList("WebService", "CreditCard");
                if (appConfiguration == null)
                {
                    throw new DMSException("Unable to retrieve Application Configuration values for credit card processing");
                }
                ApplicationConfiguration storeID = appConfiguration.Where(u => u.Name.Equals("StoreID")).FirstOrDefault();
                progStoreValue = storeID != null ? storeID.Value : string.Empty;
            }

            PaymentRepository paymentRepository = new PaymentRepository();
            PaymentTransaction paymentTransaction = new PaymentTransaction();
            PaymentRemainingBalance_Result remainingBalanceDetails;
            Payment existingPaymentDetails = null;

            // For Sale Transaction 
            if (payment.Payment.PaymentTransactionTypeID == 1)
            {
                payment.IsCreditProcessing = false;
                payment.Payment.CCOrderID = payment.Payment.ServiceRequestID + "-" + DateTime.Now;
            }
            else
            // For Credit Transaction
            {
                payment.IsCreditProcessing = true;
                existingPaymentDetails = paymentRepository.Get(existingPaymentID.Value, null);
                if (existingPaymentDetails == null)
                {
                    throw new DMSException("Unable to retrieve details for the Payment ID :" + existingPaymentID.GetValueOrDefault().ToString());
                }
                remainingBalanceDetails = paymentRepository.GetReaminingBalance(existingPaymentID.Value);
                payment.Credit_IsVoidTransaction = existingPaymentDetails.Amount == payment.Payment.Amount;
                payment.Credit_CCOrderID = remainingBalanceDetails.CCOrderID;
                payment.Credit_ResponseTDate = remainingBalanceDetails.ResponseTdate;
                payment.Payment.CCOrderID = payment.Credit_CCOrderID;
            }


            // Before Making call to web service Insert record into Payment Transaction
            // If it's fails no need to call web service.
            //Save Details into Payment Transaction
            paymentTransaction.PaymentID = null;
            paymentTransaction = payment.ToPaymentTransaction();
            if (payment.IsCreditProcessing && !payment.Credit_IsVoidTransaction)
            {
                paymentTransaction.PaymentTransactionTypeID = new CommonLookUpRepository().GetPaymentTransactionType("Credit");
            }
            paymentTransaction.CreateBy = paymentTransaction.ModifyBy = userName;
            paymentTransaction.CreateDate = paymentTransaction.ModifyDate = DateTime.Now;
            paymentTransaction.StoreNumber = progStoreValue;
            paymentRepository.SavePaymentTransaction(paymentTransaction);

            // Call Web Service 
            CreditCardTransactionStatus transactionStatus = new CreditCardTransactionStatus();
            transactionStatus = CallWebServiceForTransaction(programID, ref payment);

            //IF Web Service called Success then create Payment Record and Assign Transaction ID
            int? paymentID = null;

            if (transactionStatus.isSuccess)
            {
                try
                {
                    Payment paymentDetails = payment.ToPaymentDetails();
                    if (payment.IsCreditProcessing && payment.Credit_IsVoidTransaction)
                    {
                        paymentDetails.PaymentTransactionTypeID = new CommonLookUpRepository().GetPaymentTransactionType("Void");
                    }
                    else if (payment.IsCreditProcessing && !payment.Credit_IsVoidTransaction)
                    {
                        paymentDetails.PaymentTransactionTypeID = new CommonLookUpRepository().GetPaymentTransactionType("Credit");
                    }
                    paymentDetails.CreateBy = paymentDetails.ModifyBy = userName;
                    paymentDetails.CreateDate = paymentDetails.ModifyDate = DateTime.Now;
                    paymentDetails.FillWebServiceDetailsForPayment(transactionStatus);

                    PaymentAuthorization paymentAuthorization = new PaymentAuthorization();
                    using (TransactionScope transaction = new TransactionScope())
                    {
                        paymentID = paymentRepository.SavePaymentDetails(paymentDetails);
                        paymentAuthorization.PaymentID = paymentID;
                        paymentAuthorization.SequenceNumber = 0;
                        paymentAuthorization.AuthorizationDate = transactionStatus.ResponseTime;
                        paymentAuthorization.AuthorizationCode = transactionStatus.ProcessorReferenceNumber;
                        paymentAuthorization.AuthorizationType = "Capture";
                        paymentAuthorization.ReferenceNumber = transactionStatus.ApprovalCode;
                        paymentAuthorization.ProcessorReferenceNumber = transactionStatus.ApprovalCode;

                        if (!string.IsNullOrEmpty(transactionStatus.ApprovalCode))
                        {
                            if (transactionStatus.ApprovalCode.ToString().Length > 16)
                            {
                                paymentAuthorization.ReferenceNumber = transactionStatus.ApprovalCode.Substring(6, 10);
                                paymentAuthorization.ProcessorReferenceNumber = transactionStatus.ApprovalCode.Substring(6, 10);
                            }
                        }
                        paymentAuthorization.Amount = paymentDetails.Amount;
                        paymentAuthorization.CreateDate = DateTime.Now;
                        paymentAuthorization.CreateBy = userName;
                        paymentRepository.SavePaymentAuthorization(paymentAuthorization);
                        transaction.Complete();
                    }
                    transactionStatus.PaymentID = paymentID;
                }
                catch (Exception ex)
                {
                    logger.Warn(ex.Message, ex);
                }
            }

            // Update Payment Transaction Details.
            // Call Helper method for the conversion
            paymentTransaction.PaymentID = paymentID;
            // Fill Web Service Details
            paymentTransaction.FillWebServiceDetails(transactionStatus);
            // Request Change 1285 
            paymentTransaction.ResponseApproved = transactionStatus.ProcessorReferenceNumber;
            if (!string.IsNullOrEmpty(transactionStatus.ApprovalCode))
            {
                if (transactionStatus.ApprovalCode.ToString().Length > 16)
                {
                    paymentTransaction.ResponseRef = transactionStatus.ApprovalCode.Substring(6, 10);
                }
            }
            paymentTransaction.ResponseAuthResponse = transactionStatus.ApprovalCode;
            //Save Details into Payment Transaction
            paymentRepository.UpdatePaymentTransaction(paymentTransaction);

            CommonLookUpRepository lookUp = new CommonLookUpRepository();
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            string eventDetails = string.Empty;
            // Event Log Creation for Apply Credit 
            #region Event Log
            if (payment.IsCreditProcessing)
            {
                if (transactionStatus.isSuccess)
                {
                    eventDetails = "Apply Credit - Reason : <" + lookUp.GetPaymentReason(payment.Payment.PaymentReasonID.Value).Description + "> - Status : Approved";
                    eventLoggerFacade.LogEvent("Application/Request/Payment", EventNames.APPLY_CREDIT_APPROVED, eventDetails, userName, paymentID, EntityNames.PAYMENT, SessionID);
                }
                else
                {
                    eventDetails = "Apply Credit - Reason : <" + lookUp.GetPaymentReason(payment.Payment.PaymentReasonID.Value).Description + "> - Status : Failed";
                    eventLoggerFacade.LogEvent("Application/Request/Payment", EventNames.APPLY_CREDIT_FAILED, eventDetails, userName, paymentID, EntityNames.PAYMENT, SessionID);
                }
            }
            else // Event Log Creation for Charge Credit
            {
                long eventLogID = eventLoggerFacade.LogEvent("Application/Request/Payment", EventNames.CHARGE_CARD, "Charge Card", userName, SessionID);
                if (transactionStatus.isSuccess)
                {
                    // Create related record in case of success for the payment
                    eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, paymentID, EntityNames.PAYMENT);

                    if ("RentalCover.com".Equals(payment.ClientName, StringComparison.InvariantCultureIgnoreCase))
                    {
                        logger.InfoFormat("Transaction success");
                        logger.Info("Processing Send payment receipt for RentalCover.com");
                        //TFS:680.
                        PaymentReceiptValues_Result paymentReceiptValues = (new PaymentRepository()).GetPaymentReceiptValues(paymentID.GetValueOrDefault()).FirstOrDefault();
                        if (paymentReceiptValues == null)
                        {
                            throw new DMSException(String.Format("Unable to retrieve details for the Payment ID {0}", paymentID));
                        }
                        // Create Hash Table to hold the values
                        Dictionary<string, string> htParams = new Dictionary<string, string>();
                        htParams.Add("CCOrderID", paymentReceiptValues.CCOrderID.BlankIfNull());
                        htParams.Add("PaymentDate", paymentReceiptValues.PaymentDate.BlankIfNull());
                        htParams.Add("Service", paymentReceiptValues.Service.BlankIfNull());
                        htParams.Add("ServiceLocationAddress", paymentReceiptValues.ServiceLocationAddress.BlankIfNull());
                        htParams.Add("DestinationAddress", paymentReceiptValues.DestinationAddress.BlankIfNull());
                        htParams.Add("NameOnCard", paymentReceiptValues.NameOnCard.BlankIfNull());
                        htParams.Add("CardType", paymentReceiptValues.CardType.BlankIfNull());
                        htParams.Add("CCPartial", paymentReceiptValues.CardNumber.BlankIfNull());
                        htParams.Add("ExpirationDate", paymentReceiptValues.ExpirationDate.BlankIfNull());
                        htParams.Add("Amount", paymentReceiptValues.Amount.GetValueOrDefault().ToString("C"));
                        htParams.Add("type", paymentReceiptValues.Type.BlankIfNull());
                        htParams.Add("Program", paymentReceiptValues.Program.BlankIfNull());

                        eventLogID = eventLoggerFacade.LogEvent("Application/Request/Payment", EventNames.SEND_PAYMENT_RECEIPT_COPY_TO_CLIENT, htParams, userName, SessionID);
                        eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, paymentID, EntityNames.PAYMENT);
                        eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, paymentTransaction.ServiceRequestID, EntityNames.SERVICE_REQUEST);
                        eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, payment.MemberID, EntityNames.MEMBER);

                        logger.InfoFormat("Created Event log {0} and link records for SendPaymentReceiptToClient, Payment, SR and Member", eventLogID);
                    }
                }
                else
                {
                    // #1297 Request Change
                    // Create related record and Link it to Service Request
                    logger.InfoFormat("Transaction failed {0}", transactionStatus.Message);
                    eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, paymentTransaction.ServiceRequestID, EntityNames.SERVICE_REQUEST);
                }
            }
            #endregion
            transactionStatus.PaymentID = paymentID;
            return transactionStatus;
        }

        /// <summary>
        /// Calls the web service for transaction.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Unable to retrieve Application Configuration values for credit card processing
        /// or
        /// Unable to retrieve StoreID/Password/UseAddressVerification/UseSecruityCodeVerficiation/CertificatePassword
        /// </exception>
        public CreditCardTransactionStatus CallWebServiceForTransaction(int? programID, ref PaymentInformation payment)
        {
            logger.Info("Call Web Service For Transaction Started");
            string endPointUrl = string.Empty;
            endPointUrl = AppConfigRepository.GetValue(AppConfigConstants.CC_SERVICE_URL);
            logger.InfoFormat("Retrieved End Point Url {0}", endPointUrl);
            #region 1.Retrieve the values from ProgramConfiguration/ApplicationConfiguration which is needed in order to consume the Service.

            /*
             * Logic to retrieve StoreID, Password and Certificate Password from ProgramConfiguration.
             * If the Configurations found, then use those values to call Credit Card Service
             * If not found, use the values from Application Configuration.
             * */
            var storeValue = string.Empty;
            var passwordValue = string.Empty;
            var certificatePasswordValue = string.Empty;
            List<ApplicationConfiguration> appConfiguration = new AppConfigRepository().GetApplicationConfigurationList("WebService", "CreditCard");
            if (appConfiguration == null)
            {
                throw new DMSException("Unable to retrieve Application Configuration values for credit card processing");
            }
            ProgramMaintenanceRepository progMainRepo = new ProgramMaintenanceRepository();
            var programConfigurationList = progMainRepo.GetProgramInfo(programID, "WebService", "CreditCard");
            var progStoreID = programConfigurationList.Where(x => (x.Name.Equals("StoreID", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            var progCertificatePassword = programConfigurationList.Where(x => (x.Name.Equals("CertificatePassword", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            var progPassword = programConfigurationList.Where(x => (x.Name.Equals("Password", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (progStoreID != null && progCertificatePassword != null && progPassword != null)
            {
                storeValue = progStoreID.Value;
                certificatePasswordValue = progCertificatePassword.Value;
                passwordValue = progPassword.Value;
                logger.Info("Retrieved StoredID, Password and CertificatePassword from ProgramConfig");
            }
            else
            {

                ApplicationConfiguration certificatePassword = appConfiguration.Where(u => u.Name.Equals("CertificatePassword")).FirstOrDefault();
                ApplicationConfiguration storeID = appConfiguration.Where(u => u.Name.Equals("StoreID")).FirstOrDefault();
                ApplicationConfiguration password = appConfiguration.Where(u => u.Name.Equals("Password")).FirstOrDefault();
                if (storeID == null || password == null || certificatePassword == null)
                {
                    throw new DMSException("Unable to retrieve StoreID/Password/CertificatePassword");
                }
                else
                {
                    storeValue = storeID.Value;
                    certificatePasswordValue = certificatePassword.Value;
                    passwordValue = password.Value;
                }
                logger.InfoFormat("Retrieved storeID - {0} and Password", storeID.Value);
            }

            ApplicationConfiguration useAddressVerification = appConfiguration.Where(u => u.Name.Equals("UseAddressVerification")).FirstOrDefault();
            ApplicationConfiguration usesecurityVerification = appConfiguration.Where(u => u.Name.Equals("UseSecruityCodeVerficiation")).FirstOrDefault();
            if (useAddressVerification == null || usesecurityVerification == null)
            {
                throw new DMSException("Unable to retrieve UseAddressVerification/UseSecruityCodeVerficiation");
            }
            #endregion

            #region 2.Create object for custom class which tell the status about the transaction.
            CreditCardTransactionStatus status = new CreditCardTransactionStatus();
            #endregion

            #region 3.Consume the service from here.

            try
            {
                // Create Proxy and Post authorization objects.
                CreditCardServiceClient proxy = new CreditCardServiceClient();
                string userNameForLocalService = AppConfigRepository.GetValue(AppConfigConstants.CC_LocalService_UserName);
                string passwordForLocalService = AppConfigRepository.GetValue(AppConfigConstants.CC_LocalService_Password);
                logger.InfoFormat("Retrieved UserName - {0}, and Password for ServiceCredentials", proxy.ClientCredentials.UserName.UserName);
                if (!string.IsNullOrEmpty(endPointUrl))
                {
                    proxy.Endpoint.Address = new EndpointAddress(endPointUrl);
                }
                string userName = string.Empty;
                string domain = string.Empty;
                string[] strTokens = userNameForLocalService.Split('\\');
                if (strTokens.Length > 1)
                {
                    domain = strTokens[0];
                    userName = strTokens[1];
                }
                else
                {
                    userName = strTokens[0];
                }

                SaleRequest request = new SaleRequest();
                VoidRequest voidRequest = new VoidRequest();
                PostAuthorizationRequest postAuthorizationRequest = new PostAuthorizationRequest();
                ProcessorResponse response = new ProcessorResponse();
                // Some Information assigned into pareRequest.
                request.OrderId = payment.Payment.CCOrderID;
                request.StoreNumber = storeValue;
                request.Password = passwordValue;
                // RC 1328 
                request.CertificatePassword = certificatePasswordValue;
                voidRequest.CertificatePassword = certificatePasswordValue;
                postAuthorizationRequest.CertificatePassword = certificatePasswordValue;
                if (!payment.IsCreditProcessing)
                {
                    var cardDetails = payment.Payment;
                    request.CardNumber = cardDetails.CCAccountNumber;
                    request.ExpirationDate = new DateTime(payment.CardExpirationYear, payment.CardExpirationMonth, DateTime.DaysInMonth(payment.CardExpirationYear, payment.CardExpirationMonth));
                    request.ChargeTotal = payment.Payment.Amount.Value;
                    if (payment.SecurityCode.HasValue && payment.SecurityCode.Value > 0)
                    {
                        request.CvmNumber = payment.SecurityCode.GetValueOrDefault().ToString();
                    }
                    request.BillingZip = cardDetails.BillingPostalCode;
                    request.UseAvs = bool.Parse(useAddressVerification.Value);
                    request.UseCvm = bool.Parse(usesecurityVerification.Value);
                    status.StoreNumber = storeValue;
                }
                else if (payment.Credit_IsVoidTransaction)
                {
                    voidRequest.StoreNumber = storeValue;
                    voidRequest.Password = passwordValue;
                    voidRequest.OrderId = payment.Credit_CCOrderID;
                    voidRequest.TDate = payment.Credit_ResponseTDate;

                    // Set the values because void transaction can be failed so we need to execute return
                    postAuthorizationRequest.StoreNumber = storeValue;
                    postAuthorizationRequest.Password = passwordValue;
                    postAuthorizationRequest.OrderId = payment.Credit_CCOrderID;
                    postAuthorizationRequest.ChargeTotal = payment.Payment.Amount.Value;
                }
                else if (!payment.Credit_IsVoidTransaction)
                {
                    postAuthorizationRequest.StoreNumber = storeValue;
                    postAuthorizationRequest.Password = passwordValue;
                    postAuthorizationRequest.OrderId = payment.Credit_CCOrderID;
                    postAuthorizationRequest.ChargeTotal = payment.Payment.Amount.Value;
                }
                try
                {
                    logger.Info("Trying to open the proxy for CC Transaction");
                    // Credit Card Processing Steps
                    IntPtr token = IntPtr.Zero;
                    LogonUser(userName,
                                domain,
                                passwordForLocalService,
                                9,
                                0,
                                ref token);
                    using (WindowsImpersonationContext context = WindowsIdentity.Impersonate(token))
                    {


                        proxy.Open();
                        if (payment.Payment.PaymentTransactionTypeID.HasValue)
                        {
                            if (!payment.IsCreditProcessing) // For Sale
                            {
                                logger.Info("Trying to Execute Sale");
                                response = proxy.ExecuteSale(request);
                            }
                            else if (payment.IsCreditProcessing) // For Credit
                            {
                                logger.Info("Trying to Execute Credit");
                                if (payment.Credit_IsVoidTransaction)
                                {
                                    logger.Info("Trying to Execute Void Request");
                                    try
                                    {
                                        response = proxy.ExecuteVoid(voidRequest);
                                        if (!response.ProcessorTransactionResult.ToString().Equals("Approved"))
                                        {
                                            logger.Info("Void transaction is not approved so trying to execute return");
                                            payment.Credit_IsVoidTransaction = false;
                                            response = proxy.ExecuteReturn(postAuthorizationRequest);

                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        logger.Info("Error occurs while executing the Void Transaction so trying to execute return");
                                        logger.Info(ex.Message, ex);
                                        payment.Credit_IsVoidTransaction = false;
                                        response = proxy.ExecuteReturn(postAuthorizationRequest);
                                    }

                                }
                                else
                                {
                                    logger.Info("Trying to Execute return Request");
                                    response = proxy.ExecuteReturn(postAuthorizationRequest);
                                }
                            }
                        }
                        proxy.Close();
                        logger.Info("Web service call Succeeded and proxy closed");
                        ProcessResponse(ref status, ref response, ref payment);
                    }

                }
                catch (FaultException fex)
                {
                    logger.Error(fex);
                    throw fex;

                }

            }
            catch (TimeoutException tex)
            {
                logger.Error(tex);
                status.isSuccess = false;
                status.Message = "The connection to the credit card system was lost.  The transaction status is unknown.  Please contact the System Administrator";
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                status.isSuccess = false;
                status.Message = "The credit card service is not available.  Please try again.  If this continues, please contact the System Administrator";
            }
            #endregion
            return status;
        }

        /// <summary>
        /// Gets the specified payment ID.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public Payment Get(int paymentID, int? serviceRequestID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            Payment entity = paymentRepository.Get(paymentID, serviceRequestID);
            return entity;
        }


        public Payment GetPaymentForMemberPaymentMethod(int memberPaymentMothodId)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            MemberPaymentMethod memberPay = paymentRepository.GetMemberPaymentMethod(memberPaymentMothodId);
            Payment pay = new Payment();
            if (memberPay != null)
            {
                pay = new Payment()
                {
                    PaymentTypeID = memberPay.PaymentTypeID,
                    CCAccountNumber = memberPay.CCAccountNumber,
                    CCPartial = memberPay.CCPartial,
                    CCExpireDate = memberPay.CCExpireDate,
                    CCNameOnCard = memberPay.CCNameOnCard,
                    BillingLine1 = memberPay.BillingLine1,
                    BillingLine2 = memberPay.BillingLine2,
                    BillingCity = memberPay.BillingCity,
                    BillingStateProvince = memberPay.BillingStateProvince,
                    BillingPostalCode = memberPay.BillingPostalCode,
                    BillingCountryCode = memberPay.BillingCountryCode,
                    BillingStateProvinceID = memberPay.BillingStateProvinceID,
                    BillingCountryID = memberPay.BillingCountryID,
                    Comments = memberPay.Comments,
                    CreateDate = memberPay.CreateDate,
                    CreateBy = memberPay.CreateBy,
                    ModifyDate = memberPay.ModifyDate,
                    ModifyBy = memberPay.ModifyBy
                };

                try
                {
                    //KB: Added a null check before accessing properties on the payment object.
                    if (pay != null)
                    {
                        pay.CCAccountNumber = paymentRepository.EncryptDecrypt(pay.CCAccountNumber, false);
                    }
                }
                catch (Exception ex)
                {
                    logger.Info("Error while decrypting the account number", ex);
                    throw new DMSException(string.Format("Error while decrypting the account number for Member Payment Method ID : {0}",memberPaymentMothodId));
                }


            }
            return pay;
        }


        /// <summary>
        /// Gets the payment authorization code.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public string GetPaymentAuthorizationCode(int paymentID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetPaymentAuthorizationCode(paymentID);

        }

        /// <summary>
        /// Gets the type of the authorization.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public string GetAuthorizationType(int paymentID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetAuthorizationType(paymentID);
        }

        /// <summary>
        /// Gets the payment authorization reference number.
        /// </summary>
        /// <param name="paymentID">The payment ID.</param>
        /// <returns></returns>
        public string GetPaymentAuthorizationReferenceNumber(int paymentID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            return paymentRepository.GetPaymentAuthorizationReferenceNumber(paymentID);
        }
        #endregion

        #region Private Methods
        /// <summary>
        /// Processes the response.
        /// </summary>
        /// <param name="status">The status.</param>
        /// <param name="response">The response.</param>
        /// <param name="payment">The payment.</param>
        private void ProcessResponse(ref CreditCardTransactionStatus status, ref ProcessorResponse response, ref PaymentInformation payment)
        {
            // To Do : Fill information and take the decision for healthy transaction.
            if (response.ProcessorTransactionResult.ToString().Equals("Approved"))
            {
                status.isSuccess = true;
            }
            else
            {
                status.isSuccess = false;
            }


            status.CCTransactionReference = response.ProcessorReferenceNumber;
            status.Message = response.ErrorMessage;
            status.ProcessorTransactionResult = response.ProcessorTransactionResult.ToString(); // TODO
            status.ResponserAVS = response.AvsMessage;
            status.ResponseOrderNum = response.OrderId;
            status.ResponseError = response.ErrorMessage;
            status.ResponseApproved = response.ApprovalCode;
            status.ResponseCode = response.ProcessorResponseCode;
            status.ResponseMessage = response.ProcessorResponseMessage.ToString(); //TODO
            status.ResponseRef = response.ProcessorReferenceNumber;
            status.ResponseTime = response.TransactionDateTime;
            status.ResponseTdate = response.TDate;
            status.ProcessorReferenceNumber = response.ProcessorReferenceNumber;
            status.ApprovalCode = response.ApprovalCode;
        }

        /// <summary>
        /// Updates the total payment.
        /// </summary>
        /// <param name="list">The list.</param>
        private void UpdateTotalPayment(List<Payment_List_Result> list)
        {
            if (list != null && list.Count > 0)
            {
                decimal total = 0;
                list.ForEach(x =>
                {
                    if ("Sale".Equals(x.TransactionType, StringComparison.InvariantCultureIgnoreCase))
                    {
                        total += x.Amount ?? 0;
                    }
                    else
                    {
                        total -= x.Amount ?? 0;
                    }
                });


                list[0].TotalAmount = total;
            }
        }
        #endregion

        public Payment GetPaymentTransaction(int serviceRequestID)
        {
            PaymentRepository paymentRepository = new PaymentRepository();
            Payment payment = paymentRepository.GetLatestPaymentForEstimate(serviceRequestID);
            return payment;
        }
    }

    #region Helper Methods
    /// <summary>
    /// Helper Conversion
    /// </summary>
    static class HelperConversion
    {
        /// <summary>
        /// Fills the web service details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="response">The response.</param>
        /// <returns></returns>
        public static PaymentTransaction FillWebServiceDetails(this PaymentTransaction model, CreditCardTransactionStatus response)
        {
            model.PaymentStatusID = new CommonLookUpRepository().GetPaymentStatus(response.ProcessorTransactionResult);
            model.StoreNumber = response.StoreNumber;
            model.ResponseAVS = response.ResponserAVS;
            model.ResponseOrderNum = response.ResponseOrderNum;
            model.ResponseError = response.ResponseError;
            model.ResponseCode = response.ResponseCode;
            model.ResponseMessage = response.ResponseMessage;
            model.ResponseTime = response.ResponseTime.ToString();
            model.ResponseTdate = response.ResponseTdate;
            model.ResponseRef = response.ResponseRef;

            return model;
        }

        /// <summary>
        /// Fills the web service details for payment.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="response">The response.</param>
        /// <returns></returns>
        public static Payment FillWebServiceDetailsForPayment(this Payment model, CreditCardTransactionStatus response)
        {
            model.CCAuthCode = response.ProcessorReferenceNumber;
            model.CCAuthType = response.CCAuthType;
            model.CCTransactionReference = response.ApprovalCode;

            if (!string.IsNullOrEmpty(response.ApprovalCode))
            {
                if (response.ApprovalCode.ToString().Length > 16)
                {
                    model.CCTransactionReference = response.ApprovalCode.Substring(6, 10);
                }
            }
            return model;
        }

        /// <summary>
        /// To the payment transaction.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public static PaymentTransaction ToPaymentTransaction(this PaymentInformation model)
        {
            // Look Up Variables for the State and Country
            CommonLookUpRepository lookUP = new CommonLookUpRepository();
            string countryCode = string.Empty;
            string stateProv = string.Empty;

            if (model.Payment.BillingCountryID.HasValue)
            {
                countryCode = lookUP.GetCountry(model.Payment.BillingCountryID.Value).ISOCode;
            }

            if (model.Payment.BillingStateProvinceID.HasValue)
            {
                stateProv = lookUP.GetStateProvince(model.Payment.BillingStateProvinceID.Value).Abbreviation;
            }

            PaymentTransaction transaction = new PaymentTransaction();
            transaction.ServiceRequestID = model.Payment.ServiceRequestID.Value;
            transaction.PaymentStatusID = 1; // For Pending;
            transaction.PaymentTypeID = model.Payment.PaymentTypeID;
            transaction.PaymentTransactionTypeID = model.Payment.PaymentTransactionTypeID;
            transaction.PaymentReasonID = model.Payment.PaymentReasonID;
            transaction.PaymentReasonOther = model.Payment.PaymentReasonOther;
            transaction.CCOrderID = model.Payment.CCOrderID;
            transaction.PaymentDate = DateTime.Now;
            transaction.Amount = model.Payment.Amount;
            transaction.CurrencyTypeID = model.Payment.CurrencyTypeID;
            transaction.CCAccountNumber = model.Payment.CCAccountNumber;
            if (model.Payment.CCAccountNumber.ToString().Length > 0)
            {
                string firstDigit = model.Payment.CCAccountNumber.Substring(0, 1);
                string lastFourDigit = model.Payment.CCAccountNumber.Substring(model.Payment.CCAccountNumber.Length - 4, 4);
                string displayNumber = firstDigit + "XXXXXXXXXX" + lastFourDigit;
                transaction.CCPartial = displayNumber;
            }
            transaction.CCExpireDate = new DateTime(model.CardExpirationYear, model.CardExpirationMonth, DateTime.DaysInMonth(model.CardExpirationYear, model.CardExpirationMonth));
            transaction.CCNameOnCard = model.Payment.CCNameOnCard;
            transaction.BillingLine1 = model.Payment.BillingLine1;
            transaction.BillingLine2 = model.Payment.BillingLine2;
            transaction.BillingCity = model.Payment.BillingCity;
            transaction.BillingStateProvince = stateProv;
            transaction.BillingPostalCode = model.Payment.BillingPostalCode;
            transaction.BillingCountryCode = countryCode;
            transaction.BillingStateProvinceID = model.Payment.BillingStateProvinceID;
            transaction.BillingCountryID = model.Payment.BillingCountryID;
            transaction.Comments = model.Payment.Comments;

            // Web Service Null Values
            transaction.CCAuthCode = null;
            transaction.CCAuthType = null;
            transaction.CCTransactionReference = null;
            transaction.ResponseAVS = null;
            transaction.ResponseOrderNum = null;
            transaction.ResponseError = null;
            transaction.ResponseApproved = null;
            transaction.ResponseCode = null;
            transaction.ResponseMessage = null;
            transaction.ResponseRef = null;
            transaction.ResponseTime = null;
            transaction.ResponseTdate = null;
            transaction.ResponseTax = null;
            transaction.ResponseShipping = null;
            transaction.ResponseAuthResponse = null;
            return transaction;
        }

        /// <summary>
        /// To the payment details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public static Payment ToPaymentDetails(this PaymentInformation model)
        {
            CommonLookUpRepository lookUp = new CommonLookUpRepository();
            // Look Up Variables for the State and Country
            string countryCode = string.Empty;
            string stateProv = string.Empty;

            if (model.Payment.BillingCountryID.HasValue)
            {
                countryCode = lookUp.GetCountry(model.Payment.BillingCountryID.Value).ISOCode;
            }

            if (model.Payment.BillingStateProvinceID.HasValue)
            {
                stateProv = lookUp.GetStateProvince(model.Payment.BillingStateProvinceID.Value).Abbreviation;
            }
            Payment transaction = new Payment();
            transaction.ServiceRequestID = model.Payment.ServiceRequestID;
            transaction.PaymentTypeID = model.Payment.PaymentTypeID;
            transaction.PaymentTransactionTypeID = model.Payment.PaymentTransactionTypeID;
            transaction.PaymentStatusID = lookUp.GetPaymentStatus("Approved");
            transaction.PaymentReasonID = model.Payment.PaymentReasonID;
            transaction.PaymentReasonOther = model.Payment.PaymentReasonOther;
            transaction.PaymentDate = DateTime.Now;
            transaction.CCAccountNumber = model.Payment.CCAccountNumber;
            transaction.CCOrderID = model.Payment.CCOrderID;

            if (model.Payment.CCAccountNumber.ToString().Length > 0)
            {
                string firstDigit = model.Payment.CCAccountNumber.Substring(0, 1);
                string lastFourDigit = model.Payment.CCAccountNumber.Substring(model.Payment.CCAccountNumber.Length - 4, 4);
                string displayNumber = firstDigit + "XXXXXXXXXX" + lastFourDigit;
                transaction.CCPartial = displayNumber;
            }
            transaction.CCExpireDate = new DateTime(model.CardExpirationYear, model.CardExpirationMonth, DateTime.DaysInMonth(model.CardExpirationYear, model.CardExpirationMonth));
            transaction.Amount = model.Payment.Amount;
            transaction.CurrencyTypeID = model.Payment.CurrencyTypeID;
            transaction.CCNameOnCard = model.Payment.CCNameOnCard;
            transaction.BillingLine1 = model.Payment.BillingLine1;
            transaction.BillingLine2 = model.Payment.BillingLine2;
            transaction.BillingCity = model.Payment.BillingCity;
            transaction.BillingStateProvince = stateProv;
            transaction.BillingPostalCode = model.Payment.BillingPostalCode;
            transaction.BillingCountryCode = countryCode;
            transaction.BillingStateProvinceID = model.Payment.BillingStateProvinceID;
            transaction.BillingCountryID = model.Payment.BillingCountryID;
            transaction.Comments = model.Payment.Comments;
            return transaction;
        }
    }

    /// <summary>
    /// credit card transaction status
    /// </summary>
    public class CreditCardTransactionStatus
    {
        public bool isSuccess { get; set; }
        public string Message { get; set; }

        // Attributes whihc are the part of Web Service.
        public int? PaymentStatusID { get; set; }
        public string ProcessorTransactionResult { get; set; }
        public string ResponserAVS { get; set; }
        public string ResponseOrderNum { get; set; }
        public string ResponseError { get; set; }
        public string ResponseApproved { get; set; }
        public string ResponseCode { get; set; }
        public string ResponseMessage { get; set; }
        public DateTime ResponseTime { get; set; }
        public string ResponseTdate { get; set; }
        public string ResponseTax { get; set; }
        public string ResponseShipping { get; set; }
        public string ResponseAuthResponse { get; set; }
        public string CCAuthCode { get; set; }
        public string CCAuthType { get; set; }
        public string CCTransactionReference { get; set; }
        public string ResponseRef { get; set; }
        public string StoreNumber { get; set; }
        public int? PaymentID { get; set; }
        public string ProcessorReferenceNumber { get; set; }
        public string ApprovalCode { get; set; }
    }
    #endregion
}
