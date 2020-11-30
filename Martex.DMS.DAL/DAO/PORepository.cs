using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Collections;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using log4net;
using Martex.DMS.BLL.Model;
using System.Data.Entity;
using System.Xml;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class PORepository
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(PORepository));
        /// <summary>
        /// Searches the specified page criteria.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="userId">The user id.</param>
        /// <returns></returns>
        public List<SearchPO_Result> Search(PageCriteria pageCriteria, Guid? userId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.SearchPO(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, userId).ToList<SearchPO_Result>();
                return list;
            }
        }

        public bool IsPoPaymentEditAllowed(int poId, string[] roleNames)
        {
            bool IsEditAllowed = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                ///First Condition
                var existingRecord = dbContext.PurchaseOrders.Where(u => u.ID == poId && (u.PurchaseOrderStatu.Name.Equals("Issued") || u.PurchaseOrderStatu.Name.Equals("Issued-Paid"))).FirstOrDefault();
                if (existingRecord != null)
                {
                    /// Second Condition
                    var vendorInvoiceCount = dbContext.VendorInvoices.Where(u => u.PurchaseOrderID == poId && u.VendorInvoiceStatu.Name.Equals("Paid")).Count();
                    if (vendorInvoiceCount == 0)
                    {
                        // Third Condition
                        var appConfig = dbContext.ApplicationConfigurations.Where(u => u.Name.Equals("RolesThatAllowPOPaymentEdit")).FirstOrDefault();
                        if (appConfig != null)
                        {
                            if (!string.IsNullOrEmpty(appConfig.Value))
                            {
                                string[] tokens = appConfig.Value.Split(',');
                                foreach (var role in roleNames)
                                {
                                    if (tokens.Contains(role.ToLower()))
                                    {
                                        IsEditAllowed = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return IsEditAllowed;
        }

        /// <summary>
        /// Gets the PO for service request.
        /// </summary>
        /// <param name="serviceRequest">The service request.</param>
        /// <param name="sortColumn">The sort column.</param>
        /// <param name="sortDirection">The sort direction.</param>
        /// <returns></returns>
        public List<POForServiceRequest_Result> GetPOForServiceRequest(int serviceRequest, string sortColumn, string sortDirection)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetPOForServiceRequest(serviceRequest, sortColumn, sortDirection).ToList<POForServiceRequest_Result>();
                return list;
            }
        }

        /// <summary>
        /// Gets the vendor information.
        /// </summary>
        /// <param name="vendorLocationId">The vendor location id.</param>
        /// <param name="serviceRequest">The service request.</param>
        /// <returns></returns>
        public VendorInformation_Result GetVendorInformation(int vendorLocationId, int serviceRequest)
        {

            using (var dbContext = new DMSEntities())
            {
                var vInfo = dbContext.GetVendorInformation(vendorLocationId, serviceRequest).FirstOrDefault<VendorInformation_Result>();
                return vInfo ?? new VendorInformation_Result();
            }
        }


        /// <summary>
        /// Gets the purchase order.
        /// </summary>
        /// <param name="serviceRequest">The service request.</param>
        /// <returns></returns>
        public PurchaseOrder GetPurchaseOrder(int serviceRequest)
        {

            using (var dbContext = new DMSEntities())
            {
                var pInfo = dbContext.PurchaseOrders.Where(po => po.ServiceRequestID == serviceRequest)
                                                    .Include(p => p.VendorInvoices)
                                                    .Include(p => p.PurchaseOrderStatu)
                                                    .Include(p => p.BillTo)
                                                    .Include(p => p.ContactMethod)
                                                    .Include(p => p.CurrencyType)
                                                    .Include(p => p.PaymentType)
                                                    .Include(p => p.PurchaseOrderPayStatusCode)
                                                    .Include(p => p.PurchaseOrderCancellationReason)
                                                    .Include(p => p.PurchaseOrderType)
                                                    .OrderBy(po => po.CreateDate)
                                                    .FirstOrDefault<PurchaseOrder>();
                return pInfo ?? new PurchaseOrder();
            }
        }

        /// <summary>
        /// Gets the purchase order details.
        /// </summary>
        /// <param name="poID">The po ID.</param>
        /// <returns></returns>
        public List<PODetailItemByPOId_Result> GetPurchaseOrderDetails(int poID)
        {
            using (var dbContext = new DMSEntities())
            {
                var poDetails = dbContext.GetPODetailItemsByPOId(poID).ToList<PODetailItemByPOId_Result>();
                return poDetails;
            }

        }


        /// <summary>
        /// Adds the specified po details.
        /// </summary>
        /// <param name="poDetails">The po details.</param>
        public void Add(PurchaseOrderDetail poDetails)
        {
            using (var dbContext = new DMSEntities())
            {
                dbContext.PurchaseOrderDetails.Add(poDetails);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the PO details by ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public PurchaseOrderDetail GetPODetailsByID(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var podetail = dbContext.PurchaseOrderDetails.Where(pd => pd.ID == id).FirstOrDefault<PurchaseOrderDetail>();
                return podetail ?? new PurchaseOrderDetail();
            }
        }

        /// <summary>
        /// POs the detail update.
        /// </summary>
        /// <param name="poDetils">The po detils.</param>
        public void PODetailUpdate(PurchaseOrderDetail poDetils)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var podetail = dbContext.PurchaseOrderDetails.Where(pd => pd.ID == poDetils.ID).FirstOrDefault<PurchaseOrderDetail>();
                if (podetail != null)
                {
                    podetail.ProductID = poDetils.ProductID;
                    podetail.ProductRateID = poDetils.ProductRateID;
                    podetail.Quantity = poDetils.Quantity;
                    podetail.UnitOfMeasure = poDetils.UnitOfMeasure;
                    podetail.Rate = poDetils.Rate;
                    podetail.IsMemberPay = poDetils.IsMemberPay;
                    podetail.ExtendedAmount = poDetils.ExtendedAmount;
                    podetail.ModifyBy = poDetils.ModifyBy;
                    podetail.ModifyDate = poDetils.ModifyDate;

                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// POs the details detete.
        /// </summary>
        /// <param name="id">The id.</param>
        public void PODetailsDetete(int id)
        {
            using (var dbContext = new DMSEntities())
            {
                var podetail = dbContext.PurchaseOrderDetails.FirstOrDefault(pd => pd.ID == id);
                dbContext.PurchaseOrderDetails.Remove(podetail);
                dbContext.SaveChanges();
            }

        }

        /// <summary>
        /// Gets the PO by id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public PurchaseOrder GetPOById(int id)
        {
            using (var dbContext = new DMSEntities())
            {
                var po = dbContext.PurchaseOrders.Include("VendorInvoices")
                            .Include(p => p.VendorLocation)
                            .Include(p => p.PurchaseOrderStatu)
                            .Include(p => p.BillTo)
                            .Include(p => p.ContactMethod)
                            .Include(p => p.CurrencyType)
                            .Include(p => p.PaymentType)
                            .Include(p => p.PurchaseOrderPayStatusCode)
                            .Include(p => p.PurchaseOrderCancellationReason)
                            .Include(p => p.PurchaseOrderType)
                    .Include("VendorInvoices.PaymentType")
                            .FirstOrDefault(p => p.ID == id);
                return po ?? new PurchaseOrder();
            }
        }


        /// <summary>
        /// Gets the PO by number.
        /// </summary>
        /// <param name="poNumber">The PO number.</param>
        /// <returns></returns>
        public PurchaseOrder GetPOByNumber(string poNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var po = dbContext.PurchaseOrders.Include("VendorInvoices")
                            .Include(p => p.VendorLocation)
                            .Include(p => p.PurchaseOrderStatu)
                            .Include(p => p.BillTo)
                            .Include(p => p.ContactMethod)
                            .Include(p => p.CurrencyType)
                            .Include(p => p.PaymentType)
                            .Include(p => p.PurchaseOrderPayStatusCode)
                            .Include(p => p.PurchaseOrderCancellationReason)
                            .Include(p => p.PurchaseOrderType)
                            .Include("VendorInvoices.PaymentType").Where(p => p.PurchaseOrderNumber == poNumber).FirstOrDefault<PurchaseOrder>();
                return po;
            }
        }

        /// <summary>
        /// Determines whether [is member payment balance] [the specified service].
        /// </summary>
        /// <param name="service">The service.</param>
        /// <returns>
        ///   <c>true</c> if [is member payment balance] [the specified service]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsMemberPaymentBalance(int service)
        {
            bool returnValue = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                MemberPaymentBalance_Result mpBalance = dbContext.GetMemberPaymentBalance(service).FirstOrDefault<MemberPaymentBalance_Result>();
                if (mpBalance != null && mpBalance.Amount.HasValue)
                {
                    returnValue = true;
                }

            }
            return returnValue;

        }

        /// <summary>
        /// Cancels the PO.
        /// </summary>
        /// <param name="po">The po.</param>
        public void CancelPO(PurchaseOrder po)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var oldpo = dbContext.PurchaseOrders.Where(p => p.ID == po.ID).FirstOrDefault<PurchaseOrder>();
                if (oldpo != null)
                {
                    //TFS 602 START
                    VendorInvoice currentVendorInvoice = dbContext.VendorInvoices.Include("VendorInvoiceStatu").Where(u => u.PurchaseOrderID == oldpo.ID).FirstOrDefault();
                    if (currentVendorInvoice != null && currentVendorInvoice.VendorInvoiceStatusID.HasValue)
                    {
                        if (currentVendorInvoice.VendorInvoiceStatu.Name.Equals("Paid", StringComparison.OrdinalIgnoreCase))
                        {
                            throw new DMSException("PO has been invoiced and paid and so it cannot be cancelled");
                        }
                    }
                    //TFS 602 END

                    PurchaseOrderStatu poStatus = dbContext.PurchaseOrderStatus.Where(pos => pos.Name == "Cancelled").FirstOrDefault<PurchaseOrderStatu>();
                    oldpo.PurchaseOrderStatusID = poStatus.ID;
                    oldpo.CancellationReasonID = po.CancellationReasonID;
                    if (!string.IsNullOrEmpty(po.CancellationReasonOther))
                    {
                        oldpo.CancellationReasonOther = po.CancellationReasonOther;
                    }
                    oldpo.CancellationComment = po.CancellationComment;
                    oldpo.ModifyBy = po.ModifyBy;
                    oldpo.ModifyDate = po.ModifyDate;
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Determines whether [is already GOA] [the specified po id].
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <returns>
        ///   <c>true</c> if [is already GOA] [the specified po id]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsAlreadyGOA(int poId)
        {
            bool returnValue = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                int count = dbContext.PurchaseOrders.Where(po => po.OriginalPurchaseOrderID == poId && po.IsGOA == true && po.IsActive == true).Count();
                if (count > 0)
                {
                    returnValue = true;
                }
            }
            return returnValue;
        }

        public PurchaseOrder AddGOA(PurchaseOrder currentPO, string currentUser)
        {
            PurchaseOrder goaPO = new PurchaseOrder();
            using (DMSEntities dbContext = new DMSEntities())
            {
                var oldPo = dbContext.PurchaseOrders.Where(po => po.ID == currentPO.ID).FirstOrDefault<PurchaseOrder>();
                if (oldPo != null)
                {
                    PurchaseOrderStatu poStatus = dbContext.PurchaseOrderStatus.Where(pos => pos.Name == "Pending").FirstOrDefault<PurchaseOrderStatu>();
                    goaPO.ServiceRequestID = oldPo.ServiceRequestID;
                    goaPO.OriginalPurchaseOrderID = oldPo.ID;
                    goaPO.ContactMethodID = oldPo.ContactMethodID;
                    goaPO.PurchaseOrderStatusID = poStatus.ID;
                    goaPO.VehicleCategoryID = oldPo.VehicleCategoryID;
                    goaPO.VendorLocationID = oldPo.VendorLocationID;
                    goaPO.BillingAddressTypeID = oldPo.BillingAddressTypeID;
                    goaPO.BillingAddressLine1 = oldPo.BillingAddressLine1;
                    goaPO.BillingAddressLine2 = oldPo.BillingAddressLine2;
                    goaPO.BillingAddressLine3 = oldPo.BillingAddressLine3;
                    goaPO.BillingAddressCity = oldPo.BillingAddressCity;
                    goaPO.BillingAddressStateProvince = oldPo.BillingAddressStateProvince;
                    goaPO.BillingAddressPostalCode = oldPo.BillingAddressPostalCode;
                    goaPO.BillingAddressCountryCode = oldPo.BillingAddressCountryCode;
                    goaPO.ProductID = oldPo.ProductID;
                    goaPO.FaxPhoneTypeID = oldPo.FaxPhoneTypeID;
                    goaPO.FaxPhoneNumber = oldPo.FaxPhoneNumber;
                    goaPO.Email = oldPo.Email;
                    goaPO.DealerIDNumber = oldPo.DealerIDNumber;
                    goaPO.EnrouteMiles = oldPo.EnrouteMiles;
                    goaPO.EnrouteTimeMinutes = oldPo.EnrouteTimeMinutes;
                    goaPO.EnrouteFreeMiles = oldPo.EnrouteFreeMiles;
                    goaPO.ServiceFreeMiles = oldPo.ServiceFreeMiles;
                    goaPO.ServiceMiles = oldPo.ServiceMiles;
                    goaPO.ServiceTimeMinutes = oldPo.ServiceTimeMinutes;
                    goaPO.ReturnMiles = oldPo.ReturnMiles;
                    goaPO.ReturnTimeMinutes = oldPo.ReturnTimeMinutes;
                    goaPO.IsServiceCovered = true;
                    goaPO.MemberServiceAmount = 0;
                    goaPO.MemberPaymentTypeID = oldPo.MemberPaymentTypeID;
                    goaPO.DispatchFee = 0;
                    goaPO.IsPayByCompanyCreditCard = oldPo.IsPayByCompanyCreditCard;
                    goaPO.IsVendorAdvised = oldPo.IsVendorAdvised;
                    goaPO.IsActive = oldPo.IsActive;
                    goaPO.CreateDate = oldPo.CreateDate;
                    goaPO.CreateBy = currentUser;
                    goaPO.CreateDate = DateTime.Now;
                    goaPO.ModifyDate = DateTime.Now;
                    goaPO.ModifyBy = currentUser;
                    goaPO.ETADate = null;
                    goaPO.ETAMinutes = null;
                    goaPO.IsGOA = true;
                    goaPO.DispatchPhoneNumber = oldPo.DispatchPhoneNumber;
                    goaPO.DispatchPhoneTypeID = oldPo.DispatchPhoneTypeID;
                    goaPO.CurrencyTypeID = oldPo.CurrencyTypeID;
                    // KB: 1363	PO tab - when creating a GOA set member pay isp value to NULL
                    goaPO.IsMemberAmountCollectedByVendor = null;
                    goaPO.MemberAmountDueToCoachNet = 0;
                    goaPO.CoverageLimit = oldPo.CoverageLimit;
                    goaPO.GOAReasonID = currentPO.GOAReasonID;
                    goaPO.GOAReasonOther = currentPO.GOAReasonOther;
                    goaPO.GOAComment = currentPO.GOAComment;
                    if (!string.IsNullOrEmpty(currentPO.GOAAuthorization))
                    {
                        goaPO.GOAAuthorization = currentPO.GOAAuthorization;
                        goaPO.GOAAuthorizationDate = DateTime.Now;
                    }

                    //NP 9/18: Added due to Bug 1612
                    goaPO.AdminstrativeRating = oldPo.AdminstrativeRating;
                    goaPO.SelectionOrder = oldPo.SelectionOrder;
                    goaPO.ContractStatus = oldPo.ContractStatus;
                    goaPO.ServiceRating = oldPo.ServiceRating;
                    //End

                    if (oldPo.VendorLocationID != null)
                    {
                        VendorLocation location = dbContext.VendorLocations.Where(x => x.ID == oldPo.VendorLocationID).FirstOrDefault<VendorLocation>();
                        Vendor poVendor = dbContext.Vendors.Where(x => x.ID == location.VendorID).FirstOrDefault<Vendor>();
                        string vendorTaxId = (!string.IsNullOrEmpty(poVendor.TaxEIN)) ? poVendor.TaxEIN : poVendor.TaxSSN;
                        goaPO.VendorTaxID = vendorTaxId;
                    }

                    //NMC Bug 159 copy below fields
                    goaPO.IsPayByCompanyCreditCard = oldPo.IsPayByCompanyCreditCard;
                    goaPO.CompanyCreditCardNumber = oldPo.CompanyCreditCardNumber;
                    goaPO.PayStatusCodeID = oldPo.PayStatusCodeID;
                    //end

                    //TFS : 597
                    goaPO.PrimaryProductID = oldPo.PrimaryProductID;
                    goaPO.SecondaryProductID = oldPo.SecondaryProductID;
                    goaPO.VehicleCategoryID = oldPo.VehicleCategoryID;
                    goaPO.IsPrimaryProductCovered = oldPo.IsPrimaryProductCovered;
                    goaPO.IsSecondaryProductCovered = oldPo.IsSecondaryProductCovered;
                    goaPO.PassengersRidingWithServiceProvider = oldPo.PassengersRidingWithServiceProvider;
                    goaPO.IsPossibleTow = oldPo.IsPossibleTow;

                    goaPO.ServiceLocationAddress = oldPo.ServiceLocationAddress;
                    goaPO.ServiceLocationDescription = oldPo.ServiceLocationDescription;
                    goaPO.ServiceLocationCrossStreet1 = oldPo.ServiceLocationCrossStreet1;
                    goaPO.ServiceLocationCrossStreet2 = oldPo.ServiceLocationCrossStreet2;
                    goaPO.ServiceLocationCity = oldPo.ServiceLocationCity;
                    goaPO.ServiceLocationStateProvince = oldPo.ServiceLocationStateProvince;
                    goaPO.ServiceLocationPostalCode = oldPo.ServiceLocationPostalCode;
                    goaPO.ServiceLocationCountryCode = oldPo.ServiceLocationCountryCode;
                    goaPO.ServiceLocationLatitude = oldPo.ServiceLocationLatitude;
                    goaPO.ServiceLocationLongitude = oldPo.ServiceLocationLongitude;

                    goaPO.DestinationAddress = oldPo.DestinationAddress;
                    goaPO.DestinationDescription = oldPo.DestinationDescription;
                    goaPO.DestinationCrossStreet1 = oldPo.DestinationCrossStreet1;
                    goaPO.DestinationCrossStreet2 = oldPo.DestinationCrossStreet2;
                    goaPO.DestinationCity = oldPo.DestinationCity;
                    goaPO.DestinationStateProvince = oldPo.DestinationStateProvince;
                    goaPO.DestinationPostalCode = oldPo.DestinationPostalCode;
                    goaPO.DestinationCountryCode = oldPo.DestinationCountryCode;
                    goaPO.DestinationLatitude = oldPo.DestinationLatitude;
                    goaPO.DestinationLongitude = oldPo.DestinationLongitude;
                    goaPO.DestinationVendorLocationID = oldPo.DestinationVendorLocationID;
                    goaPO.IsDirectTowDealer = oldPo.IsDirectTowDealer;
                    goaPO.PartsAndAccessoryCode = oldPo.PartsAndAccessoryCode;

                    goaPO.PrimaryCoverageLimit = oldPo.PrimaryCoverageLimit;
                    goaPO.SecondaryCoverageLimit = oldPo.SecondaryCoverageLimit;
                    goaPO.MileageUOM = oldPo.MileageUOM;
                    goaPO.PrimaryCoverageLimitMileage = oldPo.PrimaryCoverageLimitMileage;
                    goaPO.SecondaryCoverageLimitMileage = oldPo.SecondaryCoverageLimitMileage;
                    goaPO.IsServiceGuaranteed = oldPo.IsServiceGuaranteed;
                    goaPO.IsReimbursementOnly = oldPo.IsReimbursementOnly;
                    goaPO.IsServiceCoverageBestValue = oldPo.IsServiceCoverageBestValue;
                    goaPO.ProgramServiceEventLimitID = oldPo.ProgramServiceEventLimitID;
                    goaPO.PrimaryServiceCoverageDescription = oldPo.PrimaryServiceCoverageDescription;
                    goaPO.SecondaryServiceCoverageDescription = oldPo.SecondaryServiceCoverageDescription;
                    goaPO.PrimaryServiceEligiblityMessage = oldPo.PrimaryServiceEligiblityMessage;
                    goaPO.SecondaryServiceEligiblityMessage = oldPo.SecondaryServiceEligiblityMessage;
                    goaPO.IsPrimaryOverallCovered = oldPo.IsPrimaryOverallCovered;
                    goaPO.IsSecondaryOverallCovered = oldPo.IsSecondaryOverallCovered;

                    //TFS #1288
                    goaPO.PartsAndAccessoryCode = oldPo.PartsAndAccessoryCode;
                    goaPO.IsDirectTowDealer = oldPo.IsDirectTowDealer;

                    //TFS #1292
                    goaPO.CostPlusPercentage = oldPo.CostPlusPercentage;

                    dbContext.PurchaseOrders.Add(goaPO);
                    dbContext.SaveChanges();
                }

            }
            return goaPO;
        }

        /// <summary>
        /// Inserts the GOAPO details.
        /// </summary>
        /// <param name="oldPoId">The old po id.</param>
        /// <param name="newPOId">The new PO id.</param>
        /// <param name="currentUser">The current user.</param>
        public void InsertGOAPODetails(int oldPoId, int newPOId, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.InsertGOAPODetails(oldPoId, newPOId, currentUser);
            }
        }

        /// <summary>
        /// Gets the service coverage limit.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public decimal GetServiceCoverageLimit(int programId)
        {
            decimal returnValue = 0;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var pproduct = dbContext.ProgramProducts.Where(pp => pp.ProgramID == programId).FirstOrDefault<ProgramProduct>();
                if (pproduct != null && pproduct.ServiceCoverageLimit.HasValue)
                {
                    returnValue = pproduct.ServiceCoverageLimit.Value;
                }
            }

            return returnValue;
        }

        public void SendPO(PurchaseOrder po, string setPurchageOrderStatus, string talkedTo, string vendorName, int? contactLogID, ServiceRequest eligibilityUpdatedSR, string currentUser, string eventSource, string sessionId)
        {

            using (DMSEntities dbContext = new DMSEntities())
            {
                var oldPo = dbContext.PurchaseOrders.Where(p => p.ID == po.ID).Include(p => p.PurchaseOrderStatu).FirstOrDefault<PurchaseOrder>();
                PurchaseOrderStatu puStatus = dbContext.PurchaseOrderStatus.Where(ps => ps.Name == setPurchageOrderStatus).FirstOrDefault<PurchaseOrderStatu>();
                if (oldPo != null)
                {
                    if (oldPo.PurchaseOrderStatu != null && oldPo.PurchaseOrderStatu.Name == "Pending" && oldPo.IsActive.GetValueOrDefault() == true)
                    {
                        int? nextNumber = dbContext.GetNextNumber("PurchaseOrderNumber").Single<int?>();
                        oldPo.PurchaseOrderNumber = nextNumber.ToString();
                        oldPo.IssueDate = DateTime.Now;

                        List<ProductSubType> productSubTypes = dbContext.ProductSubTypes.Where(a => a.Name == "PrimaryService" || a.Name == "SecondaryService").ToList();
                        var product = dbContext.Products.Where(a => a.ID == po.ProductID).FirstOrDefault();
                        if (product != null && productSubTypes.Where(a => a.ID == product.ProductSubTypeID).Count() > 0)
                        {
                            var eventLogRepository = new EventLogRepository();
                            eventLogRepository.LogEventForServiceRequestStatus(oldPo.ServiceRequestID, EventNames.DISPATCHED, eventSource, null, sessionId, currentUser, po.ID);
                            logger.InfoFormat("Logged service request status event {0}", EventNames.DISPATCHED);
                        }

                        if (oldPo.IsGOA.HasValue && !oldPo.IsGOA.Value)
                        {

                            if (po.ETAMinutes.HasValue)
                            {
                                oldPo.ETADate = DateTime.Now.AddMinutes(po.ETAMinutes.Value);
                            }
                            else
                            {
                                oldPo.ETADate = DateTime.Now;
                            }
                        }
                        oldPo.PurchaseOrderStatusID = puStatus.ID;
                    }
                    else if (oldPo.PurchaseOrderStatu != null && oldPo.PurchaseOrderStatu.Name == "Pending" && oldPo.IsActive.GetValueOrDefault() == false)
                    {
                        throw new DMSException(string.Format("Purchase Order ID {0} cannot be Issued since it's not active.", oldPo.ID));
                    }

                    #region Update Dispatch Fee values on issuing
                    oldPo.InternalDispatchFee = po.InternalDispatchFee;
                    oldPo.ClientDispatchFee = po.ClientDispatchFee;
                    oldPo.CreditCardProcessingFee = po.CreditCardProcessingFee;
                    oldPo.DispatchFee = po.DispatchFee;

                    oldPo.DispatchFeeAgentMinutes = po.DispatchFeeAgentMinutes;
                    oldPo.DispatchFeeTechMinutes = po.DispatchFeeTechMinutes;
                    oldPo.DispatchFeeTimeCost = po.DispatchFeeTimeCost;

                    #endregion

                    oldPo.ModifyDate = DateTime.Now;
                    oldPo.ModifyBy = po.ModifyBy;

                }
                ContactLogActionRepository clarepository = new ContactLogActionRepository();

                #region Vendor Selection
                if (contactLogID.HasValue)
                {
                    ContactAction vendorContactAction = (from ca in dbContext.ContactActions
                                                         join oc in dbContext.ContactCategories on ca.ContactCategoryID equals oc.ID
                                                         where ca.Name == "Accepted" && oc.Name == "VendorSelection"
                                                         select ca).FirstOrDefault<ContactAction>();

                    ContactLogAction clAction = new ContactLogAction();
                    clAction.ContactLogID = contactLogID.Value;
                    clAction.ContactActionID = vendorContactAction.ID;
                    clAction.CreateDate = DateTime.Now;
                    clAction.CreateBy = po.ModifyBy;
                    clarepository.Save(clAction, po.ModifyBy);
                }
                #endregion

                #region Create ContactLog
                ContactLogRepository clRepository = new ContactLogRepository();
                ContactLog cl = new ContactLog();
                ContactCategory cc = dbContext.ContactCategories.Where(ccExp => ccExp.Name == "ContactVendor").FirstOrDefault<ContactCategory>();
                ContactType ct = dbContext.ContactTypes.Where(cType => cType.Name == "Vendor").FirstOrDefault<ContactType>();

                ContactSource cs = dbContext.ContactSources.Where(cSource => cSource.Name == "ServiceRequest" && cSource.ContactCategoryID == cc.ID).FirstOrDefault<ContactSource>();
                if (contactLogID.HasValue)
                {
                    cl.ID = contactLogID.GetValueOrDefault();
                }
                if (cc != null)
                {
                    cl.ContactCategoryID = cc.ID;
                }
                if (ct != null)
                {
                    cl.ContactTypeID = ct.ID;
                }

                cl.ContactMethodID = po.ContactMethodID;
                if (cs != null)
                {
                    cl.ContactSourceID = cs.ID;
                }

                cl.Company = vendorName;
                cl.TalkedTo = talkedTo;
                if (!string.IsNullOrEmpty(po.FaxPhoneNumber))
                {
                    cl.PhoneTypeID = po.FaxPhoneTypeID;
                    cl.PhoneNumber = po.FaxPhoneNumber;
                }
                else
                {
                    cl.Email = po.Email;
                }
                cl.Direction = "Outbound";
                cl.Description = "Send PO to Vendor";
                cl.CreateDate = DateTime.Now;
                cl.ModifyDate = DateTime.Now;
                cl.CreateBy = po.ModifyBy;
                cl.ModifyBy = po.ModifyBy;
                clRepository.Save(cl, po.ModifyBy, po.ID, EntityNames.PURCHASE_ORDER);
                clRepository.CreateLinkRecord(cl.ID, EntityNames.VENDOR_LOCATION, po.VendorLocationID);

                #endregion

                #region ContactLogReason
                ContactLogReasonRepository clrRepository = new ContactLogReasonRepository();
                ContactReason cReason = dbContext.ContactReasons.Where(cr => cr.Name == "Service Information" && cr.ContactCategoryID == cc.ID).FirstOrDefault<ContactReason>();
                ContactLogReason clReason = new ContactLogReason();
                clReason.ContactLogID = cl.ID;
                clReason.ContactReasonID = cReason.ID;
                clReason.CreateDate = DateTime.Now;
                clReason.CreateBy = po.ModifyBy;
                clrRepository.Save(clReason, po.ModifyBy);
                #endregion

                #region ContactLogAction

                #region Contact Vendor
                ContactAction ContactVandorContactAction = (from ca in dbContext.ContactActions
                                                            join oc in dbContext.ContactCategories on ca.ContactCategoryID equals oc.ID
                                                            where ca.Name == "Pending" && oc.Name == "ContactVendor"
                                                            select ca).FirstOrDefault<ContactAction>();

                ContactLogAction clActionContactVendor = new ContactLogAction();
                clActionContactVendor.ContactLogID = cl.ID;
                clActionContactVendor.ContactActionID = ContactVandorContactAction.ID;
                clActionContactVendor.CreateDate = DateTime.Now;
                clActionContactVendor.CreateBy = po.ModifyBy;
                clarepository.Save(clActionContactVendor, po.ModifyBy);
                #endregion
                #endregion

                #region CommunicationQueue
                // int cmValidation = dbContext.ContactMethods.Where(cm => cm.ID == po.ContactMethodID && cm.Name == "Verbally").Count();
                ContactMethod cm = dbContext.ContactMethods.Where(c => c.ID == po.ContactMethodID && c.IsActive == true).FirstOrDefault<ContactMethod>();
                if (cm != null)
                {
                    if (!"Verbally".Equals(cm.Name))
                    {
                        PurchaseOrderTemplate_Result poTemplate = dbContext.GetPurchaseOrderTemplate(po.ID, cl.ID).FirstOrDefault<PurchaseOrderTemplate_Result>();
                        string processedSubject = string.Empty;
                        string messageText = string.Empty;
                        CommunicationQueue cQueue = new CommunicationQueue();
                        cQueue.ContactMethodID = po.ContactMethodID;

                        if ("Email".Equals(cm.Name))
                        {
                            cQueue.Subject = processedSubject;
                            cQueue.NotificationRecipient = po.Email;
                        }
                        else if ("Fax".Equals(cm.Name))
                        {
                            //cQueue.PhoneTypeID = po.PhoneTypeID;
                            cQueue.NotificationRecipient = po.FaxPhoneNumber;
                        }
                        if (poTemplate != null)
                        {
                            Template activeTemplate = dbContext.Templates.Where(t => t.Name == "PurchaseOrder" + cm.Name && t.IsActive == true).FirstOrDefault<Template>();
                            if (activeTemplate == null)
                            {
                                throw new DMSException("Unable to retrieve template PurchaseOrder" + cm.Name);
                            }
                            Hashtable PoTempValues = new Hashtable();
                            PoTempValues.Add("POFaxFrom", poTemplate.POFrom);
                            // PoTempValues.Add("PurchaseOrderNumber", poTemplate.PurchaseOrderNumber);
                            PoTempValues.Add("PurchaseOrderNumber", oldPo.PurchaseOrderNumber);
                            PoTempValues.Add("TalkedTo", talkedTo ?? string.Empty);
                            PoTempValues.Add("VendorName", poTemplate.VendorName ?? string.Empty);
                            PoTempValues.Add("VendorNumber", poTemplate.VendorNumber ?? string.Empty);
                            PoTempValues.Add("VendorFax", poTemplate.FaxPhoneNumber ?? string.Empty);
                            // PoTempValues.Add("POFaxFrom", poTemplate.POFrom);
                            PoTempValues.Add("IssueDateTime", oldPo.IssueDate.HasValue ? oldPo.IssueDate.Value.ToString("HH:mm:ss-MM/dd/yyyy") : string.Empty);
                            //PoTempValues.Add("IssueDateTime", poTemplate.IssueDate);
                            PoTempValues.Add("CreateBy", poTemplate.OpenedBy);
                            PoTempValues.Add("ProductCategoryName", poTemplate.ServiceName ?? string.Empty);
                            PoTempValues.Add("ETAMinutes", po.ETAMinutes.HasValue ? po.ETAMinutes.ToString() : string.Empty);
                            PoTempValues.Add("Safe", poTemplate.Safe);
                            PoTempValues.Add("MemberPay", poTemplate.MemberPay);
                            PoTempValues.Add("MemberName", poTemplate.MemberName);
                            PoTempValues.Add("MembershipNumber", poTemplate.MembershipNumber ?? string.Empty);
                            PoTempValues.Add("ContactNumber", poTemplate.ContactPhoneNumber ?? string.Empty);
                            PoTempValues.Add("AlternateContact", poTemplate.ContactAltPhoneNumber ?? string.Empty);
                            PoTempValues.Add("ServiceLocationAddress", poTemplate.ServiceLocationAddress ?? string.Empty);
                            PoTempValues.Add("ServiceLocationDescription", poTemplate.ServiceLocationDescription ?? string.Empty);
                            PoTempValues.Add("ServiceLocationCrossStreet", poTemplate.ServiceLocationCrossStreet ?? string.Empty);
                            PoTempValues.Add("ServiceLocationCityState", poTemplate.CityState ?? string.Empty);
                            PoTempValues.Add("ServiceLocationPostalCode", poTemplate.Zip ?? string.Empty);
                            PoTempValues.Add("DestinationDescription", poTemplate.DestinationDescription ?? string.Empty);
                            PoTempValues.Add("DestinationAddress", poTemplate.DestinationAddress ?? string.Empty);
                            PoTempValues.Add("DestinationCityState", poTemplate.DestinationCityState ?? string.Empty);
                            PoTempValues.Add("DestinationPostalCode", poTemplate.DestinationZip ?? string.Empty);
                            PoTempValues.Add("VehicleYear", poTemplate.VehicleYear ?? string.Empty);
                            PoTempValues.Add("VehicleMake", poTemplate.VehicleMake ?? string.Empty);
                            PoTempValues.Add("VehicleModel", poTemplate.VehicleModel ?? string.Empty);
                            PoTempValues.Add("VehicleDescription", poTemplate.VehicleDescription ?? string.Empty);
                            PoTempValues.Add("VehicleColor", poTemplate.VehicleColor ?? string.Empty);
                            PoTempValues.Add("VehicleStateLicense", poTemplate.License ?? string.Empty);
                            PoTempValues.Add("VehicleVin", poTemplate.VehicleVIN ?? string.Empty);
                            PoTempValues.Add("VehicleChassis", poTemplate.VehicleChassis ?? string.Empty);
                            PoTempValues.Add("VehicleLength", poTemplate.VehicleLength.HasValue ? poTemplate.VehicleLength.Value.ToString() : string.Empty);
                            PoTempValues.Add("VehicleEngine", poTemplate.VehicleEngine ?? string.Empty);
                            PoTempValues.Add("VehicleClass", poTemplate.Class ?? string.Empty);
                            PoTempValues.Add("VendorCallback", poTemplate.VendorCallback);
                            PoTempValues.Add("VendorBilling", poTemplate.VendorBilling);
                            //KB: TFS 656 - Added extra item to the email and fax template
                            PoTempValues.Add("AdditionalInstructions", po.AdditionalInstructions ?? string.Empty);
                            CommunicationQueueRepository cqRepository = new CommunicationQueueRepository();
                            processedSubject = TemplateUtil.ProcessTemplate(activeTemplate.Subject, PoTempValues);
                            messageText = TemplateUtil.ProcessTemplate(activeTemplate.Body, PoTempValues);
                            cQueue.TemplateID = activeTemplate.ID;
                            cQueue.MessageData = GetXML(PoTempValues);
                        }

                        cQueue.ContactLogID = cl.ID;

                        //cQueue.ContactMethodID = po.ContactMethodID;
                        //ContactMethod email = dbContext.ContactMethods.Where(ecm => ecm.Name == "Email").FirstOrDefault<ContactMethod>();
                        //ContactMethod fax = dbContext.ContactMethods.Where(fcm => fcm.Name == "Fax").FirstOrDefault<ContactMethod>();
                        //if (po.ContactMethodID == email.ID)
                        //{
                        //    cQueue.Subject = processedSubject;
                        //    cQueue.Email = po.Email;
                        //}
                        //else if (po.ContactMethodID == fax.ID)
                        //{
                        //    //cQueue.PhoneTypeID = po.PhoneTypeID;
                        //    cQueue.PhoneNumber = po.FaxPhoneNumber;
                        //}
                        cQueue.MessageText = messageText;
                        cQueue.ScheduledDate = DateTime.Now;
                        cQueue.CreateDate = DateTime.Now;
                        cQueue.CreateBy = po.ModifyBy;
                        dbContext.CommunicationQueues.Add(cQueue);
                    }
                    else
                    {
                        CommunicationQueueRepository repository = new CommunicationQueueRepository();
                        CommunicationLog comLog = new CommunicationLog();
                        comLog.ContactMethodID = po.ContactMethodID;
                        comLog.Status = "SUCCESS";
                        comLog.CreateBy = po.CreateBy;
                        comLog.ModifyBy = po.ModifyBy;
                        comLog.CreateDate = DateTime.Now;
                        comLog.ModifyDate = DateTime.Now;
                        repository.AddCommunicationLog(comLog);
                    }
                }
                #endregion

                #region ServiceRequest Update
                var serviceRequest = dbContext.ServiceRequests.Where(sr => sr.ID == po.ServiceRequestID).Include(x => x.ServiceRequestStatu).FirstOrDefault<ServiceRequest>();
                if (serviceRequest != null)
                {
                    //int count = dbContext.PurchaseOrders.Where(poCount => poCount.ServiceRequestID == po.ServiceRequestID && po.OriginalPurchaseOrderID == null).Count();
                    int? poCount = dbContext.GetPOCountForRedispath(po.ServiceRequestID).Single<int?>();
                    if (poCount.HasValue && poCount.Value > 1)
                    {
                        NextAction na = dbContext.NextActions.Where(n => n.Name == "ManualClosedLoop").FirstOrDefault<NextAction>();
                        if (na != null)
                        {
                            serviceRequest.NextActionID = na.ID;
                        }
                        serviceRequest.IsRedispatched = true;
                        serviceRequest.NextActionScheduledDate = oldPo.ETADate;
                    }
                    if (serviceRequest.ServiceRequestStatu != null)
                    {
                        string status = serviceRequest.ServiceRequestStatu.Name;
                        if (status == "Entry" || status == "Submitted")
                        {
                            ServiceRequestStatu srStatus = dbContext.ServiceRequestStatus.Where(s => s.Name == "Dispatched").FirstOrDefault<ServiceRequestStatu>();
                            if (srStatus != null)
                            {
                                serviceRequest.ServiceRequestStatusID = srStatus.ID;

                                NextAction dispatchNextAction = dbContext.NextActions.Where(n => n.Name == "Dispatch").FirstOrDefault<NextAction>();
                                if (dispatchNextAction != null && dispatchNextAction.ID == serviceRequest.NextActionID)
                                {
                                    serviceRequest.NextActionID = null;
                                    serviceRequest.NextActionAssignedToUserID = null;
                                    serviceRequest.NextActionScheduledDate = null;
                                }
                            }
                        }
                    }

                    #region TFS #648 Change Eligibility values on SR
                    serviceRequest.IsPrimaryOverallCovered = eligibilityUpdatedSR.IsPrimaryOverallCovered;
                    serviceRequest.PrimaryCoverageLimit = eligibilityUpdatedSR.PrimaryCoverageLimit;
                    serviceRequest.PrimaryCoverageLimitMileage = eligibilityUpdatedSR.PrimaryCoverageLimitMileage;
                    serviceRequest.MileageUOM = eligibilityUpdatedSR.MileageUOM;
                    serviceRequest.IsServiceCoverageBestValue = eligibilityUpdatedSR.IsServiceCoverageBestValue;
                    serviceRequest.PrimaryServiceEligiblityMessage = eligibilityUpdatedSR.PrimaryServiceEligiblityMessage;
                    #endregion
                }
                #endregion

                #region Vendor Invoice creation

                //Issue fix 2167 remove logic to create vendor invoice
                //if(setPurchageOrderStatus == "Issued" &&(po.IsPayByCompanyCreditCard.HasValue && po.IsPayByCompanyCreditCard.Value == true) && !string.IsNullOrEmpty(po.CompanyCreditCardNumber))
                //{
                //    List<VendorInvoice> vendorsList = dbContext.VendorInvoices.Where(x=>x.PurchaseOrderID == po.ID).ToList<VendorInvoice>();
                //    if (vendorsList.Count == 0)
                //    {
                //        VendorInvoice vendorInvoice = CreateVendorInvoiceForPO(po);
                //        dbContext.VendorInvoices.Add(vendorInvoice);
                //    }
                //}

                #endregion

                dbContext.SaveChanges();

                #region Update PO From Service Request : TFS 597
                PurchaseOrder currentPurchaseOrder = dbContext.PurchaseOrders.Where(p => p.ID == po.ID).FirstOrDefault<PurchaseOrder>();
                if (currentPurchaseOrder != null && !currentPurchaseOrder.IsGOA.GetValueOrDefault())
                {
                    ServiceRequest currentServiceRequest = dbContext.ServiceRequests.Where(sr => sr.ID == currentPurchaseOrder.ServiceRequestID).FirstOrDefault<ServiceRequest>();
                    if (currentServiceRequest != null)
                    {
                        currentPurchaseOrder.PrimaryProductID = currentServiceRequest.PrimaryProductID;
                        currentPurchaseOrder.SecondaryProductID = currentServiceRequest.SecondaryProductID;
                        currentPurchaseOrder.VehicleCategoryID = currentServiceRequest.VehicleCategoryID;
                        currentPurchaseOrder.IsPrimaryProductCovered = currentServiceRequest.IsPrimaryProductCovered;
                        currentPurchaseOrder.IsSecondaryProductCovered = currentServiceRequest.IsSecondaryProductCovered;
                        currentPurchaseOrder.PassengersRidingWithServiceProvider = currentServiceRequest.PassengersRidingWithServiceProvider;
                        currentPurchaseOrder.IsPossibleTow = currentServiceRequest.IsPossibleTow;

                        currentPurchaseOrder.ServiceLocationAddress = currentServiceRequest.ServiceLocationAddress;
                        currentPurchaseOrder.ServiceLocationDescription = currentServiceRequest.ServiceLocationDescription;
                        currentPurchaseOrder.ServiceLocationCrossStreet1 = currentServiceRequest.ServiceLocationCrossStreet1;
                        currentPurchaseOrder.ServiceLocationCrossStreet2 = currentServiceRequest.ServiceLocationCrossStreet2;
                        currentPurchaseOrder.ServiceLocationCity = currentServiceRequest.ServiceLocationCity;
                        currentPurchaseOrder.ServiceLocationStateProvince = currentServiceRequest.ServiceLocationStateProvince;
                        currentPurchaseOrder.ServiceLocationPostalCode = currentServiceRequest.ServiceLocationPostalCode;
                        currentPurchaseOrder.ServiceLocationCountryCode = currentServiceRequest.ServiceLocationCountryCode;
                        currentPurchaseOrder.ServiceLocationLatitude = currentServiceRequest.ServiceLocationLatitude;
                        currentPurchaseOrder.ServiceLocationLongitude = currentServiceRequest.ServiceLocationLongitude;

                        currentPurchaseOrder.DestinationAddress = currentServiceRequest.DestinationAddress;
                        currentPurchaseOrder.DestinationDescription = currentServiceRequest.DestinationDescription;
                        currentPurchaseOrder.DestinationCrossStreet1 = currentServiceRequest.DestinationCrossStreet1;
                        currentPurchaseOrder.DestinationCrossStreet2 = currentServiceRequest.DestinationCrossStreet2;
                        currentPurchaseOrder.DestinationCity = currentServiceRequest.DestinationCity;
                        currentPurchaseOrder.DestinationStateProvince = currentServiceRequest.DestinationStateProvince;
                        currentPurchaseOrder.DestinationPostalCode = currentServiceRequest.DestinationPostalCode;
                        currentPurchaseOrder.DestinationCountryCode = currentServiceRequest.DestinationCountryCode;
                        currentPurchaseOrder.DestinationLatitude = currentServiceRequest.DestinationLatitude;
                        currentPurchaseOrder.DestinationLongitude = currentServiceRequest.DestinationLongitude;
                        currentPurchaseOrder.DestinationVendorLocationID = currentServiceRequest.DestinationVendorLocationID;
                        currentPurchaseOrder.IsDirectTowDealer = currentServiceRequest.IsDirectTowDealer;
                        currentPurchaseOrder.PartsAndAccessoryCode = currentServiceRequest.PartsAndAccessoryCode;

                        currentPurchaseOrder.PrimaryCoverageLimit = currentServiceRequest.PrimaryCoverageLimit;
                        currentPurchaseOrder.SecondaryCoverageLimit = currentServiceRequest.SecondaryCoverageLimit;
                        currentPurchaseOrder.MileageUOM = currentServiceRequest.MileageUOM;
                        currentPurchaseOrder.PrimaryCoverageLimitMileage = currentServiceRequest.PrimaryCoverageLimitMileage;
                        currentPurchaseOrder.SecondaryCoverageLimitMileage = currentServiceRequest.SecondaryCoverageLimitMileage;
                        currentPurchaseOrder.IsServiceGuaranteed = currentServiceRequest.IsServiceGuaranteed;
                        currentPurchaseOrder.IsReimbursementOnly = currentServiceRequest.IsReimbursementOnly;
                        currentPurchaseOrder.IsServiceCoverageBestValue = currentServiceRequest.IsServiceCoverageBestValue;
                        currentPurchaseOrder.ProgramServiceEventLimitID = currentServiceRequest.ProgramServiceEventLimitID;
                        currentPurchaseOrder.PrimaryServiceCoverageDescription = currentServiceRequest.PrimaryServiceCoverageDescription;
                        currentPurchaseOrder.SecondaryServiceCoverageDescription = currentServiceRequest.SecondaryServiceCoverageDescription;
                        currentPurchaseOrder.PrimaryServiceEligiblityMessage = currentServiceRequest.PrimaryServiceEligiblityMessage;
                        currentPurchaseOrder.SecondaryServiceEligiblityMessage = currentServiceRequest.SecondaryServiceEligiblityMessage;
                        currentPurchaseOrder.IsPrimaryOverallCovered = currentServiceRequest.IsPrimaryOverallCovered;
                        currentPurchaseOrder.IsSecondaryOverallCovered = currentServiceRequest.IsSecondaryOverallCovered;

                        dbContext.SaveChanges();
                    }
                }
                #endregion


            }
            UpdateContactLogLinkForPOIssuing(po.ServiceRequestID, po.ID);
        }

        public VendorInvoice CreateVendorInvoiceForPO(PurchaseOrder po)
        {
            VendorInvoice vendorInvoice = new VendorInvoice();
            DateTime invoiceDate = DateTime.Now;
            Vendor vendor = null;

            using (DMSEntities dbContext = new DMSEntities())
            {

                vendorInvoice.PurchaseOrderID = po.ID;
                if (po.VendorLocationID.HasValue)
                {
                    VendorManagementRepository vendorrepository = new VendorManagementRepository();
                    VendorLocation vendorLocation = vendorrepository.GetVendorLocationDetails(po.VendorLocationID.Value);
                    vendorInvoice.VendorID = vendorLocation.VendorID;
                    vendor = vendorrepository.Get(vendorLocation.VendorID);
                }
                VendorInvoiceStatu status = ReferenceDataRepository.GetVendorInvoiceStatus().Where(x => x.Name == "Paid").FirstOrDefault();
                if (status == null)
                {
                    throw new DMSException("Vendor Invoice Status with name Paid not configured in the system");
                }
                vendorInvoice.VendorInvoiceStatusID = status.ID;
                SourceSystem sourcesystem = ReferenceDataRepository.GetSourceSystemByName(SourceSystemName.DISPATCH);
                if (sourcesystem == null)
                {
                    throw new DMSException("Source system with name Dispatch not configured in the system");
                }
                vendorInvoice.SourceSystemID = sourcesystem.ID;
                PaymentType paymenttype = ReferenceDataRepository.GetPaymentTypes().Where(x => x.Name == PaymentTypeName.TEMPORARY_CC).FirstOrDefault();
                if (paymenttype == null)
                {
                    throw new DMSException("PaymentType with name TemporaryCC not configured in the system");
                }
                vendorInvoice.PaymentTypeID = paymenttype.ID;
                vendorInvoice.ReceivedDate = invoiceDate;
                vendorInvoice.InvoiceDate = invoiceDate;
                vendorInvoice.InvoiceAmount = po.PurchaseOrderAmount;
                if (vendor != null)
                {
                    vendorInvoice.BillingBusinessName = vendor.Name;
                    vendorInvoice.BillingContactName = string.Join(" ", vendor.ContactFirstName, vendor.ContactLastName);
                    AddressRepository repo = new AddressRepository();
                    AddressEntity address = repo.GetAddresses(vendor.ID, EntityNames.VENDOR, AddressTypeNames.BILLING).FirstOrDefault();
                    if (address != null)
                    {
                        vendorInvoice.BillingAddressLine1 = address.Line1;
                        vendorInvoice.BillingAddressLine2 = address.Line2;
                        vendorInvoice.BillingAddressLine3 = address.Line3;
                        vendorInvoice.BillingAddressCity = address.City;
                        vendorInvoice.BillingAddressStateProvince = address.StateProvince;
                        vendorInvoice.BillingAddressPostalCode = address.PostalCode;
                        vendorInvoice.BillingAddressCountryCode = address.CountryCode;

                    }
                }
                vendorInvoice.ToBePaidDate = invoiceDate;
                vendorInvoice.ExportDate = null;
                vendorInvoice.PaymentDate = invoiceDate;
                vendorInvoice.PaymentAmount = po.PurchaseOrderAmount;
                vendorInvoice.PaymentNumber = po.CompanyCreditCardNumber;
                vendorInvoice.CheckClearedDate = null;
                vendorInvoice.ActualETAMinutes = po.ETAMinutes;
                vendorInvoice.IsActive = true;
                vendorInvoice.CreateDate = invoiceDate;
                vendorInvoice.CreateBy = po.ModifyBy;
                vendorInvoice.AccountingInvoiceBatchID = null;
                vendorInvoice.ExportDate = null;
                vendorInvoice.ExportBatchID = null;
                vendorInvoice.InvoiceDate = null;
                vendorInvoice.ReceiveContactMethodID = null;
                var serviceRequest = dbContext.ServiceRequests.Where(sr => sr.ID == po.ServiceRequestID).FirstOrDefault<ServiceRequest>();
                if (serviceRequest != null)
                {
                    Case caseobj = dbContext.Cases.Where(x => x.ID == serviceRequest.CaseID).FirstOrDefault();
                    if (!string.IsNullOrEmpty(caseobj.VehicleVIN))
                    {
                        vendorInvoice.Last8OfVIN = caseobj.VehicleVIN.Substring(caseobj.VehicleVIN.Length - 8);
                    }
                    vendorInvoice.VehicleMileage = caseobj.VehicleCurrentMileage;

                }
            }

            return vendorInvoice;
        }
        public void ReIssueCC(int poId, string user)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                DateTime dt = DateTime.Now;
                var poobj = dbContext.PurchaseOrders.Where(p => p.ID == poId).FirstOrDefault<PurchaseOrder>();

                //Update purchase order
                string purchaseOrderPayStatusCodeName = string.Empty;
                if ((poobj.IsServiceCovered.HasValue && !poobj.IsServiceCovered.Value &&
                                         poobj.IsMemberAmountCollectedByVendor.HasValue && poobj.IsMemberAmountCollectedByVendor.Value && (poobj.MemberServiceAmount == poobj.TotalServiceAmount)))
                {
                    purchaseOrderPayStatusCodeName = PurchaseOrderPayStatusCodeNames.PAID_BY_MEMBER;
                }
                else if (poobj.IsPayByCompanyCreditCard.HasValue && poobj.IsPayByCompanyCreditCard.Value == true)
                {
                    purchaseOrderPayStatusCodeName = PurchaseOrderPayStatusCodeNames.PAY_BY_CC;
                }
                else
                {
                    purchaseOrderPayStatusCodeName = PurchaseOrderPayStatusCodeNames.PAY_TO_VENDOR;
                }
                poobj.PayStatusCodeID = ReferenceDataRepository.GetPurchaseOrderPayStatusCodeByName(purchaseOrderPayStatusCodeName).ID;
                poobj.IsPayByCompanyCreditCard = false;
                poobj.CompanyCreditCardNumber = null;
                poobj.ModifyDate = dt;
                poobj.ModifyBy = user;

                //Delete old vendor Invoice
                VendorInvoice vendorInvoice = dbContext.VendorInvoices.Where(x => x.PurchaseOrderID == poId).FirstOrDefault();
                if (vendorInvoice != null)
                {
                    dbContext.Entry(vendorInvoice).State = EntityState.Deleted;
                }

                dbContext.SaveChanges();

            }
        }

        public bool CanReissueCC(int poId)
        {
            bool canreissue = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var po = dbContext.PurchaseOrders.Where(x => x.ID == poId).FirstOrDefault();
                var vendorInvoice = dbContext.VendorInvoices.Where(x => x.PurchaseOrderID == poId).FirstOrDefault();
                if (po.IsPayByCompanyCreditCard != null && po.IsPayByCompanyCreditCard.Value == true && vendorInvoice != null && vendorInvoice.AccountingInvoiceBatchID == null && po.AccountingInvoiceBatchID == null)
                {
                    canreissue = true;
                }
            }
            return canreissue;
        }
        /// <summary>
        /// Gets the XML from a given list of name-value pairs
        /// </summary>
        /// <param name="eventDetails">List of name-value pairs</param>
        /// <returns>XML as string</returns>
        public string GetXML(Hashtable eventDetails)
        {
            #region Old Code
            /*StringBuilder sb = new StringBuilder("<MessageData>");

            foreach (string key in eventDetails.Keys)
            {
                string val = eventDetails[key] as string;
                if (!string.IsNullOrEmpty(val))
                {
                    val = val.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("'", "&quot;");
                }
                sb.AppendFormat("<{0}>{1}</{0}>", key, val);
            }

            sb.Append("</MessageData>");
            return sb.ToString();*/
            #endregion

            StringBuilder sb = new StringBuilder(""); //"<MessageData>");
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(sb, settings))
            {
                writer.WriteStartElement("MessageData");
                foreach (string key in eventDetails.Keys)
                {
                    string val = eventDetails[key] as string;
                    writer.WriteElementString(key, val);
                }
                writer.WriteEndElement();

                writer.Close();
            }
            return sb.ToString();
        }
        /// <summary>
        /// Gets the member pay dispatch fee.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public string GetMemberPayDispatchFee(int programId)
        {
            string returnValue = string.Empty;
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(programId, "Application", "Rule");

            result.ForEach(x =>
            {
                if (x.Name == "MemberPayDispatchFee" && x.DataType != "Query")
                {
                    returnValue = x.Value;
                }
            });
            if (string.IsNullOrEmpty(returnValue))
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    ApplicationConfiguration appConfig = dbContext.ApplicationConfigurations.Where(ac => ac.Name == "MemberPayDispatchFee").FirstOrDefault<ApplicationConfiguration>();
                    if (appConfig != null && appConfig.Value != null)
                    {
                        returnValue = appConfig.Value;
                    }
                }
            }
            return returnValue;
        }

        public PurchaseOrder AddOrUpdatePO(PurchaseOrder po, string mode, List<PurchaseOrderDetailsModel> poDetails, ISPs_Result isp, int programId, bool isPoPaymentEditAllowed)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (isPoPaymentEditAllowed)
                {
                    var oldPo = dbContext.PurchaseOrders.Where(p => p.ID == po.ID).Include(p => p.PurchaseOrderStatu).Include(p => p.VendorLocation).FirstOrDefault<PurchaseOrder>();
                    if (oldPo != null)
                    {
                        oldPo.IsPayByCompanyCreditCard = po.IsPayByCompanyCreditCard;
                        oldPo.CompanyCreditCardNumber = po.CompanyCreditCardNumber;
                        if (po.PayStatusCodeID.HasValue)
                        {
                            oldPo.PayStatusCodeID = po.PayStatusCodeID;
                        }
                    }
                    dbContext.SaveChanges();
                    if ("View".Equals(mode, StringComparison.InvariantCultureIgnoreCase))
                    {
                        po = GetPOById(po.ID);
                    }

                    //return po;
                }
                if ("View".Equals(mode, StringComparison.InvariantCultureIgnoreCase))
                {
                    return po;
                }
                PhoneType phoType = dbContext.PhoneTypes.Where(ct => ct.Name == "Fax").FirstOrDefault<PhoneType>();
                if ("Edit".Equals(mode, StringComparison.InvariantCultureIgnoreCase))
                {

                    var oldPo = dbContext.PurchaseOrders.Where(p => p.ID == po.ID).Include(p => p.PurchaseOrderStatu).Include(p => p.VendorLocation).FirstOrDefault<PurchaseOrder>();

                    if (oldPo != null)
                    {
                        oldPo.ContactMethodID = po.ContactMethodID;
                        oldPo.FaxPhoneNumber = po.FaxPhoneNumber;
                        oldPo.Email = po.Email;

                        oldPo.TaxAmount = po.TaxAmount;
                        oldPo.TotalServiceAmount = po.TotalServiceAmount;
                        oldPo.MemberServiceAmount = po.MemberServiceAmount;
                        oldPo.MemberPaymentTypeID = po.MemberPaymentTypeID;
                        oldPo.CoachNetServiceAmount = po.CoachNetServiceAmount;
                        oldPo.IsMemberAmountCollectedByVendor = po.IsMemberAmountCollectedByVendor;
                        oldPo.DispatchFee = po.DispatchFee;
                        //NP 10/14/2015: Update Dispatch Fee values.
                        oldPo.ClientDispatchFee = po.ClientDispatchFee;
                        oldPo.InternalDispatchFee = po.InternalDispatchFee;
                        oldPo.CreditCardProcessingFee = po.CreditCardProcessingFee;

                        oldPo.DispatchFeeAgentMinutes = po.DispatchFeeAgentMinutes;
                        oldPo.DispatchFeeTechMinutes = po.DispatchFeeTechMinutes;
                        oldPo.DispatchFeeTimeCost = po.DispatchFeeTimeCost;


                        oldPo.DispatchFeeBillToID = po.DispatchFeeBillToID;
                        oldPo.MemberAmountDueToCoachNet = po.MemberAmountDueToCoachNet;
                        oldPo.PurchaseOrderAmount = po.PurchaseOrderAmount;
                        oldPo.IsVendorAdvised = po.IsVendorAdvised;
                        oldPo.ETAMinutes = po.ETAMinutes;
                        oldPo.VehicleCategoryID = po.VehicleCategoryID;
                        // KB: Update Credit card attributes.
                        oldPo.IsPayByCompanyCreditCard = po.IsPayByCompanyCreditCard;
                        oldPo.CompanyCreditCardNumber = po.CompanyCreditCardNumber;
                        oldPo.AdditionalInstructions = po.AdditionalInstructions;

                        if (po.IsCoverageLimitEnabled.GetValueOrDefault())
                        {
                            oldPo.CoverageLimit = po.CoverageLimit;
                        }

                        if (oldPo.IsServiceCovered != po.IsServiceCovered)
                        {
                            oldPo.IsServiceCovered = po.IsServiceCovered;
                            oldPo.IsServiceCoveredOverridden = po.IsServiceCoveredOverridden;

                            oldPo.CoverageLimitMileage = po.CoverageLimitMileage;
                            oldPo.MileageUOM = po.MileageUOM;
                            oldPo.IsServiceCoverageBestValue = po.IsServiceCoverageBestValue;
                            //po.ServiceCoverageDescription = vpb.ServiceCoverageDescription;
                            oldPo.ServiceEligibilityMessage = po.ServiceEligibilityMessage;

                            oldPo.IsServiceCoverageBestValue = po.IsServiceCoverageBestValue;
                            //Sanghi CR : 307
                            if (!oldPo.IsServiceCoverageBestValue.GetValueOrDefault())
                            {
                                oldPo.CoverageLimit = po.CoverageLimit;
                            }
                        }

                        //TFS 618
                        /* NP 5/31: TFS 618 : change the logic to set the IsPreferredVendor value only when the Purchase Order is issued (regardless of the OriginalPurchaseOrderID value)
                        if (!oldPo.OriginalPurchaseOrderID.HasValue)
                        {*/
                        var currentVendorLocation = oldPo.VendorLocation;
                        if (currentVendorLocation != null)
                        {
                            IsPreferredVendorByProduct_Result IsPreferredVendor = dbContext.GetIsPreferredVendorByProduct(currentVendorLocation.VendorID, oldPo.ProductID).FirstOrDefault();
                            oldPo.IsPreferredVendor = IsPreferredVendor.IsPreferred;
                        }
                        /*}*/

                        //TFS 618
                        /* NP 5/31: TFS 618 : change the logic to set the IsPreferredVendor value only when the Purchase Order is issued (regardless of the OriginalPurchaseOrderID value)
                        if (!oldPo.OriginalPurchaseOrderID.HasValue)
                        {*/
                        //var currentVendorLocation = oldPo.VendorLocation;
                        //if (currentVendorLocation != null)
                        //{
                        //    IsPreferredVendorByProduct_Result IsPreferredVendor = dbContext.GetIsPreferredVendorByProduct(currentVendorLocation.VendorID, oldPo.ProductID).FirstOrDefault();
                        //    oldPo.IsPreferredVendor = IsPreferredVendor.IsPreferred;
                        //}
                        /*}*/

                        oldPo.CurrencyTypeID = po.CurrencyTypeID;
                        oldPo.ModifyDate = DateTime.Now;
                        oldPo.ModifyBy = po.ModifyBy;
                        //TFS Item 2392
                        if (po.PayStatusCodeID.HasValue)
                        {
                            oldPo.PayStatusCodeID = po.PayStatusCodeID;
                        }

                        //CostPlusServiceAmount
                        oldPo.CostPlusServiceAmount = po.CostPlusServiceAmount;

                        foreach (PurchaseOrderDetailsModel item in poDetails)
                        {
                            if (item.Mode == "Insert")
                            {
                                dbContext.PurchaseOrderDetails.Add(item.GetPurchaseOrderDetail());
                            }
                            else if (item.Mode == "Update")
                            {
                                PODetailUpdate(item.GetPurchaseOrderDetail());

                            }
                            else if (item.Mode == "Deleted")
                            {
                                PODetailsDetete(item.ID);
                            }
                        }

                        //Determine whether primary service product has changed if yes then update it.If null returned ignore it.
                        PO_ChangedPrimaryProduct_Result changedProduct = GetChangedPrimaryServiceProduct(oldPo.ID);
                        if (changedProduct != null && changedProduct.ProductID.HasValue)
                        {
                            oldPo.ProductID = changedProduct.ProductID.Value;
                        }
                    }
                }
                else
                {
                    PurchaseOrderStatu puStatus = dbContext.PurchaseOrderStatus.Where(ps => ps.Name == "Pending").FirstOrDefault<PurchaseOrderStatu>();
                    po.PurchaseOrderStatusID = puStatus.ID;
                    var calculateDispatchFee = false;
                    if (mode == "GoToPo")
                    {

                        if (po.VendorLocationID == 0)
                        {
                            po.VendorLocationID = null;
                        }
                        po.IsActive = true;
                        VendorData_Result vdResult = dbContext.GetVendorData(po.VendorLocationID).FirstOrDefault<VendorData_Result>();
                        if (vdResult != null)
                        {
                            po.BillingAddressTypeID = vdResult.BusinessAddressTypeID;
                            po.BillingAddressLine1 = vdResult.BusinessAddressLine1;
                            po.BillingAddressLine2 = vdResult.BusinessAddressLine2;
                            po.BillingAddressLine3 = vdResult.BusinessAddressLine3;
                            po.BillingAddressCity = vdResult.BusinessAddressCity;
                            po.BillingAddressCountryCode = vdResult.BusinessAddressCountryCode;
                            po.BillingAddressStateProvince = vdResult.BusinessAddressStateProviince;
                            po.BillingAddressPostalCode = vdResult.BusinessAddressPostalCode;
                            po.Email = vdResult.Email;
                            CurrencyType curType = (from cType in dbContext.CurrencyTypes
                                                    join cou in dbContext.Countries on cType.CountryID equals cou.ID
                                                    where (cou.ISOCode == vdResult.BusinessAddressCountryCode)
                                                    select cType).FirstOrDefault<CurrencyType>();
                            if (curType != null)
                            {
                                po.CurrencyTypeID = curType.ID;
                            }
                            PhoneRepository phoneRepository = new PhoneRepository();
                            var dispatchType = phoneRepository.GetPhoneTypeByName("Dispatch");
                            if (dispatchType != null)
                            {
                                po.DispatchPhoneTypeID = dispatchType.ID;
                            }

                        }

                        if (phoType != null)
                        {
                            po.FaxPhoneTypeID = phoType.ID;
                        }
                        ContactMethod conMothod = dbContext.ContactMethods.Where(cm => cm.Name == "Fax").FirstOrDefault<ContactMethod>();
                        if (conMothod != null)
                        {
                            po.ContactMethodID = conMothod.ID;
                        }
                        ServiceRequest serviceRequest = (from sr in dbContext.ServiceRequests
                                                         where sr.ID == po.ServiceRequestID
                                                         select sr).FirstOrDefault<ServiceRequest>();

                        //Program currentprogram = ReferenceDataRepository.GetProgramByID(programId);
                        // TFS 1264
                        ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
                        var programResult = programMaintenanceRepository.GetProgramInfo(programId, "Application", "Rule");
                        var poDispatchFeeBillToName = programResult.Where(x => (x.Name.Equals("DispatchFeeBillToName", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                        var poCostPlusPercentage = programResult.Where(x => (x.Name.Equals("POCostPlusPercentage", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                        if (poCostPlusPercentage != null)
                        {
                            po.CostPlusPercentage = Convert.ToDecimal(poCostPlusPercentage.Value);
                        }
                        if (poDispatchFeeBillToName != null)
                        {
                            var dispatchFee = GetMemberPayDispatchFee(programId);
                            calculateDispatchFee = true; // Check to see if we have to exec an sp and fill the 
                            if (!string.IsNullOrEmpty(dispatchFee))
                            {
                                po.DispatchFee = decimal.Parse(dispatchFee);
                            }
                            int billtoId = (from billto in dbContext.BillToes
                                            where billto.Name == poDispatchFeeBillToName.Value && billto.IsActive == true
                                            select billto.ID).FirstOrDefault();
                            if (billtoId != 0)
                            {
                                po.DispatchFeeBillToID = billtoId;
                            }
                        }
                        else
                        {
                            po.DispatchFee = 0;
                            int billtoId = (from billto in dbContext.BillToes
                                            where billto.Name == "CoachNet" && billto.IsActive == true
                                            select billto.ID).FirstOrDefault();
                            if (billtoId != 0)
                            {
                                po.DispatchFeeBillToID = billtoId;
                            }
                        }
                        po.DealerIDNumber = serviceRequest.DealerIDNumber;
                    }
                    //Setting vendor tax id incase of copy and gotopo

                    if (po.VendorLocationID.HasValue && po.VendorLocationID.Value > 0)
                    {
                        VendorLocation location = dbContext.VendorLocations.Where(x => x.ID == po.VendorLocationID).FirstOrDefault<VendorLocation>();
                        Vendor poVendor = dbContext.Vendors.Where(x => x.ID == location.VendorID).FirstOrDefault<Vendor>();
                        string vendorTaxId = (!string.IsNullOrEmpty(poVendor.TaxEIN)) ? poVendor.TaxEIN : poVendor.TaxSSN;
                        po.VendorTaxID = vendorTaxId;
                    }
                    po.CreateDate = DateTime.Now;
                    po.ModifyDate = DateTime.Now;
                    #region TFS 1214 -  Add logic to check ProgramConfiguration for how to set Mbr Pays ISP radio buttons
                    ProgramMaintenanceRepository progMainRepo = new ProgramMaintenanceRepository();
                    var result = progMainRepo.GetProgramInfo(programId, "Application", "Rule");
                    var memberPaysISPDefault = result.Where(x => (x.Name.Equals("MemberPaysISPDefault", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                    if (memberPaysISPDefault != null)
                    {
                        if (memberPaysISPDefault.Value.Equals("Yes", StringComparison.InvariantCultureIgnoreCase))
                        {
                            po.IsMemberAmountCollectedByVendor = true;
                        }
                        else if (memberPaysISPDefault.Value.Equals("No", StringComparison.InvariantCultureIgnoreCase))
                        {
                            po.IsMemberAmountCollectedByVendor = false;
                        }
                    }
                    #endregion
                    dbContext.PurchaseOrders.Add(po);
                    //KB: TFS 298
                    if (mode == "GoToPo" || mode == "CopyPO" || mode == "POChangeService")
                    {
                        int? vendorValue = null;
                        if (isp.VendorID != 0)
                        {
                            vendorValue = isp.VendorID;
                        }
                        decimal poTotalServiceAmount = 0;
                        var gotoPOitems = dbContext.GoToPODetailItems(po.ServiceRequestID, po.EnrouteMiles, po.ReturnMiles, (decimal?)isp.EstimatedHours, isp.ProductID, isp.VendorLocationID, vendorValue).ToList<GoToPODetailItem_Result>();
                        foreach (GoToPODetailItem_Result item in gotoPOitems)
                        {
                            PurchaseOrderDetail poDetail = new PurchaseOrderDetail();
                            poDetail.PurchaseOrderID = po.ID;
                            poDetail.Sequence = item.Sequence;
                            poDetail.ProductID = item.ProductID;
                            poDetail.ProductRateID = item.RateTypeID;
                            poDetail.UnitOfMeasure = item.UnitOfMeasure;
                            poDetail.ContractedRate = item.ContractedRate;
                            poDetail.Rate = item.RatePrice;
                            poDetail.Quantity = item.Quantity;
                            poDetail.ExtendedAmount = (item.RatePrice * item.Quantity);
                            poDetail.CreateBy = po.CreateBy;
                            poDetail.CreateDate = DateTime.Now;
                            poDetail.ModifyBy = po.ModifyBy;
                            poDetail.ModifyDate = po.ModifyDate;
                            poDetail.IsMemberPay = (item.IsMemberPay == 0) ? false : true;
                            poTotalServiceAmount += poDetail.ExtendedAmount.GetValueOrDefault();
                            dbContext.PurchaseOrderDetails.Add(poDetail);

                        }
                        po.TotalServiceAmount = poTotalServiceAmount;
                        po.TotalServiceAmountEstimate = poTotalServiceAmount;
                        // NP 06/13: TFS #1289 
                        po.TotalServiceAmountThreshold = poTotalServiceAmount * (po.ThresholdPercentage + 1);

                    }
                    else if (mode == "Add")
                    {
                        foreach (PurchaseOrderDetailsModel item in poDetails)
                        {
                            if (item.Mode == "Insert")
                            {
                                dbContext.PurchaseOrderDetails.Add(item.GetPurchaseOrderDetail());
                            }
                            else if (item.Mode == "Update")
                            {
                                PODetailUpdate(item.GetPurchaseOrderDetail());
                            }
                        }
                    }
                    dbContext.SaveChanges();

                    if (calculateDispatchFee)
                    {
                        // Check to see if we have to execute an sp to calculate dispatch fee values.
                        ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
                        var programResult = programMaintenanceRepository.GetProgramInfo(programId, "Application", "Rule");
                        var calculateMemberPayDispatchFee = programResult.Where(x => (x.Name.Equals("MemberPayDispatchFee", StringComparison.InvariantCultureIgnoreCase) && x.DataType != null && x.DataType.Equals("Query", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                        if (calculateMemberPayDispatchFee != null)
                        {
                            logger.InfoFormat("Executing an sp to calculate the dispatch fee values {0}", calculateMemberPayDispatchFee.Value);
                            PO_MemberPayDispatchFee_Result pOMemberPayDispatchFeeResult = ReferenceDataRepository.CalculateMemberPayDispatchFee(po.ID, po.PurchaseOrderAmount, calculateMemberPayDispatchFee.Value);
                            if (pOMemberPayDispatchFeeResult != null)
                            {
                                po.DispatchFee = pOMemberPayDispatchFeeResult.DispatchFee;
                                po.InternalDispatchFee = pOMemberPayDispatchFeeResult.InternalDispatchFee;
                                po.ClientDispatchFee = pOMemberPayDispatchFeeResult.ClientDispatchFee;
                                po.CreditCardProcessingFee = pOMemberPayDispatchFeeResult.CreditCardProcessingFee;

                                po.DispatchFeeAgentMinutes = pOMemberPayDispatchFeeResult.DispatchFeeAgentMinutes;
                                po.DispatchFeeTechMinutes = pOMemberPayDispatchFeeResult.DispatchFeeTechMinutes;
                                po.DispatchFeeTimeCost = pOMemberPayDispatchFeeResult.DispatchFeeTimeCost;
                            }
                        }
                    }
                }
                dbContext.SaveChanges();
                po = GetPOById(po.ID);
            }
            return po;
        }

        public void UpdatePOServiceEligibility(PurchaseOrder po)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var oldPo = dbContext.PurchaseOrders.Where(p => p.ID == po.ID).FirstOrDefault<PurchaseOrder>();
                oldPo.ProductID = po.ProductID;
                oldPo.IsServiceCovered = po.IsServiceCovered;
                oldPo.CoverageLimit = po.CoverageLimit;
                oldPo.CoverageLimitMileage = po.CoverageLimitMileage;
                oldPo.MileageUOM = po.MileageUOM;
                oldPo.IsServiceCoverageBestValue = po.IsServiceCoverageBestValue;
                oldPo.ServiceEligibilityMessage = po.ServiceEligibilityMessage;
                if (po.IsServiceCoveredOverridden.GetValueOrDefault())
                {
                    oldPo.IsServiceCoveredOverridden = po.IsServiceCoveredOverridden;

                }
                dbContext.SaveChanges();
            }
        }

        public bool IsPODetailItemProductChanged(PurchaseOrderDetailsModel poDetail, int programId, int? vehicleCategoryId)
        {
            bool isProductChanged = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                bool? ischanged = dbContext.CoverageLimitUpdate(programId, vehicleCategoryId, poDetail.PurchaseOrderID, poDetail.ProductID, poDetail.ProductRateID).SingleOrDefault<bool?>();
                if (ischanged.HasValue)
                {
                    isProductChanged = ischanged.Value;
                }
            }
            return isProductChanged;
        }
        /// <summary>
        /// Determines whether [is deal tow] [the specified program id].
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns>
        ///   <c>true</c> if [is deal tow] [the specified program id]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsDealTow(int programId)
        {
            bool returnValue = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                IsDealerTow_Result result = dbContext.IsDealerTow(programId).FirstOrDefault<IsDealerTow_Result>();
                if (result != null && result.Value == "Yes")
                {
                    returnValue = true;
                }

            }

            return returnValue;
        }

        /// <summary>
        /// Gets the send PO history.
        /// </summary>
        /// <param name="purchaseOrderId">The purchase order id.</param>
        /// <returns></returns>
        public List<SendPOHistory_Result> GetSendPOHistory(int purchaseOrderId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<SendPOHistory_Result> sendPoHistoryList = dbContext.GetSendPOHistory(purchaseOrderId).ToList<SendPOHistory_Result>();

                return sendPoHistoryList ?? new List<SendPOHistory_Result>();
            }
        }

        /// <summary>
        /// POs the disable.
        /// </summary>
        /// <param name="poid">The poid.</param>
        public void PODisable(int poid, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                PurchaseOrder po = dbContext.PurchaseOrders.Where(p => p.ID == poid).Include(p => p.PurchaseOrderStatu).FirstOrDefault<PurchaseOrder>();
                if (po != null && po.PurchaseOrderStatu != null && po.PurchaseOrderStatu.Name.Equals("pending", StringComparison.InvariantCultureIgnoreCase))
                {
                    po.IsActive = false;
                    po.ModifyBy = currentUser;
                    po.ModifyDate = DateTime.Now;
                }
                dbContext.SaveChanges();
            }
        }

        public void PODelete(int poid, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                PurchaseOrder po = dbContext.PurchaseOrders.Where(p => p.ID == poid).FirstOrDefault<PurchaseOrder>();
                if (po != null)
                {
                    po.IsActive = false;
                    po.ModifyBy = currentUser;
                    po.ModifyDate = DateTime.Now;
                }
                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// Gets the product by ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public Product GetProductByID(int id)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                var prod = dbcontext.Products.Where(p => p.ID == id).FirstOrDefault<Product>();
                return prod ?? new Product();
            }
        }

        /// <summary>
        /// Gets the name of the product by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public Product GetProductByName(string name)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                var prod = dbcontext.Products.Where(p => p.Name == name).FirstOrDefault<Product>();
                return prod ?? new Product();
            }
        }

        /// <summary>
        /// Gets the ratetype by ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public RateType GetRatetypeByID(int id)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                var rateType = dbcontext.RateTypes.Where(rt => rt.ID == id).FirstOrDefault<RateType>();
                return rateType ?? new RateType();
            }
        }

        public decimal GetCoverageLimitForPO(int? programID, int? vehicleCategoryID, int? poID)
        {

            using (DMSEntities dbcontext = new DMSEntities())
            {
                decimal? rateType = dbcontext.GetCoverageLimitForPO(programID, vehicleCategoryID, poID).Single<decimal?>();
                return rateType ?? 0;
            }
        }

        /// <summary>
        /// Gets the vendor rate.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorRates_Result> GetVendorRate(PageCriteria pageCriteria, int VendorLocationID)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                List<VendorRates_Result> vendorRatesResult = dbcontext.GetVendorRates(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, VendorLocationID).ToList<VendorRates_Result>();
                return vendorRatesResult;
            }
        }

        /// <summary>
        /// Gets the vendor location product.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="productID">The product ID.</param>
        /// <returns></returns>
        public VendorLocationProduct GetVendorLocationProduct(int? vendorLocationID, int? productID)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                VendorLocationProduct vlp = dbcontext.VendorLocationProducts.Where(a => a.VendorLocationID == vendorLocationID && a.ProductID == productID).FirstOrDefault();
                return vlp;
            }
        }

        public PO_ChangedPrimaryProduct_Result GetChangedPrimaryServiceProduct(int purchaseOrderID)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                return dbcontext.PO_GetChangedPrimaryProduct(purchaseOrderID).FirstOrDefault<PO_ChangedPrimaryProduct_Result>();
            }
        }

        public Case GetCaseForPO(int poId)
        {
            Case caseObj = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                PurchaseOrder po = dbContext.PurchaseOrders.Where(x => x.ID == poId).FirstOrDefault<PurchaseOrder>();
                ServiceRequest serviceRequest = dbContext.ServiceRequests.Where(x => x.ID == po.ServiceRequestID).FirstOrDefault<ServiceRequest>();
                caseObj = dbContext.Cases.Where(x => x.ID == serviceRequest.CaseID).FirstOrDefault<Case>();

            }
            return caseObj;
        }

        public bool IsPaymentAllowed(int programId)
        {
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(programId, "Application", "Rule");
            bool allowPayment = false;
            var item = result.Where(x => (x.Name.Equals("AllowPaymentProcessing", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (item != null)
            {
                allowPayment = true;
            }
            return allowPayment;
        }

        public int? GetVendorSelectionContactLog(int serviceRequestId, int? vendorLocationId)
        {
            int? contactLogId = null;
            List<int> vendorContactLogIdList = new List<int>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                var ContactLogLinkModelList = (from CLL in dbContext.ContactLogLinks
                                               join CL in dbContext.ContactLogs on CLL.ContactLogID equals CL.ID
                                               join CC in dbContext.ContactCategories on CL.ContactCategoryID equals CC.ID
                                               join CS in dbContext.ContactSources on CL.ContactSourceID equals CS.ID
                                               join CT in dbContext.ContactTypes on CL.ContactTypeID equals CT.ID
                                               join ET in dbContext.Entities on CLL.EntityID equals ET.ID
                                               where CLL.RecordID == serviceRequestId && CT.Name == "Vendor" && CC.Name == "VendorSelection" && CS.Name == "VendorData"
                                               && ET.Name == "ServiceRequest"
                                               select new
                                               {
                                                   ContactLogId = CLL.ContactLogID,
                                                   ModifyDate = CL.ModifyDate
                                               } into ContactLogLinkModel
                                               orderby ContactLogLinkModel.ModifyDate descending
                                               select ContactLogLinkModel);

                if (vendorLocationId.HasValue)
                {
                    vendorContactLogIdList = (from CLL in dbContext.ContactLogLinks
                                              join ET in dbContext.Entities on CLL.EntityID equals ET.ID
                                              where CLL.RecordID == vendorLocationId && ET.Name == "VendorLocation"
                                              select CLL.ContactLogID.Value).ToList<int>();

                    var filteredContactLinkModelList = (from CDL in ContactLogLinkModelList
                                                        where vendorContactLogIdList.Contains(CDL.ContactLogId.Value)
                                                        select CDL);

                    if (filteredContactLinkModelList.Count() > 0)
                    {
                        contactLogId = (from FCDL in filteredContactLinkModelList
                                        orderby FCDL.ModifyDate descending
                                        select FCDL.ContactLogId.Value).FirstOrDefault<int>();
                    }
                }
                else
                {
                    contactLogId = (from FCDL in ContactLogLinkModelList
                                    orderby FCDL.ModifyDate descending
                                    select FCDL.ContactLogId.Value).FirstOrDefault<int>();
                }
            }

            return contactLogId;
        }

        public void UpdatePOPaymentStatus(int poId, int? payStatusCodeID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var oldPo = dbContext.PurchaseOrders.Where(p => p.ID == poId).FirstOrDefault<PurchaseOrder>();
                oldPo.PayStatusCodeID = payStatusCodeID;
                dbContext.SaveChanges();
            }
        }

        public string GetContractStatus(int vendorId)
        {
            string contractStatus = string.Empty;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Vendor_Contract_Status_Get(vendorId).ToList<Vendor_Contract_Status_Get_Result>();
                if (list.Count() > 0)
                {
                    contractStatus = list[0].ContractStatus;
                }

            }
            return contractStatus;
        }



        public void SaveSRActivityComments(Comment comment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                comment.EntityID = dbContext.Entities.Where(a => a.Name == "ServiceRequest").Select(a => a.ID).FirstOrDefault();
                dbContext.Comments.Add(comment);
                dbContext.SaveChanges();
            }
        }

        public Vendor GetVendorDetails(int vendorLocationId)
        {
            Vendor vendor = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorLocation location = dbContext.VendorLocations.Where(a => a.ID == vendorLocationId).FirstOrDefault<VendorLocation>();
                vendor = dbContext.Vendors.Where(a => a.ID == location.VendorID).FirstOrDefault<Vendor>();
            }
            return vendor;
        }

        public List<VendorInvoice> GetVendorInvoices(int poId)
        {
            List<VendorInvoice> vendorInvoices = new List<VendorInvoice>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                vendorInvoices = dbContext.VendorInvoices.Where(a => a.PurchaseOrderID == poId).ToList<VendorInvoice>();

            }
            return vendorInvoices;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="poID"></param>
        /// <param name="ccNumber"></param>
        /// <param name="userName"></param>
        public void UpdateCompanyCCNumber(int poID, string ccNumber, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingPODetails = dbContext.PurchaseOrders.Where(u => u.ID == poID).FirstOrDefault();
                if (existingPODetails == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve PO Details for ID {0}", poID));
                }
                existingPODetails.CompanyCreditCardNumber = ccNumber;
                existingPODetails.ModifyBy = userName;
                existingPODetails.ModifyDate = DateTime.Now;
                dbContext.SaveChanges();
            }
        }

        public ServiceRequest GetSRByPO(int poID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var po = dbContext.PurchaseOrders.Where(x => x.ID == poID).FirstOrDefault();
                if (po != null)
                {
                    var sr = dbContext.ServiceRequests.Include("Case").Include(s => s.ServiceRequestStatu).Where(s => s.ID == po.ServiceRequestID).FirstOrDefault();
                    return sr;
                }
                return null;
            }
        }

        public string ViewPODocument(PurchaseOrder po, string talkedTo, string vendorName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var oldPo = dbContext.PurchaseOrders.Where(p => p.ID == po.ID).FirstOrDefault<PurchaseOrder>();
                ContactLogRepository clRepository = new ContactLogRepository();
                ContactLog cl = new ContactLog();
                ContactCategory cc = dbContext.ContactCategories.Where(ccExp => ccExp.Name == "ContactVendor").FirstOrDefault<ContactCategory>();
                ContactType ct = dbContext.ContactTypes.Where(cType => cType.Name == "Vendor").FirstOrDefault<ContactType>();

                ContactSource cs = dbContext.ContactSources.Where(cSource => cSource.Name == "ServiceRequest" && cSource.ContactCategoryID == cc.ID).FirstOrDefault<ContactSource>();
                if (cc != null)
                {
                    cl.ContactCategoryID = cc.ID;
                }
                if (ct != null)
                {
                    cl.ContactTypeID = ct.ID;
                }

                cl.ContactMethodID = po.ContactMethodID;
                if (cs != null)
                {
                    cl.ContactSourceID = cs.ID;
                }

                cl.Company = vendorName;
                cl.TalkedTo = talkedTo;
                if (!string.IsNullOrEmpty(po.FaxPhoneNumber))
                {
                    cl.PhoneTypeID = po.FaxPhoneTypeID;
                    cl.PhoneNumber = po.FaxPhoneNumber;
                }
                else
                {
                    cl.Email = po.Email;
                }
                cl.Direction = "Outbound";
                cl.Description = "Send PO to Vendor";
                cl.CreateDate = DateTime.Now;
                cl.ModifyDate = DateTime.Now;
                cl.CreateBy = po.ModifyBy;
                cl.ModifyBy = po.ModifyBy;

                clRepository.Save(cl, po.ModifyBy, po.ID, EntityNames.PURCHASE_ORDER);
                clRepository.CreateLinkRecord(cl.ID, EntityNames.VENDOR_LOCATION, po.VendorLocationID);

                string messageText = string.Empty;
                ContactMethod cm = dbContext.ContactMethods.Where(c => c.ID == po.ContactMethodID && c.IsActive == true).FirstOrDefault<ContactMethod>();

                if (cm != null)
                {
                    if (ContactMethodNames.VERBALLY.Equals(cm.Name, StringComparison.InvariantCultureIgnoreCase))
                    {
                        cm = dbContext.ContactMethods.Where(c => c.Name == ContactMethodNames.FAX && c.IsActive == true).FirstOrDefault<ContactMethod>();
                        if (cm == null)
                        {
                            throw new DMSException("Contact Method not set in DB : " + ContactMethodNames.FAX);
                        }
                    }
                    PurchaseOrderTemplate_Result poTemplate = dbContext.GetPurchaseOrderTemplate(po.ID, cl.ID).FirstOrDefault<PurchaseOrderTemplate_Result>();
                    string processedSubject = string.Empty;


                    if (poTemplate != null)
                    {
                        Template activeTemplate = dbContext.Templates.Where(t => t.Name == "PurchaseOrder" + cm.Name && t.IsActive == true).FirstOrDefault<Template>();
                        if (activeTemplate == null)
                        {
                            throw new DMSException("Unable to retrieve template PurchaseOrder" + cm.Name);
                        }
                        Hashtable PoTempValues = new Hashtable();
                        PoTempValues.Add("POFaxFrom", poTemplate.POFrom);
                        //PoTempValues.Add("PurchaseOrderNumber", poTemplate.PurchaseOrderNumber == null ? string.Empty : poTemplate.PurchaseOrderNumber);
                        PoTempValues.Add("PurchaseOrderNumber", oldPo.PurchaseOrderNumber == null ? string.Empty : oldPo.PurchaseOrderNumber);
                        PoTempValues.Add("TalkedTo", talkedTo ?? string.Empty);
                        PoTempValues.Add("VendorName", poTemplate.VendorName ?? string.Empty);
                        PoTempValues.Add("VendorNumber", poTemplate.VendorNumber ?? string.Empty);
                        PoTempValues.Add("VendorFax", poTemplate.FaxPhoneNumber ?? string.Empty);
                        // PoTempValues.Add("POFaxFrom", poTemplate.POFrom);
                        PoTempValues.Add("IssueDateTime", oldPo.IssueDate.HasValue ? oldPo.IssueDate.Value.ToString("HH:mm:ss-MM/dd/yyyy") : string.Empty);
                        //PoTempValues.Add("IssueDateTime", poTemplate.IssueDate);
                        PoTempValues.Add("CreateBy", poTemplate.OpenedBy);
                        PoTempValues.Add("ProductCategoryName", poTemplate.ServiceName ?? string.Empty);
                        PoTempValues.Add("ETAMinutes", po.ETAMinutes.HasValue ? po.ETAMinutes.ToString() : string.Empty);
                        PoTempValues.Add("Safe", poTemplate.Safe);
                        PoTempValues.Add("MemberPay", poTemplate.MemberPay);
                        PoTempValues.Add("MemberName", poTemplate.MemberName);
                        PoTempValues.Add("MembershipNumber", poTemplate.MembershipNumber ?? string.Empty);
                        PoTempValues.Add("ContactNumber", poTemplate.ContactPhoneNumber ?? string.Empty);
                        PoTempValues.Add("AlternateContact", poTemplate.ContactAltPhoneNumber ?? string.Empty);
                        PoTempValues.Add("ServiceLocationAddress", poTemplate.ServiceLocationAddress ?? string.Empty);
                        PoTempValues.Add("ServiceLocationDescription", poTemplate.ServiceLocationDescription ?? string.Empty);
                        PoTempValues.Add("ServiceLocationCrossStreet", poTemplate.ServiceLocationCrossStreet ?? string.Empty);
                        PoTempValues.Add("ServiceLocationCityState", poTemplate.CityState ?? string.Empty);
                        PoTempValues.Add("ServiceLocationPostalCode", poTemplate.Zip ?? string.Empty);
                        PoTempValues.Add("DestinationDescription", poTemplate.DestinationDescription ?? string.Empty);
                        PoTempValues.Add("DestinationAddress", poTemplate.DestinationAddress ?? string.Empty);
                        PoTempValues.Add("DestinationCityState", poTemplate.DestinationCityState ?? string.Empty);
                        PoTempValues.Add("DestinationPostalCode", poTemplate.DestinationZip ?? string.Empty);
                        PoTempValues.Add("VehicleYear", poTemplate.VehicleYear ?? string.Empty);
                        PoTempValues.Add("VehicleMake", poTemplate.VehicleMake ?? string.Empty);
                        PoTempValues.Add("VehicleModel", poTemplate.VehicleModel ?? string.Empty);
                        PoTempValues.Add("VehicleDescription", poTemplate.VehicleDescription ?? string.Empty);
                        PoTempValues.Add("VehicleColor", poTemplate.VehicleColor ?? string.Empty);
                        PoTempValues.Add("VehicleStateLicense", poTemplate.License ?? string.Empty);
                        PoTempValues.Add("VehicleVin", poTemplate.VehicleVIN ?? string.Empty);
                        PoTempValues.Add("VehicleChassis", poTemplate.VehicleChassis ?? string.Empty);
                        PoTempValues.Add("VehicleLength", poTemplate.VehicleLength.HasValue ? poTemplate.VehicleLength.Value.ToString() : string.Empty);
                        PoTempValues.Add("VehicleEngine", poTemplate.VehicleEngine ?? string.Empty);
                        PoTempValues.Add("VehicleClass", poTemplate.Class ?? string.Empty);
                        PoTempValues.Add("VendorCallback", poTemplate.VendorCallback ?? string.Empty);
                        PoTempValues.Add("VendorBilling", poTemplate.VendorBilling ?? string.Empty);
                        // TFS 659 : 
                        PoTempValues.Add("AdditionalInstructions", po.AdditionalInstructions ?? string.Empty);
                        CommunicationQueueRepository cqRepository = new CommunicationQueueRepository();
                        messageText = TemplateUtil.ProcessTemplate(activeTemplate.Body, PoTempValues);
                    }

                }
                return messageText;
            }
        }

        /// <summary>
        /// Gets the issued po's for sr.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        public List<PurchaseOrder> GetIssuedPOsForSR(int serviceRequestID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                PurchaseOrderStatu poStatus = dbContext.PurchaseOrderStatus.Where(pos => pos.Name == "Issued").FirstOrDefault<PurchaseOrderStatu>();
                List<PurchaseOrder> issuedPOs = dbContext.PurchaseOrders.Where(a => a.ServiceRequestID == serviceRequestID && a.PurchaseOrderStatusID == poStatus.ID).Include(p => p.PurchaseOrderStatu).ToList<PurchaseOrder>();
                return issuedPOs;
            }

        }

        /// <summary>
        /// Gets the POs by status for a given ServiceRequest
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="status">The PO status.</param>
        /// <returns>List of PurchaseOrders matching the given status under the given ServiceRequest</returns>
        public List<PurchaseOrder> GetPOsByStatus(int serviceRequestID, string status)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                PurchaseOrderStatu poStatus = dbContext.PurchaseOrderStatus.Where(pos => pos.Name == status).FirstOrDefault<PurchaseOrderStatu>();
                List<PurchaseOrder> list = dbContext.PurchaseOrders.Where(a => a.ServiceRequestID == serviceRequestID && a.PurchaseOrderStatusID == poStatus.ID && a.IsActive == true).Include(p => p.PurchaseOrderStatu).OrderByDescending(p => p.CreateDate).ToList<PurchaseOrder>();
                return list;
            }

        }

        /// <summary>
        /// Updates the contact log link for po issuing.
        /// </summary>
        /// <param name="srId">The sr identifier.</param>
        /// <param name="poId">The po identifier.</param>
        public void UpdateContactLogLinkForPOIssuing(int srId, int poId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.UpdateContactLogLinkForPurchaseOrderIssuing(srId, poId);
            }

        }

        /// <summary>
        /// Gets the po issue hagerty event mail tag.
        /// </summary>
        /// <param name="poId">The po identifier.</param>
        /// <returns></returns>
        public List<POIssueHagertyEventMailTag_Result> GetPOIssueHagertyEventMailTag(int poId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetPOIssueHagertyEventMailTag(poId).ToList();
            }
        }

        /// <summary>
        /// Gets all po for service request.
        /// </summary>
        /// <param name="serviceRequestId">The service request identifier.</param>
        /// <returns></returns>
        public List<PurchaseOrder> GetAllPOForServiceRequest(int serviceRequestId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var purchaseOrderList = dbContext.PurchaseOrders.Where(po => po.ServiceRequestID == serviceRequestId)
                    .Include(p => p.PurchaseOrderStatu)
                                                    .Include(p => p.BillTo)
                                                    .Include(p => p.ContactMethod)
                                                    .Include(p => p.CurrencyType)
                                                    .Include(p => p.PaymentType)
                                                    .Include(p => p.PurchaseOrderPayStatusCode)
                                                    .Include(p => p.PurchaseOrderCancellationReason)
                                                    .Include(p => p.PurchaseOrderType)
                    .OrderBy(po => po.CreateDate).ToList<PurchaseOrder>();
                return purchaseOrderList ?? new List<PurchaseOrder>();
            }
        }

        /// <summary>
        /// Gets the sr has accounting invoice batch identifier.
        /// </summary>
        /// <param name="serviceRequestId">The service request identifier.</param>
        /// <returns></returns>
        public bool GetSRHasAccountingInvoiceBatchID(int serviceRequestId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetSRHasAccountingInvoiceBatchID(serviceRequestId).FirstOrDefault().SRHasAccountingInvoiceBatchID.GetValueOrDefault();
            }
        }

        public GetRecentCallDetails_Result GetRecentCallDetails(int poID)
        {

            using (DMSEntities dbContext = new DMSEntities())
            {
                var po = dbContext.PurchaseOrders.Where(x => x.ID == poID).FirstOrDefault();
                /*callLog = (from cl in dbContext.ContactLogs
                           join cllsr in dbContext.ContactLogLinks on cl.ID equals cllsr.ContactLogID                                                                                    
                           join cllvl in dbContext.ContactLogLinks on cl.ID equals cllvl.ContactLogID                                                                                    
                           join cla in dbContext.ContactLogActions on cl.ID equals cla.ContactLogID 
                           where cllsr.Entity.Name == "ServiceRequest" && cllsr.RecordID == po.ServiceRequestID 
                                && cllvl.Entity.Name == "VendorLocation"
                                && cllvl.RecordID == po.VendorLocationID
                                && cla.ContactAction.Name == "Negotiate"
                           orderby cl.CreateDate descending
                           select new CallLog()
                           {
                               CallLogTalkedTo = cl.TalkedTo,
                               PhoneNumberCalled = cl.PhoneNumber,
                               PhoneType = cl.PhoneType.Name
                           }).FirstOrDefault();*/

                var callLog = dbContext.GetRecentCallDetails(poID).FirstOrDefault();
                return callLog;
            }
        }

        /// <summary>
        /// Updates the approval details.
        /// </summary>
        /// <param name="purchaseOrderId">The purchase order identifier.</param>
        /// <param name="approvalDetails">The approval details.</param>
        public void UpdateApprovalDetails(int purchaseOrderId, EstimateApprovalModel approvalDetails, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var po = dbContext.PurchaseOrders.Where(x => x.ID == purchaseOrderId).FirstOrDefault();
                var contactActions = ReferenceDataRepository.GetContactAction("MemberPayEstimate");
                var contactActionForAcceptID = contactActions.Where(x => x.Name == "AcceptOverage").FirstOrDefault().ID;
                var contactActionForDeclineID = contactActions.Where(x => x.Name == "RejectOverage").FirstOrDefault().ID;
                if (po != null)
                {
                    if (approvalDetails.ContactActionID == contactActionForAcceptID)
                    {
                        po.IsOverageApproved = true;
                        approvalDetails.IsApproved = true;
                    }
                    else if (approvalDetails.ContactActionID == contactActionForDeclineID)
                    {
                        po.IsOverageApproved = false;
                        approvalDetails.IsApproved = false;
                    }
                    po.ModifyBy = currentUser;
                    po.ModifyDate = DateTime.Now;

                    dbContext.SaveChanges();
                }
            }

        }

        /// <summary>
        /// Gets the po threshold percentage.
        /// </summary>
        /// <param name="vehicleCategoryID">The vehicle category identifier.</param>
        /// <param name="productCategoryID">The product category identifier.</param>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <param name="clientID">The client identifier.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public decimal GetPOThresholdPercentage(int vehicleCategoryID, int productCategoryID, int vendorID, int? clientID, int? programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                decimal thresholdPercentage = 0;
                var percentage = dbContext.GetPOThresholdPercentage(vehicleCategoryID, productCategoryID, vendorID, clientID, programID).FirstOrDefault();
                if (percentage != null)
                {
                    thresholdPercentage = percentage.GetValueOrDefault();
                }
                return thresholdPercentage;
            }
        }

        /// <summary>
        /// Updates the manager approval details.
        /// </summary>
        /// <param name="poId">The po identifier.</param>
        /// <param name="isThresholdApproved">if set to <c>true</c> [is threshold approved].</param>
        /// <param name="approvedUserName">Name of the approved user.</param>
        /// <param name="serviceTotal">The service total.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        public void UpdateManagerApprovalDetails(int poId, bool isThresholdApproved, string approvedUserName, decimal? serviceTotal, string loggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var po = dbContext.PurchaseOrders.Where(x => x.ID == poId).FirstOrDefault();
                if (po != null)
                {
                    po.IsThresholdApproved = isThresholdApproved;
                    if (!isThresholdApproved)
                    {
                        po.RejectedTotalServiceAmount = serviceTotal;
                    }
                    po.ThresholdPINPerson = approvedUserName;
                    po.ModifyBy = loggedInUserName;
                    po.ModifyDate = DateTime.Now;

                    dbContext.SaveChanges();
                }
            }
        }
    }
}
