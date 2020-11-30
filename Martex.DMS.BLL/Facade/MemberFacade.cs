using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;
using System.Transactions;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.DAL.DMSBaseException;
using log4net;
using Martex.DMS.BLL.HagertyPlusService; //Lakshmi - Hagerty Integration 
using System.ServiceModel;  //Lakshmi - Hagerty Integration 
using Martex.DMS.BLL.Model;  //Lakshmi - Hagerty Integration 
using Martex.DMS.BLL.Common; //Lakshmi - Hagerty Integration
using System.Collections;
using Newtonsoft.Json;
using Martex.DMS.BLL.DataValidators;


namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade Manages Member
    /// </summary>
    public class MemberFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(MemberFacade));

        #endregion

        #region Public Methods

        /// <summary>
        /// Used to Insert a new Record.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Error While creating Membership record !
        /// or
        /// Error while creating Member record !
        /// or
        /// Invalid event name
        /// </exception>
        public bool Save(MemberModel model, string userName, string sessionID)
        {
            logger.InfoFormat("MemeberFacade - Save(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                MemberModel = model,
                userName = userName,
                sessionID = sessionID
            }));

            CommonLookUpRepository repository = new CommonLookUpRepository();
            string suffix = null;
            string prefix = null;

            if (model.Suffix != null)
            {
                suffix = repository.GetSuffix(model.Suffix.Value).Name;
            }
            if (model.Prefix != null)
            {
                prefix = repository.GetPrefix(model.Prefix.Value).Name;
            }

            // TFS:2256 : Update Membership.MembershipNumber in some situations [ When ProgramConfig has InsertMembershipNumber set to Yes ].

            var progRepository = new ProgramMaintenanceRepository();
            var programConfigs = progRepository.GetProgramInfo(model.ProgramID, "Application", "Rule");
            bool updateMembershipNumber = programConfigs.Where(p => p.Name.Equals("InsertMembershipNumber", StringComparison.InvariantCultureIgnoreCase) && p.Value.Equals("Yes", StringComparison.InvariantCultureIgnoreCase)).Count() > 0;

            logger.InfoFormat("Update MembershipNumber from Program {0} is evaluated to be {1}", model.ProgramID, updateMembershipNumber);

            // Do We want to log all Addresses ?
            Dictionary<string, string> eventDetails = new Dictionary<string, string>();
            //TFS : 610
            //eventDetails.Add("ClientReferenceNumber", model.ClientReferenceNumber);
            eventDetails.Add("Program", model.ProgramID_input.BlankIfNull());
            eventDetails.Add("Prefix", model.Prefix_input.BlankIfNull());
            eventDetails.Add("FirstName", model.FirstName.BlankIfNull());
            eventDetails.Add("MiddleName", model.MiddleName.BlankIfNull());
            eventDetails.Add("LastName", model.LastName.BlankIfNull());
            eventDetails.Add("Suffix", model.Suffix_input.BlankIfNull());
            eventDetails.Add("PhoneType", model.PhoneNumber_ddlPhoneType_input.BlankIfNull());
            eventDetails.Add("PhoneNumber", model.PhoneNumber.BlankIfNull());
            eventDetails.Add("Address1", model.AddressLine1.BlankIfNull());
            eventDetails.Add("Address2", model.AddressLine2.BlankIfNull());
            eventDetails.Add("Address3", model.AddressLine3.BlankIfNull());
            eventDetails.Add("City", model.City.BlankIfNull());
            eventDetails.Add("Country", model.Country_input.BlankIfNull());
            eventDetails.Add("State", model.State_input.BlankIfNull());
            eventDetails.Add("Zip", model.PostalCode.BlankIfNull());
            eventDetails.Add("Email", model.Email.BlankIfNull());
            eventDetails.Add("EffectiveDate", model.EffectiveDate != null ? model.EffectiveDate.Value.ToString("MM/dd/yyyy") : string.Empty);
            eventDetails.Add("ExpirationDate", model.ExpirationDate != null ? model.ExpirationDate.Value.ToString("MM/dd/yyyy") : string.Empty);

            if (model.DynamicDataElements != null && model.DynamicDataElements.Count > 0)
            {
                logger.Info("Adding dynamic elements to the Event Log");
                //TFS : 1008
                foreach (var item in model.DynamicDataElements)
                {
                    var key = item.Key.Split('$')[0];
                    if (!eventDetails.ContainsKey(key))
                    {
                        eventDetails.Add(key, item.Value.BlankIfNull());
                    }
                }
            }
            var currentProgram = progRepository.Get(model.ProgramID.GetValueOrDefault());
            string clientName = string.Empty;
            if (currentProgram != null)
            {
                clientName = currentProgram.Client.Name;
            }

            using (TransactionScope tran = new TransactionScope())
            {

                Membership membership = model.ToMembership(userName);

                //TFS : 610
                //if (updateMembershipNumber && !string.IsNullOrEmpty(model.ClientReferenceNumber))
                //{
                //    membership.MembershipNumber = model.ClientReferenceNumber;
                //    logger.InfoFormat("Set the MS # to {0}", model.ClientReferenceNumber);
                //}
                Member member = model.ToMember(userName);

                member.Prefix = prefix;
                member.Suffix = suffix;

                // Set the source system to "Dispatch"
                var sourceSystemFromDB = ReferenceDataRepository.GetSourceSystemByName("Dispatch");
                if (sourceSystemFromDB == null)
                {
                    throw new DMSException("SourceSystem - Dispatch is not set up in the system");
                }

                logger.Info("Setting the source system to Dispatch");

                member.SourceSystemID = sourceSystemFromDB.ID;
                membership.SourceSystemID = sourceSystemFromDB.ID;

                //Insert Membership Record
                MembershipRepository membershipRepository = new MembershipRepository();
                int membsershipID = membershipRepository.Save(membership);
                if (membsershipID <= 0)
                {
                    throw new DMSException("Error While creating Membership record !");
                }

                logger.InfoFormat("Saved Membership record @ ID : {0}", membership.ID);
                //Insert Member record
                MemberRepository memberRepository = new MemberRepository();
                member.MembershipID = membsershipID;
                // TFS : 1392
                model.MembershipID = membsershipID;
                // END TFS : 1392
                int memberID = memberRepository.Save(member);
                if (memberID <= 0)
                {
                    throw new DMSException("Error while creating Member record !");
                }
                logger.InfoFormat("Saved Member record @ ID : {0}", member.ID);
                model.MemberID = memberID;
                //Insert New Address Record
                /* CR-SCHEMA-CHANGE */
                logger.Info("Attempting to save addresses against member and membership");
                var addressFacade = new AddressFacade();
                List<AddressEntity> addressList = GetAddressEntities(model, userName, repository);
                addressFacade.SaveAddresses(memberID, EntityNames.MEMBER, userName, addressList, AddressFacade.ADD);

                addressList = GetAddressEntities(model, userName, repository);
                addressFacade.SaveAddresses(membership.ID, EntityNames.MEMBERSHIP, userName, addressList, AddressFacade.ADD);

                // For Phone Number
                logger.Info("Attempting to save phone details against member and membership");
                PhoneFacade facade = new PhoneFacade();
                List<PhoneEntity> phoneList = GetPhoneEntities(model);
                facade.SavePhoneDetails(memberID, EntityNames.MEMBER, userName, phoneList, PhoneFacade.ADD);

                phoneList = GetPhoneEntities(model);
                facade.SavePhoneDetails(membership.ID, EntityNames.MEMBERSHIP, userName, phoneList, PhoneFacade.ADD);

                //For Event Log
                EventLogRepository eventLogRepository = new EventLogRepository();

                EventLog eventLog = GetEventLogForRegisterMember(userName, sessionID, eventDetails, EventNames.REGISTER_MEMBER);
                logger.InfoFormat("Trying to log the event {0}", EventNames.REGISTER_MEMBER);
                long eventLogId = eventLogRepository.Add(eventLog, model.CaseID, EntityNames.CASE);
                logger.InfoFormat("Event log created for {0} : [ ID = {1} ] ", EventNames.REGISTER_MEMBER, eventLogId);
                eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.CLIENT, currentProgram != null ? currentProgram.ClientID : null);
                eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.PROGRAM, model.ProgramID);

                if (ClientNames.EFG_COMPANIES.Equals(clientName, StringComparison.InvariantCultureIgnoreCase))
                {
                    eventLog = GetEventLogForRegisterMember(userName, sessionID, eventDetails, EventNames.EFG_REGISTER_MEMBER);
                    eventLogId = eventLogRepository.Add(eventLog, model.CaseID, EntityNames.CASE);
                    logger.InfoFormat("Event log created for {0} : [ ID = {1} ] ", EventNames.EFG_REGISTER_MEMBER, eventLogId);
                    eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.CLIENT, currentProgram != null ? currentProgram.ClientID : null);
                    eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.PROGRAM, model.ProgramID);
                }
                //logger.InfoFormat("Event log created successfully for Case {0} and ID : {1}", model.CaseID, eventLogId);

                //TFS:610
                #region Program Data Item records
                if (model.DynamicDataElements != null && model.DynamicDataElements.Count > 0)
                {
                    logger.Info(string.Format("Creating Program Data Elements for Member ID {0}", member.ID));
                    int programDataItemId = 0;
                    string[] tokens = null;
                    foreach (var item in model.DynamicDataElements)
                    {
                        programDataItemId = 0;
                        tokens = item.Key.Split('$');
                        int.TryParse(tokens[1], out programDataItemId);
                        if (programDataItemId != 0)
                        {
                            ProgramMaintenanceRepository.AddDynamicDataValue(EntityNames.MEMBER, member.ID, programDataItemId, item.Value, userName);
                        }
                    }
                    logger.Info("Program Data Elements created");
                }
                #endregion
                tran.Complete();
            }
            return true;
        }

        private static EventLog GetEventLogForRegisterMember(string userName, string sessionID, Dictionary<string, string> eventDetails, string eventName)
        {
            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(eventName);

            if (theEvent == null)
            {
                throw new DMSException(string.Format("Invalid event name - {0}", eventName));
            }
            EventLog eventLog = new EventLog();
            eventLog.Source = "StartCall";
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Data = eventDetails.GetXml();
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = userName;
            return eventLog;
        }

        /// <summary>
        /// Searches the member.
        /// </summary>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="programID">The program ID.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public List<SearchMember_Result> SearchMember(string loggedInUserName, string eventSource, int inboundCallId, PageCriteria pageCriteria, int programID, string sessionID)
        {
            // Make an event log entry
            //For Event Log
            EventLogRepository eventLogRepository = new EventLogRepository();

            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(EventNames.MEMBER_SEARCH);

            if (theEvent == null)
            {
                throw new DMSException(string.Format("Invalid event name : {0}", EventNames.MEMBER_SEARCH));
            }

            EventLog eventLog = new EventLog();
            eventLog.Source = eventSource;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = pageCriteria.WhereClause;
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = loggedInUserName;


            long eventLogId = eventLogRepository.Add(eventLog, inboundCallId, EntityNames.INBOUND_CALL);
            return new MemberRepository().SearchMember(pageCriteria, programID);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="pageCriteria"></param>
        /// <param name="memberIDList"></param>
        /// <param name="membershipIDList"></param>
        /// <returns></returns>
        public List<StartCallMemberSelections_Result> SearchMember(PageCriteria criteria, string memberIDList)
        {
            MemberRepository repository = new MemberRepository();
            return repository.SearchMember(criteria, memberIDList);
        }

        /// <summary>
        /// Gets the member from case.
        /// </summary>
        /// <param name="callbackNumber">The callback number.</param>
        /// <param name="contactPhoneTypeId">The contact phone type id.</param>
        /// <returns></returns>
        public Member GetMemberFromCase(string callbackNumber, int contactPhoneTypeId)
        {
            // Place to do some formatting if need be.
            var memberRepository = new MemberRepository();
            Member member = memberRepository.GetMemberFromCase(callbackNumber, contactPhoneTypeId);

            return member;
        }

        /// <summary>
        /// Gets the vehicle information.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<Vehicle> GetVehicleInformation(int memberID, int membershipID)
        {
            return new MemberRepository().GetVehicleInformation(memberID, membershipID);
        }

        /// <summary>
        /// Gets the service request history.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<RecentServiceRequest> GetServiceRequestHistory(int membershipID)
        {
            return new MemberRepository().GetServiceRequestHistory(membershipID);
        }

        /// <summary>
        /// Gets the member information.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public List<Member_Information_Result> GetMemberInformation(int memberID)
        {
            return new MemberRepository().GetMemberInformation(memberID);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="programID"></param>
        /// <returns></returns>
        public List<ProgramServiceEventLimit> GetProgramServiceEventLimit(int programID)
        {
            return new MemberRepository().GetProgramServiceEventLimit(programID);
        }

        /// <summary>
        /// Gets the membership contact information.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public MemberContactInformation_Result GetMembershipContactInformation(int memberID)
        {
            return new MemberRepository().GetMembershipContactInformation(memberID);
        }

        /// <summary>
        /// Gets the associate list for member.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<MemberAssociateList_Result> GetAssociateListForMember(PageCriteria pageCriteria)
        {
            logger.InfoFormat("MemeberFacade - GetAssociateListForMember() : Parameters{0}", JsonConvert.SerializeObject(new
            {
                PageCriteria = pageCriteria
            }));
            return new MemberRepository().GetAssociateListForMember(pageCriteria);
        }

        /// <summary>
        /// Gets the member service request history.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<MemberServiceRequestHistory_Result> GetMemberServiceRequestHistory(PageCriteria pageCriteria)
        {
            logger.InfoFormat("MemeberFacade - GetMemberServiceRequestHistory(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                PageCriteria = pageCriteria
            }));

            return new MemberRepository().GetMemberServiceRequestHistory(pageCriteria);
        }

        /// <summary>
        /// Gets the closed loop.
        /// </summary>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public List<CloseLoopSearch_Result> GetClosedLoop(string loggedInUserName, string eventSource, int inboundCallId, PageCriteria pageCriteria, string sessionID)
        {
            // Make an event log entry
            //For Event Log
            EventLogRepository eventLogRepository = new EventLogRepository();

            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(EventNames.CLOSED_LOOP_SEARCH);

            if (theEvent == null)
            {
                throw new DMSException(string.Format("Invalid event name : {0}", EventNames.CLOSED_LOOP_SEARCH));
            }

            EventLog eventLog = new EventLog();
            eventLog.Source = eventSource;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = pageCriteria.WhereClause;
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = loggedInUserName;

            logger.InfoFormat("Trying to log the event {0}", EventNames.CLOSED_LOOP_SEARCH);
            long eventLogId = eventLogRepository.Add(eventLog, inboundCallId, EntityNames.INBOUND_CALL);

            return new MemberRepository().GetClosedLoop(pageCriteria);
        }

        /// <summary>
        /// Saves the member contact information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <param name="caseID">The case ID.</param>
        /// <param name="sessionId">The session id.</param>
        /// <exception cref="DMSException"></exception>
        public void SaveMemberContactInformation(MembershipContactInformation model, string userName, string eventSource, int? serviceRequestId, int caseID, string sessionId)
        {
            logger.InfoFormat("MemeberFacade - SaveMemberContactInformation(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                MembershipContactInformation = model,
                userName = userName,
                eventSource = eventSource,
                serviceRequestId = serviceRequestId,
                caseID = caseID,
                sessionId = sessionId
            }));
            Dictionary<string, string> eventDetails = new Dictionary<string, string>();
            eventDetails.Add("AddressID", model.AddressID.ToString());
            eventDetails.Add("Line1", model.Address1);
            eventDetails.Add("Line2", model.Address2);
            eventDetails.Add("Line3", model.Address3);
            eventDetails.Add("City", model.City);
            eventDetails.Add("StateProvince", model.StateProvinceID.ToString());
            eventDetails.Add("PostalCode", model.Zip);
            eventDetails.Add("CountryCode", model.CountryID.ToString());
            eventDetails.Add("Email", model.Email);
            eventDetails.Add("Phone", model.HomePhone.PhoneNumber);
            eventDetails.Add("ContactFirst", model.FirstName);
            eventDetails.Add("ContactLast", model.LastName);
            eventDetails.Add("IsDeliveryDriver", model.IsDeliveryDriver.ToString());
            eventDetails.Add("CallbackNumber", model.CallbackNumber.PhoneNumber);
            eventDetails.Add("AlternateNumber", model.AlternateCallbackNumber.PhoneNumber);
            eventDetails.Add("CellPhone", model.CellPhone.PhoneNumber);
            eventDetails.Add("WorkPhone", model.WorkPhone.PhoneNumber);
            using (TransactionScope tran = new TransactionScope())
            {
                // CR-SCHEMA-CHANGE addressRepository.Update(address);
                CommonLookUpRepository lookupRepo = new CommonLookUpRepository();
                /* Store the Information into address*/
                AddressEntity addressEntity = new AddressEntity();
                addressEntity.AddressTypeID = 1; // Default to 1
                addressEntity.ID = model.AddressID;
                addressEntity.RecordID = model.MemberID;
                addressEntity.Line1 = model.Address1;
                addressEntity.Line2 = model.Address2;
                addressEntity.Line3 = model.Address3;
                addressEntity.City = model.City;
                addressEntity.StateProvinceID = model.StateProvinceID;

                if (model.CountryID != null)
                {
                    Country country = lookupRepo.GetCountry(model.CountryID.Value);
                    addressEntity.CountryCode = country.ISOCode;
                }
                if (model.StateProvinceID != null)
                {
                    StateProvince s = lookupRepo.GetStateProvince(model.StateProvinceID.Value);
                    addressEntity.StateProvince = s.Abbreviation;
                }
                addressEntity.PostalCode = model.Zip;
                addressEntity.CountryID = model.CountryID;
                addressEntity.CreateDate = System.DateTime.Now;
                addressEntity.ModifyDate = System.DateTime.Now;
                addressEntity.CreateBy = userName;
                addressEntity.ModifyBy = userName;

                AddressRepository addressRepository = new AddressRepository();
                addressRepository.Save(addressEntity, EntityNames.MEMBER);
                /* address ends here */


                /* Begin Phone Number */
                PhoneRepository phoneRepository = new PhoneRepository();
                model.HomePhone.RecordID = model.MemberID;
                model.HomePhone.PhoneTypeID = 1;
                model.HomePhone.CreateDate = System.DateTime.Now;
                model.HomePhone.ModifyDate = System.DateTime.Now;
                model.HomePhone.CreateBy = userName;
                model.HomePhone.ModifyBy = userName;
                phoneRepository.Save(model.HomePhone, EntityNames.MEMBER, false);

                //For Optional Fields
                if (!string.IsNullOrEmpty(model.CellPhone.PhoneNumber))
                {
                    model.CellPhone.RecordID = model.MemberID;
                    model.CellPhone.PhoneTypeID = 3;
                    model.CellPhone.CreateDate = System.DateTime.Now;
                    model.CellPhone.ModifyDate = System.DateTime.Now;
                    model.CellPhone.CreateBy = userName;
                    model.CellPhone.ModifyBy = userName;
                    phoneRepository.Save(model.CellPhone, EntityNames.MEMBER, false);
                }

                if (!string.IsNullOrEmpty(model.WorkPhone.PhoneNumber))
                {
                    model.WorkPhone.RecordID = model.MemberID;
                    model.WorkPhone.PhoneTypeID = 2;
                    model.WorkPhone.CreateDate = System.DateTime.Now;
                    model.WorkPhone.ModifyDate = System.DateTime.Now;
                    model.WorkPhone.CreateBy = userName;
                    model.WorkPhone.ModifyBy = userName;
                    phoneRepository.Save(model.WorkPhone, EntityNames.MEMBER, false);
                }
                /* End of Phone Number */

                MemberRepository member = new MemberRepository();
                logger.InfoFormat("Updating member details of member id : {0}", model.MemberID);
                member.UpdatePersonalInfo(model.FirstName, model.LastName, model.Email, userName, model.MemberID);
                logger.Info("Updated member details successfully");
                if (serviceRequestId != null)
                {
                    EventLogRepository eventLogRepository = new EventLogRepository();

                    IRepository<Event> eventRepository = new EventRepository();
                    Event theEvent = eventRepository.Get<string>(EventNames.SAVE_MEMBER_TAB);

                    if (theEvent == null)
                    {
                        throw new DMSException(string.Format("Invalid event name : {0}", EventNames.SAVE_MEMBER_TAB));
                    }

                    EventLog eventLog = new EventLog();
                    eventLog.Source = eventSource;
                    eventLog.EventID = theEvent.ID;
                    eventLog.SessionID = sessionId;
                    eventLog.Description = eventDetails.GetXml();
                    eventLog.CreateDate = DateTime.Now;
                    eventLog.CreateBy = userName;
                    logger.InfoFormat("Trying to log the event {0}", EventNames.SAVE_MEMBER_TAB);
                    long eventLogId = eventLogRepository.Add(eventLog, serviceRequestId, EntityNames.SERVICE_REQUEST);
                    //logger.InfoFormat("Added Event Log Successfully for {0}", EventNames.SAVE_MEMBER_TAB);
                }


                // Update case with callback and alternate callback numbers.
                CaseRepository caseRepository = new CaseRepository();
                Case c = new Case()
                {
                    ContactFirstName = model.FirstName,
                    ContactLastName = model.LastName,
                    ContactPhoneNumber = model.CallbackNumber.PhoneNumber,
                    ContactPhoneTypeID = model.CallbackNumber.PhoneTypeID,
                    ContactAltPhoneNumber = model.AlternateCallbackNumber.PhoneNumber,
                    ContactAltPhoneTypeID = model.AlternateCallbackNumber.PhoneTypeID,
                    ContactEmail = model.Email,
                    ID = caseID,
                    // CR: 1239 - DeliveryDriver
                    IsDeliveryDriver = model.IsDeliveryDriver

                };
                logger.Info("Updating Contact Details in Case");
                caseRepository.UpdateContactDetails(c);
                logger.Info("Updated Contact Details in Case Successfully.");
                IServiceRequestDataValidator validator = new MemberDataValidator();
                TabValidationStatus tabValidationStatus = validator.Validate(serviceRequestId.GetValueOrDefault());

                logger.InfoFormat("Member data validation status = {0}", tabValidationStatus.ToString());

                ServiceRequestRepository serviceRepository = new ServiceRequestRepository();
                serviceRepository.UpdateTabStatus(serviceRequestId.GetValueOrDefault(), TabConstants.MemberTab, userName, (int)tabValidationStatus);
                tran.Complete();
            }
        }

        /// <summary>
        /// Gets the membership information.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public MembsershipInformation_Result GetMembershipInformation(int membershipID)
        {
            return new MemberRepository().GetMembershipInformation(membershipID);
        }

        /// <summary>
        /// Gets the member detailsby ID.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public Member GetMemberDetailsbyID(int memberID)
        {
            return new MemberRepository().GetMemberDetailsbyID(memberID);
        }

        /// <summary>
        /// Clients the portal register member.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="loggedInuser">The logged in user.</param>
        /// <returns></returns>
        public int? ClientPortalRegisterMember(MemberModel model, string loggedInuser)
        {
            return new MemberRepository().ClientPortalMemberRegistration(model, loggedInuser);
        }

        /// <summary>
        /// Gets the member by number.
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        public Member GetMemberByNumber(string memberNumber)
        {
            var memberRepository = new MemberRepository();
            return memberRepository.GetMemberByNumber(memberNumber);
        }

        /// <summary>
        /// Gets the mobile call for service.
        /// </summary>
        /// <param name="formattednumber">The formatted number.</param>
        /// <returns></returns>
        public Mobile_CallForService GetMobileCallForService(string formattednumber)
        {
            var memberRepository = new MemberRepository();
            return memberRepository.GetMobileCallForService(formattednumber);
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Make Hagerty service call and get Hagerty member information.
        /// </summary>
        /// <param name="memberNumber">The member ID.</param>
        /// <param name="IsHagertyProgram">Hagerty Program or not</param>
        /// <param name="SeachCriteria">Member Search Criteria values</param>
        /// <param name="StateAbbreviation">State Abbreviation</param>
        /// <param name="loggedInUserName">Logged in user name</param>
        /// <param name="eventSource">Event source</param>
        /// <param name="inboundCallId">The inbound call ID.</param>
        /// <param name="programID">The Parent Program id. </param>
        /// <param name="sessionID">The session id.</param>
        /// <returns></returns>
        public bool GetMemberInformationFromHagerty(string memberNumber, bool IsHagertyProgram, MemberSearchCriteria SeachCriteria, string StateAbbreviation, string loggedInUserName, string eventSource,
            int inboundCallId, int programID, string sessionID, bool emploeeInd = false)
        {

            bool isSuccess = false;
            string customerNumber = string.Empty;
            string customerFName = string.Empty;
            string customerLName = string.Empty;
            string autoPolicyNo = string.Empty;
            string stateOrProviceNo = string.Empty;
            string zipcode = string.Empty;
            string anyErrorsOnServiceCall = string.Empty;
            int MemberCount_Result = 0;
            long elapsedMMsec = 0;
            StringBuilder resultset = new System.Text.StringBuilder();


            if (SeachCriteria != null)
            {
                customerNumber = (!string.IsNullOrEmpty(SeachCriteria.MemberNumber)) ? SeachCriteria.MemberNumber : string.Empty;
                customerFName = (!string.IsNullOrEmpty(SeachCriteria.FirstName)) ? SeachCriteria.FirstName : string.Empty;
                customerLName = (!string.IsNullOrEmpty(SeachCriteria.LastName)) ? SeachCriteria.LastName : string.Empty;
                autoPolicyNo = string.Empty;
                stateOrProviceNo = (!string.IsNullOrEmpty(StateAbbreviation)) ? StateAbbreviation : string.Empty;
                zipcode = (!string.IsNullOrEmpty(SeachCriteria.ZipCode)) ? SeachCriteria.ZipCode : string.Empty;
            }
            else if (!string.IsNullOrEmpty(memberNumber))
            {
                customerNumber = memberNumber;
            }

            ServiceMembershipResponse MembershipResponse = null;
            List<HPlusMembershipInformation> HPlusMembershipList = new List<HPlusMembershipInformation>();
            logger.Info("Current program is a Hagerty Program. Attempting to invoke the web service");

            // Check whether it is Hagerty Program
            if (IsHagertyProgram)
            {
                try
                {
                    EndpointAddress wsAddress = new EndpointAddress(AppConfigRepository.GetValue(AppConfigConstants.HagertyPlus_Service_URI));  //Lakshmi Added on 11/15/2013
                    WSHttpBinding wsBinding = new WSHttpBinding("WSHttpBinding_INMCHPlus");

                    using (NMCHPlusClient nmcHPlusClient = new NMCHPlusClient(wsBinding, wsAddress))
                    {

                        nmcHPlusClient.ClientCredentials.UserName.UserName = AppConfigRepository.GetValue(AppConfigConstants.HagertyPlus_Service_UserName);  //"HPlusDevNMC"
                        nmcHPlusClient.ClientCredentials.UserName.Password = AppConfigRepository.GetValue(AppConfigConstants.HagertyPlus_Service_Password);  //"9nd4n/7p#<PP%jh3"

                        System.Diagnostics.Stopwatch watchStart = System.Diagnostics.Stopwatch.StartNew();
                        logger.InfoFormat("MemberFacade - GetMemberInformationFromHagerty - Calling API for RequestMembershipInformation with Params : Customer Number : {0},Auto Policy Number : {1}, Customer First Name : {2}, Customer Last Name : {3}, State Or Province No :{4}, Zip Code : {5}, emploeeInd : {6}", customerNumber, autoPolicyNo, customerFName, customerLName, stateOrProviceNo, zipcode, emploeeInd);
                        MembershipResponse = nmcHPlusClient.RequestMembershipInformation(customerNumber, autoPolicyNo, customerFName, customerLName, stateOrProviceNo, zipcode, emploeeInd);
                        watchStart.Stop();
                        elapsedMMsec = watchStart.ElapsedMilliseconds;

                        if (!emploeeInd && MembershipResponse.HPlusMemberInformation != null)
                        {
                            HPlusMembershipList = MembershipResponse.HPlusMemberInformation.ToList();

                            logger.InfoFormat("MemberFacade - GetMemberInformationFromHagerty - Return Success of RequestMembershipInformation with Members Count :{0}", HPlusMembershipList != null ? HPlusMembershipList.Count : 0);
                            // Members information will be Insert or update into DMS database.
                            if (HPlusMembershipList != null && HPlusMembershipList.Count > 0)
                            {
                                MemberCount_Result = HPlusMembershipList.Count;
                                foreach (HPlusMembershipInformation hPlusMember in HPlusMembershipList)
                                {
                                    if (!string.IsNullOrEmpty(hPlusMember.CustomerNumber))
                                    {
                                        string MemberFirstName = (!string.IsNullOrEmpty(hPlusMember.PrimaryInsuredInformation.PrimaryInsuredName.FirstName)) ?
                                            hPlusMember.PrimaryInsuredInformation.PrimaryInsuredName.FirstName : string.Empty;

                                        string MemberLastName = (!string.IsNullOrEmpty(hPlusMember.PrimaryInsuredInformation.PrimaryInsuredName.LastName)) ?
                                            hPlusMember.PrimaryInsuredInformation.PrimaryInsuredName.LastName : string.Empty;

                                        resultset = resultset.Append("<Member>" +
                                            "<MembershipNumber>" + hPlusMember.CustomerNumber + "</MembershipNumber>" +
                                            "<CustomerFirstName>" + MemberFirstName + "</CustomerFirstName>" +
                                            "<CustomerLastName>" + MemberLastName + "</CustomerLastName>" +
                                            "<CustomerType>" + hPlusMember.CustomerType + "</CustomerType>" +
                                            "<PlanType>" + hPlusMember.PlanType + "</PlanType>" +
                                           "</Member>");
                                        logger.InfoFormat("MemberFacade - GetMemberInformationFromHagerty -Calling SaveHagertyMemberInformation for the Member : {0}", resultset);
                                        SaveHagertyMemberInformation(hPlusMember, programID, loggedInUserName, eventSource, sessionID, stateOrProviceNo, zipcode);
                                        isSuccess = true;
                                    }
                                }
                            }
                            else
                            {
                                emploeeInd = true;
                                System.Diagnostics.Stopwatch watchStop = System.Diagnostics.Stopwatch.StartNew();
                                logger.InfoFormat("MemberFacade - GetMemberInformationFromHagerty - Calling API again for RequestMembershipInformation with Params : Customer Number : {0},Auto Policy Number : {1}, Customer First Name : {2}, Customer Last Name : {3}, State Or Province No :{4}, Zip Code : {5}, emploeeInd : {6}", customerNumber, autoPolicyNo, customerFName, customerLName, stateOrProviceNo, zipcode, emploeeInd);
                                MembershipResponse = nmcHPlusClient.RequestMembershipInformation(customerNumber, autoPolicyNo, customerFName, customerLName, stateOrProviceNo, zipcode, emploeeInd);
                                watchStop.Stop();
                                elapsedMMsec = watchStop.ElapsedMilliseconds;

                                if (MembershipResponse.HPlusMemberInformation != null)
                                {
                                    HPlusMembershipList = MembershipResponse.HPlusMemberInformation.ToList();
                                    logger.InfoFormat("MemberFacade - GetMemberInformationFromHagerty - Return Success of RequestMembershipInformation with Members Count :{0}", HPlusMembershipList != null ? HPlusMembershipList.Count : 0);

                                    // Members information will be Insert or update into DMS database.
                                    if (HPlusMembershipList != null && HPlusMembershipList.Count > 0)
                                    {
                                        MemberCount_Result = HPlusMembershipList.Count;
                                        foreach (HPlusMembershipInformation hPlusMember in HPlusMembershipList)
                                        {
                                            if (!string.IsNullOrEmpty(hPlusMember.CustomerNumber))
                                            {
                                                string MemberFirstName = (!string.IsNullOrEmpty(hPlusMember.PrimaryInsuredInformation.PrimaryInsuredName.FirstName)) ?
                                                    hPlusMember.PrimaryInsuredInformation.PrimaryInsuredName.FirstName : string.Empty;

                                                string MemberLastName = (!string.IsNullOrEmpty(hPlusMember.PrimaryInsuredInformation.PrimaryInsuredName.LastName)) ?
                                                    hPlusMember.PrimaryInsuredInformation.PrimaryInsuredName.LastName : string.Empty;

                                                resultset = resultset.Append("<Member>" +
                                                    "<MembershipNumber>" + hPlusMember.CustomerNumber + "</MembershipNumber>" +
                                                    "<CustomerFirstName>" + MemberFirstName + "</CustomerFirstName>" +
                                                    "<CustomerLastName>" + MemberLastName + "</CustomerLastName>" +
                                                    "<CustomerType>" + hPlusMember.CustomerType + "</CustomerType>" +
                                                    "<PlanType>" + hPlusMember.PlanType + "</PlanType>" +
                                                   "</Member>");
                                                logger.InfoFormat("MemberFacade - GetMemberInformationFromHagerty -Calling SaveHagertyMemberInformation for the Member : {0}", resultset);
                                                SaveHagertyMemberInformation(hPlusMember, programID, loggedInUserName, eventSource, sessionID, stateOrProviceNo, zipcode);
                                                isSuccess = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                    }

                }
                catch (FaultException fex)
                {

                    anyErrorsOnServiceCall = fex.Message;
                    logger.Error(anyErrorsOnServiceCall);
                }
                catch (Exception ex)
                {
                    anyErrorsOnServiceCall += ex.Message;
                    logger.Error(anyErrorsOnServiceCall);
                }

                Program program = ReferenceDataRepository.GetProgramByID(programID);

                //For Event Log
                EventLogRepository eventLogRepository = new EventLogRepository();

                IRepository<Event> eventRepository = new EventRepository();
                Event theEvent = eventRepository.Get<string>(EventNames.RETRIEVE_HAGERTY_MEMBER);

                if (theEvent == null)
                {
                    throw new DMSException("Invalid event name");
                }

                EventLog eventLog = new EventLog();
                eventLog.Source = eventSource;
                eventLog.EventID = theEvent.ID;
                eventLog.SessionID = sessionID;
                if (string.IsNullOrEmpty(anyErrorsOnServiceCall))
                {
                    eventLog.Data = @"<HagertyService>" +
                                            "<DateTime>" + DateTime.Now + "</DateTime>" +
                                            "<SearchValues>" +
                                            "<MembershipNumber>" + customerNumber + "</MembershipNumber>" +
                                            "<AutoPolicyNo>" + autoPolicyNo + "</AutoPolicyNo>" +
                                            "<CustomerFirstName>" + customerFName + "</CustomerFirstName>" +
                                            "<CustomerLastName>" + customerLName + "</CustomerLastName>" +
                                            "<CustomerStateorProvince>" + stateOrProviceNo + "</CustomerStateorProvince>" +
                                            "<CustomerZipCode>" + zipcode + "</CustomerZipCode>" +
                                            "</SearchValues>" +
                                            "<ResultSet>" +
                                            "<Result>Success</Result>" +
                                            "<ResultCount>" + MemberCount_Result + "</ResultCount>" +
                                            "<ElapsedTime>" + Convert.ToString(elapsedMMsec) + "</ElapsedTime>" +
                                            "<Members>" +
                                             resultset.ToString() +
                                            "</Members>" +
                                            "</ResultSet>" +
                                            "</HagertyService>";
                }
                else
                {
                    eventLog.Data = eventLog.Description = @"<HagertyService>" +
                                            "<DateTime>" + DateTime.Now + "</DateTime>" +
                                            "<SearchValues>" +
                                            "<MembershipNumber>" + customerNumber + "</MembershipNumber>" +
                                            "<AutoPolicyNo>" + autoPolicyNo + "</AutoPolicyNo>" +
                                            "<CustomerFirstName>" + customerFName + "</CustomerFirstName>" +
                                            "<CustomerLastName>" + customerLName + "</CustomerLastName>" +
                                            "<CustomerStateorProvince>" + stateOrProviceNo + "</CustomerStateorProvince>" +
                                            "<CustomerZipCode>" + zipcode + "</CustomerZipCode>" +
                                            "</SearchValues>" +
                                            "<ResultSet>" +
                                            "<ResultCount>" + MemberCount_Result + "</ResultCount>" +
                                            "<ElapsedTime>" + Convert.ToString(elapsedMMsec) + "</ElapsedTime>" +
                                            "<Members>" +
                                             resultset.ToString() +
                                            "</Members>" +
                                            "<Error>" + anyErrorsOnServiceCall + "</Error>" +
                                            "</ResultSet>" +
                                            "</HagertyService>";
                }
                eventLog.CreateDate = DateTime.Now;
                eventLog.CreateBy = loggedInUserName;
                logger.InfoFormat("Trying to log the event {0}", EventNames.RETRIEVE_HAGERTY_MEMBER);
                long eventLogId = eventLogRepository.Add(eventLog, null, EntityNames.SERVICE_REQUEST);
                eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.PROGRAM, programID);
                eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.CLIENT, program != null ? program.ClientID : null);
                //logger.InfoFormat("Event log created successfully for Service Request : {0} and ID : {1}", model.CaseID, eventLogId);
            }
            return isSuccess;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Saves the Hagerty Member information to data base.
        /// </summary>
        /// 
        /// <param name="hPlusMemberInfo">Hagerty Member Info</param>
        /// <param name="userName">The user name.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionId">The session id.</param>
        public void SaveHagertyMemberInformation(HPlusMembershipInformation hPlusMemberInfo, int parentprogramID, string userName, string eventSource, string sessionId, string searchHagertyState, string searchHagertyZip)
        {
            logger.InfoFormat("MemeberFacade - SaveHagertyMemberInformation(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                HPlusMembershipInformation = hPlusMemberInfo,
                parentprogramID = parentprogramID,
                userName = userName,
                eventSource = eventSource,
                sessionId = sessionId,
                searchHagertyState = searchHagertyState,
                searchHagertyZip = searchHagertyZip
            }));

            var transactionOptions = new TransactionOptions();
            transactionOptions.IsolationLevel = IsolationLevel.ReadCommitted;
            transactionOptions.Timeout = TransactionManager.MaximumTimeout;

            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, transactionOptions))
            {

                List<Membership> membershipList = null;

                int? NewMembershipID = null;

                string _CustomerNumber = string.Empty;

                int? HagertyNewPgmID = null;

                int? SourceSystemID = null;

                string CustomerType = string.Empty;

                string PlanType = string.Empty;

                string defaultCustomerType = string.Empty;

                string defaultPlanType = string.Empty;

                int? activeReq = 0;


                MembershipRepository membershipRepository = new MembershipRepository();
                MemberRepository memberRepository = new MemberRepository();
                AddressRepository addressRespository = new AddressRepository();


                if (!string.IsNullOrEmpty(hPlusMemberInfo.CustomerNumber))
                {
                    _CustomerNumber = hPlusMemberInfo.CustomerNumber.ToString();
                    logger.InfoFormat("Querying membership with MS number = {0} and program ID = {1}", _CustomerNumber, parentprogramID);
                    membershipList = memberRepository.GetMemberShipsByMembershipNo(hPlusMemberInfo.CustomerNumber, parentprogramID);

                    #region Get New program ID based on Customer Type & Plan Type
                    try
                    {
                        Type HplusType = hPlusMemberInfo.GetType();
                        System.Reflection.PropertyInfo custProperty = HplusType.GetProperty("CustomerType");
                        System.Reflection.PropertyInfo planProperty = HplusType.GetProperty("PlanType");



                        if (custProperty != null & planProperty != null)
                        {
                            if (!string.IsNullOrEmpty(hPlusMemberInfo.CustomerType) & !string.IsNullOrEmpty(hPlusMemberInfo.PlanType))
                            {
                                HagertyNewPgmID = memberRepository.GetHagertyNewProgramID(hPlusMemberInfo.CustomerType, hPlusMemberInfo.PlanType);
                            }
                            else
                            {
                                HagertyNewPgmID = memberRepository.GetHagertyNewProgramID(defaultCustomerType, defaultPlanType);

                                EventLogRepository eventLogRepository = new EventLogRepository();

                                IRepository<Event> eventRepository = new EventRepository();
                                Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                                EventLog eventLog = new EventLog();
                                eventLog.Source = eventSource;
                                eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                                eventLog.SessionID = sessionId;
                                eventLog.Description = " Customer Type and Plan Type comes as null or empty.So getting Non-Standard program ID for Hagerty Member.";

                                eventLog.CreateDate = DateTime.Now;
                                eventLog.CreateBy = userName;

                                long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.UPDATE_MEMBER);
                            }
                        }
                        else
                        {
                            HagertyNewPgmID = memberRepository.GetHagertyNewProgramID(defaultCustomerType, defaultPlanType);

                            EventLogRepository eventLogRepository = new EventLogRepository();

                            IRepository<Event> eventRepository = new EventRepository();
                            Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                            EventLog eventLog = new EventLog();
                            eventLog.Source = eventSource;
                            eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                            eventLog.SessionID = sessionId;
                            eventLog.Description = " No Customer Type and Plan Type property returned from Hagerty service. So getting Non-Standard program ID for Hagerty Member.";

                            eventLog.CreateDate = DateTime.Now;
                            eventLog.CreateBy = userName;

                            long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.UPDATE_MEMBER);
                        }



                    }
                    catch (Exception ex)
                    {
                        // if any reason exception thrown, still need to get an default ptogram ID.
                        HagertyNewPgmID = memberRepository.GetHagertyNewProgramID(defaultCustomerType, defaultPlanType);

                        //For Event Log
                        EventLogRepository eventLogRepository = new EventLogRepository();

                        IRepository<Event> eventRepository = new EventRepository();
                        Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                        EventLog eventLog = new EventLog();
                        eventLog.Source = eventSource;
                        eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                        eventLog.SessionID = sessionId;
                        if (!string.IsNullOrEmpty(ex.Message))
                        {
                            eventLog.Description = " Error in finding New program ID." + ex.Message;
                        }

                        eventLog.CreateDate = DateTime.Now;
                        eventLog.CreateBy = userName;

                        long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.UPDATE_MEMBER);
                    }
                    #endregion

                    #region Get Source System ID from SourceSystem Table for Hagerty Web Service

                    SourceSystemID = membershipRepository.GetSourceSystemID("HagertyPlusService");

                    #endregion

                    # region Checking whether Member is an Active Service Request Member.
                    // Checking whether this membership has any active service request. If yes, we do not do anything with Vehicle information. If no, then we are insert(if any new)/updating existing
                    // hagerty vehicle information in vehicle table.( NOT DELETING).
                    try
                    {
                        if (membershipList != null && membershipList.Count > 0)
                        {
                            foreach (Membership membership in membershipList)
                            {
                                List<RecentServiceRequest> recentServiceReq = memberRepository.GetServiceRequestHistory(membership.ID);
                                if (recentServiceReq != null & recentServiceReq.Count > 0)
                                {
                                    int[] memberIDs = memberRepository.GetMemberIDList(hPlusMemberInfo.CustomerNumber, parentprogramID);
                                    if (memberIDs != null & memberIDs.Length > 0)
                                    {
                                        foreach (int id in memberIDs)
                                        {
                                            activeReq = recentServiceReq.Where(x => x.MemberID == id && (x.Status != "Cancelled" && x.Status != "Complete")).Count();
                                            if (activeReq > 0)
                                            {
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch
                    {
                        activeReq = 0;
                    }
                    #endregion

                    #region Store Hagerty Member Information to Membership Table

                    //***** Store Hagerty Membership Information in to Membership Table ********//
                    try
                    {
                        if (membershipList != null && membershipList.Count > 0)    // Updating existing record in to Membership Table
                        {
                            foreach (Membership _membership in membershipList)
                            {
                                _membership.MembershipNumber = memberRepository.Left(hPlusMemberInfo.CustomerNumber.ToString(), 25);
                                _membership.IsActive = true;//TFS : 594//(hPlusMemberInfo.HPlusExpirationDate >= DateTime.Now) ? true : false;
                                _membership.ModifyBy = userName;
                                _membership.ModifyDate = System.DateTime.Now;

                                membershipRepository.Save(_membership, EntityNames.MEMBERSHIP, userName);

                                //List<AddressEntity> addressList = addressRespository.GetMembershipAddressInfoByMembershipNumber(hPlusMemberInfo.CustomerNumber, EntityNames.MEMBERSHIP, parentprogramID);


                                AddressEntity saveAddressbyMemberShipID = CreateHagertyMemberAdress(hPlusMemberInfo, hPlusMemberInfo.CustomerNumber, parentprogramID, EntityNames.MEMBERSHIP, null, _membership.ID, searchHagertyState, searchHagertyZip, activeReq);
                                if (saveAddressbyMemberShipID != null)
                                {
                                    addressRespository.SaveHagertyMemberAddress(saveAddressbyMemberShipID, EntityNames.MEMBERSHIP, "Home", saveAddressbyMemberShipID.RecordID.Value, userName); //Member Address stored by Membership ID in Address Entity table.
                                }
                            }
                        }
                        else   // Creating a new record in to Membership Table/
                        {
                            Membership membership = new Membership();
                            membership.MembershipNumber = memberRepository.Left(hPlusMemberInfo.CustomerNumber.ToString(), 25);
                            membership.Email = null;
                            membership.ClientReferenceNumber = null;
                            membership.ClientMembershipKey = null;
                            membership.IsActive = true;
                            membership.SourceSystemID = (SourceSystemID.HasValue) ? SourceSystemID.Value : 0;
                            membership.CreateBy = userName;
                            membership.CreateDate = System.DateTime.Now;
                            NewMembershipID = membershipRepository.Save(membership);

                            AddressEntity saveAddressbyMemberShipID = CreateHagertyMemberAdress(hPlusMemberInfo, hPlusMemberInfo.CustomerNumber, parentprogramID, EntityNames.MEMBERSHIP, null, NewMembershipID.Value, searchHagertyState, searchHagertyZip, activeReq);

                            if (saveAddressbyMemberShipID != null)
                            {
                                addressRespository.SaveHagertyMemberAddress(saveAddressbyMemberShipID, EntityNames.MEMBERSHIP, "Home", saveAddressbyMemberShipID.RecordID.Value, userName); //Member Address stored by Membership ID in Address Entity table.
                            }

                        }
                    }
                    catch (Exception ex)
                    {

                        //For Event Log
                        EventLogRepository eventLogRepository = new EventLogRepository();

                        IRepository<Event> eventRepository = new EventRepository();
                        Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                        EventLog eventLog = new EventLog();
                        eventLog.Source = eventSource;
                        eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                        eventLog.SessionID = sessionId;
                        if (!string.IsNullOrEmpty(ex.Message))
                        {
                            eventLog.Description = " Error: Inserting or updating Membership in Membership Table. " + ex.Message;
                        }
                        eventLog.CreateDate = DateTime.Now;
                        eventLog.CreateBy = userName;

                        long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.UPDATE_MEMBER_SHIP);
                    }

                    #endregion

                    #region  Store Hagerty Primary Member Information to Member Table
                    // ***** Store Hagerty Primary Member Information into Member Table ******/

                    try
                    {
                        int? primarymemberID = null;

                        List<Member> members = memberRepository.GetPrimaryMemberInfoByMembershipNumber(hPlusMemberInfo.CustomerNumber, parentprogramID);


                        if (members != null & (!NewMembershipID.HasValue))
                        {
                            foreach (Member member in members)                  //Updating an existing primary member info in Member table.
                            {
                                if (HagertyNewPgmID != null)
                                {
                                    member.ProgramID = HagertyNewPgmID.Value;
                                }
                                memberRepository.Save(CreateHagertyPrimaryMemberInfo(hPlusMemberInfo, member), EntityNames.MEMBER, userName);

                                AddressEntity saveAddressbyMemberID = CreateHagertyMemberAdress(hPlusMemberInfo, hPlusMemberInfo.CustomerNumber, parentprogramID, EntityNames.MEMBER, member.ID, null, searchHagertyState, searchHagertyZip, activeReq);

                                if (saveAddressbyMemberID != null)
                                {
                                    addressRespository.SaveHagertyMemberAddress(saveAddressbyMemberID, EntityNames.MEMBER, "Home", saveAddressbyMemberID.RecordID.Value, userName); //Member Address stored by MemberID in Address Entity table.
                                }

                            }
                        }
                        else if (members == null & (!NewMembershipID.HasValue))
                        {
                            if (membershipList != null && membershipList.Count > 0)    // Updating existing record in to Membership Table
                            {
                                foreach (Membership _membership in membershipList)
                                {
                                    Member newMember = new Member();
                                    newMember.MembershipID = _membership.ID;
                                    newMember.ProgramID = HagertyNewPgmID.Value;
                                    newMember.SourceSystemID = (SourceSystemID.HasValue) ? SourceSystemID.Value : 0;
                                    newMember.CreateDate = DateTime.Now;
                                    newMember.CreateBy = userName;


                                    primarymemberID = memberRepository.Save(CreateHagertyPrimaryMemberInfo(hPlusMemberInfo, newMember));

                                    if (primarymemberID.HasValue)
                                    {
                                        AddressEntity saveAddressbyMemberID = CreateHagertyMemberAdress(hPlusMemberInfo, hPlusMemberInfo.CustomerNumber, parentprogramID, EntityNames.MEMBER, primarymemberID.Value, null, searchHagertyState, searchHagertyZip, activeReq);

                                        if (saveAddressbyMemberID != null)
                                        {
                                            addressRespository.SaveHagertyMemberAddress(saveAddressbyMemberID, EntityNames.MEMBER, "Home", saveAddressbyMemberID.RecordID.Value, userName); //Member Address stored by MemberID in Address Entity table.
                                        }

                                        CreateHagertyMemberPhone(hPlusMemberInfo, _CustomerNumber, EntityNames.MEMBER, primarymemberID.Value, userName);
                                    }
                                }
                            }
                        }
                        else if (NewMembershipID.HasValue)    // Adding a new primary member into Member table.
                        {
                            Member newMember = new Member();
                            newMember.MembershipID = NewMembershipID.Value;
                            newMember.ProgramID = HagertyNewPgmID.Value;
                            newMember.SourceSystemID = (SourceSystemID.HasValue) ? SourceSystemID.Value : 0;
                            newMember.CreateDate = DateTime.Now;
                            newMember.CreateBy = userName;

                            primarymemberID = memberRepository.Save(CreateHagertyPrimaryMemberInfo(hPlusMemberInfo, newMember));

                            if (primarymemberID.HasValue)
                            {
                                AddressEntity saveAddressbyMemberID = CreateHagertyMemberAdress(hPlusMemberInfo, hPlusMemberInfo.CustomerNumber, parentprogramID, EntityNames.MEMBER, primarymemberID.Value, null, searchHagertyState, searchHagertyZip, activeReq);

                                if (saveAddressbyMemberID != null)
                                {
                                    addressRespository.SaveHagertyMemberAddress(saveAddressbyMemberID, EntityNames.MEMBER, "Home", saveAddressbyMemberID.RecordID.Value, userName); //Member Address stored by MemberID in Address Entity table.
                                }

                                CreateHagertyMemberPhone(hPlusMemberInfo, _CustomerNumber, EntityNames.MEMBER, primarymemberID.Value, userName);
                            }

                        }

                    }

                    catch (Exception ex)
                    {

                        //For Event Log
                        EventLogRepository eventLogRepository = new EventLogRepository();

                        IRepository<Event> eventRepository = new EventRepository();
                        Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                        EventLog eventLog = new EventLog();
                        eventLog.Source = eventSource;
                        eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                        eventLog.SessionID = sessionId;
                        if (!string.IsNullOrEmpty(ex.Message))
                        {
                            eventLog.Description = " Error: Inserting or updating Primary Member in Member Table. " + ex.Message;
                        }
                        eventLog.CreateDate = DateTime.Now;
                        eventLog.CreateBy = userName;

                        long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.UPDATE_MEMBER);
                    }

                    #endregion

                    #region Store Hagerty Secondary Member Information into Member Table
                    // ***** Store Hagerty Secondary Member Information into Member Table ******/
                    try
                    {
                        SecondaryMember secMember = null;
                        List<SecondaryMember> secMemberList = new List<SecondaryMember>();

                        List<HouseholdDrivers> housholdDrivers = (hPlusMemberInfo.HouseholdDriverInformation != null) ? hPlusMemberInfo.HouseholdDriverInformation.ToList() : null;

                        // Secondary Member infomation is updated or inserted only when web service returns Secondary Member info.
                        if (housholdDrivers != null && housholdDrivers.Count > 0)
                        {
                            foreach (HouseholdDrivers drivers in housholdDrivers)
                            {
                                secMember = new SecondaryMember();
                                secMember.secFirstName = drivers.DriverName.FirstName.Trim().ToUpper();
                                secMember.secLastName = drivers.DriverName.LastName.Trim().ToUpper();
                                secMember.secFullName = drivers.DriverName.FirstName.Trim().ToUpper() + "|" + drivers.DriverName.LastName.Trim().ToUpper();
                                secMemberList.Add(secMember);
                            }

                            List<Member> secondaryMembers = memberRepository.GetSecondaryMemberInfoByMembershipNumber(hPlusMemberInfo.CustomerNumber, parentprogramID);

                            if ((secondaryMembers != null) & (housholdDrivers != null & housholdDrivers.Count > 0))
                            {
                                // Find any more new Hagerty Members which is not in DB.
                                List<SecondaryMember> newList = memberRepository.MoreNewSecondaryMember(hPlusMemberInfo.CustomerNumber, secMemberList, parentprogramID);

                                if (newList != null & newList.Count > 0)
                                {
                                    foreach (SecondaryMember newMembers in newList)
                                    {
                                        Member member = new Member();
                                        if (membershipList != null && membershipList.Count > 0)
                                        {
                                            member.MembershipID = membershipList[0].ID;
                                        }

                                        member.FirstName = memberRepository.Left(newMembers.secFirstName, 50);
                                        member.LastName = memberRepository.Left(newMembers.secLastName, 50);
                                        member.ProgramID = HagertyNewPgmID.Value;
                                        member.EffectiveDate = (!string.IsNullOrEmpty(hPlusMemberInfo.HPlusEffectiveDate.ToString())) ? Convert.ToDateTime(hPlusMemberInfo.HPlusEffectiveDate.ToShortDateString()) : Convert.ToDateTime(DateTime.MaxValue.ToShortDateString());
                                        member.ExpirationDate = (!string.IsNullOrEmpty(hPlusMemberInfo.HPlusExpirationDate.ToString())) ? Convert.ToDateTime(hPlusMemberInfo.HPlusExpirationDate.ToShortDateString()) : Convert.ToDateTime(DateTime.MaxValue.ToShortDateString());

                                        member.IsPrimary = false;

                                        member.IsActive = (hPlusMemberInfo.HPlusExpirationDate >= DateTime.Now) ? true : false;
                                        member.SourceSystemID = (SourceSystemID.HasValue) ? SourceSystemID.Value : 0;
                                        member.CreateBy = userName;
                                        member.CreateDate = DateTime.Now;

                                        int? memberID = memberRepository.Save(member);

                                        if (memberID.HasValue)
                                        {

                                            AddressEntity saveAddressbyMemberID = CreateHagertyMemberAdress(hPlusMemberInfo, hPlusMemberInfo.CustomerNumber, parentprogramID, EntityNames.MEMBER, memberID.Value, null, searchHagertyState, searchHagertyZip, activeReq);

                                            if (saveAddressbyMemberID != null)
                                            {
                                                addressRespository.SaveHagertyMemberAddress(saveAddressbyMemberID, EntityNames.MEMBER, "Home", saveAddressbyMemberID.RecordID.Value, userName); //Member Address stored by MemberID in Address Entity table.
                                            }

                                            CreateHagertyMemberPhone(hPlusMemberInfo, _CustomerNumber, EntityNames.MEMBER, memberID.Value, userName);
                                        }

                                    }
                                }
                                //MemberRepository memberRep = new MemberRepository();
                                //Updating existing Hagerty members
                                List<Member> oldMemberList = memberRepository.ExistingSecondaryMember(secondaryMembers, secMemberList);
                                string clientMemberType = string.Empty;
                                if (oldMemberList != null & oldMemberList.Count > 0)
                                {
                                    foreach (Member existingMember in oldMemberList)
                                    {
                                        existingMember.EffectiveDate = (!string.IsNullOrEmpty(hPlusMemberInfo.HPlusEffectiveDate.ToString())) ? Convert.ToDateTime(hPlusMemberInfo.HPlusEffectiveDate.ToShortDateString()) : Convert.ToDateTime(DateTime.MaxValue.ToShortDateString());
                                        existingMember.ExpirationDate = (!string.IsNullOrEmpty(hPlusMemberInfo.HPlusExpirationDate.ToString())) ? Convert.ToDateTime(hPlusMemberInfo.HPlusExpirationDate.ToShortDateString()) : Convert.ToDateTime(DateTime.MaxValue.ToShortDateString());
                                        existingMember.ProgramID = HagertyNewPgmID.Value;
                                        existingMember.IsPrimary = false;

                                        clientMemberType = (!string.IsNullOrEmpty(hPlusMemberInfo.CustomerType)) ? memberRepository.Left(hPlusMemberInfo.CustomerType, 50) : string.Empty;
                                        switch (clientMemberType)
                                        {
                                            case "PCS":
                                                clientMemberType = "PCS";
                                                break;
                                            case "H":
                                                clientMemberType = "VIP";
                                                break;
                                            case "E":
                                                clientMemberType = "EMPLOYEE";
                                                break;
                                            case "S":
                                                clientMemberType = "S";
                                                break;
                                            case "M":
                                                clientMemberType = "M";
                                                break;
                                            default:
                                                clientMemberType = string.Empty;
                                                break;
                                        }
                                        existingMember.ClientMemberType = clientMemberType;
                                        existingMember.IsActive = (hPlusMemberInfo.HPlusExpirationDate >= DateTime.Now) ? true : false;
                                        existingMember.ModifyBy = userName;
                                        existingMember.ModifyDate = DateTime.Now;
                                        memberRepository.Save(existingMember, EntityNames.MEMBER, userName);

                                        AddressEntity saveAddressbyMemberID = CreateHagertyMemberAdress(hPlusMemberInfo, hPlusMemberInfo.CustomerNumber, parentprogramID, EntityNames.MEMBER, existingMember.ID, null, searchHagertyState, searchHagertyZip, activeReq);

                                        if (saveAddressbyMemberID != null)
                                        {
                                            addressRespository.SaveHagertyMemberAddress(saveAddressbyMemberID, EntityNames.MEMBER, "Home", saveAddressbyMemberID.RecordID.Value, userName); //Member Address stored by MemberID in Address Entity table.
                                        }

                                    }
                                }

                            }
                            else if ((secondaryMembers == null) & (housholdDrivers != null & housholdDrivers.Count > 0))  // Adding new member info in Member table.
                            {
                                Member _member = null;
                                for (int i = 0; i < housholdDrivers.Count; i++)
                                {
                                    _member = new Member();
                                    if (NewMembershipID.HasValue)
                                    {
                                        _member.MembershipID = NewMembershipID.Value;
                                    }
                                    else if (membershipList != null && membershipList.Count > 0)
                                    {
                                        _member.MembershipID = membershipList[0].ID;
                                    }

                                    _member.FirstName = (!string.IsNullOrEmpty(housholdDrivers[i].DriverName.FirstName)) ? memberRepository.Left(housholdDrivers[i].DriverName.FirstName, 50) : string.Empty;
                                    _member.LastName = (!string.IsNullOrEmpty(housholdDrivers[i].DriverName.LastName)) ? memberRepository.Left(housholdDrivers[i].DriverName.LastName, 50) : string.Empty;
                                    _member.ProgramID = HagertyNewPgmID.Value;
                                    _member.EffectiveDate = (!string.IsNullOrEmpty(hPlusMemberInfo.HPlusEffectiveDate.ToString())) ? Convert.ToDateTime(hPlusMemberInfo.HPlusEffectiveDate.ToShortDateString()) : Convert.ToDateTime(DateTime.MaxValue.ToShortDateString());
                                    _member.ExpirationDate = (!string.IsNullOrEmpty(hPlusMemberInfo.HPlusExpirationDate.ToString())) ? Convert.ToDateTime(hPlusMemberInfo.HPlusExpirationDate.ToShortDateString()) : Convert.ToDateTime(DateTime.MaxValue.ToShortDateString());

                                    _member.IsPrimary = false;

                                    _member.IsActive = (hPlusMemberInfo.HPlusExpirationDate >= DateTime.Now) ? true : false;
                                    _member.SourceSystemID = (SourceSystemID.HasValue) ? SourceSystemID.Value : 0;

                                    _member.CreateBy = userName;
                                    _member.CreateDate = DateTime.Now;
                                    //memberRepository.Save(secMember, EntityNames.MEMBER, userName);
                                    int? memberID = memberRepository.Save(_member);

                                    if (memberID.HasValue)
                                    {
                                        AddressEntity saveAddressbyMemberID = CreateHagertyMemberAdress(hPlusMemberInfo, hPlusMemberInfo.CustomerNumber, parentprogramID, EntityNames.MEMBER, memberID, null, searchHagertyState, searchHagertyZip, activeReq);
                                        if (saveAddressbyMemberID != null)
                                        {
                                            addressRespository.SaveHagertyMemberAddress(saveAddressbyMemberID, EntityNames.MEMBER, "Home", saveAddressbyMemberID.RecordID.Value, userName); //Member Address stored by MemberID in Address Entity table.
                                        }

                                        CreateHagertyMemberPhone(hPlusMemberInfo, _CustomerNumber, EntityNames.MEMBER, memberID, userName);
                                    }

                                }
                            }


                        }
                    }
                    catch (Exception ex)
                    {

                        //For Event Log
                        EventLogRepository eventLogRepository = new EventLogRepository();

                        IRepository<Event> eventRepository = new EventRepository();
                        Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                        EventLog eventLog = new EventLog();
                        eventLog.Source = eventSource;
                        eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                        eventLog.SessionID = sessionId;
                        if (!string.IsNullOrEmpty(ex.Message))
                        {
                            eventLog.Description = " Error: Inserting or updating secondary Member in Member Table. " + ex.Message;
                        }
                        eventLog.CreateDate = DateTime.Now;
                        eventLog.CreateBy = userName;

                        long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.UPDATE_MEMBER);
                    }

                    #endregion

                    #region Store Hagerty Member Phone Information into PhoneEntity Table
                    // ***** Store Hagerty Member Phone Information into PhoneEntity Table ******/

                    PhoneRepository phoneRepository = new PhoneRepository();
                    string countryCode = string.Empty;

                    try
                    {
                        List<PhoneEntity> phoneList = phoneRepository.GetPhoneInfoByMembershipNumber(_CustomerNumber, EntityNames.MEMBER, parentprogramID);

                        if (!string.IsNullOrEmpty(hPlusMemberInfo.CountryCode) & (hPlusMemberInfo.CountryCode == "USA"))
                        {
                            countryCode = "1";
                        }

                        if (phoneList != null & phoneList.Count > 0)
                        {
                            foreach (PhoneEntity memberPhone in phoneList)
                            {
                                if (!string.IsNullOrEmpty(hPlusMemberInfo.CustomerPhone))
                                {
                                    memberPhone.PhoneNumber = memberRepository.Left(countryCode + " " + hPlusMemberInfo.CustomerPhone.ToString(), 50);
                                }

                                PhoneType phoneTypeName = phoneRepository.GetPhoneTypeByID((memberPhone.PhoneTypeID.HasValue) ? memberPhone.PhoneTypeID.Value : 1);      //Get Phone Type by Phone Type ID.

                                phoneRepository.Save(memberPhone, EntityNames.MEMBER, phoneTypeName.Name, memberPhone.RecordID, userName);
                            }
                        }
                        else
                        {
                            int[] memberIDs = memberRepository.GetMemberIDList(hPlusMemberInfo.CustomerNumber, parentprogramID);
                            if (memberIDs != null & memberIDs.Length > 0)
                            {
                                foreach (int id in memberIDs)
                                {
                                    CreateHagertyMemberPhone(hPlusMemberInfo, _CustomerNumber, EntityNames.MEMBER, id, userName);
                                }
                            }
                        }

                    }
                    catch (Exception ex)
                    {

                        //For Event Log
                        EventLogRepository eventLogRepository = new EventLogRepository();

                        IRepository<Event> eventRepository = new EventRepository();
                        Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"

                        EventLog eventLog = new EventLog();
                        eventLog.Source = eventSource;
                        eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                        eventLog.SessionID = sessionId;
                        if (!string.IsNullOrEmpty(ex.Message))
                        {
                            eventLog.Description = " Error: Inserting or updating Member Phone Info in Phone Entity Table. " + ex.Message;
                        }

                        eventLog.CreateDate = DateTime.Now;
                        eventLog.CreateBy = userName;

                        long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.UPDATE_MEMBER);
                    }

                    #endregion

                    #region Store Hagerty Vehicle Information into Vehicle Table
                    // ***** Store Hagerty Vehicle Information into Vehicle Table ******/

                    VehicleRepository vehicleRespository = new VehicleRepository();
                    Vehicle _vehicle = null;
                    //int? activeReq = 0;


                    try
                    {
                        if (activeReq != null & activeReq.Value == 0)
                        {
                            Vehicle[] vehicleList = vehicleRespository.GetVehiclesInfoByMemberShipNumber(_CustomerNumber, parentprogramID);

                            PolicyVehicles[] policyVehicles = (hPlusMemberInfo.VehicleInformation != null) ? hPlusMemberInfo.VehicleInformation.ToArray() : null;
                            if (policyVehicles != null && policyVehicles.Length > 0)
                            {
                                if (vehicleList != null && vehicleList.Length > 0)
                                {
                                    for (int i = 0; i <= policyVehicles.Length - 1; i++)
                                    {
                                        try
                                        {
                                            if (i <= vehicleList.Length - 1)
                                            {
                                                if (vehicleList[i] != null & policyVehicles[i] != null)
                                                {
                                                    vehicleList[i].Make = (!string.IsNullOrEmpty(policyVehicles[i].Make)) ? memberRepository.Left(policyVehicles[i].Make, 50) : string.Empty;
                                                    vehicleList[i].Model = (!string.IsNullOrEmpty(policyVehicles[i].Model)) ? memberRepository.Left(policyVehicles[i].Model, 50) : string.Empty;
                                                    vehicleList[i].Year = (!string.IsNullOrEmpty(policyVehicles[i].Year)) ? memberRepository.Left(policyVehicles[i].Year, 4) : string.Empty;

                                                    if (!string.IsNullOrEmpty(policyVehicles[i].VehicleType))
                                                    {
                                                        vehicleList[i].VehicleTypeID = vehicleRespository.GetVehicleTypeId(policyVehicles[i].VehicleType);
                                                    }

                                                    if (!string.IsNullOrEmpty(policyVehicles[i].Make))
                                                    {
                                                        vehicleList[i].VehicleCategoryID = vehicleRespository.GetVehicleCategory(policyVehicles[i].Make);
                                                    }
                                                    vehicleList[i].IsActive = true;
                                                    vehicleList[i].ModifyBy = userName;
                                                    vehicleList[i].ModifyDate = DateTime.Now;

                                                    vehicleRespository.SaveHagertyVehicle(vehicleList[i]);
                                                }
                                            }
                                            else
                                            {
                                                for (int j = i; j <= policyVehicles.Length - 1; j++)
                                                {
                                                    if (policyVehicles[j] != null)
                                                    {
                                                        if (membershipList != null && membershipList.Count > 0)
                                                        {
                                                            foreach (Membership membership in membershipList)
                                                            {
                                                                _vehicle = CreateHagertyMemberVehicleInfo(policyVehicles[i], membership.ID);
                                                                _vehicle.CreateBy = userName;
                                                                _vehicle.CreateDate = DateTime.Now;

                                                                vehicleRespository.AddVehicle(_vehicle);
                                                            }
                                                        }
                                                        else if (NewMembershipID.HasValue)
                                                        {
                                                            _vehicle = CreateHagertyMemberVehicleInfo(policyVehicles[i], NewMembershipID.Value);
                                                            _vehicle.CreateBy = userName;
                                                            _vehicle.CreateDate = DateTime.Now;

                                                            vehicleRespository.AddVehicle(_vehicle);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        catch (Exception ex)
                                        {
                                            //For Event Log
                                            EventLogRepository eventLogRepository = new EventLogRepository();

                                            IRepository<Event> eventRepository = new EventRepository();
                                            Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                                            EventLog eventLog = new EventLog();
                                            eventLog.Source = eventSource;
                                            eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                                            eventLog.SessionID = sessionId;
                                            if (!string.IsNullOrEmpty(ex.Message))
                                            {
                                                eventLog.Description = " Error: Inserting Member Vehicle info in Vehicle Table. " + ex.Message;
                                            }
                                            eventLog.CreateDate = DateTime.Now;
                                            eventLog.CreateBy = userName;

                                            long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.ADD_VEHICLE);
                                        }

                                    }


                                }

                                else
                                {
                                    foreach (PolicyVehicles vehicle in policyVehicles)
                                    {
                                        try
                                        {
                                            if (membershipList != null && membershipList.Count > 0)
                                            {
                                                foreach (Membership membership in membershipList)
                                                {
                                                    _vehicle = CreateHagertyMemberVehicleInfo(vehicle, membership.ID);
                                                    _vehicle.CreateBy = userName;
                                                    _vehicle.CreateDate = DateTime.Now;

                                                    vehicleRespository.AddVehicle(_vehicle);
                                                }
                                            }
                                            else if (NewMembershipID.HasValue)
                                            {
                                                _vehicle = CreateHagertyMemberVehicleInfo(vehicle, NewMembershipID.Value);
                                                _vehicle.CreateBy = userName;
                                                _vehicle.CreateDate = DateTime.Now;

                                                vehicleRespository.AddVehicle(_vehicle);
                                            }
                                        }
                                        catch (Exception ex)
                                        {

                                            //For Event Log
                                            EventLogRepository eventLogRepository = new EventLogRepository();

                                            IRepository<Event> eventRepository = new EventRepository();
                                            Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                                            EventLog eventLog = new EventLog();
                                            eventLog.Source = eventSource;
                                            eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                                            eventLog.SessionID = sessionId;
                                            if (!string.IsNullOrEmpty(ex.Message))
                                            {
                                                eventLog.Description = " Error: Inserting Member Vehicle info in Vehicle Table. " + ex.Message;
                                            }
                                            eventLog.CreateDate = DateTime.Now;
                                            eventLog.CreateBy = userName;

                                            long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.ADD_VEHICLE);
                                        }

                                    }
                                }

                            }
                        }
                    }
                    catch (Exception exc)
                    {
                        //For Event Log
                        EventLogRepository eventLogRepository = new EventLogRepository();

                        IRepository<Event> eventRepository = new EventRepository();
                        Event theEvent = eventRepository.Get<string>(EventNames.INSERT_UPDATE_HAGERTY_MEMBER);  // TO- Do List: Need to add a new Event name. Like "Save Hagerty Member"
                        EventLog eventLog = new EventLog();
                        eventLog.Source = eventSource;
                        eventLog.EventID = (theEvent != null) ? theEvent.ID : 0;
                        eventLog.SessionID = sessionId;
                        if (!string.IsNullOrEmpty(exc.Message))
                        {
                            eventLog.Description = " Error in Insert/update Member Vehicle info in Vehicle Table. " + exc.Message;
                        }

                        eventLog.CreateDate = DateTime.Now;
                        eventLog.CreateBy = userName;

                        long eventLogId = eventLogRepository.Add(eventLog, null, EventNames.ADD_VEHICLE);
                    }

                    #endregion


                }
                tran.Complete();
            }

        }


        /// <summary>
        /// Updates the members expiration date.
        /// </summary>
        /// <param name="expirationDate">The expiration date.</param>
        /// <param name="comments">The comments.</param>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session identifier.</param>
        /// <param name="source">The source.</param>
        public string UpdateMembersExpirationDate(DateTime? expirationDate, string comments, int memberID, int serviceRequestID, string currentUser, string sessionID, string source, int? programID, int? productCategoryID, int? productID, int? vehicleTypeID, int? vehicleCategoryID, bool? isPossibleTow, int? caseID)
        {
            logger.InfoFormat("MemeberFacade - UpdateMembersExpirationDate(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                expirationDate = expirationDate,
                comments = comments,
                memberID = memberID,
                serviceRequestID = serviceRequestID,
                currentUser = currentUser,
                sessionID = sessionID,
                source = source,
                programID = programID,
                productCategoryID = productCategoryID,
                productID = productID,
                vehicleTypeID = vehicleTypeID,
                vehicleCategoryID = vehicleCategoryID,
                isPossibleTow = isPossibleTow,
                caseID = caseID
            }));
            using (TransactionScope tran = new TransactionScope())
            {
                MemberRepository repository = new MemberRepository();
                CaseRepository caseRepository = new CaseRepository();

                Member member = repository.GetMemberDetailsbyID(memberID);
                string memberStatus = "Inactive";
                if (member == null)
                {
                    throw new DMSException("Member Not Found with ID : " + memberID);
                }


                Case existingCase = caseRepository.GetCaseById(caseID.GetValueOrDefault());
                if (existingCase == null)
                {
                    throw new DMSException("No Case found with ID :" + caseID);
                }


                DateTime? membersExpirationDate = repository.UpdateMembersExpirationDate(expirationDate, memberID, serviceRequestID, currentUser);

                memberStatus = member.EffectiveDate.GetValueOrDefault() <= DateTime.Today && expirationDate.GetValueOrDefault() >= DateTime.Today ? "Active" : "Inactive";

                ServiceFacade serviceFacade = new ServiceFacade();
                int? towCategoryID = null;

                if (isPossibleTow.GetValueOrDefault())
                {
                    var pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                    towCategoryID = pc.ID;
                }
                serviceFacade.UpdateServiceEligibility(memberID, programID, productCategoryID, productID, vehicleTypeID, vehicleCategoryID, towCategoryID, serviceRequestID, caseID, currentUser,SourceSystemName.DISPATCH);

                CommentRepository commentRepository = new CommentRepository();
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                commentRepository.Save(CommentTypeNames.MEMBER, EntityNames.MEMBER, memberID, comments, currentUser);

                Hashtable ht = new Hashtable();
                ht.Add("ExpirationBefore", membersExpirationDate);
                ht.Add("ExpirationAfter", expirationDate);
                ht.Add("Comment", comments);
                ht.Add("BeforeStatus", existingCase.MemberStatus);
                ht.Add("AfterStatus", memberStatus);

                long eventLogID = eventLogFacade.LogEvent(source, EventNames.UPDATE_MEMBER_EXPIRATION, ht.GetMessageData(), currentUser, sessionID);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, memberID, EntityNames.MEMBER);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, serviceRequestID, EntityNames.SERVICE_REQUEST);
                tran.Complete();

                return memberStatus;
            }

        }

        /// <summary>
        /// Saves the members expiration date.
        /// </summary>
        /// <param name="expirationDate">The expiration date.</param>
        /// <param name="comments">The comments.</param>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="inboundCallID">The inbound call identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session identifier.</param>
        /// <param name="source">The source.</param>
        public void SaveMembersExpirationDate(DateTime? expirationDate, string comments, int memberID, int inboundCallID, int caseID, string currentUser, string sessionID, string source)
        {
            logger.InfoFormat("MemeberFacade - SaveMembersExpirationDate(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                expirationDate = expirationDate,
                comments = comments,
                memberID = memberID,
                inboundCallID = inboundCallID,
                caseID = caseID,
                currentUser = currentUser,
                sessionID = sessionID,
                source = source
            }));
            using (TransactionScope tran = new TransactionScope())
            {
                MemberRepository repository = new MemberRepository();

                DateTime? membersExpirationDate = repository.SaveMembersExpirationDate(expirationDate, memberID, currentUser);
                CommentRepository commentRepository = new CommentRepository();
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                CaseRepository caseRepository = new CaseRepository();
                commentRepository.Save(CommentTypeNames.MEMBER, EntityNames.MEMBER, memberID, comments, currentUser);

                Hashtable ht = new Hashtable();
                ht.Add("ExpirationBefore", membersExpirationDate);
                ht.Add("ExpirationAfter", expirationDate);
                ht.Add("Comment", comments);


                long eventLogID = eventLogFacade.LogEvent(source, EventNames.UPDATE_MEMBER_EXPIRATION, ht.GetMessageData(), currentUser, sessionID);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, inboundCallID, EntityNames.INBOUND_CALL);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, memberID, EntityNames.MEMBER);
                tran.Complete();
            }
        }

        /// <summary>
        /// Saves the name of the member.
        /// </summary>
        /// <param name="firstName">The first name.</param>
        /// <param name="middleName">Name of the middle.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="inboundCallID">The inbound call identifier.</param>
        /// <param name="caseID">The case identifier.</param>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session identifier.</param>
        /// <param name="source">The source.</param>
        public void SaveMemberName(string firstName, string middleName, string lastName, int memberID, int inboundCallID, int caseID, int serviceRequestID, string currentUser, string sessionID, string source)
        {
            logger.InfoFormat("MemeberFacade - SaveMemberName(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                firstName = firstName,
                middleName = middleName,
                lastName = lastName,
                memberID = memberID,
                inboundCallID = inboundCallID,
                caseID = caseID,
                serviceRequestID = serviceRequestID,
                currentUser = currentUser,
                sessionID = sessionID,
                source = source
            }));
            using (TransactionScope tran = new TransactionScope())
            {
                MemberRepository repository = new MemberRepository();

                repository.SaveMemberName(firstName, middleName, lastName, memberID, currentUser);


                Hashtable ht = new Hashtable();
                ht.Add("FirstName", firstName);
                ht.Add("MiddleName", middleName);
                ht.Add("LastName", lastName);

                EventLoggerFacade eventLogFacade = new EventLoggerFacade();

                long eventLogID = eventLogFacade.LogEvent(source, EventNames.CHANGE_MEMBER_NAME, ht.GetMessageData(), currentUser, sessionID);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, memberID, EntityNames.MEMBER);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, serviceRequestID, EntityNames.SERVICE_REQUEST);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, inboundCallID, EntityNames.INBOUND_CALL);
                tran.Complete();
            }
        }

        public void UpdateMembersProgram(int programID, string comments, int currentProgramID, int memberID, int inboundCallID, int caseID, int serviceRequestID, string currentUser, string sessionID, string source)
        {
            logger.InfoFormat("MemeberFacade - SaveMembersExpirationDate(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                toProgramID = programID,
                comments = comments,
                fromProgramID = currentProgramID,
                memberID = memberID,
                inboundCallID = inboundCallID,
                caseID = caseID,
                serviceRequestID = serviceRequestID,
                currentUser = currentUser,
                sessionID = sessionID,
                source = source
            }));
            using (TransactionScope tran = new TransactionScope())
            {
                MemberRepository repository = new MemberRepository();

                repository.UpdateMembersProgramID(programID, memberID, currentUser);

                var caseRepository = new CaseRepository();
                caseRepository.UpdateProgramID(programID, caseID, currentUser);

                CommentRepository commentRepository = new CommentRepository();
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                commentRepository.Save(CommentTypeNames.MEMBER, EntityNames.MEMBER, memberID, comments, currentUser);

                Hashtable ht = new Hashtable();
                ht.Add("FromProgramID", currentProgramID);
                ht.Add("ToProgramID", programID);
                ht.Add("Comment", comments);


                long eventLogID = eventLogFacade.LogEvent(source, EventNames.CHANGE_MEMBER_PROGRAM, ht.GetMessageData(), currentUser, sessionID);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, serviceRequestID, EntityNames.SERVICE_REQUEST);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, inboundCallID, EntityNames.INBOUND_CALL);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogID, memberID, EntityNames.MEMBER);
                tran.Complete();
            }
        }
        /// <summary>
        /// Gets the program coverage information list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramCoverageInformationList_Result> GetProgramCoverageInformationList(PageCriteria pc, int? programID)
        {
            logger.InfoFormat("MemeberFacade - GetProgramCoverageInformationList(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                PageCriteria = pc,
                programID = programID

            }));
            MemberRepository repository = new MemberRepository();
            return repository.GetProgramCoverageInformationList(pc, programID);
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets the member parent program by ID.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public int? GetMemberParentProgrambyID(int memberID)
        {
            logger.InfoFormat("MemeberFacade - GetMemberParentProgrambyID(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                memberID = memberID

            }));
            return new MemberRepository().GetMemberParentProgrambyID(memberID);
        }

        #endregion

        #region Private Methods

        /// <summary>
        /// Gets the address entities.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="repository">The repository.</param>
        /// <returns></returns>
        private static List<AddressEntity> GetAddressEntities(MemberModel model, string userName, CommonLookUpRepository repository)
        {
            List<AddressEntity> addressList = new List<AddressEntity>();
            AddressEntity addressEntity = new AddressEntity();
            addressEntity.AddressTypeID = 1; // Default to Home
            addressEntity.Line1 = model.AddressLine1;
            addressEntity.Line2 = model.AddressLine2;
            addressEntity.Line3 = model.AddressLine3;
            addressEntity.City = model.City;
            addressEntity.StateProvinceID = model.State;
            addressEntity.PostalCode = model.PostalCode;
            addressEntity.CountryID = model.Country;
            addressEntity.CreateDate = addressEntity.ModifyDate = DateTime.Now;
            addressEntity.CreateBy = addressEntity.ModifyBy = userName;
            if (model.State.HasValue)
            {
                addressEntity.StateProvince = repository.GetStateProvince(model.State.Value).Abbreviation;
            }

            if (model.Country.HasValue)
            {
                addressEntity.CountryCode = repository.GetCountry(model.Country.Value).ISOCode;
            }
            addressList.Add(addressEntity);
            return addressList;
        }

        /// <summary>
        /// Gets the phone entities.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        private static List<PhoneEntity> GetPhoneEntities(MemberModel model)
        {
            PhoneEntity phoneEntity = new PhoneEntity();
            phoneEntity.PhoneNumber = model.PhoneNumber;
            phoneEntity.PhoneTypeID = model.PhoneType;
            List<PhoneEntity> phoneList = new List<PhoneEntity>();
            phoneList.Add(phoneEntity);
            return phoneList;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Create Hagerty Member Address object.
        /// </summary>
        /// <param name="hplusMemberInfo">The Hagerty Member Info.</param>
        /// <param name="membershipNo">The membership number.</param>
        /// <param name="entityName">The entity name.</param>
        /// <param name="memberID">The member id.</param>
        /// <param name="membershipId">The membership id.</param>
        /// <returns></returns>
        private static AddressEntity CreateHagertyMemberAdress(HPlusMembershipInformation hplusMemberInfo, string membershipNo, int pgmID, string entityName, int? memberID, int? membershipId, string stateAbbre, string zip, int? activeSvcReqMember)
        {
            AddressEntity memberAdd = new AddressEntity();
            CommonLookUpRepository lookupRep = new CommonLookUpRepository();
            MemberRepository member = new MemberRepository();


            if (entityName == EntityNames.MEMBER)
            {
                memberAdd.RecordID = (memberID.HasValue) ? memberID.Value : member.GetPrimaryMemberInfoByMembershipNumber(membershipNo, pgmID)[0].ID;
                memberAdd.EntityID = 5;
            }

            if (entityName == EntityNames.MEMBERSHIP)
            {
                logger.InfoFormat("Querying membership with MS number = {0} and program ID = {1}", membershipNo, pgmID);
                memberAdd.RecordID = (membershipId.HasValue) ? membershipId.Value : member.GetMemberShipsByMembershipNo(membershipNo, pgmID)[0].ID;
                memberAdd.EntityID = 6;
            }


            if (hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress != null)
            {

                memberAdd.AddressTypeID = 1;        // For now, keep Address TypeID as 1 (Home)..

                memberAdd.Line1 = (!string.IsNullOrEmpty(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.AddressLine1)) ?
                                            member.Left(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.AddressLine1.ToString(), 100) : string.Empty;

                memberAdd.Line2 = (!string.IsNullOrEmpty(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.AddressLine2)) ?
                                member.Left(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.AddressLine2.ToString(), 100) : string.Empty;

                memberAdd.City = (!string.IsNullOrEmpty(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.City)) ?
                                 member.Left(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.City.ToString(), 100) : string.Empty;

                memberAdd.PostalCode = (!string.IsNullOrEmpty(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.PostalCode)) ?
                                 member.Left(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.PostalCode.ToString(), 20) : string.Empty;


                if (!string.IsNullOrEmpty(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.State))
                {
                    StateProvince state = lookupRep.GetStateProvinceByAbbreviation(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.State.ToUpper());

                    memberAdd.StateProvinceID = state.ID;

                    memberAdd.StateProvince = (!string.IsNullOrEmpty(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.State)) ?
                                member.Left(hplusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredAddress.State.ToString(), 10) : string.Empty;

                }


                if (!string.IsNullOrEmpty(hplusMemberInfo.CountryCode) && hplusMemberInfo.CountryCode == "USA")
                {
                    memberAdd.CountryCode = "US";
                    memberAdd.CountryID = 1;
                }
                return memberAdd;
            }
            /* KB: TFS:569 - Do not create dummy address data when the data is not coming from Hagerty web service.
            else if (activeSvcReqMember.Value == 0)  //Lakshmi - Added this code for Project 13713 
            {
                if (!string.IsNullOrEmpty(zip))
                {
                    memberAdd.PostalCode = member.Left(zip, 20);
                }

                if (!string.IsNullOrEmpty(stateAbbre))
                {
                    StateProvince state = lookupRep.GetStateProvinceByAbbreviation(stateAbbre.ToUpper());

                    memberAdd.StateProvinceID = state.ID;

                    memberAdd.StateProvince = member.Left(stateAbbre.ToString(), 10);
                }

                if (!string.IsNullOrEmpty(hplusMemberInfo.CountryCode) && hplusMemberInfo.CountryCode == "USA")
                {
                    memberAdd.CountryCode = "US";
                    memberAdd.CountryID = 1;
                }

                return memberAdd;
            }*/
            return null;

        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Create Hagerty Member phone info object.
        /// </summary>
        /// <param name="hplusMemberInfo">The Hagerty Member Info.</param>
        /// <param name="membershipNo">The membership number.</param>
        /// <param name="entityName">The entity name.</param>
        /// <param name="memberID">The member id.</param>
        /// <param name="membershipId">The membership id.</param>
        /// <returns></returns>
        private static void CreateHagertyMemberPhone(HPlusMembershipInformation hplusMemberInfo, string membershipNo, string entityName, int? memberID, string userName)
        {
            PhoneEntity phoneinfo = new PhoneEntity();
            PhoneRepository phoneRepository = new PhoneRepository();
            MemberRepository memberRep = new MemberRepository();
            string countryCode = string.Empty;


            if (!string.IsNullOrEmpty(hplusMemberInfo.CountryCode) & (hplusMemberInfo.CountryCode == "USA"))
            {
                countryCode = "1";
            }

            phoneinfo.RecordID = memberID.Value;
            phoneinfo.EntityID = 5;

            phoneinfo.PhoneNumber = (!string.IsNullOrEmpty(hplusMemberInfo.CustomerPhone)) ?
                               memberRep.Left(countryCode + " " + hplusMemberInfo.CustomerPhone.ToString(), 50) : string.Empty;



            phoneRepository.Save(phoneinfo, EntityNames.MEMBER, "Home", phoneinfo.RecordID, userName);      //  This record will be saved as 'Home' Phone Type 
            //phoneRepository.Save(phoneinfo, EntityNames.MEMBER, "Cell", phoneinfo.RecordID, userName);      //  This record will be saved as 'Cell' Phone Type 

        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Create Hagerty primary member info object.
        /// </summary>
        /// <param name="hplusMemberInfo">The Hagerty Member Info.</param>
        /// <param name="memberObj">The member object.</param>
        /// <returns></returns>
        private static Member CreateHagertyPrimaryMemberInfo(HPlusMembershipInformation hPlusMemberInfo, Member memberObj)
        {
            MemberRepository memberRep = new MemberRepository();

            if (hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName != null)
            {
                memberObj.FirstName = (!string.IsNullOrEmpty(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.FirstName)) ?
                                       memberRep.Left(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.FirstName, 50) : string.Empty;

                memberObj.Prefix = (!string.IsNullOrEmpty(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.NamePrefix)) ?
                   memberRep.Left(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.NamePrefix, 10) : string.Empty;

                memberObj.Suffix = (!string.IsNullOrEmpty(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.NameSuffix)) ?
                    memberRep.Left(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.NameSuffix, 10) : string.Empty;

                memberObj.MiddleName = (!string.IsNullOrEmpty(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.MiddleName)) ?
                    memberRep.Left(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.MiddleName, 50) : string.Empty;

                memberObj.LastName = (!string.IsNullOrEmpty(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.LastName)) ?
                    memberRep.Left(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.LastName, 50) : string.Empty;

                memberObj.IsPrimary = (!string.IsNullOrEmpty(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.FirstName) &&
                !string.IsNullOrEmpty(hPlusMemberInfo.PrimaryInsuredInformation.PrimaryInsuredName.LastName)) ? true : false;


            }

            DateTime? nullDateTime = null;
            memberObj.EffectiveDate = (!string.IsNullOrEmpty(hPlusMemberInfo.HPlusEffectiveDate.ToString())) ? Convert.ToDateTime(hPlusMemberInfo.HPlusEffectiveDate.ToShortDateString()) : nullDateTime;//TFS 594 Convert.ToDateTime(DateTime.MaxValue.ToShortDateString());
            memberObj.ExpirationDate = (!string.IsNullOrEmpty(hPlusMemberInfo.HPlusExpirationDate.ToString())) ? Convert.ToDateTime(hPlusMemberInfo.HPlusExpirationDate.ToShortDateString()) : nullDateTime;  // //TFS 594 Convert.ToDateTime(DateTime.MaxValue.ToShortDateString());
            memberObj.IsActive = true;//TFS  :  594(hPlusMemberInfo.HPlusExpirationDate >= DateTime.Now) ? true : false;         //(hPlusMemberInfo.HPlusActiveIndicator.ToString() == "A") ? true : false;
            string clientMemberType = string.Empty;
            clientMemberType = (!string.IsNullOrEmpty(hPlusMemberInfo.CustomerType)) ? memberRep.Left(hPlusMemberInfo.CustomerType, 50) : string.Empty;

            switch (clientMemberType)
            {
                case "PCS":
                    clientMemberType = "PCS";
                    break;
                case "H":
                    clientMemberType = "VIP";
                    break;
                case "E":
                    clientMemberType = "EMPLOYEE";
                    break;
                case "S":
                    clientMemberType = "S";
                    break;
                case "M":
                    clientMemberType = "M";
                    break;
                default:
                    clientMemberType = string.Empty;
                    break;
            }
            memberObj.ClientMemberType = clientMemberType;

            return memberObj;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Create Hagerty member vehicle info object.
        /// </summary>
        /// <param name="policyvehicle">The Hagerty Member Vehicle Info.</param>
        /// <param name="membershipID">The membership ID.</param>
        private static Vehicle CreateHagertyMemberVehicleInfo(PolicyVehicles policyvehicle, int membershipID)
        {
            Vehicle _vehicle = new Vehicle();
            VehicleRepository vehicleRespository = new VehicleRepository();
            MemberRepository memberRep = new MemberRepository();

            _vehicle.Year = (!string.IsNullOrEmpty(policyvehicle.Year)) ? memberRep.Left(policyvehicle.Year.ToString(), 4) : string.Empty;

            _vehicle.Make = (!string.IsNullOrEmpty(policyvehicle.Make)) ? memberRep.Left(policyvehicle.Make.ToString(), 50) : string.Empty;

            _vehicle.Model = (!string.IsNullOrEmpty(policyvehicle.Model)) ? memberRep.Left(policyvehicle.Model.ToString(), 50) : string.Empty;

            _vehicle.MembershipID = membershipID;

            if (!string.IsNullOrEmpty(policyvehicle.VehicleType))
            {
                _vehicle.VehicleTypeID = vehicleRespository.GetVehicleTypeId(policyvehicle.VehicleType);
            }

            if (!string.IsNullOrEmpty(policyvehicle.Make))
            {
                _vehicle.VehicleCategoryID = vehicleRespository.GetVehicleCategory(policyvehicle.Make);
            }
            _vehicle.IsActive = true;
            return _vehicle;
        }

        #endregion




    }

    /// <summary>
    /// Helper Extensions.
    /// </summary>
    public static class ExtensionForMemberToDifferentModels
    {
        #region Public Methods
        /// <summary>
        /// To the membership.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public static Membership ToMembership(this MemberModel model, string userName)
        {
            Membership membership = new Membership();
            // CR-SCHEMA-CHANGE membership.PhoneNumber = model.PhoneNumber;
            membership.Email = model.Email;
            membership.ClientReferenceNumber = model.ClientReferenceNumber;
            membership.ClientMembershipKey = null;
            membership.IsActive = true;
            membership.CreateBy = membership.ModifyBy = userName;
            membership.CreateDate = membership.ModifyDate = System.DateTime.Now;
            return membership;
        }

        /// <summary>
        /// To the member.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public static Member ToMember(this MemberModel model, string userName)
        {
            Member member = new Member();
            member.ProgramID = model.ProgramID;

            member.FirstName = model.FirstName;
            member.MiddleName = model.MiddleName;
            member.LastName = model.LastName;
            member.Email = model.Email;
            member.EffectiveDate = model.EffectiveDate;
            member.ExpirationDate = model.ExpirationDate;
            member.ClientMemberKey = null;
            member.IsPrimary = true;
            member.IsActive = true;

            member.CreateBy = member.ModifyBy = userName;
            member.CreateDate = member.ModifyDate = System.DateTime.Now;


            return member;
        }
        #endregion
    }
}
