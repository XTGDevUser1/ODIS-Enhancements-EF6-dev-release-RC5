using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using log4net;
using System.Data.Entity.Core.Objects;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class ClaimsRepository
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ClaimsRepository));

        private bool ValidateAmountApproved(DAL.Claim claim)
        {
            bool isValid = true;
            if (claim.AmountApproved.GetValueOrDefault() <= 0)
            {
                isValid = false;
            }
            return isValid;
        }

        private bool ValidatePayeeName(DAL.Claim claim)
        {
            bool isValid = true;
            if (string.IsNullOrEmpty(claim.ContactName))
            {
                isValid = false;
            }
            return isValid;
        }

        private bool ValidateClaimAmountThreshold(DAL.Claim claim, decimal thresholdAmount)
        {
            bool isValid = true;
            if (claim.AmountApproved.GetValueOrDefault() > thresholdAmount)
            {
                isValid = false;
            }
            return isValid;
        }

        private bool ValidateClaimAddress(DAL.Claim model)
        {
            bool isValid = true;
            if (string.IsNullOrEmpty(model.PaymentAddressLine1) ||
                string.IsNullOrEmpty(model.PaymentAddressCity) ||
                string.IsNullOrEmpty(model.PaymentAddressPostalCode) ||
               !model.PaymentAddressCountryID.HasValue ||
               !model.PaymentAddressStateProvinceID.HasValue)
            {
                isValid = false;
            }
            return isValid;
        }

        public ClaimStatusSummary VerifyClaims(List<int> claims, string currentUser, string useraction)
        {
            ClaimStatusSummary summary = new ClaimStatusSummary();

            const string READY_FOR_PAYMENT = "ReadyForPayment";
            const string EXCEPTION = "Exception";
            const string REJECTED = "Denied";

            const string APPROVED = "Approved";
            const string INPROCESS = "In-Process";
            const string RECEIVED = "AuthorizationIssued";
            const string CANCELLED = "Cancelled";
            const string PAID = "Paid";

            var lookUp = new CommonLookUpRepository();
            var exceptionStatus = lookUp.GetClaimStatus(EXCEPTION);
            var approvedStatus = lookUp.GetClaimStatus(APPROVED);
            var readyForPaymentStatus = lookUp.GetClaimStatus(READY_FOR_PAYMENT);

            string amount = AppConfigRepository.GetValue("MaximumClaimAmountThreshold"); //KB: No need to use type while looking up appconfig, ApplicationConfigurationTypes.VENDOR_INVOICE);
            decimal decimalAmount = 0;
            decimal.TryParse(amount, out decimalAmount);



            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;

                var claimsFromDB = dbContext.Claims.Include("ClaimStatu").Include("ClaimType").Include("ACESClaimStatu").Where(x => claims.Contains(x.ID) && x.ClaimType.Name != "FordQFC").ToList<Claim>();

                int counter = 0;
                DateTime beforeVerify = DateTime.Now;
                claimsFromDB.ForEach(c =>
                {
                    DateTime start = DateTime.Now;
                    // Run the following validation rules. - PLEASE DO NOT DELETE THE FOLLOWING COMMENTS!
                    /* Exception when:
                     * Payee name is incompete : ISNULL(Claim.ContactName,’’) = ‘’
                     * Payee address incomplete : If any of these elements are missing then error
                                                    ISNULL(Claim.PaymentAddressLine1,'')=''
                                                    OR ISNULL(Claim.PaymentAddressCity,'')=''
                                                    OR Exception ISNULL(Claim. PaymentAddressStateProvince,'')=''
                                                    OR ISNULL(Claim. PaymentAddressPostalCode,'')=''
                                                    OR ISNULL(Claim. PaymentAddressCountryCode,'')=''

                     * Claim amount not greater than 0 : Claim.ApprovedAmount <= 0
                     * Claim amount over threshold : Claim.ApprovedAmount > Value from ApplicatonConfiguration Name  = MaximumClaimAmountThreshold 
                     */

                    List<string> exceptionMessages = new List<string>();
                    bool isException = false;

                    bool updateClaim = false;

                    if (c.ClaimStatu != null)
                    {
                        var currentClaimStatus = c.ClaimStatu;
                        /*if (READY_FOR_PAYMENT.Equals(currentClaimStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.ReadyForPayment += 1;
                            summary.ReadyForPaymentAmount += c.AmountApproved.GetValueOrDefault();
                            summary.ClaimsReadyForPayment.Add(c.ID);
                        }
                        else */
                        if (RECEIVED.Equals(currentClaimStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.Received += 1;
                            summary.ReceivedAmount += c.AmountApproved.GetValueOrDefault();
                        }
                        else if (CANCELLED.Equals(currentClaimStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.Cancelled += 1;
                            summary.CancelledAmount += c.AmountApproved.GetValueOrDefault();
                        }
                        else if (PAID.Equals(currentClaimStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.Paid += 1;
                            summary.PaidAmount += c.AmountApproved.GetValueOrDefault();
                        }
                        else if (REJECTED.Equals(currentClaimStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.Rejected += 1;
                            summary.RejectedAmount += c.AmountApproved.GetValueOrDefault();
                        }
                        // TFS:180 - Do not touch Approved ones when the action is pay
                        else if ("pay".Equals(useraction) && APPROVED.Equals(currentClaimStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.Approved += 1;
                            summary.ApprovedAmount += c.AmountApproved.GetValueOrDefault();
                        }

                        else if (INPROCESS.Equals(currentClaimStatus.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            summary.InProcess += 1;
                            summary.InProcessAmount += c.AmountApproved.GetValueOrDefault();
                        }
                        else // Process items in Exceptions and ReadyForPayment
                        {
                            updateClaim = true;
                            // Get all previous exceptions and delete them.
                            var previousExceptions = dbContext.ClaimExceptions.Where(v => v.ClaimID == c.ID).ToList<ClaimException>();
                            previousExceptions.ForEach(r =>
                            {
                                dbContext.Entry(r).State = EntityState.Deleted;
                            });

                            if (!ValidatePayeeName(c))
                            {
                                isException = true;
                                exceptionMessages.Add("Payee name incomplete");
                            }
                            if (!ValidateClaimAddress(c))
                            {
                                isException = true;
                                exceptionMessages.Add("Payee address incomplete");
                            }
                            if (!ValidateAmountApproved(c))
                            {
                                isException = true;
                                exceptionMessages.Add("Claim amount not greater than 0");
                            }
                            if (!ValidateClaimAmountThreshold(c, decimalAmount))
                            {
                                isException = true;
                                exceptionMessages.Add("Claim amount over threshold");
                            }
                            // ACES checks
                            if (c.ClaimType.IsFordACES != null && c.ClaimType.IsFordACES.Value)
                            {
                                if (c.ACESClaimStatu == null || !"Cleared".Equals(c.ACESClaimStatu.Name) || c.ACESClearedDate == null)
                                {
                                    isException = true;
                                    exceptionMessages.Add("ACES Status is not cleared or ACES Cleared Date is not provided");
                                }
                            }
                        }
                        if (isException)
                        {
                            summary.Exceptions += 1;
                            summary.ExceptionsAmount += c.AmountApproved.GetValueOrDefault();
                            c.ClaimStatusID = exceptionStatus.ID;

                            c.ModifyBy = currentUser;
                            c.ModifyDate = DateTime.Now;

                            summary.ClaimsWithExceptions.Add(c.ID);

                            exceptionMessages.ForEach(exceptionMessage =>
                            {
                                ClaimException ce = new ClaimException();
                                ce.ClaimID = c.ID;
                                ce.Description = exceptionMessage;
                                ce.CreateDate = DateTime.Now;
                                ce.CreateBy = currentUser;

                                dbContext.ClaimExceptions.Add(ce);
                            });
                        }
                        else if (updateClaim)
                        {
                            summary.ReadyForPayment += 1;
                            summary.ReadyForPaymentAmount += c.AmountApproved.GetValueOrDefault();
                            c.ClaimStatusID = readyForPaymentStatus.ID;

                            c.ModifyBy = currentUser;
                            c.ModifyDate = DateTime.Now;
                            summary.ClaimsReadyForPayment.Add(c.ID);
                        }

                    }
                    DateTime end = DateTime.Now;
                    logger.InfoFormat(" [ {0} ] - Time to process claim id - {1} is {2} ms", ++counter, c.ID, (end - start).TotalMilliseconds);

                });
                dbContext.SaveChanges();

                DateTime afterVerify = DateTime.Now;
                logger.InfoFormat("Time taken to process {0} claims is {1} ms", counter, (afterVerify - beforeVerify).TotalMilliseconds);
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
        public void CreateStagingDataForClaim(int claimID, long batchID, DateTime? batchTimeStamp, string currentUser)
        {
            // Get the following entities from ODIS:
            // Batch (including status and type), Vendor, VendorACH, PurchaseOrder, Invoice, BillingAddress and BusinessPhoneNumber.
            Batch batch = null;

            Vendor vendor = null;
            Member member = null;
            Membership membership = null;
            Claim claim = null;
            Program program = null;

            string glPaymentMethodConfig = null;
            bool isFordProgram = false;

            var progRepo = new ProgramMaintenanceRepository();
            string countryIS0Code3 = string.Empty;
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;

                claim = dbContext.Claims.Include("Vendor")
                                        .Include("Member")
                                        .Include(a => a.Member.Membership)
                                        .Include("ClaimType")
                                        .Include("ClaimCategory")
                                        .Include("Program")
                                        .Include(x => x.Program.Client)
                                        .Where(c => c.ID == claimID).FirstOrDefault();

                if (claim != null && claim.ClaimType.Name.Equals("FordQFC"))
                {
                    logger.InfoFormat("Skipping claim - {0} as it is of type - FordQFC", claim.ID);
                    dbContext.Dispose();
                    return;
                }
                if (claim != null)
                {
                    Country claimCountry = (from cn in dbContext.Countries
                                            where cn.ISOCode == claim.PaymentAddressCountryCode
                                            select cn).FirstOrDefault<Country>();
                    if (claimCountry != null)
                    {
                        countryIS0Code3 = claimCountry.ISOCode3;
                    }
                    vendor = claim.Vendor;
                    member = claim.Member;
                    program = claim.Program;

                    if (PayeeTypeName.MEMBER.Equals(claim.PayeeType, StringComparison.InvariantCultureIgnoreCase))
                    {
                        if (member != null && string.IsNullOrEmpty(member.ClaimSubmissionNumber))
                        {
                            UpdateMemberClaimReferenceNumber(member.ID, currentUser);
                            MemberRepository memberRepository = new MemberRepository();
                            member = memberRepository.Get(member.ID);
                        }
                    }

                    if (member != null)
                    {
                        membership = member.Membership;
                    }

                }

                batch = dbContext.Batches.Include("BatchType").Where(b => b.ID == batchID).FirstOrDefault();

                //TODO: Review the following line.
                bool glExpenseAccountSet = false;
                string claimType = claim.ClaimType.Name;
                if (claim.ProgramID != null)
                {
                    string client = claim.Program.Client.Name;
                    logger.InfoFormat("Client for the current claim {0} is {1}", claim.ID, client);
                    // If client = Ford or Hagerty and claimtype=Roadside, then check program config. If a value is not found, use the one from AppConfig.
                    if ("Ford".Equals(client, StringComparison.InvariantCultureIgnoreCase) || "Hagerty".Equals(client, StringComparison.InvariantCultureIgnoreCase))
                    {
                        if ("Ford".Equals(client, StringComparison.InvariantCultureIgnoreCase))
                        {
                            isFordProgram = true;
                        }
                        if ("RoadsideReimbursement".Equals(claim.ClaimType.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            List<ProgramInformation_Result> programConfigs = progRepo.GetProgramInfo(claim.ProgramID, "Application", null);
                            var item = programConfigs.Where(p => p.Name == "ClaimRoadsideGLExpenseAccount").FirstOrDefault();
                            if (item != null)
                            {
                                logger.InfoFormat("Found a value {0} for ClaimRoadsideGLExpenseAccount and Program {1} in ProgramConfiguration", item.Value, claim.ProgramID.GetValueOrDefault());
                                glPaymentMethodConfig = item.Value;
                                glExpenseAccountSet = true;
                            }
                            else
                            {
                                glPaymentMethodConfig = AppConfigRepository.GetValue("ClaimRoadsideGLExpenseAccount");
                                logger.InfoFormat("Didn't find a value for ClaimRoadsideGLExpenseAccount and Program {0} in ProgramConfiguration, so attempting to use ClaimRoadsideGLExpenseAccount - {1} from ApplicationConfiguration", claim.ProgramID.GetValueOrDefault(), glPaymentMethodConfig);
                                glExpenseAccountSet = true;
                            }
                        }
                    }
                }

                if (!glExpenseAccountSet)
                {

                    if ("RoadsideReimbursement".Equals(claimType, StringComparison.InvariantCultureIgnoreCase))
                    {
                        logger.InfoFormat("Using the value from Appconfig for ClaimType = {0} and key = ClaimRoadsideGLExpenseAccount ", claimType);
                        glPaymentMethodConfig = AppConfigRepository.GetValue("ClaimRoadsideGLExpenseAccount");
                    }
                    else if ("Damage".Equals(claimType, StringComparison.InvariantCultureIgnoreCase))
                    {
                        logger.InfoFormat("Using the value from Appconfig for ClaimType = {0} and key = ClaimDamageGLExpenseAccount", claimType);
                        glPaymentMethodConfig = AppConfigRepository.GetValue("ClaimDamageGLExpenseAccount");
                    }
                    else if ("MotorhomeReimbursement".Equals(claimType, StringComparison.InvariantCultureIgnoreCase))
                    {
                        logger.InfoFormat("Using the value from Appconfig for ClaimType = {0} and key = ClaimACESGLClearingExpenseAccount", claimType);
                        glPaymentMethodConfig = AppConfigRepository.GetValue("ClaimACESGLClearingExpenseAccount");
                    }
                    else if ("FordQFC".Equals(claimType, StringComparison.InvariantCultureIgnoreCase))
                    {
                        logger.InfoFormat("Using the value from Appconfig for ClaimType = {0} and key = ClaimQFCGLClearingExpenseAccount", claimType);
                        glPaymentMethodConfig = AppConfigRepository.GetValue("ClaimQFCGLClearingExpenseAccount");
                    }
                }

            }

            using (NMC_ETLEntities dbContext = new NMC_ETLEntities())
            {
                string vendorOrMemberNumber = string.Empty;
                if (PayeeTypeName.MEMBER.Equals(claim.PayeeType, StringComparison.InvariantCultureIgnoreCase))
                {
                    vendorOrMemberNumber = (member != null ? Left(member.ClaimSubmissionNumber, 7) : "0");
                }
                else
                {
                    vendorOrMemberNumber = vendor != null ? vendor.ID.ToString() : string.Empty;
                }
                var vendorMastersCreatedForBatch = dbContext.APVendorMasters.Where(v => v.VendorNumber == vendorOrMemberNumber && v.ETL_Load_ID == batch.MasterETLLoadID).Count();

                logger.InfoFormat("VendorMaster records created for {0} is {0}", vendorOrMemberNumber, vendorMastersCreatedForBatch);

                if (vendorMastersCreatedForBatch == 0)
                {
                    logger.InfoFormat("Creating VendorMaster record for {0}", vendorOrMemberNumber);
                    // Create an entry in APVendorMaster and APCheckRequest.
                    string vendorRef = null;

                    if (vendor != null)
                    {
                        logger.InfoFormat("VendorRef [VendorNumber] = {0}", vendor.VendorNumber);
                        vendorRef = Left(vendor.VendorNumber, 15);
                    }
                    else if (member != null && member.Membership != null)
                    {
                        vendorRef = Left(member.Membership.MembershipNumber != null ? member.Membership.MembershipNumber : member.Membership.ClientReferenceNumber, 15);
                        logger.InfoFormat("VendorRef [ MS Or ClientRef# ] = {0}", vendorRef);
                    }

                    APVendorMaster vendorMaster = new APVendorMaster()
                    {
                        ETL_Load_ID = batch.MasterETLLoadID,
                        AddDateTime = batchTimeStamp,
                        Division = GetAccountDivisionNumber(batch),
                        VendorNumber = vendorOrMemberNumber,
                        VendorName = Trim(ReplaceCommas(Left(claim.ContactName, 30), " ")),
                        AddressLine1 = Trim(ReplaceCommas(Left(claim.PaymentAddressLine1, 30), " ")),
                        AddressLine2 = Trim(ReplaceCommas(Left(claim.PaymentAddressLine2, 30), " ")),
                        AddressLine3 = Trim(ReplaceCommas(Left(claim.PaymentAddressLine3, 30), " ")),
                        City = Left(claim.PaymentAddressCity, 20),
                        State = Left(claim.PaymentAddressStateProvince, 2),
                        ZipCode = Left(claim.PaymentAddressPostalCode, 10),
                        PhoneNumber = GetFormattedPhoneNumber(claim.ContactPhoneNumber),
                        VendorRef = vendorRef,
                        MasterFileComment = claim.ClaimType.Name,
                        EmailAddress = null,
                        BankAccountNumber = null,
                        BankTransitNumber = null,
                        BankAccountType = null,
                        CountryCode = countryIS0Code3
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
                    VendorNumber = vendor != null ? Left(vendor.ID.ToString(), 7) : (member != null ? Left(member.ClaimSubmissionNumber, 7) : null), //TODO: Vendor number is 8 characters in our db.
                    InvoiceNumber = claim.ID.ToString(),
                    InvoiceDate = claim.ClaimDate.HasValue ? claim.ClaimDate.Value.Date : (DateTime?)null,
                    InvoiceDueDate = claim.ClaimDate.HasValue ? claim.ClaimDate.Value.Date : (DateTime?)null,
                    Comment = claim.ClaimType.Name,
                    SeparateCheck = "N",
                    InvoiceAmount = claim.AmountApproved,
                    GLExpenseAccount = glPaymentMethodConfig,
                    ExpenseAmount = claim.AmountApproved,
                    AdditionalComment = Left(claim.ClaimCategory != null ? claim.ClaimCategory.Description : claim.ClaimType.Description, 50),
                    PaymentMethod = "Check",
                    DocumentNoteID = null,
                    ContractType = null,
                    PONumber = null,

                    ReceivedDate = claim.ReceivedDate.HasValue ? claim.ReceivedDate.Value.Date : (DateTime?)null,
                    ProgramName = program != null ? program.Name : null,
                    ProgramRefNumber = (isFordProgram) ? claim.VehicleVIN : ((member != null && member.Membership != null) ? member.Membership.MembershipNumber : null)


                    // All other fields are left as nulls.

                };


                dbContext.APCheckRequests.Add(checkRequest);
                dbContext.SaveChanges();
            }
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

        public string Trim(string s)
        {
            if (!string.IsNullOrEmpty(s))
            {
                return s.Trim();
            }
            return s;
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
                dbContext.Database.CommandTimeout = 600;
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
                dbContext.Database.CommandTimeout = 600;
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
        public void UpdateBatchDetailsOnClaim(List<int> claims, long batchID, string currentUser, string eventSource, string eventName, string eventDetails, string entityName, string sessionID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //var claimsFromDB = (from vi in dbContext.Claims
                //                      join i in claims on vi.ID equals i
                //                      select vi).ToList<Claim>();
                //var payInvoiceEvent = dbContext.Events.Where(e => e.Name == "PayClaim").FirstOrDefault();

                //if (payInvoiceEvent == null)
                //{
                //    throw new DMSException("Event - PayClaim is not set up in the system");
                //}

                //var paidStatus = dbContext.ClaimStatus.Where(x => x.Name == "Paid").FirstOrDefault();
                //if (paidStatus == null)
                //{
                //    throw new DMSException("ClaimStatus - Paid is not set up in the system");
                //}

                //DateTime now = DateTime.Now;
                //claimsFromDB.ForEach(i =>
                //{
                //    i.ExportBatchID = (int)batchID;
                //    i.ExportDate = now;
                //    i.ModifyBy = currentUser;
                //    i.ModifyDate = now;
                //    i.ClaimStatusID = paidStatus.ID;

                //    i.PaymentDate = now;
                //    i.PaymentAmount = i.AmountApproved;

                //    i.PaymentPayeeName = null; //TODO: Review.

                //});
                dbContext.Database.CommandTimeout = 600;
                StringBuilder claimsXML = new StringBuilder("<Claims>");
                claims.ForEach(i =>
                {
                    claimsXML.AppendFormat("<ID>{0}</ID>", i);
                });
                claimsXML.Append("</Claims>");
                dbContext.UpdateBatchDetailsAndLogEventsForPayClaims(claimsXML.ToString(), batchID, currentUser, eventSource, eventName, eventDetails, entityName, sessionID);
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
                //var vendorMaster = dbContext.APVendorMasters.Where(v => v.ETL_Load_ID == etlExecutionLogId).FirstOrDefault();

                //if (vendorMaster != null)
                //{
                //    vendorMaster.ProcessFlag = true;
                //    vendorMaster.Status = "Y";
                //}

                //var checkRequest = dbContext.APCheckRequests.Where(v => v.ETL_Load_ID == etlExecutionLogId).FirstOrDefault();

                //if (checkRequest != null)
                //{
                //    checkRequest.ProcessFlag = true;
                //    checkRequest.Status = "Y";
                //}
                dbContext.Database.CommandTimeout = 600;
                dbContext.UpdateStatusOnStagingTables(etlExecutionLogId);
                dbContext.UpdateExecutionLog(etlExecutionLogId, 1);

                dbContext.SaveChanges();

            }
        }
    }
}
