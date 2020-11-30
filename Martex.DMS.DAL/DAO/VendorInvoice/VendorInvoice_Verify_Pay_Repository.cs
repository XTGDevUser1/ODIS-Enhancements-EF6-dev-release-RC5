using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity.Core.Objects;
using log4net;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorInvoiceRepository
    {

        /// <summary>
        /// Verifies the invoices.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="includeValidationsForPayment">if set to <c>true</c> [include validations for payment].</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Incorrect value for MaximumInvoiceAmountThreshold -  + maxInvoiceAmountThreshold.Value</exception>
        public VendorInvoiceStatusSummary VerifyInvoices(List<int> invoices, string currentUser, bool includeValidationsForPayment = false)
        {
            VendorInvoiceStatusSummary summary = new VendorInvoiceStatusSummary();

            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                // Get all VendorInvoices
                // Validate each invoice and update the status accordingly.
                // In the case of an exception, write related records too.

                var invoicesFromDB = dbContext.VendorInvoices.Include("Vendor")
                                                                .Include("VendorInvoiceStatu")
                                                                .Include(i => i.PurchaseOrder)
                                                                .Include(i=> i.PurchaseOrder.PurchaseOrderStatu)
                                                                .Include(i=>i.PurchaseOrder.VendorLocation)
                                                                .Include(i=>i.PurchaseOrder.PurchaseOrderPayStatusCode)
                                                                .Where(x => invoices.Contains(x.ID)).ToList<VendorInvoice>();
                var vendorInvoiceStatuses = dbContext.VendorInvoiceStatus.ToList<VendorInvoiceStatu>();

                const string READY_FOR_PAYMENT = "ReadyForPayment";
                var readyforPaymentID = vendorInvoiceStatuses.Where(x => x.Name == READY_FOR_PAYMENT).FirstOrDefault();
                const string VENDOR_INVOICE_STATUS = "VendorInvoiceStatus";
                ThrowErrorForMissingEntity(readyforPaymentID, VENDOR_INVOICE_STATUS, READY_FOR_PAYMENT);

                const string EXCEPTION = "Exception";
                var exceptionID = vendorInvoiceStatuses.Where(x => x.Name == EXCEPTION).FirstOrDefault();
                ThrowErrorForMissingEntity(readyforPaymentID, VENDOR_INVOICE_STATUS, EXCEPTION);

                const string RECEIVED = "Received";
                var receivedID = vendorInvoiceStatuses.Where(x => x.Name == RECEIVED).FirstOrDefault();
                ThrowErrorForMissingEntity(readyforPaymentID, VENDOR_INVOICE_STATUS, RECEIVED);

                const string CANCELLED = "Cancelled";
                var cancelledID = vendorInvoiceStatuses.Where(x => x.Name == CANCELLED).FirstOrDefault();
                ThrowErrorForMissingEntity(readyforPaymentID, VENDOR_INVOICE_STATUS, CANCELLED);

                const string PAID = "Paid";
                var paidID = vendorInvoiceStatuses.Where(x => x.Name == PAID).FirstOrDefault();
                ThrowErrorForMissingEntity(readyforPaymentID, VENDOR_INVOICE_STATUS, PAID);

                const string MAXIMUM_INVOICE_AMOUNT_THRESHOLD = "MaximumInvoiceAmountThreshold";
                var maxInvoiceAmountThreshold = dbContext.ApplicationConfigurations.Where(x => MAXIMUM_INVOICE_AMOUNT_THRESHOLD == x.Name).FirstOrDefault();
                ThrowErrorForMissingEntity(maxInvoiceAmountThreshold, "Applicationconfiguration", MAXIMUM_INVOICE_AMOUNT_THRESHOLD);

                decimal dMaxInvoiceAmountThreshold = Decimal.MinValue;

                decimal.TryParse(maxInvoiceAmountThreshold.Value, out dMaxInvoiceAmountThreshold);

                if (dMaxInvoiceAmountThreshold == Decimal.MinValue)
                {
                    throw new DMSException("Incorrect value for MaximumInvoiceAmountThreshold - " + maxInvoiceAmountThreshold.Value);
                }
                int counter = 0;
                DateTime beforeVerify = DateTime.Now;
                invoicesFromDB.ForEach(i =>
                {
                    DateTime start = DateTime.Now;
                    // Run the following validation rules. - PLEASE DO NOT DELETE THE FOLLOWING COMMENTS!
                    /* ReadyForPayment - InvoiceStatus= ReadForPayment and ToBePaidDate <= CurrentDate OR ToBePaidDate is a future date.
                     * Exceptions :
                     *               Vendor.IsPaymentOnHold = true
                     *               Missing Tax IDs
                     *               Payee name incomplete (Vendor.IsLevyActive && Vendor.LevyReceiptName = '') 
                     *                                      OR 
                     *                                      (!Vendor.IsLevyActive && Vendor.Name = '')
                     *              Payee Address incomplete (Vendor.IsLevyActive && missing fields on AddressType = 'Levy')
                     *                                      OR
                     *                                      (!Vendor.IsLevyActive && missing fields on AddressType = 'Billing')
                     *             ACH Information incomplete (VendorACH.ACHStatus = 'Active' && missing VendorACH.AccountNumber and ABANumber)
                     *             Invoice Amount over threshold (InvoiceAmount > AppConfig [ 'MaximumInvoiceAmountThreshold' ]
                     * Received     - InvoiceStatus = Received
                     * Cancelled    - InvoiceStatus = Cancelled
                     * Paid         - InvoiceStatus = Paid
                     */
                    List<string> exceptionMessages = new List<string>();
                    bool isException = false;
                    Vendor vendor = null;
                    List<AddressEntity> addresses = null;
                    bool updateInvoice = false;
                    if (i.VendorInvoiceStatu != null)
                    {
                        vendor = i.Vendor;

                        addresses = (from a in dbContext.AddressEntities.Include(a=>a.AddressType)
                                     where a.RecordID == vendor.ID && a.Entity.Name == "Vendor" && (a.AddressType.Name == "Levy" || a.AddressType.Name == "Billing")
                                     select a).ToList<AddressEntity>();

                        var currentInvoiceStatus = i.VendorInvoiceStatu;
                        if (RECEIVED.Equals(currentInvoiceStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.Received += 1;
                            summary.ReceivedAmount += i.InvoiceAmount.GetValueOrDefault();
                        }
                        else if (CANCELLED.Equals(currentInvoiceStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.Cancelled += 1;
                            summary.CancelledAmount += i.InvoiceAmount.GetValueOrDefault();
                        }
                        else if (PAID.Equals(currentInvoiceStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.Paid += 1;
                            summary.PaidAmount += i.InvoiceAmount.GetValueOrDefault();
                        }
                        else // Process items in ReadyForPayment and Exceptions
                        {
                            updateInvoice = true;
                            // Get all previous exceptions and delete them.
                            var previousExceptions = dbContext.VendorInvoiceExceptions.Where(v => v.VendorInvoiceID == i.ID).ToList<VendorInvoiceException>();
                            previousExceptions.ForEach(r =>
                            {
                                dbContext.Entry(r).State = EntityState.Deleted;
                            });

                            var vendorACH = dbContext.VendorACHes.Include("ACHStatu").Where(v => v.VendorID == vendor.ID && v.IsActive == true).FirstOrDefault();

                            // TFS : 1720 : Validate Vendor for TaxIDs if only the total Amount paid so far, in the current calendar year > $600.
                            decimal? totalPaidSoFar = 0;
                            if (vendor != null)
                            {
                                DateTime today = DateTime.Today;
                                totalPaidSoFar = (from vi in dbContext.VendorInvoices
                                                  where vi.PaymentDate != null && vi.PaymentDate.Value.Year == today.Year && vi.VendorID == vendor.ID
                                                  select vi).Sum(a => a.PaymentAmount);

                                logger.InfoFormat("Total Paid so far for the vendor {0} is {1}", vendor.ID, totalPaidSoFar.GetValueOrDefault().ToString("C"));
                            }

                            if (vendor != null && (vendor.IsPaymentOnHold ?? false))
                            {
                                isException = true;
                                exceptionMessages.Add("Vendor on payment hold");
                            }

                            if (vendor != null && ((vendor.IsLevyActive ?? false) && string.IsNullOrEmpty(vendor.LevyRecipientName) ||
                                      (!(vendor.IsLevyActive ?? false) && string.IsNullOrEmpty(vendor.Name)))
                                )
                            {
                                isException = true;
                                exceptionMessages.Add("Payee name incomplete");
                            }

                            if (vendor != null && (((vendor.IsLevyActive ?? false) && AreAddressFieldsMissing(addresses.Where(a => a.AddressType.Name == "Levy").FirstOrDefault())) ||
                                        (!(vendor.IsLevyActive ?? false) && AreAddressFieldsMissing(addresses.Where(a => a.AddressType.Name == "Billing").FirstOrDefault()))
                                ))
                            {
                                isException = true;
                                exceptionMessages.Add("Payee address incomplete");
                            }

                            var billingAddress = (vendor.IsLevyActive ?? false) ? addresses.Where(a => a.AddressType.Name == "Levy").FirstOrDefault() : addresses.Where(a => a.AddressType.Name == "Billing").FirstOrDefault();

                            //TFS : 2012 : Candian Vendors doesn't require Tax ID validation.
                            if (vendor == null || (billingAddress == null
                                                    || (!"CA".Equals(billingAddress.CountryCode, StringComparison.InvariantCultureIgnoreCase)
                                                        && (totalPaidSoFar.GetValueOrDefault() > 600 && string.IsNullOrEmpty(vendor.TaxEIN) && string.IsNullOrEmpty(vendor.TaxSSN))
                                                        )
                                                  ))
                            {
                                isException = true;
                                exceptionMessages.Add("Missing Tax ID");
                            }

                            //if (vendorACH != null && !vendorACH.ACHStatu.Name.Equals("Valid", StringComparison.InvariantCultureIgnoreCase))
                            //{
                            //    isException = true;
                            //    exceptionMessages.Add("ACH status is not valid");
                            //}

                            if (vendorACH != null && vendorACH.ACHStatu.Name.Equals("Valid", StringComparison.InvariantCultureIgnoreCase) && (string.IsNullOrEmpty(vendorACH.AccountNumber) || string.IsNullOrEmpty(vendorACH.BankABANumber)))
                            {
                                isException = true;
                                exceptionMessages.Add("ACH information incomplete");
                            }
                            // TFS : 1993 : ABANumber Validation.
                            if (vendorACH != null && vendorACH.ACHStatu.Name.Equals("Valid", StringComparison.InvariantCultureIgnoreCase))
                            {
                                bool? isABANumberValid = dbContext.IsABANumberValid(vendorACH.BankABANumber).SingleOrDefault<bool?>();
                                if (isABANumberValid == null || !isABANumberValid.Value)
                                {
                                    isException = true;
                                    exceptionMessages.Add("ABA Number is invalid");
                                }
                            }

                            if (i.InvoiceAmount.GetValueOrDefault() > dMaxInvoiceAmountThreshold)
                            {
                                isException = true;
                                exceptionMessages.Add("Invoice amount over threshold");
                            }

                            // Perform additional checks for "Pay Invoices"
                            if (!isException) // && includeValidationsForPayment) //KB: Let's run the validations for both "Verify" and "Pay" invoices.
                            {
                                var po = i.PurchaseOrder;
                                if (po.PurchaseOrderStatu == null || !"Issued".Equals(po.PurchaseOrderStatu.Name))
                                {
                                    isException = true;
                                    exceptionMessages.Add("PO is not in Issued status");
                                }

                                // TFS : 2236
                                /*if (i.ToBePaidDate == null || i.ToBePaidDate.Value.Date > DateTime.Now.Date)
                                {
                                    isException = true;
                                    exceptionMessages.Add("Payment date has not been met");
                                }*/
                                //TFS: 2013
                                if (po.PurchaseOrderPayStatusCode != null)
                                {
                                    if ("OnHold".Equals(po.PurchaseOrderPayStatusCode.Name, StringComparison.InvariantCultureIgnoreCase))
                                    {
                                        isException = true;
                                        exceptionMessages.Add("PO Pay Status Code is OnHold");
                                    }
                                    if ("PaidByCC".Equals(po.PurchaseOrderPayStatusCode.Name, StringComparison.InvariantCultureIgnoreCase) ||
                                        "PaidByMember".Equals(po.PurchaseOrderPayStatusCode.Name, StringComparison.InvariantCultureIgnoreCase))
                                    {
                                        isException = true;
                                        exceptionMessages.Add(string.Format("PO Pay Status Code {0}", po.PurchaseOrderPayStatusCode.Name));
                                    }
                                }

                            }

                        }

                        logger.InfoFormat("Exceptions for Vendor Invoice [ {0} ] so far are [ {1} ]", i.ID, string.Join(",", exceptionMessages));

                        if (isException)
                        {
                            summary.Exceptions += 1;
                            summary.ExceptionsAmount += i.InvoiceAmount.GetValueOrDefault();

                            i.VendorInvoiceStatusID = exceptionID.ID;
                            i.ModifyBy = currentUser;
                            i.ModifyDate = DateTime.Now;

                            summary.InvoicesWithExceptions.Add(i.ID);

                            exceptionMessages.ForEach(exceptionMessage =>
                            {
                                VendorInvoiceException vie = new VendorInvoiceException();
                                vie.VendorInvoiceID = i.ID;
                                vie.Description = exceptionMessage;
                                vie.CreateDate = DateTime.Now;
                                vie.CreateBy = currentUser;

                                dbContext.VendorInvoiceExceptions.Add(vie);
                            });
                        }
                        else if (updateInvoice)
                        {
                            i.VendorInvoiceStatusID = readyforPaymentID.ID;
                            i.ModifyBy = currentUser;
                            i.ModifyDate = DateTime.Now;

                            // Update Address fields on invoice.
                            var addressToBeUsed = (vendor.IsLevyActive ?? false) ? addresses.Where(a => a.AddressType.Name == "Levy").FirstOrDefault()
                                                                                    : addresses.Where(a => a.AddressType.Name == "Billing").FirstOrDefault();
                            if (addressToBeUsed != null)
                            {
                                i.BillingAddressLine1 = addressToBeUsed.Line1;
                                i.BillingAddressLine2 = addressToBeUsed.Line2;
                                i.BillingAddressLine3 = addressToBeUsed.Line3;
                                i.BillingAddressCity = addressToBeUsed.City;
                                i.BillingAddressStateProvince = addressToBeUsed.StateProvince;
                                i.BillingAddressCountryCode = addressToBeUsed.CountryCode;
                                i.BillingAddressPostalCode = addressToBeUsed.PostalCode;
                            }

                            //KB: TFS : 2165 - Update BusinessName and Contact details of Vendor on VendorInvoice.
                            if ((vendor.IsLevyActive ?? false))
                            {
                                i.BillingBusinessName = vendor.LevyRecipientName;
                                i.BillingContactName = null;
                            }
                            else
                            {
                                i.BillingBusinessName = vendor.Name;
                                i.BillingContactName = string.Join(" ", vendor.ContactFirstName, vendor.ContactLastName);
                            }

                            //TFS : 2236
                            if (i.ToBePaidDate == null || i.ToBePaidDate.Value.Date > DateTime.Now.Date)
                            {
                                summary.ReadyForPaymentInFuture += 1;
                                summary.ReadyForPaymentInFutureAmount += i.InvoiceAmount.GetValueOrDefault();
                            }
                            else
                            {
                                summary.ReadyForPayment += 1;
                                summary.ReadyForPaymentAmount += i.InvoiceAmount.GetValueOrDefault();
                                summary.InvoicesReadyForPayment.Add(i.ID);
                            }

                            
                        }
                    }

                    DateTime end = DateTime.Now;
                    logger.InfoFormat(" [ {0} ] - Time to process invoice id - {1} is {2} ms", ++counter, i.ID, (end - start).TotalMilliseconds);
                });

                dbContext.SaveChanges();

                DateTime afterVerify = DateTime.Now;
                logger.InfoFormat("Time taken to process {0} invoices is {1} ms", counter, (afterVerify - beforeVerify).TotalMilliseconds);
            }

            return summary;

        }

        /// <summary>
        /// Throws the error for missing entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <param name="entityType">Type of the entity.</param>
        /// <param name="val">The value.</param>
        /// <exception cref="DMSException"></exception>
        protected void ThrowErrorForMissingEntity(object entity, string entityType, string val)
        {
            if (entity == null)
            {
                throw new DMSException(string.Format("{0} - {1} not set up in the system", entityType, val));
            }
        }

        /// <summary>
        /// Ares the address fields missing.
        /// </summary>
        /// <param name="a">The aggregate.</param>
        /// <returns></returns>
        private bool AreAddressFieldsMissing(AddressEntity a)
        {
            if (a == null ||
                string.IsNullOrEmpty(a.Line1) ||
                string.IsNullOrEmpty(a.City) ||
                string.IsNullOrEmpty(a.StateProvince) ||
                string.IsNullOrEmpty(a.CountryCode) ||
                string.IsNullOrEmpty(a.PostalCode)
                )
            {
                return true;
            }
            return false;
        }


        /// <summary>
        /// Gets the etl execution log unique identifier.
        /// </summary>
        /// <param name="description">The description.</param>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public int GetETLExecutionLogID(string description, string userName)
        {
            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                ObjectParameter logIDParam = new ObjectParameter("LogID", typeof(int));
                dbContext.CreateExecutionLog(description, userName, logIDParam);
                return (int)logIDParam.Value;
            }
        }


        /// <summary>
        /// Creates the staging data for invoice.
        /// </summary>
        /// <param name="invoiceID">The invoice unique identifier.</param>
        /// <param name="batchID">The batch unique identifier.</param>
        /// <param name="batchTimeStamp">The batch time stamp.</param>
        public void CreateStagingDataForInvoice(int invoiceID, long batchID, DateTime? batchTimeStamp)
        {
            // Get the following entities from ODIS:
            // Batch (including status and type), Vendor, VendorACH, PurchaseOrder, Invoice, BillingAddress and BusinessPhoneNumber.
            Batch batch = null;
            VendorACH vendorACH = null;
            Vendor vendor = null;
            VendorRegion vendorRegion = null;
            //KB: TFS 2165 : Use the data from VendorInvoice and not vendor.
            //AddressEntity billingAddress = null;
            PhoneEntity businessPhone = null;
            VendorInvoice invoice = null;
            List<ACHStatu> achStatuses = null;
            PurchaseOrder po = null;
            //int? programID = 0;
            string glPaymentMethodConfig = null;
            string countryISOCode3 = string.Empty;

            var progRepo = new ProgramMaintenanceRepository();


            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                invoice = dbContext.VendorInvoices.Include("Vendor").Include("VendorInvoicePaymentDifferenceReasonCode").Where(vi => vi.ID == invoiceID).FirstOrDefault();

                if (invoice != null)
                {
                    vendorACH = dbContext.VendorACHes.Where(ach => ach.VendorID == invoice.VendorID && ach.IsActive == true).FirstOrDefault();
                    vendor = dbContext.Vendors.Include("VendorRegion").Where(vr => vr.ID == invoice.VendorID).FirstOrDefault();
                    if (vendor != null)
                    {
                        vendorRegion = vendor.VendorRegion;
                    }

                    //KB: TFS 2165 : Use the data from VendorInvoice and not vendor.
                    /*billingAddress = (from a in dbContext.AddressEntities
                                      where a.RecordID == invoice.VendorID && a.Entity.Name == "Vendor" && a.AddressType.Name == "Billing"
                                      select a).FirstOrDefault();
                    if (billingAddress == null)
                    {
                        throw new DMSException("Billing address is missing");
                    }*/
                    Country vendorCountry = (from cn in dbContext.Countries
                                             where cn.ISOCode == invoice.BillingAddressCountryCode
                                             select cn).FirstOrDefault<Country>();
                    if (vendorCountry != null)
                    {
                        countryISOCode3 = vendorCountry.ISOCode3;
                    }

                    businessPhone = (from p in dbContext.PhoneEntities
                                     where p.RecordID == invoice.VendorID && p.Entity.Name == "Vendor" && p.PhoneType.Name == "Office"
                                     select p).FirstOrDefault();
                    if (businessPhone == null)
                    {
                        //throw new DMSException("Dispatch Phone is missing");
                        businessPhone = new PhoneEntity();
                    }
                    po = dbContext.PurchaseOrders.Include("Product").Where(p => p.ID == invoice.PurchaseOrderID).FirstOrDefault();
                }

                batch = dbContext.Batches.Include("BatchType").Where(b => b.ID == batchID).FirstOrDefault();
                achStatuses = dbContext.ACHStatus.ToList<ACHStatu>();

                Case currentCase = (from p in dbContext.PurchaseOrders
                                    join sr in dbContext.ServiceRequests on p.ServiceRequestID equals sr.ID
                                    join c in dbContext.Cases on sr.CaseID equals c.ID
                                    where p.ID == po.ID
                                    select c

                             ).FirstOrDefault();

                List<ProgramInformation_Result> programConfigs = progRepo.GetProgramInfo(currentCase.ProgramID, "Application", null);
                // TFS : IF PO/SR/Case associated with this VendorInvoice was for delivery driverCase.IsDeliveryDriver = 1  
                //          THEN  use program function to look for ProgramConfiguration where name = 'DeliveryDriverISPGLExpenseAccount' and use that account
                //      ELSE check for program specific GL accountuse program function to look for ProgramConfiguration where name = 'ISPGLExpenseAccount' and use that account
                //      ELSE use the defaultApplicationConfiguration where name = 'ISPGLExpenseAccount' and use this account

                var item = programConfigs.Where(p => (currentCase.IsDeliveryDriver == true && p.Name == "DeliveryDriverISPGLCheckExpenseAccount") ||
                                                    (currentCase.IsDeliveryDriver == false && p.Name == "ISPCheckGLExpenseAccount")).FirstOrDefault();
                if (item != null)
                {
                    logger.InfoFormat("Found a value {0} for DeliveryDriver {1} and Program {2} in ProgramConfiguration", item.Value, currentCase.IsDeliveryDriver, currentCase.ProgramID.GetValueOrDefault());
                    glPaymentMethodConfig = item.Value;
                }
                else
                {
                    glPaymentMethodConfig = AppConfigRepository.GetValue("ISPCheckGLExpenseAccount");
                    logger.InfoFormat("Didn't find a value for DeliveryDriver {0} and Program {1} in ProgramConfiguration, so attempting to use ISPCheckGLExpenseAccount - {2} from ApplicationConfiguration", currentCase.IsDeliveryDriver, currentCase.ProgramID.GetValueOrDefault(), glPaymentMethodConfig);
                }

            }

            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                var validACHStatus = achStatuses.Where(a => a.Name == "Valid").FirstOrDefault();
                string vendorID = vendor.ID.ToString();
                var vendorMastersCreatedForBatch = dbContext.APVendorMasters.Where(v => v.VendorNumber == vendorID && v.ETL_Load_ID == batch.MasterETLLoadID).Count();

                logger.InfoFormat("VendorMaster records created for {0} is {1}", vendorID, vendorMastersCreatedForBatch);

                if (vendorMastersCreatedForBatch == 0)
                {
                    logger.InfoFormat("Creating VendorMaster record for Vendor {0}", vendor.ID);

                    // Create an entry in APVendorMaster and APCheckRequest.
                    APVendorMaster vendorMaster = new APVendorMaster()
                    {
                        ETL_Load_ID = batch.MasterETLLoadID,
                        AddDateTime = batchTimeStamp,
                        Division = GetAccountDivisionNumber(batch),
                        VendorNumber = Left(invoice.VendorID.ToString(), 7), //TODO: Vendor number is 8 characters in our db.
                        VendorName = ReplaceCommas(Left(invoice.BillingBusinessName, 30), " "), //KB : TFS 2165 - Get the data from VendorInvoice and not Vendor.
                        AddressLine1 = ReplaceCommas(Left(invoice.BillingAddressLine1, 30), " "),
                        AddressLine2 = ReplaceCommas(Left(invoice.BillingAddressLine2, 30), " "),
                        AddressLine3 = ReplaceCommas(Left(invoice.BillingAddressLine3, 30), " "),
                        City = ReplaceCommas(Left(invoice.BillingAddressCity, 20), " "),
                        State = ReplaceCommas(Left(invoice.BillingAddressStateProvince, 2), " "),
                        ZipCode = Left(invoice.BillingAddressPostalCode, 10),
                        PhoneNumber = GetFormattedPhoneNumber(businessPhone.PhoneNumber),
                        VendorRef = Left(invoice.Vendor.VendorNumber, 15),
                        MasterFileComment = invoice.Vendor.IsLevyActive.GetValueOrDefault() ? "Levy Check - " + ReplaceCommas(Left(invoice.Vendor.Name, 17), " ") : "ISP Check",
                        EmailAddress = vendorACH != null && vendorACH.ACHStatusID == validACHStatus.ID ? Left(vendorACH.ReceiptEmail, 50) : Left(invoice.Vendor.Email, 50),
                        BankAccountNumber = vendorACH != null && vendorACH.ACHStatusID == validACHStatus.ID && !string.IsNullOrEmpty(vendorACH.AccountNumber) ? Left(vendorACH.AccountNumber, 17) : string.Empty,
                        BankTransitNumber = vendorACH != null && vendorACH.ACHStatusID == validACHStatus.ID && !string.IsNullOrEmpty(vendorACH.BankABANumber) ? Left(vendorACH.BankABANumber, 9) : string.Empty,
                        BankAccountType = vendorACH != null && vendorACH.ACHStatusID == validACHStatus.ID ? GetAccountType(vendorACH.AccountType) : string.Empty,
                        CountryCode = ReplaceCommas(countryISOCode3, " ")
                    };
                    dbContext.APVendorMasters.Add(vendorMaster);
                }


                APCheckRequest checkRequest = new APCheckRequest()
                {
                    ETL_Load_ID = batch.TransactionETLLoadID,
                    ProcessFlag = null,
                    Status = null,
                    ErrorDescription = null,
                    AddDateTime = batchTimeStamp,
                    Division = GetAccountDivisionNumber(batch),
                    VendorNumber = Left(invoice.VendorID.ToString(), 7),
                    InvoiceNumber = invoice.ID.ToString(),
                    InvoiceDate = invoice.InvoiceDate.HasValue ? invoice.InvoiceDate.Value.Date : (DateTime?)null,
                    InvoiceDueDate = invoice.InvoiceDate.HasValue ? invoice.InvoiceDate.Value.Date : (DateTime?)null,
                    Comment = "Vendor Invoice",
                    SeparateCheck = "N",
                    InvoiceAmount = invoice.PaymentAmount,
                    GLExpenseAccount = glPaymentMethodConfig,
                    ExpenseAmount = invoice.PaymentAmount,
                    AdditionalComment = Left(GetAdditionalComment(po, invoice.VendorInvoicePaymentDifferenceReasonCode), 50), //po.Product != null ? Left(po.Product.Name, 41) : string.Empty,
                    PaymentMethod = vendorACH != null && vendorACH.ACHStatusID == validACHStatus.ID ? "ACH" : "Check",
                    DocumentNoteID = null,
                    ContractType = null,
                    PONumber = po.PurchaseOrderNumber,
                    POIssuedDate = po.IssueDate.HasValue ? po.IssueDate.Value.Date : (DateTime?)null,
                    VendorInvoiceNumber = ReplaceCommas(Left(invoice.InvoiceNumber, 15), " "), // TFS 2110 : Store Left(15) of InvoiceNumber without commas.
                    ReceivedDate = invoice.ReceivedDate.HasValue ? invoice.ReceivedDate.Value.Date : (DateTime?)null,

                    //TODO: To be filled
                    VendorRepContactName = ReplaceCommas(vendorRegion != null ? string.Join(" ", vendorRegion.ContactFirstName, vendorRegion.ContactLastName) : string.Empty, " "),
                    VendorRepContactEmail = vendorRegion != null ? vendorRegion.Email : string.Empty,
                    VendorRepContactPhoneNumber = vendorRegion != null ? GetFormattedPhoneNumber(vendorRegion.PhoneNumber) : string.Empty

                    // All other fields are left as nulls.

                };


                dbContext.APCheckRequests.Add(checkRequest);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the additional comment.
        /// </summary>
        /// <param name="po">The position.</param>
        /// <param name="vendorInvoicePaymentDifferenceReasonCode">The vendor invoice payment difference reason code.</param>
        /// <returns></returns>
        private string GetAdditionalComment(PurchaseOrder po, VendorInvoicePaymentDifferenceReasonCode vendorInvoicePaymentDifferenceReasonCode)
        {
            List<string> strArray = new List<string>();
            if (po.Product != null && !string.IsNullOrEmpty(po.Product.Name))
            {
                strArray.Add(po.Product.Name);
            }
            if (vendorInvoicePaymentDifferenceReasonCode != null && !string.IsNullOrEmpty(vendorInvoicePaymentDifferenceReasonCode.Description))
            {
                strArray.Add(vendorInvoicePaymentDifferenceReasonCode.Description);
            }

            string result = string.Join("*", strArray.ToArray());

            return result;
        }



        /// <summary>
        /// Gets the type of the account.
        /// </summary>
        /// <param name="accountType">Type of the account.</param>
        /// <returns></returns>
        private string GetAccountType(string accountType)
        {
            if (accountType.Contains("Saving"))
            {
                return "S";
            }
            else if (accountType.Contains("Check"))
            {
                return "C";
            }
            return string.Empty;
        }


        /// <summary>
        /// Gets the formatted phone number.
        /// </summary>
        /// <param name="p">The application.</param>
        /// <returns></returns>
        private string GetFormattedPhoneNumber(string p)
        {
            if (string.IsNullOrEmpty(p))
            {
                return p;
            }
            var tokens = p.Split(' ');
            var phoneNumber = tokens[1];
            //TODO: Let's drop extension for now to support the size of the target column.
            phoneNumber = phoneNumber.Split('x', 'X')[0];

            return string.Format("({0}){1}-{2}", phoneNumber.Substring(0, 3), phoneNumber.Substring(3, 3), phoneNumber.Substring(6));
        }

        public string ReplaceCommas(string s, string replacementString)
        {
            if (string.IsNullOrEmpty(s))
            {
                return s;
            }

            return s.Replace(",", replacementString);
        }

        /// <summary>
        /// Get the first n characters from the left.
        /// </summary>
        /// <param name="s">The string</param>
        /// <param name="number">The number of characters to be extracted from the start.</param>
        /// <returns></returns>
        public string Left(string s, int number)
        {
            if (!string.IsNullOrEmpty(s) && s.Length > number)
            {
                return s.Substring(0, number);
            }
            else if (!string.IsNullOrEmpty(s) && s.Length <= number)
            {
                return s;
            }

            return s;
        }
        /// <summary>
        /// Gets the account division number.
        /// </summary>
        /// <param name="batch">The batch.</param>
        /// <returns></returns>
        private decimal? GetAccountDivisionNumber(Batch batch)
        {
            if (batch != null && batch.BatchType != null && batch.BatchType.AccountingDivisionNumber != null)
            {
                string s = Left(batch.BatchType.AccountingDivisionNumber.ToString(), 2);
                return Convert.ToDecimal(s);
            }
            return null;
        }

        /// <summary>
        /// Gets the vendor master lines.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <returns></returns>
        public List<APVendorMaster> GetVendorMasterLines(long etlExecutionLogID)
        {
            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                var result = dbContext.APVendorMasters.Where(a => a.ETL_Load_ID == etlExecutionLogID).ToList();
                return result;
            }
        }

        /// <summary>
        /// Gets the check request lines.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <returns></returns>
        public List<APCheckRequest> GetCheckRequestLines(long etlExecutionLogID)
        {
            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                var result = dbContext.APCheckRequests.Where(a => a.ETL_Load_ID == etlExecutionLogID).ToList();
                return result;
            }
        }

        /// <summary>
        /// Updates the batch details configuration invoice.
        /// </summary>
        /// <param name="invoices">The invoices.</param>
        /// <param name="batchID">The batch unique identifier.</param>
        /// <param name="currentUser">The current user.</param>
        public void UpdateBatchDetailsOnInvoice(List<int> invoices, long batchID, string currentUser, string eventSource, string eventName, string eventDetails, string entityName, string sessionID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                StringBuilder invoicesXML = new StringBuilder("<Invoices>");
                invoices.ForEach(i =>
                    {
                        invoicesXML.AppendFormat("<ID>{0}</ID>", i);
                    });
                invoicesXML.Append("</Invoices>");
                dbContext.UpdateBatchDetailsAndLogEventsForPayInvoices(invoicesXML.ToString(), batchID, currentUser, eventSource, eventName, eventDetails, entityName, sessionID);
                dbContext.SaveChanges();


            }
        }

        /// <summary>
        /// Updates the staging and execution log.
        /// </summary>
        /// <param name="etlExecutionLogId">The etl execution log unique identifier.</param>
        public void UpdateStagingAndExecutionLog(int etlExecutionLogId)
        {
            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                dbContext.UpdateStatusOnStagingTables(etlExecutionLogId);
                dbContext.UpdateExecutionLog(etlExecutionLogId, 1);
            }
        }

    }
}
