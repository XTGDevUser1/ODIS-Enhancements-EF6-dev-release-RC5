using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Model.VendorPortal;
using System.Transactions;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using log4net;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorInvoiceFacade
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorInvoiceFacade));

        public const string PO_NOT_EXISTS = "PO_NOT_EXISTS";
        public const string PO_NOT_ASSIGNED = "PO_NOT_ASSIGNED";
        public const string PO_PAID_BY_CC = "PO_PAID_BY_CC";
        public const string PO_NOT_ISSUED = "PO_NOT_ISSUED";


        private const string PO_LAPSED = "PO_LAPSED";
        private const string APP_CONFIG_VALUE_NOT_FOUND = "APP_CONFIG_VALUE_NOT_FOUND";
        private const string AMOUNT_THRESHOLD_EXCEEDED = "AMOUNT_THRESHOLD_EXCEEDED";
        private const string PO_ALREADY_PAID = "PO_ALREADY_PAID";
        private const string LOWER_PO_AMOUNT = "LOWER_PO_AMOUNT";
        private const string MISSING_BILLING_ADDRESS = "MISSING_BILLING_ADDRESS";
        private const string MISSING_TAX_ID = "MISSING_TAX_ID";
        private const string VENDOR_STATUS_ISSUE = "VENDOR_STATUS_ISSUE";
        private const string PO_ALREADY_INVOICED = "PO_ALREADY_INVOICED";

        private const string INVOICE_AMOUNT_ABOVE_PO_AMOUNT = "INVOICE_AMOUNT_ABOVE_PO_AMOUNT";
        private const string PO_TOO_EARLY = "PO_TOO_EARLY";

        private const string VENDOR_PORTAL_SOURCE_SYSTEM = "VendorPortal";
        public VendorInvoiceRepository repository = new VendorInvoiceRepository();


        /// <summary>
        /// Submits the invoice.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session unique identifier.</param>
        /// <param name="invoiceStatus">The invoice status.</param>
        /// <param name="sourceSystem">The source system.</param>
        /// <param name="contactMethod">The contact method.</param>
        /// <exception cref="DMSException">
        /// Contact Category - VendorInvoice is not set up in the system
        /// or
        /// Contact Type - Vendor is not set up in the system
        /// or
        /// Contact Method - Web is not set up in the system
        /// or
        /// ContactReason - SubmitInvoice is not set up for Category - VendorInvoice
        /// or
        /// ContactAction - ReceivedInvoice is not set up for Category - VendorInvoice
        /// </exception>
        public VendorInvoice SubmitInvoice(VendorInvoiceModel model, string eventSource, string currentUser, string sessionID, string invoiceStatus = "ReadyForPayment", string sourceSystem = "VendorPortal", string contactMethod = "Web")
        {
            //1. Validate Invoice
            logger.Info("Validating invoice");
            var validationResults = ValidateInvoice(model, sourceSystem);
            VendorInvoice v = null;

            logger.Info("Completed verifying invoice details");
            using (TransactionScope tran = new TransactionScope())
            {
                // Save data only after the data is found to be valid.
                VendorInvoiceRepository invoiceRepository = new VendorInvoiceRepository();
                PORepository poRepository = new PORepository();
                PurchaseOrder po = poRepository.GetPOById(validationResults.PurchaseOrderID);
                var now = DateTime.Now;
                var billingAddress = validationResults.BillingAddress;
                decimal? payAmount = model.PayAmount;
                if (sourceSystem == "VendorPortal")
                {
                    //KB: TFS 1989 : Setting PayAmount to invoiceamount when the invoice is submitted from VendorPortal
                    //payAmount = po != null ? po.PurchaseOrderAmount : model.PayAmount;
                    payAmount = model.InvoiceAmount;
                }
                VendorInvoice invoice = new VendorInvoice()
                {
                    PurchaseOrderID = validationResults.PurchaseOrderID,
                    VendorID = model.VendorID,
                    InvoiceNumber = model.InvoiceNumber,
                    ReceivedDate = model.ReceivedDate ?? now,
                    InvoiceDate = model.InvoiceDate ?? now,
                    InvoiceAmount = model.InvoiceAmount,

                    PaymentAmount = payAmount,

                    BillingBusinessName = validationResults.VendorName,
                    BillingContactName = validationResults.ContactName,
                    VendorInvoicePaymentDifferenceReasonCodeID = model.VendorInvoicePaymentDifferenceReasonCodeID,
                    // KB: Commented out due to TFS item : 1503	Vendor Portal - Submit Invoice - do not fill in billing fields on VendorInvoice table
                    // NP 10/17: uncommented out due to TFS item : 1932 
                    BillingAddressLine1 = billingAddress.Line1,
                    BillingAddressLine2 = billingAddress.Line2,
                    BillingAddressLine3 = billingAddress.Line3,
                    BillingAddressCity = billingAddress.City,
                    BillingAddressStateProvince = billingAddress.StateProvince,
                    BillingAddressCountryCode = billingAddress.CountryCode,
                    BillingAddressPostalCode = billingAddress.PostalCode,

                    //TFS # 1602 If hours == 7 (over 6), then minutes = 361 else hours*60 + minutes

                    ActualETAMinutes = (model.Hours.GetValueOrDefault() == 7) ? 361 : model.Hours.GetValueOrDefault() * 60 + model.Minutes.GetValueOrDefault(),

                    Last8OfVIN = model.VIN,
                    VehicleMileage = model.Mileage,

                    // NP 9/16: Changed ToBePaidDate to DateTime from model.ToBePaidDate as in TFS Item:1503
                    ToBePaidDate = model.ToBePaidDate ?? DateTime.Now,
                    //VendorInvoiceStatusID = vendorInvoiceStatus.ID,

                    IsActive = true,
                    CreateDate = now,
                    CreateBy = currentUser
                };
                logger.InfoFormat("Actual minutes set to {0}", invoice.ActualETAMinutes);
                logger.Info("Adding Invoice");
                invoiceRepository.Add(invoice, invoiceStatus, sourceSystem, contactMethod);
                v = invoice;
                model.InvoiceID = v.ID;
                ContactLogRepository cLogRepository = new ContactLogRepository();
                ContactLog contactLog = new ContactLog()
                {
                    Company = validationResults.VendorName,
                    Direction = "Inbound",
                    Description = "Submit Vendor Invoice",
                    CreateDate = now,
                    CreateBy = currentUser
                };
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                var contactCategory = staticDataRepo.GetContactCategoryByName("VendorInvoice");

                if (contactCategory == null)
                {
                    logger.Warn("Contact Category - VendorInvoice is not set up in the system");
                    throw new DMSException("Contact Category - VendorInvoice is not set up in the system");
                }
                contactLog.ContactCategoryID = contactCategory.ID;

                var contactType = staticDataRepo.GetTypeByName("Vendor");
                if (contactType == null)
                {
                    logger.Warn("Contact Type - Vendor is not set up in the system");
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }
                contactLog.ContactTypeID = contactType.ID;

                var contactMethodFromDB = staticDataRepo.GetMethodByName(contactMethod);
                if (contactMethodFromDB == null)
                {
                    logger.Warn("Contact Method - Web is not set up in the system");
                    throw new DMSException("Contact Method - Web is not set up in the system");
                }
                contactLog.ContactMethodID = contactMethodFromDB.ID;

                cLogRepository.Save(contactLog, currentUser, invoice.ID, EntityNames.VENDOR_INVOICE);
                cLogRepository.CreateLinkRecord(contactLog.ID, EntityNames.VENDOR, model.VendorID);

                logger.Info("Created Contact Log and link records");
                // Contact Log Reason and Actions pending.
                ContactLogReasonRepository cLogReasonRepo = new ContactLogReasonRepository();
                ContactLogReason cLogReason = new ContactLogReason()
                {
                    ContactLogID = contactLog.ID,
                    CreateDate = now,
                    CreateBy = currentUser
                };
                var contactReason = staticDataRepo.GetContactReason("SubmitInvoice", "VendorInvoice");
                if (contactReason == null)
                {
                    logger.Warn("ContactReason - SubmitInvoice is not set up for Category - VendorInvoice");
                    throw new DMSException("ContactReason - SubmitInvoice is not set up for Category - VendorInvoice");
                }
                cLogReason.ContactReasonID = contactReason.ID;

                cLogReasonRepo.Save(cLogReason, currentUser);

                logger.Info("Created ContactLogReason record");

                ContactLogActionRepository cLogActionRepo = new ContactLogActionRepository();
                ContactLogAction cLogAction = new ContactLogAction()
                {
                    ContactLogID = contactLog.ID,
                    CreateBy = currentUser,
                    CreateDate = now
                };

                var contactAction = staticDataRepo.GetContactActionByName("ReceivedInvoice", "VendorInvoice");
                if (contactAction == null)
                {
                    logger.Warn("ContactAction - ReceivedInvoice is not set up for Category - VendorInvoice");
                    throw new DMSException("ContactAction - ReceivedInvoice is not set up for Category - VendorInvoice");
                }
                cLogActionRepo.Save(cLogAction, currentUser);
                logger.Info("Created ContactLogAction record");

                // Event Logs
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.ADD_VENDOR_INVOICE, "Add Vendor Invoice", currentUser, invoice.ID, EntityNames.VENDOR_INVOICE, sessionID);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogId, model.VendorID.Value, EntityNames.VENDOR);

                logger.Info("Event log and link records created successfully");

                tran.Complete();
            }

            return v;
        }


        /// <summary>
        /// Updates the invoice.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session unique identifier.</param>
        /// <param name="invoiceStatus">The invoice status.</param>
        /// <param name="sourceSystem">The source system.</param>
        /// <param name="contactMethod">The contact method.</param>
        public void UpdateInvoice(VendorInvoiceModel model, string eventSource, string currentUser, string sessionID, string invoiceStatus = "Received", string sourceSystem = "VendorPortal", string contactMethod = "Web")
        {
            //1. Validate Invoice
            logger.Info("Validating invoice");
            var validationResults = ValidateInvoice(model, sourceSystem);
            logger.Info("Completed verifying invoice details");
            using (TransactionScope tran = new TransactionScope())
            {
                // Save data only after the data is found to be valid.

                var now = DateTime.Now;

                VendorInvoice invoice = new VendorInvoice()
                {
                    InvoiceNumber = model.InvoiceNumber,
                    ReceivedDate = model.ReceivedDate ?? now,
                    InvoiceDate = model.InvoiceDate ?? now,
                    ToBePaidDate = model.ToBePaidDate,
                    InvoiceAmount = model.InvoiceAmount,
                    ActualETAMinutes = model.Hours.GetValueOrDefault() * 60 + model.Minutes.GetValueOrDefault(),
                    Last8OfVIN = model.VIN,
                    VehicleMileage = model.Mileage,
                    IsActive = true,
                    ModifyBy = currentUser,
                    ModifyDate = now,
                    ID = model.InvoiceID,
                    VendorInvoicePaymentDifferenceReasonCodeID = model.VendorInvoicePaymentDifferenceReasonCodeID,
                    PaymentAmount = model.PayAmount
                };

                repository.UpdateInvoice(invoice, invoiceStatus, sourceSystem, contactMethod);
                // Event Logs
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.UPDATE_VENDOR_INVOICE, "Update Vendor Invoice", currentUser, invoice.ID, EntityNames.VENDOR_INVOICE, sessionID);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogId, model.VendorID.Value, EntityNames.VENDOR);

                logger.Info("Event log and link records created successfully");

                tran.Complete();

            }
        }
        /// <summary>
        /// Validates the invoice.
        ///(1)	Verify PO number
        ///(a)	PO number entered must exist
        ///(b)	PO number entered must belong to that vendor
        ///(c)	PO number entered must be in “Issued” status
        ///(i)	Message: 
        ///That PO number cannot be verified, please check the number and try again.  If you think that PO number should be verified, please call Vendor Services at 800-111-1111
        ///(2)	PO Status = “Over 120 days”
        ///(a)	Message:
        ///Cannot submit invoice because the PO is over 120 days old
        ///(3)	Verify Invoice Amount
        ///(a)	If ABS(InvoiceAmount – PurchaseOrderAmount) > (SELECT Value FROM ApplicationConfiguration WHERE Name = 'POInvoiceDifferenceThreshold'), display message:
        ///Invoice amount does not match the PO amount
        ///(b)	If (POAmount – InvoiceAmount)/POAmount > .5 then display message:
        ///Please check the invoice amount, it is much lower than the PO amount
        ///(4)	Verify Vendor Information
        ///(a)	If Vendor Billing address is missing, display message:
        ///Missing vendor billing address, please go to My Account and enter your billing address
        ///(b)	If Vendor TaxID is missing, display message:
        ///Missing Tax ID, please go to My Account and enter your Tax ID
        ///(c)	If VendorStatus = On Hold Payment, or Temporary then display message:
        ///There is an issue with your status, please contact Vendor Services

        /// </summary>
        /// <param name="model">The model.</param>
        public InvoiceValidationResults ValidateInvoice(VendorInvoiceModel model, string sourceSystem)
        {
            var validationResults = new InvoiceValidationResults();

            #region Verify PO

            var poRepository = new PORepository();
            logger.InfoFormat("Trying to retrieve PO # {0}", model.PONumber);
            var po = poRepository.GetPOByNumber(model.PONumber != null ? model.PONumber.Trim() : string.Empty);

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

            if (po == null)
            {
                logger.WarnFormat("PO with number {0} doesn't exist", model.PONumber);
                throw new DMSException(PO_NOT_EXISTS);
            }
            //The following case might arise when submitting an invoice from Vendor Invoices screen (not the portal) and the billing details are empty.
            if (model.VendorID == null || model.VendorID == 0)
            {
                model.VendorID = po.VendorLocation.VendorID;
            }
            if (po.VendorLocation.VendorID != model.VendorID)
            {
                logger.WarnFormat("PO not assigned to {0}. It is assigned to Vendor ID : {1}", model.VendorID, po.VendorLocation.VendorID);
                throw new DMSException(PO_NOT_ASSIGNED);
            }

            #region The following logic is replaced with a logic that considers PurchaseOrderPayStatusCode.
            /*

            //NP 02/24: Issue 137(NMC) : It should just check the IsPaybyCompanyCreditCard = 1
            if (po.IsPayByCompanyCreditCard.HasValue && po.IsPayByCompanyCreditCard.Value)// && !string.IsNullOrEmpty(po.CompanyCreditCardNumber))
            {
                logger.WarnFormat("PO [ ID : {0} ] paid by CC", po.ID);
                throw new DMSException(PO_PAID_BY_CC);
            }

            //TFS: 1718

            if (po.PurchaseOrderAmount.GetValueOrDefault() == 0 && po.TotalServiceAmount.GetValueOrDefault() == po.MemberServiceAmount.GetValueOrDefault())
            {
                logger.WarnFormat("PO [ ID : {0} ] paid by member", po.ID);
                throw new DMSException(PO_ALREADY_PAID);
            }
            */

            #endregion

            //KB: TFS 150 - Consider the PayStatusCode on PurchaseOrder.
            if (po.PayStatusCodeID != null && po.PayStatusCodeID == paidByCCStatusCode.ID)
            {
                logger.WarnFormat("PO [ ID : {0} ] paid by CC", po.ID);
                throw new DMSException(PO_PAID_BY_CC);
            }

            if (po.PayStatusCodeID != null && po.PayStatusCodeID == paidByMemberStatusCode.ID)
            {
                logger.WarnFormat("PO [ ID : {0} ] paid by member", po.ID);
                throw new DMSException(PO_ALREADY_PAID);
            }

            if (!"Issued".Equals(po.PurchaseOrderStatu.Name, StringComparison.InvariantCultureIgnoreCase))
            {
                logger.WarnFormat("PO [ ID : {0} ] status is not Issued", po.ID);
                throw new DMSException(PO_NOT_ISSUED);
            }

            var elapsedTime = (DateTime.Now - po.IssueDate.Value);

            if (model.InvoiceID == 0) // The following validations are applicable during an add invoice only.
            {
                var invoiceRepository = new VendorInvoiceRepository();
                List<VendorInvoice> invoicesForPO = invoiceRepository.GetVendorInvoiceListforPO(po.ID);
                if (invoicesForPO.Count > 0)
                {
                    logger.WarnFormat("PO [ ID : {0} ] has invoices", po.ID);
                    throw new DMSException(PO_ALREADY_INVOICED);
                }

                string sMaxElapsedTime = AppConfigRepository.GetValue("POInvoiceMaxElapsedTime");
                int defaultTime = 90;
                if (!string.IsNullOrEmpty(sMaxElapsedTime))
                {
                    int.TryParse(sMaxElapsedTime, out defaultTime);
                }

                if (!model.AllowLapsedPOs)
                {
                    if (elapsedTime.TotalDays > defaultTime)
                    {
                        logger.WarnFormat("PO [ ID : {0} ] is older than 90 days. It is older by {1} days", po.ID, elapsedTime.TotalDays);
                        throw new DMSException(PO_LAPSED);
                    }
                }
            }

            validationResults.PurchaseOrderID = po.ID;


            // TFS # 1640 : The following check is not applicable for VendorPortal
            // TFS # 1692 : Turn this off on Vendor Invoice too.
            //if (!VENDOR_PORTAL_SOURCE_SYSTEM.Equals(sourceSystem, StringComparison.InvariantCultureIgnoreCase))
            //{
            //    var strInvoiceDifferenceThreshold = AppConfigRepository.GetValue(AppConfigConstants.PO_INVOICE_DIFFERENCE_THRESHOLD);
            //    if (strInvoiceDifferenceThreshold != null)
            //    {
            //        decimal diffAmountThreshold = 0;
            //        decimal.TryParse(strInvoiceDifferenceThreshold, out diffAmountThreshold);
            //        if (Math.Abs(model.InvoiceAmount - po.PurchaseOrderAmount.GetValueOrDefault()) > diffAmountThreshold)
            //        {
            //            throw new DMSException(AMOUNT_THRESHOLD_EXCEEDED);
            //        }
            //    }
            //    else
            //    {
            //        throw new DMSException(APP_CONFIG_VALUE_NOT_FOUND);
            //    }
            //}

            if (!VENDOR_PORTAL_SOURCE_SYSTEM.Equals(sourceSystem, StringComparison.InvariantCultureIgnoreCase))
            {
                var strMaxAmountThreshold = AppConfigRepository.GetValue(AppConfigConstants.MAXIMUM_INVOICE_AMOUNT_THRESHOLD);
                if (strMaxAmountThreshold != null)
                {
                    decimal maxAmountThreshold = 0;
                    decimal.TryParse(strMaxAmountThreshold, out maxAmountThreshold);
                    if (model.PayAmount.GetValueOrDefault() > maxAmountThreshold)
                    {
                        logger.WarnFormat("PO [ ID : {0} ] Pay Amount exceeds maximum of {1}", po.ID, maxAmountThreshold.ToString("C"));
                        throw new DMSException(string.Format("Pay Amount exceeds maximum of {0}", maxAmountThreshold.ToString("C")));
                    }
                }
                else
                {
                    logger.WarnFormat("AppConfig - {0} not set up in the system", AppConfigConstants.MAXIMUM_INVOICE_AMOUNT_THRESHOLD);
                    throw new DMSException(APP_CONFIG_VALUE_NOT_FOUND);
                }
            }

            //TFS 1640 : Validation specific to Vendor Portal - Submit Invoice.
            if (VENDOR_PORTAL_SOURCE_SYSTEM.Equals(sourceSystem, StringComparison.InvariantCultureIgnoreCase))
            {
                if (model.InvoiceAmount > po.PurchaseOrderAmount)
                {
                    logger.WarnFormat("Invoice amount is greater than PO Amount {0}", po.PurchaseOrderAmount);
                    throw new DMSException(INVOICE_AMOUNT_ABOVE_PO_AMOUNT);
                }

                if (elapsedTime.TotalHours < 6)
                {
                    logger.WarnFormat("PO [ ID : {0} ] is too early", po.ID);
                    throw new DMSException(PO_TOO_EARLY);
                }
            }

            //TFS 1640 
            if (!model.AllowLowerPOAmount)
            {
                if (model.InvoiceAmount < (decimal)0.5 * po.PurchaseOrderAmount.GetValueOrDefault())
                {
                    logger.WarnFormat("PO [ ID : {0} ] Invoice amount {1} is less than half the PurchaseOrderamount {2}", po.ID, model.InvoiceAmount, po.PurchaseOrderAmount.GetValueOrDefault());
                    throw new DMSException(LOWER_PO_AMOUNT);
                }
            }

            #endregion

            #region Verify Vendor Information

            var addressRepository = new AddressRepository();
            List<AddressEntity> addresses = addressRepository.GetAddresses(model.VendorID.Value, EntityNames.VENDOR, "Billing");

            if (addresses == null || addresses.Count == 0)
            {
                logger.InfoFormat("Missing billing address for Vendor {0}", model.VendorID);
                throw new DMSException(MISSING_BILLING_ADDRESS);
            }

            validationResults.BillingAddress = addresses.FirstOrDefault();

            var vendorRepository = new VendorRepository();
            var vendor = vendorRepository.GetByID(model.VendorID.GetValueOrDefault());

            // TFS 2089: CA Vendors doesn't need this validation on Tax IDs.
            if (!"CA".Equals(validationResults.BillingAddress.CountryCode))
            {
                if (string.IsNullOrEmpty(vendor.TaxEIN) && string.IsNullOrEmpty(vendor.TaxSSN))
                {
                    if (VENDOR_PORTAL_SOURCE_SYSTEM.Equals(sourceSystem))
                    {
                        logger.InfoFormat("Missing Tax ID for Vendor {0}", model.VendorID);
                        throw new DMSException(MISSING_TAX_ID);
                    }
                    //TFS : 1718
                    //else
                    //{
                    //    throw new DMSException("Missing TaxID, please go to Vendor page and enter their TaxID");
                    //}
                }
            }
            validationResults.VendorName = vendor.Name;
            validationResults.ContactName = vendor.ContactFirstName + ' ' + vendor.ContactLastName;

            var vendorStatus = vendor.VendorStatu.Name;
            if ("OnHold".Equals(vendorStatus, StringComparison.InvariantCultureIgnoreCase) ||
                "Temporary".Equals(vendorStatus, StringComparison.InvariantCultureIgnoreCase))
            {
                logger.InfoFormat("Status of the vendor {0} is {1}", model.VendorID, vendorStatus);
                if ("VendorPortal".Equals(sourceSystem))
                {                    
                    throw new DMSException(VENDOR_STATUS_ISSUE);
                }
                else
                {
                    throw new DMSException(string.Format("The Vendor Status = {0}. Invoices cannot be entered.", vendorStatus));
                }

            }

            #endregion

            return validationResults;
        }
    }

    public class InvoiceValidationResults
    {
        public int PurchaseOrderID { get; set; }
        public AddressEntity BillingAddress { get; set; }
        public string VendorName { get; set; }
        public string ContactName { get; set; }
    }
}
