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
    /// <summary>
    /// Facade to Manage POs
    /// </summary>
    public class POFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(MemberFacade));
        #endregion

        #region Public Methods
        /// <summary>
        /// Searches the specified logged in user name.
        /// </summary>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="userId">The user id.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public List<SearchPO_Result> Search(string loggedInUserName, string eventSource, int inboundCallId, PageCriteria pageCriteria, Guid? userId, string sessionID)
        {
            // Make an event log entry
            //For Event Log
            EventLogRepository eventLogRepository = new EventLogRepository();

            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(EventNames.PO_SEARCH);

            if (theEvent == null)
            {
                throw new DMSException(string.Format("Invalid event name : {0}", EventNames.PO_SEARCH));
            }

            EventLog eventLog = new EventLog();
            eventLog.Source = eventSource;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = pageCriteria.WhereClause;
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = loggedInUserName;


            long eventLogId = eventLogRepository.Add(eventLog, inboundCallId, EntityNames.INBOUND_CALL);
            return new PORepository().Search(pageCriteria, userId);
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
            return new PORepository().GetPOForServiceRequest(serviceRequest, sortColumn, sortDirection);
        }

        /// <summary>
        /// Gets all po for service request.
        /// </summary>
        /// <param name="serviceRequestId">The service request identifier.</param>
        /// <returns></returns>
        public List<PurchaseOrder> GetAllPOForServiceRequest(int serviceRequestId)
        {
            return new PORepository().GetAllPOForServiceRequest(serviceRequestId);
        }

        /// <summary>
        /// Gets the sr has accounting invoice batch identifier.
        /// </summary>
        /// <param name="serviceRequestId">The service request identifier.</param>
        /// <returns></returns>
        public bool GetSRHasAccountingInvoiceBatchID(int serviceRequestId)
        {
            return new PORepository().GetSRHasAccountingInvoiceBatchID(serviceRequestId);

        }

        /// <summary>
        /// Gets the vendor information.
        /// </summary>
        /// <param name="vendorLocationId">The vendor location id.</param>
        /// <param name="serviceRequest">The service request.</param>
        /// <returns></returns>
        public VendorInformation_Result GetVendorInformation(int vendorLocationId, int? serviceRequest)
        {
            return new PORepository().GetVendorInformation(vendorLocationId, serviceRequest.GetValueOrDefault());
        }

        /// <summary>
        /// Gets the purchase order.
        /// </summary>
        /// <param name="serviceRequest">The service request.</param>
        /// <returns></returns>
        public PurchaseOrder GetPurchaseOrder(int serviceRequest)
        {
            return new PORepository().GetPurchaseOrder(serviceRequest);
        }

        /// <summary>
        /// Gets the purchase order details.
        /// </summary>
        /// <param name="poID">The po ID.</param>
        /// <returns></returns>
        public List<PODetailItemByPOId_Result> GetPurchaseOrderDetails(int poID)
        {
            return new PORepository().GetPurchaseOrderDetails(poID);
        }

        /// <summary>
        /// Adds the specified po details.
        /// </summary>
        /// <param name="podetails">The podetails.</param>
        public void Add(PurchaseOrderDetail podetails)
        {
            new PORepository().Add(podetails);
        }

        /// <summary>
        /// Gets the PO details by ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public PurchaseOrderDetail GetPODetailsByID(int id)
        {
            return new PORepository().GetPODetailsByID(id);
        }

        /// <summary>
        /// POs the detail update.
        /// </summary>
        /// <param name="poDetils">The po detils.</param>
        public void PODetailUpdate(PurchaseOrderDetail poDetils)
        {
            new PORepository().PODetailUpdate(poDetils);
        }

        /// <summary>
        /// POs the details detete.
        /// </summary>
        /// <param name="id">The id.</param>
        public void PODetailsDetete(int id)
        {
            new PORepository().PODetailsDetete(id);
        }

        /// <summary>
        /// Gets the PO by id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public PurchaseOrder GetPOById(int id)
        {
            return new PORepository().GetPOById(id);
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
            return new PORepository().IsMemberPaymentBalance(service);
        }

        /// <summary>
        /// Cancels the PO.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionId">The session id.</param>
        public void CancelPO(PurchaseOrder po, string currentUser, string eventSource, string sessionId)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                var eventLoggerFacade = new EventLoggerFacade();
                eventLoggerFacade.LogEvent(eventSource, EventNames.CANCEL_PO, "Cancel PO", currentUser, po.ID, EntityNames.PURCHASE_ORDER, sessionId);
                new PORepository().CancelPO(po);
                tran.Complete();
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
            return new PORepository().IsAlreadyGOA(poId);

        }

        /// <summary>
        /// Adds the GOA.
        /// </summary>
        /// <param name="currentPO">The current PO.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionId">The session id.</param>
        /// <returns></returns>
        public PurchaseOrder AddGOA(PurchaseOrder currentPO, string currentUser, string eventSource, string sessionId)
        {
            PurchaseOrder goaPO = new PurchaseOrder();
            PORepository porepository = new PORepository();
            using (TransactionScope tran = new TransactionScope())
            {
                logger.InfoFormat("Creating EventLog");
                var eventLoggerFacade = new EventLoggerFacade();
                eventLoggerFacade.LogEvent(eventSource, EventNames.CREATE_GOA, "Create GOA", currentUser, currentPO.ID, EntityNames.PURCHASE_ORDER, sessionId);
                logger.InfoFormat("Created EventLog Successfully for Creating GOA");
                logger.Info("Creating GOA");
                goaPO = porepository.AddGOA(currentPO, currentUser);
                logger.Info("Added GOA Successfully");
                porepository.InsertGOAPODetails(currentPO.ID, goaPO.ID, currentUser);
                logger.Info("Inserted Into GOADetails Successfully");
                tran.Complete();
            }

            return goaPO;
        }

        /// <summary>
        /// Gets the service coverage limit.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public decimal GetServiceCoverageLimit(int programId)
        {
            return new PORepository().GetServiceCoverageLimit(programId);
        }

        /// <summary>
        /// Sends the PO.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="setPurchaseOrderStatus">The set purchase order status.</param>
        /// <param name="talkedTo">The talked to.</param>
        /// <param name="vendorName">Name of the vendor.</param>
        /// <param name="ContactLogID">The contact log ID.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionId">The session id.</param>
        public void SendPO(PurchaseOrder po, string setPurchaseOrderStatus, string talkedTo, string vendorName, int? ContactLogID, string currentUser, string eventSource, string sessionId)//, int memberId, string clientName, string serviceType)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                var eventLoggerFacade = new EventLoggerFacade();
                eventLoggerFacade.LogEvent(eventSource, EventNames.SEND_PO, "Send PO", currentUser, po.ID, EntityNames.PURCHASE_ORDER, sessionId);
                PORepository repository = new PORepository();

                #region TFS 527
                //List<PurchaseOrder> issuedPurchaseOrders = new PORepository().GetIssuedPOsForSR(po.ServiceRequestID);
                #endregion
                #region TFS #648 Change Eligibility values on SR
                ServiceRequest sr = repository.GetSRByPO(po.ID);
                PurchaseOrder existingPO = repository.GetPOById(po.ID);
                Case caseobj = new CaseFacade().GetCaseById(sr.CaseID);
                int? towCategoryId = null;
                Product p = ReferenceDataRepository.GetProductById(existingPO.ProductID.HasValue ? existingPO.ProductID.GetValueOrDefault() : sr.PrimaryProductID.GetValueOrDefault());
                int? productCategoryId = p != null ? p.ProductCategoryID : null;

                if (sr.IsPossibleTow.GetValueOrDefault())
                {
                    ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                    if (pc != null)
                    {
                        towCategoryId = pc.ID;
                    }
                }
                ServiceEligibilityModel model = new ServiceFacade().GetServiceEligibilityModel(caseobj.ProgramID, productCategoryId, existingPO.ProductID.HasValue ? existingPO.ProductID : sr.PrimaryProductID, caseobj.VehicleTypeID, po.VehicleCategoryID, towCategoryId, sr.ID, sr.CaseID, SourceSystemName.DISPATCH,false, true);
                if (sr != null)
                {
                    sr.IsPrimaryOverallCovered = model.IsPrimaryOverallCovered;
                    sr.PrimaryCoverageLimit = model.PrimaryCoverageLimit;
                    sr.PrimaryCoverageLimitMileage = model.PrimaryCoverageLimitMileage;
                    sr.MileageUOM = model.MileageUOM;
                    sr.IsServiceCoverageBestValue = model.IsServiceCoverageBestValue;
                    sr.PrimaryServiceEligiblityMessage = model.PrimaryServiceEligiblityMessage;

                }

                #endregion
                repository.SendPO(po, setPurchaseOrderStatus, talkedTo, vendorName, ContactLogID, sr, currentUser, eventSource, sessionId);

                Program program = ReferenceDataRepository.GetProgramByID(caseobj.ProgramID.GetValueOrDefault());

                #region TFS 527 : Dispatch - Request - PO Tab: Insert EventLog when Hagerty VIP member uses the service
                /* NP 01/07: TFS 527 : Dispatch - Request - PO Tab: Insert EventLog when Hagerty VIP member uses the service*/
                logger.InfoFormat("Executing GetPOIssueHagertyEventMailTag for Purchase Order ID {0}", po.ID);
                List<POIssueHagertyEventMailTag_Result> poTagResult = repository.GetPOIssueHagertyEventMailTag(po.ID);

                var clientMemberType = poTagResult.Where(u => u.ColumnName.Equals("ClientMemberType", StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                var client = poTagResult.Where(u => u.ColumnName.Equals("Client", StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                var memberID = poTagResult.Where(u => u.ColumnName.Equals("MemberId", StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                var programCode = poTagResult.Where(u => u.ColumnName.Equals("ProgramCode", StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                var programName = poTagResult.Where(u => u.ColumnName.Equals("ProgramName", StringComparison.OrdinalIgnoreCase)).FirstOrDefault();


                #region TFS 972 & 980 : Creating event log if program is either 'EFG Patterson' or 'Service Contract - EFG'.
                if ((ProgramNames.EFG_PATTERSON.Equals(programName.ColumnValue, StringComparison.InvariantCultureIgnoreCase)) || (ProgramNames.EFG_SERVICE_CONTRACT.Equals(programName.ColumnValue, StringComparison.InvariantCultureIgnoreCase)))
                {
                    logger.InfoFormat("Creating an event log for {0} program", programName.ColumnValue);
                    int memberIDInteger = 0;
                    int.TryParse(memberID.ColumnValue, out memberIDInteger);

                    string eventName = (ProgramNames.EFG_PATTERSON.Equals(programName.ColumnValue, StringComparison.InvariantCultureIgnoreCase)) ? EventNames.EFG_PATTERSON_ISSUED_PO : EventNames.EFG_SERVICE_CONTRACT_ISSUED_PO;
                    string eventDescription = (ProgramNames.EFG_PATTERSON.Equals(programName.ColumnValue, StringComparison.InvariantCultureIgnoreCase)) ? "Patterson Issued a PO" : "Service Contract - EFG Issued a PO";

                    InsertEventLogForPOIssued(po, currentUser, eventSource, sessionId, poTagResult, memberIDInteger, caseobj.ProgramID, program != null ? program.ClientID : null, eventName, eventDescription);
                }
                #endregion

                if (clientMemberType != null && client != null && memberID != null)
                {
                    int memberIDInteger = 0;
                    int.TryParse(memberID.ColumnValue, out memberIDInteger);

                    logger.InfoFormat("Comparing Client Member Type {0} and Client Name {1}", clientMemberType.ColumnValue, client.ColumnValue);
                    if ((clientMemberType.ColumnValue == "VIP" || clientMemberType.ColumnValue == "PCS") && client.ColumnValue == "Hagerty")
                    {
                        string eventName = clientMemberType.ColumnValue.Equals("VIP") ? EventNames.HAGERTY_VIP_ISSUED_PO : EventNames.HAGERTY_PCS_ISSUED_PO;
                        string eventDescription = clientMemberType.ColumnValue.Equals("VIP") ? "Hagerty VIP PO Issued Notification" : "Hagerty PCS PO Issued Notification";

                        InsertEventLogForPOIssued(po, currentUser, eventSource, sessionId, poTagResult, memberIDInteger, caseobj.ProgramID, program != null ? program.ClientID : null, eventName, eventDescription);
                    }
                }
                else
                {
                    logger.Info("Key records are not found or it's null for ClientMemberType,Client and MemberId");
                }
                if (programCode != null &&
                    client != null &&
                    memberID != null &&
                    "Hagerty".Equals(client.ColumnValue, StringComparison.InvariantCultureIgnoreCase) &&
                    "HPNSPCL".Equals(programCode.ColumnValue, StringComparison.InvariantCultureIgnoreCase) &&
                    (clientMemberType == null || (clientMemberType.ColumnValue != "VIP" && clientMemberType.ColumnValue != "PCS"))
                    )
                {
                    int memberIDInteger = 0;
                    int.TryParse(memberID.ColumnValue, out memberIDInteger);

                    string eventName = EventNames.HAGERTY_SPECIAL_ISSUED_PO;
                    string eventDescription = "Hagerty Special Program Member Issued a PO";

                    InsertEventLogForPOIssued(po, currentUser, eventSource, sessionId, poTagResult, memberIDInteger, caseobj.ProgramID, program != null ? program.ClientID : null, eventName, eventDescription);
                }
                #endregion

                #region TFS 657 : Send Novum client email when the first PO is issued on an SR


                if (programCode != null &&
                    client != null &&
                    memberID != null &&
                     "Novum".Equals(client.ColumnValue, StringComparison.InvariantCultureIgnoreCase)
                    )
                {
                    int memberIDInteger = 0;
                    int.TryParse(memberID.ColumnValue, out memberIDInteger);

                    string eventName = EventNames.NOVUM_ISSUED_PO;
                    string eventDescription = " Novum PO Issued Notification";
                    InsertEventLogForPOIssued(po, currentUser, eventSource, sessionId, poTagResult, memberIDInteger, caseobj.ProgramID, program != null ? program.ClientID : null, eventName, eventDescription);
                }

                #endregion

                tran.Complete();
            }
        }

        /// <summary>
        /// Inserts the event log for po issued.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionId">The session identifier.</param>
        /// <param name="poTagResult">The po tag result.</param>
        /// <param name="memberIDInteger">The member identifier integer.</param>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="eventDescription">The event description.</param>
        private static void InsertEventLogForPOIssued(PurchaseOrder po, string currentUser, string eventSource, string sessionId, List<POIssueHagertyEventMailTag_Result> poTagResult, int memberIDInteger, int? programID, int? clientID, string eventName, string eventDescription)
        {
            var eventLoggerFacade = new EventLoggerFacade();
            EventLogRepository eventLogRepository = new EventLogRepository();
            bool doesEventLogLinkExists = eventLogRepository.DoesEventLogLinkExists(po.ServiceRequestID, EntityNames.SERVICE_REQUEST, eventName);
            if (!doesEventLogLinkExists)
            {
                Hashtable PoTempValues = new Hashtable();
                poTagResult.ForEach(x =>
                {
                    PoTempValues.Add(x.ColumnName, x.ColumnValue);
                });

                long eventLogId = eventLoggerFacade.LogEvent(eventSource, eventName, eventDescription, new PORepository().GetXML(PoTempValues), currentUser, po.ServiceRequestID, EntityNames.SERVICE_REQUEST, sessionId);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogId, po.ID, EntityNames.PURCHASE_ORDER);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogId, memberIDInteger, EntityNames.MEMBER);

                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogId, programID, EntityNames.PROGRAM);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogId, clientID, EntityNames.CLIENT);

            }
        }

        /// <summary>
        /// Gets the member pay dispatch fee.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public string GetMemberPayDispatchFee(int programId)
        {
            return new PORepository().GetMemberPayDispatchFee(programId);
        }


        /// <summary>
        /// Updates the po service eligibility.
        /// </summary>
        /// <param name="po">The po.</param>
        public void UpdatePOServiceEligibility(PurchaseOrder po)
        {
            PORepository rep = new PORepository();
            rep.UpdatePOServiceEligibility(po);
        }

        /// <summary>
        /// Adds the or update PO.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="mode">The mode.</param>
        /// <param name="poDetails">The po details.</param>
        /// <param name="isp">The isp.</param>
        /// <param name="programID">The program ID.</param>
        /// <param name="source">The source.</param>
        /// <param name="sessionId">The session id.</param>
        /// <returns></returns>
        public PurchaseOrder AddOrUpdatePO(PurchaseOrder po, string mode, List<PurchaseOrderDetailsModel> poDetails, ISPs_Result isp, int programID, string source, string sessionId, int? vendorID = null, bool isPoPaymentEditAllowed = false)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                //NP 9/18: Adding ServiceRating and other 3 column values to Purchase Order table. Ref: Bug 1621
                PORepository repository = new PORepository();
                if (vendorID != null)
                {
                    //ContractStatu contractStatus = new VendorManagementRepository().GetVendorContractStatusID(vendorID.GetValueOrDefault());
                    Vendor vendor = new VendorManagementRepository().Get(vendorID.GetValueOrDefault());
                    VendorLocationProduct vlp = new PORepository().GetVendorLocationProduct(po.VendorLocationID, po.ProductID);
                    string contractStatus = new PORepository().GetContractStatus(vendorID.Value);
                    po.ServiceRating = vlp != null ? vlp.Rating : null;
                    po.ContractStatus = (!string.IsNullOrEmpty(contractStatus)) ? contractStatus : null;
                    po.AdminstrativeRating = vendor.AdministrativeRating;
                }
                if (isp != null)
                {
                    po.SelectionOrder = isp.SelectionOrder;
                }
                //NP 9/18: End 
                if (mode == "CopyPO")
                {

                }
                po = new PORepository().AddOrUpdatePO(po, mode, poDetails, isp, programID, isPoPaymentEditAllowed);

                //Bug 332 update po service eligibility fields if product changed.
                if ("Edit".Equals(mode, StringComparison.InvariantCultureIgnoreCase))
                {

                    ServiceRequest sr = repository.GetSRByPO(po.ID);
                    Case caseobj = new CaseFacade().GetCaseById(sr.CaseID);
                    int? towCategoryId = null;
                    foreach (PurchaseOrderDetailsModel item in poDetails)
                    {
                        towCategoryId = null;
                        if (item.Mode == "Update")
                        {
                            bool isproductChanged = repository.IsPODetailItemProductChanged(item, programID, po.VehicleCategoryID);
                            if (isproductChanged)
                            {
                                Product p = ReferenceDataRepository.GetProductById(item.ProductID.GetValueOrDefault());
                                int? productCategoryId = p.ProductCategoryID;

                                if (sr.IsPossibleTow.GetValueOrDefault())
                                {
                                    ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                                    if (pc != null)
                                    {
                                        towCategoryId = pc.ID;
                                    }
                                }

                                ServiceEligibilityModel model = new ServiceFacade().GetServiceEligibilityModel(programID, productCategoryId, item.ProductID, caseobj.VehicleTypeID, po.VehicleCategoryID, towCategoryId, po.ServiceRequestID, sr.CaseID, SourceSystemName.DISPATCH, false, true);
                                if ("Base".Equals(item.RateType.Description, StringComparison.InvariantCultureIgnoreCase) || "Hourly".Equals(item.RateType.Description, StringComparison.InvariantCultureIgnoreCase))
                                {
                                    po.ProductID = item.ProductID;
                                }
                                po.IsServiceCovered = model.IsPrimaryOverallCovered;
                                po.CoverageLimit = model.PrimaryCoverageLimit;
                                po.CoverageLimitMileage = model.PrimaryCoverageLimitMileage;
                                po.MileageUOM = model.MileageUOM;
                                po.IsServiceCoverageBestValue = model.IsServiceCoverageBestValue;
                                po.ServiceEligibilityMessage = model.PrimaryServiceEligiblityMessage;
                                repository.UpdatePOServiceEligibility(po);
                            }
                        }
                    }
                }

                string eventName = EventNames.CREATE_PO;
                string eventDescription = "Create PO";
                switch (mode.ToLower())
                {
                    case "gotopo":
                        {
                            eventName = EventNames.ACCEPT_CREATE_PO;
                            eventDescription = "Accept Create PO";
                            break;
                        }
                    case "edit":
                        {
                            eventName = EventNames.UPDATE_PO;
                            eventDescription = "Update PO";
                            break;
                        }
                    case "copypo":
                        {
                            eventName = EventNames.COPY_PO;
                            eventDescription = "Copy PO";
                            break;
                        }
                }
                //KB : TFS 298

                if (!"POChangeService".Equals(mode))
                {
                    EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                    eventLoggerFacade.LogEvent(source, eventName, eventDescription, po.ModifyBy, po.ID, EntityNames.PURCHASE_ORDER, sessionId);
                }
                tran.Complete();
            }
            return po;
        }

        public void ReIssueCC(int poId, string sourceSystem, string user, string sessionId)
        {

            PORepository po = new PORepository();
            po.ReIssueCC(poId, user);

            EventLoggerFacade facade = new EventLoggerFacade();

            string eventDetails = "Re-Issued Temporary CC for PO ID " + poId.ToString();
            long eventLogId = facade.LogEvent(sourceSystem, EventNames.REISSUED_TEMPORARY_CC, eventDetails, user, sessionId);

            facade.CreateRelatedLogLinkRecord(eventLogId, poId, EntityNames.PURCHASE_ORDER);



        }

        public void SaveServiceCovered(int poId, bool isServiceCovered, string loggedInUserName, string eventSource, string sessionID, string serviceCoveredOverridenInstructions)
        {
            EventLoggerFacade facade = new EventLoggerFacade();
            string eventDetails = "Override PO Service Covered  " + poId.ToString();
            eventDetails += " <Comment>" + serviceCoveredOverridenInstructions + "</Comment>";
            long eventLogId = facade.LogEvent(eventSource, EventNames.EVENT_OVERRIDEPOSERVICECOVERED, eventDetails, loggedInUserName, sessionID);
            facade.CreateRelatedLogLinkRecord(eventLogId, poId, EntityNames.PURCHASE_ORDER);
        }

        public bool CanReissueCC(int poId)
        {
            return new PORepository().CanReissueCC(poId);
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
            return new PORepository().IsDealTow(programId);
        }

        /// <summary>
        /// Gets the send PO history.
        /// </summary>
        /// <param name="purchaseOrderId">The purchase order id.</param>
        /// <returns></returns>
        public List<SendPOHistory_Result> GetSendPOHistory(int purchaseOrderId)
        {
            return new PORepository().GetSendPOHistory(purchaseOrderId);
        }

        /// <summary>
        /// Disables the PO
        /// </summary>
        /// <param name="poid">The poid.</param>
        public void PODisable(int poid, string currentUser)
        {
            logger.InfoFormat("POFacade - PODisable(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poid,
                currentUser = currentUser
            }));
            new PORepository().PODisable(poid, currentUser);
        }

        /// <summary>
        /// Deletes the PO
        /// </summary>
        /// <param name="poid">The poid.</param>
        /// <param name="currentUser">The current user.</param>
        public void PODelete(int poid, string currentUser)
        {
            logger.InfoFormat("POFacade - PODelete(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poid,
                currentUser = currentUser
            }));
            new PORepository().PODelete(poid, currentUser);
        }

        /// <summary>
        /// Logs the Change of Service for PO
        /// </summary>
        /// <param name="oldpo">The oldpo.</param>
        /// <param name="newpo">The newpo.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionId">The session identifier.</param>
        public void POLogChangeService(PurchaseOrder oldpo, PurchaseOrder newpo, string eventSource, string currentUser, string sessionId)
        {
            logger.InfoFormat("POFacade - POLogChangeService(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                oldPOID = oldpo.ID,
                newPOID = newpo.ID,
                currentUser = currentUser
            }));
            EventLoggerFacade eventLogFacade = new EventLoggerFacade();
            Product odlProduct = ReferenceDataRepository.GetProductById(oldpo.ProductID.GetValueOrDefault());
            int? oldproductCategoryId = (odlProduct != null) ? odlProduct.ProductCategoryID : null;


            Product newProduct = ReferenceDataRepository.GetProductById(newpo.ProductID.GetValueOrDefault());
            int? newproductCategoryId = (newProduct != null) ? newProduct.ProductCategoryID : null;

            List<VehicleCategory> vehicleCategorylist = ReferenceDataRepository.GetVehicleCategories();
            List<ProductCategory> productcategoryList = ReferenceDataRepository.GetProductCategories();

            var wcBefore = vehicleCategorylist.Where(x => x.ID == oldpo.VehicleCategoryID).FirstOrDefault();
            var wcAfter = vehicleCategorylist.Where(x => x.ID == newpo.VehicleCategoryID).FirstOrDefault();

            var pcBefore = productcategoryList.Where(x => x.ID == oldproductCategoryId).FirstOrDefault();
            var pcAfter = productcategoryList.Where(x => x.ID == newproductCategoryId).FirstOrDefault();


            Hashtable ht = new Hashtable();
            ht.Add("WeightClassBefore", wcBefore != null ? wcBefore.Name : string.Empty);
            ht.Add("WeightClassAfter", wcAfter != null ? wcAfter.Name : string.Empty);
            ht.Add("ServiceTypeBefore", pcBefore != null ? pcBefore.Name : string.Empty);
            ht.Add("ServiceTypeAfter", pcAfter != null ? pcAfter.Name : string.Empty);
            long eventLogID = eventLogFacade.LogEvent(eventSource, EventNames.EVENT_PO_CHANGE_SERVICE, ht.GetMessageData(true), currentUser, sessionId);
            eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, oldpo.ID, EntityNames.PURCHASE_ORDER);
            eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, newpo.ID, EntityNames.PURCHASE_ORDER);

        }
        /// <summary>
        /// POs the leave tab.
        /// </summary>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionId">The session id.</param>
        /// <param name="relatedRecord">The related record.</param>
        /// <param name="entityName">Name of the entity.</param>
        public static void POLeaveTab(string eventSource, string currentUser, string sessionId, int relatedRecord, string entityName)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ServiceRequestRepository serviceRepository = new ServiceRequestRepository();
                serviceRepository.UpdateTabStatus(relatedRecord, TabConstants.POTab, currentUser);

                tran.Complete();
            }

        }

        /// <summary>
        /// Creates the goto PO contact log.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="relatedRecord">The related record.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Contact Type - Vendor is not set up in the system
        /// or
        /// Contact Method - Phone is not set up in the system
        /// or
        /// Contact Category - VendorSelection is not set up in the system
        /// or
        /// Contact Source - Vendor for category : VendorSelection is not set up in the system
        /// or
        /// ContactReason - ISP selection is not set up for category - VendorSelection
        /// or
        /// contactAction - for Negotiate not available
        /// </exception>
        public int? CreateGotoPOContactLog(GoToPOModel model, string currentUser, int relatedRecord, string entityName, int? LastVendorContactLogID)
        {
            int? returnValue = null;
            using (TransactionScope tran = new TransactionScope())
            {
                #region 1. Create ContactLog and Link record for service request
                var contactLogRepository = new ContactLogRepository();

                ContactLog contactLog = new ContactLog();
                if (LastVendorContactLogID == null)
                {
                    contactLog.ContactSourceID = null; //TODO : Where from do we get this ?
                    contactLog.TalkedTo = model.TalkedTo;
                    contactLog.Company = model.VendorName;
                    contactLog.PhoneTypeID = null; // TODO: Where from would we get this ?
                    contactLog.PhoneNumber = model.PhoneNumber;
                    contactLog.Direction = "Outbound";
                    contactLog.CreateBy = currentUser;
                    contactLog.CreateDate = DateTime.Now;
                    contactLog.ModifyBy = currentUser;
                    contactLog.ModifyDate = DateTime.Now;
                } else
                {
                    contactLog.ID = LastVendorContactLogID.GetValueOrDefault();
                    contactLog.ContactSourceID = null; //TODO : Where from do we get this ?
                    contactLog.TalkedTo = model.TalkedTo;
                    contactLog.Company = model.VendorName;
                    contactLog.PhoneTypeID = null; // TODO: Where from would we get this ?
                    contactLog.PhoneNumber = model.PhoneNumber;
                    contactLog.Direction = "Outbound";
                    contactLog.CreateBy = currentUser;
                    contactLog.CreateDate = DateTime.Now;
                    contactLog.ModifyBy = currentUser;
                    contactLog.ModifyDate = DateTime.Now;
                }

                // Get the phone Type ID
                PhoneRepository phoneRepository = new PhoneRepository();
                PhoneType phoneType = phoneRepository.GetPhoneTypeByName(model.PhoneType);
                if (phoneType == null)
                {
                    throw new DMSException(string.Format("Phone type - {0} is not set up in the system", model.PhoneType));
                }

                if (phoneType != null)
                {
                    contactLog.PhoneTypeID = phoneType.ID;
                }
                // Get Contactcategory, method, type and Source

                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactType vendorType = staticDataRepo.GetTypeByName("Vendor");
                if (vendorType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }

                contactLog.ContactTypeID = vendorType.ID;
                ContactMethod contactMethod = staticDataRepo.GetMethodByName("Phone");
                if (contactMethod == null)
                {
                    throw new DMSException("Contact Method - Phone is not set up in the system");
                }
                contactLog.ContactMethodID = contactMethod.ID;

                ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("VendorSelection");
                if (contactCategory == null)
                {
                    throw new DMSException("Contact Category - VendorSelection is not set up in the system");
                }

                contactLog.ContactCategoryID = contactCategory.ID;

                ContactSource contactSource = staticDataRepo.GetContactSourceByName("VendorData", "VendorSelection");
                if (contactSource == null)
                {
                    throw new DMSException("Contact Source - Vendor for category : VendorSelection is not set up in the system");
                }
                contactLog.ContactSourceID = contactSource.ID;


                contactLogRepository.Save(contactLog, currentUser, relatedRecord, entityName);
                #endregion

                #region 2. Add a link record to VendorLocation
                contactLogRepository.CreateLinkRecord(contactLog.ID, EntityNames.VENDOR_LOCATION, model.VendorLocationID);
                #endregion

                #region 3. Create a contactLogReason record

                ContactLogReasonRepository contactLogReasonRepo = new ContactLogReasonRepository();
                ContactLogReason reason = new ContactLogReason()
                {
                    ContactLogID = contactLog.ID
                };

                ContactReason contactReason = staticDataRepo.GetContactReason("ISP selection", "VendorSelection");
                if (contactReason == null)
                {
                    throw new DMSException("ContactReason - ISP selection is not set up for category - VendorSelection");
                }
                reason.ContactReasonID = contactReason.ID;

                contactLogReasonRepo.Save(reason, currentUser);
                #endregion

                #region 4. Create a contactLogAction record.

                ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                ContactAction contactAction = staticDataRepo.GetContactActionByName("Negotiate");
                if (contactAction == null)
                {
                    throw new DMSException("contactAction - for Negotiate not available");
                }
                ContactLogAction logAction = new ContactLogAction()
                {
                    ContactLogID = contactLog.ID,
                    ContactActionID = contactAction.ID
                };

                logActionRepo.Save(logAction, currentUser);
                returnValue = contactLog.ID;
                #endregion
                tran.Complete();
            }
            return returnValue;
        }

        /// <summary>
        /// Gets the product by ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public Product GetProductByID(int id)
        {
            return new PORepository().GetProductByID(id);
        }

        /// <summary>
        /// Gets the name of the product by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public Product GetProductByName(string name)
        {
            return new PORepository().GetProductByName(name);
        }

        /// <summary>
        /// Gets the ratetype by ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public RateType GetRatetypeByID(int id)
        {
            return new PORepository().GetRatetypeByID(id);
        }

        /// <summary>
        /// Gets the vendor rate.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorRates_Result> GetVendorRate(PageCriteria pageCriteria, int VendorLocationID)
        {
            return new PORepository().GetVendorRate(pageCriteria, VendorLocationID);
        }

        public PO_ChangedPrimaryProduct_Result GetChangedPrimaryServiceProduct(int purchaseOrderID)
        {
            return new PORepository().GetChangedPrimaryServiceProduct(purchaseOrderID);
        }

        public Case GetCaseForPO(int poId)
        {
            return new PORepository().GetCaseForPO(poId);
        }

        public bool IsPaymentAllowed(int programId)
        {
            return new PORepository().IsPaymentAllowed(programId);
        }

        public int? GetVendorSelectionContactLog(int serviceRequestId, int? vendorLocationId)
        {
            return new PORepository().GetVendorSelectionContactLog(serviceRequestId, vendorLocationId);
        }

        public void UpdatePOPaymentStatus(int poId, int? payStatusCodeID)
        {
            new PORepository().UpdatePOPaymentStatus(poId, payStatusCodeID);
        }

        #endregion

        public void SaveSRActivityContact(Activity_AddContact model, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactLogRepository contactRepository = new ContactLogRepository();
                VendorInvoiceRepository vendorInvoiceRepo = new VendorInvoiceRepository();
                string direction = "";
                if (model.IsInbound)
                {
                    direction = "Inbound";
                }
                else
                {
                    direction = "Outbound";
                }
                ContactType contactType = staticDataRepo.GetTypeByName("Vendor");
                if (contactType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }
                ContactLog contactLog = new ContactLog();
                contactLog.ContactCategoryID = model.ContactCategory;
                contactLog.ContactTypeID = contactType.ID;
                contactLog.ContactMethodID = model.ContactMethod;
                contactLog.TalkedTo = model.TalkedTo;
                contactLog.PhoneNumber = model.PhoneNumber;
                if (model.PhoneNumberType > 0)
                {
                    contactLog.PhoneTypeID = model.PhoneNumberType;
                }
                contactLog.Email = model.Email;
                contactLog.Direction = direction;
                contactLog.Description = "PO Edit Service Request Add Contact";
                contactLog.Comments = model.Notes;
                contactLog.CreateBy = currentUser;
                contactLog.CreateDate = DateTime.Now;

                vendorInvoiceRepo.SaveContactLog(contactLog);
                int contactLogID = contactLog.ID;
                foreach (var reasonRecord in model.ContactReasonID)
                {
                    ContactLogReason contactLogReason = new ContactLogReason();
                    contactLogReason.ContactLogID = contactLogID;
                    if (reasonRecord.HasValue)
                    {
                        contactLogReason.ContactReasonID = reasonRecord.GetValueOrDefault();
                    }
                    contactLogReason.CreateBy = currentUser;
                    contactLogReason.CreateDate = DateTime.Now;
                    vendorInvoiceRepo.SaveContactLogReason(contactLogReason);
                }

                foreach (var actionRecord in model.ContactActionID)
                {
                    ContactLogAction contactLogAction = new ContactLogAction();
                    contactLogAction.ContactLogID = contactLogID;
                    if (actionRecord.HasValue)
                    {
                        contactLogAction.ContactActionID = actionRecord.GetValueOrDefault();
                    }
                    contactLogAction.CreateBy = currentUser;
                    contactLogAction.CreateDate = DateTime.Now;
                    vendorInvoiceRepo.SaveContactLogAction(contactLogAction);
                }
                contactRepository.CreateLinkRecord(contactLogID, EntityNames.SERVICE_REQUEST, model.ServiceRequestID);
                //contactRepository.CreateLinkRecord(contactLogID, EntityNames.VENDOR, model.VendorID);
                tran.Complete();
            }
        }

        public void SaveSRActivityComments(int CommentType, string Comments, int serviceRequsetID, string currentuser)
        {
            PORepository repository = new PORepository();
            Comment comment = new Comment();
            comment.RecordID = serviceRequsetID;
            comment.CommentTypeID = CommentType;
            comment.Description = Comments;
            comment.CreateBy = currentuser;
            comment.CreateDate = DateTime.Now;
            repository.SaveSRActivityComments(comment);
        }

        public Vendor GetVendorDetails(int vendorLocationId)
        {
            PORepository repository = new PORepository();
            return repository.GetVendorDetails(vendorLocationId);
        }

        public List<VendorInvoice> GetVendorInvoices(int poId)
        {
            PORepository repository = new PORepository();
            return repository.GetVendorInvoices(poId);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="poID"></param>
        /// <param name="ccNumber"></param>
        /// <param name="userName"></param>
        /// <param name="sessionID"></param>
        /// <param name="pageReferennce"></param>
        public void UpdateCompanyCCNumber(int poID, string ccNumber, string userName, string sessionID, string pageReferennce)
        {

            PORepository repository = new PORepository();
            PurchaseOrder previousDetails = repository.GetPOById(poID);

            using (TransactionScope transaction = new TransactionScope())
            {
                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();

                string eventData = string.Format("<MessageData><After>{1}</After><Before>{0}</Before></MessageData>", previousDetails.CompanyCreditCardNumber, ccNumber);
                string eventDescription = eventLoggerFacade.GetEventByName(EventNames.EDIT_CC_NUMBER_ON_PO).Description;
                eventLoggerFacade.LogEvent(pageReferennce, EventNames.EDIT_CC_NUMBER_ON_PO, eventDescription, eventData, userName, poID, EntityNames.PURCHASE_ORDER, sessionID);

                repository.UpdateCompanyCCNumber(poID, ccNumber, userName);
                transaction.Complete();
            }
        }

        /// <summary>
        /// Gets the sr by po.
        /// </summary>
        /// <param name="poId">The po identifier.</param>
        /// <returns></returns>
        public ServiceRequest GetSRByPO(int poId)
        {
            var poRepository = new PORepository();
            return poRepository.GetSRByPO(poId);
        }

        /// <summary>
        /// Views the po document.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="talkedTo">The talked to.</param>
        /// <param name="vendorName">Name of the vendor.</param>
        /// <returns></returns>
        public string ViewPODocument(PurchaseOrder po, string talkedTo, string vendorName)
        {
            string poDocument = new PORepository().ViewPODocument(po, talkedTo, vendorName);
            return poDocument;
        }

        /// <summary>
        /// Determines whether [is po payment edit allowed] [the specified po identifier].
        /// </summary>
        /// <param name="poId">The po identifier.</param>
        /// <param name="roleNames">The role names.</param>
        /// <returns></returns>
        public bool IsPoPaymentEditAllowed(int poId, string[] roleNames)
        {
            return new PORepository().IsPoPaymentEditAllowed(poId, roleNames);
        }

        /// <summary>
        /// Updates the po on approval.
        /// </summary>
        /// <param name="purchaseOrderID">The purchase order identifier.</param>
        /// <param name="approvalDetails">The approval details.</param>
        public void UpdatePOOnApproval(int purchaseOrderID, int serviceRequestID, EstimateApprovalModel approvalDetails, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                var poRepository = new PORepository();
                poRepository.UpdateApprovalDetails(purchaseOrderID, approvalDetails, currentUser);

                #region 1. Create contactLog record
                var contactLogRepository = new ContactLogRepository();
                ContactLog contactLog = new ContactLog()
                {
                    ContactSourceID = null,
                    TalkedTo = approvalDetails.TalkedToForApproval,
                    PhoneTypeID = approvalDetails.PhoneTypeID,
                    PhoneNumber = approvalDetails.PhoneNumberCalled,
                    Direction = "Outbound",
                    Description = "Approve estimate overage",
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    Comments = approvalDetails.Comments
                };


                // Get Contactcategory, method, type and Source
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactType memberType = staticDataRepo.GetTypeByName("Member");
                if (memberType == null)
                {
                    throw new DMSException("Contact Type - Member is not set up in the system");
                }

                contactLog.ContactTypeID = memberType.ID;
                ContactMethod contactMethod = staticDataRepo.GetMethodByName("Phone");
                if (contactMethod == null)
                {
                    throw new DMSException("Contact Method - Phone is not set up in the system");
                }
                contactLog.ContactMethodID = contactMethod.ID;

                ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("MemberPayEstimate");
                if (contactCategory == null)
                {
                    throw new DMSException("Contact Category - MemberPayEstimate is not set up in the system");
                }
                contactLog.ContactCategoryID = contactCategory.ID;

                ContactSource contactSource = staticDataRepo.GetContactSourceByName("ServiceRequest", "MemberPayEstimate");
                if (contactSource == null)
                {
                    throw new DMSException("Contact Source - ServiceRequest for category : MemberPayEstimate is not set up in the system");
                }
                contactLog.ContactSourceID = contactSource.ID;

                contactLogRepository.Save(contactLog, currentUser, serviceRequestID, EntityNames.SERVICE_REQUEST);

                #endregion

                #region 3. Create ContactLogReason
                var contactReason = staticDataRepo.GetContactReason("ApproveOverage", "MemberPayEstimate");
                if (contactReason == null)
                {
                    throw new DMSException("Contact Reason - ApproveOverage is not set up in the system");
                }
                if (contactReason != null)
                {
                    ContactLogReasonRepository contactLogReasonRepo = new ContactLogReasonRepository();
                    ContactLogReason reason = new ContactLogReason()
                    {
                        ContactLogID = contactLog.ID,
                        ContactReasonID = contactReason.ID
                    };
                    contactLogReasonRepo.Save(reason, currentUser);
                }

                #endregion

                #region 4. Create ContactLogAction

                if (approvalDetails.ContactActionID != null)
                {
                    ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                    ContactLogAction logAction = new ContactLogAction()
                    {
                        ContactLogID = contactLog.ID,
                        ContactActionID = approvalDetails.ContactActionID,
                        Comments = approvalDetails.Comments
                    };

                    logActionRepo.Save(logAction, currentUser);
                }

                #endregion

                tran.Complete();
            }


        }

        /// <summary>
        /// Submits the manager approval threshold.
        /// </summary>
        /// <param name="poId">The po identifier.</param>
        /// <param name="isManagerApprovedThreshold">if set to <c>true</c> [is manager approved threshold].</param>
        /// <param name="managerApprovalPIN">The manager approval pin.</param>
        /// <param name="managerApprovalComments">The manager approval comments.</param>
        /// <param name="approvedUserName">Name of the approved user.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="source">The source.</param>
        /// <param name="sessionId">The session identifier.</param>
        public void SubmitManagerApprovalThreshold(int poId, bool isManagerApprovedThreshold, int managerApprovalPIN, string managerApprovalComments, int? approvedUserId, string approvedUserName, decimal? serviceTotal, decimal? serviceMax, string loggedInUserName, string source, string sessionId)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                var poRepository = new PORepository();
                poRepository.UpdateManagerApprovalDetails(poId, isManagerApprovedThreshold, approvedUserName,serviceTotal, loggedInUserName);

                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                var poOverThresholdDecision = isManagerApprovedThreshold ? "Approved" : "Rejected";
                Hashtable ht = new Hashtable();
                ht.Add("POOverThresholdManagerResponse", poOverThresholdDecision);
                ht.Add("PoOverThresholdManager", approvedUserName);
                ht.Add("POOverThresholdServiceTotal", "$"+serviceTotal);
                ht.Add("PoOverThresholdServiceMax", "$" + serviceMax);
                ht.Add("PoOverThresholdManagerComments", managerApprovalComments);
                string eventData = ht.GetEventDetail(true);
                string eventDescription = "PO Over Threshold Manager Approval";
                string eventName = isManagerApprovedThreshold ? EventNames.PO_THRESHOLD_APPROVED : EventNames.PO_THRESHOLD_REJECTED;
                long eventLogId = eventLoggerFacade.LogEvent(source, eventName, eventDescription, eventData, loggedInUserName, poId, EntityNames.PURCHASE_ORDER, sessionId);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogId, approvedUserId, EntityNames.USER);

                tran.Complete();
            }
        }

        public PurchaseOrder GetPOByNumber(string poNumber)
        {
            PORepository repository = new PORepository();
            return repository.GetPOByNumber(poNumber);
        }
    }
}
