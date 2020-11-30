using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DMSBaseException;
using log4net;
using System.Collections;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.BLL.Facade
{
    public class CustomerFeedbackFacade
    {

        protected static readonly ILog logger = LogManager.GetLogger(typeof(CustomerFeedbackFacade));

        /// <summary>
        /// Gets the Customer Feedback.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<dms_CustomerFeedback_list_Result> GetCustomerfeedbackdata(PageCriteria criteria)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetCustomerfeedbackdata(criteria);
        }

        public CustomerFeedback GetCustomerFeedbackById(int? customerFeedBackId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetCustomerFeedbackById(customerFeedBackId);
        }

        public string GetCustomerFeedbackTypeForFeedback(int? customerFeedBackId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetCustomerFeedbackTypeForFeedback(customerFeedBackId);
        }

        public int GetPrioritiesBySource(int? SourceId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetPrioritiesBySource(SourceId);
        }




        /// <summary>
        /// Creates the customer feedback.
        /// </summary>
        /// <param name="serviceRequestId">The service request identifier.</param>
        /// <param name="feedbackStatus">The feedback status.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionId">The session identifier.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public CustomerFeedback CreateCustomerFeedback(int serviceRequestId, string purchaseOrderNumber, string feedbackStatus, string eventSource, string sessionId, string loggedInUser)
        {
            /*
             * Get FeedbackStatusID for the given feedbackstatus
             * Get User.ID for the logged in User
             * Get Member and Member details (Address, Email) from the Member using the ServiceRequestID
             * Create a CustomerFeedback
             */
            var newCustomerFeedback = new CustomerFeedback();
            using (var tran = new TransactionScope())
            {
                newCustomerFeedback.ServiceRequestID = serviceRequestId;
                newCustomerFeedback.PurchaseOrderNumber = purchaseOrderNumber;

                var customerFeedbackStatus = ReferenceDataRepository.GetCustomerFeedbackStatusByName(feedbackStatus);
                if (customerFeedbackStatus == null)
                {
                    throw new DMSException(string.Format("CustomerFeedbackStatus with name - {0} is not found in the system", feedbackStatus));
                }

                newCustomerFeedback.CustomerFeedbackStatusID = customerFeedbackStatus.ID;

                var userRepository = new UserRepository();
                var aspnetUser = userRepository.GetUserByName(loggedInUser);
                if (aspnetUser != null)
                {
                    // Check user existance in Agent','RVTech','Manager','Dispatcher','FrontEnd' roles and insert.
                    List<User> userlist = ReferenceDataRepository.GetAssignedTo();

                    newCustomerFeedback.AssignedToUserID = userlist.Any(c => c.ID == aspnetUser.Users.FirstOrDefault().ID) ? aspnetUser.Users.FirstOrDefault().ID : default(int?);
                }

                var serviceRequest = (new ServiceRequestRepository()).GetById(serviceRequestId);
                var memberId = serviceRequest.Case.MemberID;
                var member = (new MemberRepository()).Get(memberId.GetValueOrDefault());

                newCustomerFeedback.MemberFirstName = member.FirstName;
                newCustomerFeedback.MemberLastName = member.LastName;
                newCustomerFeedback.MemberEmail = member.Email;
                newCustomerFeedback.MembershipNumber = member.Membership.MembershipNumber;

                var addressRepository = new AddressRepository();
                var addresses = addressRepository.GetAddresses(memberId.GetValueOrDefault(), EntityNames.MEMBER, AddressTypeNames.HOME);
                if (addresses != null && addresses.Count > 0)
                {
                    var homeAddress = addresses.FirstOrDefault();
                    newCustomerFeedback.MemberAddressLine1 = homeAddress.Line1;
                    newCustomerFeedback.MemberAddressLine2 = homeAddress.Line2;
                    newCustomerFeedback.MemberAddressLine3 = homeAddress.Line3;
                    newCustomerFeedback.MemberAddressCity = homeAddress.City;
                    newCustomerFeedback.MemberAddressStateProvince = homeAddress.StateProvince;
                    newCustomerFeedback.MemberAddressStateProvinceID = homeAddress.StateProvinceID;
                    newCustomerFeedback.MemberAddressPostalCode = homeAddress.PostalCode;
                    newCustomerFeedback.MemberAddressCountryCode = homeAddress.CountryCode;
                    newCustomerFeedback.MemberAddressCountryID = homeAddress.CountryID;
                }

                var phoneRepository = new PhoneRepository();
                var phoneNumber = phoneRepository.Get(memberId.GetValueOrDefault(), EntityNames.MEMBER, PhoneTypeNames.Home);
                if (phoneNumber != null)
                {
                    newCustomerFeedback.MemberPhoneNumber = phoneNumber.PhoneNumber;
                }

                newCustomerFeedback.CreateBy = loggedInUser;
                newCustomerFeedback.CreateDate = DateTime.Now;
                newCustomerFeedback.StartDate = DateTime.Now;

                logger.InfoFormat("Creating a new Customer Feedback record");
                var repository = new CustomerFeedbackRepository();
                repository.Save(newCustomerFeedback);

                var eventLogFacade = new EventLoggerFacade();
                var eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.INSERT_CUSTOMER_FEEDBACK, "Insert Customer Feedback", loggedInUser, newCustomerFeedback.ID, EntityNames.CUSTOMER_FEEDBACK, sessionId);
                logger.InfoFormat("Created eventlog and link records with logID = {0}", eventLogId);
                tran.Complete();

                return newCustomerFeedback;
            }


        }

        /// <summary>
        /// Updates the customer feedback.
        /// </summary>
        /// <param name="customerFeedback">The customer feedback.</param>
        /// <param name="serviceRequestId">The service request identifier.</param>
        /// <param name="feedbackStatus">The feedback status.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionId">The session identifier.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        public void UpdateCustomerFeedback(CustomerFeedback customerFeedback, int serviceRequestId, string feedbackStatus, string eventSource, string sessionId, string loggedInUser, int? oldStatusId)
        {
            using (var tran = new TransactionScope())
            {
                int? memberId = null;

                if (customerFeedback != null)
                {
                    logger.InfoFormat("Updating Customer Feedback - {0}", customerFeedback.ID);

                    var repository = new CustomerFeedbackRepository();

                    if (oldStatusId != null && customerFeedback.CustomerFeedbackStatusID != null && customerFeedback.CustomerFeedbackStatusID != oldStatusId)
                    {
                        repository.SaveCustomerFeedbackStatusChangeLog(customerFeedback.ID, loggedInUser, oldStatusId, customerFeedback.CustomerFeedbackStatusID);
                    }
                    customerFeedback.ModifyBy = loggedInUser;
                    customerFeedback.ModifyDate = DateTime.Now;
                    repository.Save(customerFeedback);

                    repository.UnlockCustomerFeedback(customerFeedback.ID);

                    logger.InfoFormat("Updated Customer Feedback - {0} successfully", customerFeedback.ID);

                    var eventLogFacade = new EventLoggerFacade();


                    #region Create Closed Customer Feedback Event Log when status is changed to closed only

                    var serviceRequest = (new ServiceRequestRepository()).GetById((int)customerFeedback.ServiceRequestID);
                    if(serviceRequest != null)
                    {
                        memberId = serviceRequest.Case.MemberID.GetValueOrDefault();
                    }                     
                    var closedCustFeedbackStatus = ReferenceDataRepository.GetCustomerFeedbackStatusByName(CustomerFeedbackStatusNames.CLOSED);
                    if (closedCustFeedbackStatus == null)
                    {
                        throw new DMSException(string.Format("Unable to find the Customer Feedback Status with name :{0}", CustomerFeedbackStatusNames.CLOSED));
                    }
                    var oldCustFeedbackStatus = repository.GetCustomerFeedbackStatusById(oldStatusId.GetValueOrDefault());
                    if (oldCustFeedbackStatus == null)
                    {
                        throw new DMSException(string.Format("Unable to find the Customer Feedback Status with id :{0}", oldStatusId));
                    }
                    int closedstatusid = closedCustFeedbackStatus.ID;

                    // If the new status is Closed and is different from Old status, log an event for Close Customer feedback.
                    if (customerFeedback.CustomerFeedbackStatusID == closedstatusid && customerFeedback.CustomerFeedbackStatusID != oldStatusId)
                    {

                        Hashtable clearedActionHastTable = new Hashtable();
                        clearedActionHastTable.Add("OldStatus", oldCustFeedbackStatus.Name);
                        clearedActionHastTable.Add("NewStatus", CustomerFeedbackStatusNames.CLOSED);

                        var eventLogData = clearedActionHastTable.GetEventDetail();
                        var closedCustFeedbackEventLogId = eventLogFacade.LogEvent(eventSource, EventNames.CLOSE_CUSTOMER_FEEDBACK, "Close Customer Feedback", eventLogData.ToString(), loggedInUser, customerFeedback.ID, EntityNames.CUSTOMER_FEEDBACK, sessionId);
                        eventLogFacade.CreateRelatedLogLinkRecord(closedCustFeedbackEventLogId, serviceRequestId, EntityNames.SERVICE_REQUEST);
                        eventLogFacade.CreateRelatedLogLinkRecord(closedCustFeedbackEventLogId, memberId, EntityNames.MEMBER);
                        logger.InfoFormat("Created eventlog and link records with logID = {0}", closedCustFeedbackEventLogId);
                    }
                    else if (customerFeedback.CustomerFeedbackStatusID != closedstatusid && customerFeedback.CustomerFeedbackStatusID != oldStatusId)
                    {
                        var newCustomerFeedbackStatus = repository.GetCustomerFeedbackStatusById(customerFeedback.CustomerFeedbackStatusID.GetValueOrDefault());
                        Hashtable hashTable = new Hashtable();
                        hashTable.Add("OldStatus", oldCustFeedbackStatus.Name);
                        hashTable.Add("NewStatus", newCustomerFeedbackStatus.Name);

                        var eventLogData = hashTable.GetEventDetail();

                        var eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.UPDATE_CUSTOMER_FEEDBACK, "Update Customer Feedback", eventLogData.ToString(), loggedInUser, customerFeedback.ID, EntityNames.CUSTOMER_FEEDBACK, sessionId);
                        logger.InfoFormat("Created eventlog and link records with logID = {0}", eventLogId);

                    }
                    else
                    {
                        var eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.UPDATE_CUSTOMER_FEEDBACK, "Update Customer Feedback", loggedInUser, customerFeedback.ID, EntityNames.CUSTOMER_FEEDBACK, sessionId);
                        logger.InfoFormat("Created eventlog and link records with logID = {0}", eventLogId);

                    }

                    #endregion

                    tran.Complete();
                }
            }
        }


        public List<CustomerFeedbackActivityList_Result> GetCustomerFeedbackActivityList(PageCriteria pc, int customerFeedbackID)
        {
            var repository = new CustomerFeedbackRepository();
            return repository.GetCustomerFeedbackActivityList(pc, customerFeedbackID);
        }

        /// <summary>
        /// Saves the Customer Feedback activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="CustomerFeedbackId">The CustomerFeedback Id.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveCustomerFeedbackActivityComments(int CommentType, string Comments, int CustomerFeedbackId, string currentUser)
        {
            var repository = new CustomerFeedbackRepository();
            Comment comment = new Comment();
            comment.RecordID = CustomerFeedbackId;
            comment.CommentTypeID = CommentType;
            comment.Description = Comments;
            comment.CreateBy = currentUser;
            comment.CreateDate = DateTime.Now;

            repository.SaveCustomerFeedbackActivityComments(comment);
        }

        /// <summary>
        /// Saves the Customer Feedback activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveCustomerFeedbackActivityContact(Activity_AddContact model, string currentUser)
        {
            VendorInvoiceRepository viRepository = new VendorInvoiceRepository();
            using (TransactionScope tran = new TransactionScope())
            {
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactLogRepository contactRepository = new ContactLogRepository();
                string direction = "";
                if (model.IsInbound)
                {
                    direction = "Inbound";
                }
                else
                {
                    direction = "Outbound";
                }
                ContactType contactType = staticDataRepo.GetTypeByName("CustomerFeedback");
                if (contactType == null)
                {
                    throw new DMSException("Contact Type - CustomerFeedback is not set up in the system");
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
                contactLog.Description = "Customer Feedback Processing";
                contactLog.Comments = model.Notes;
                contactLog.CreateBy = currentUser;
                contactLog.CreateDate = DateTime.Now;

                viRepository.SaveContactLog(contactLog);
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
                    viRepository.SaveContactLogReason(contactLogReason);
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
                    viRepository.SaveContactLogAction(contactLogAction);
                }

                contactRepository.CreateLinkRecord(contactLogID, EntityNames.CUSTOMER_FEEDBACK, model.CustomerFeedbackID);
                tran.Complete();
            }
        }

        /// <summary>
        /// Get Customer Feedback Member by FeedbackID
        /// </summary>
        /// <param name="customerFeedbackId">Customer Feedback Id</param>
        /// <param name="loggedInUser">The current user id</param>
        /// <returns></returns>
        public CustomerFeedbackMember GetCustomerFeedbackMember(int customerFeedbackId, string loggedInUser)
        {
            CustomerFeedbackMember feedbackMember = new CustomerFeedbackMember();
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            CustomerFeedback customerFeedbackData = _repos.GetCustomerFeedbackById(customerFeedbackId);

            if (customerFeedbackData != null)
            {
                var serviceRequest = (new ServiceRequestRepository()).GetById((int)customerFeedbackData.ServiceRequestID);
                var memberId = serviceRequest.Case.MemberID;
                var member = (new MemberRepository()).Get(memberId.GetValueOrDefault());
                var memberShip = (new MembershipRepository()).Get(member.MembershipID);

                if (memberShip != null)
                    feedbackMember.MembershipNumber = memberShip.MembershipNumber;

                feedbackMember.FirstName = member.FirstName;
                feedbackMember.LastName = member.LastName;
                feedbackMember.MemberEmailAddress = member.Email;
                feedbackMember.MemberPhoneNumber = member.MemberNumber;

                var addressRepository = new AddressRepository();
                var addresses = addressRepository.GetAddresses(memberId.GetValueOrDefault(), EntityNames.MEMBER, AddressTypeNames.HOME);
                if (addresses != null && addresses.Count > 0)
                {
                    var homeAddress = addresses.FirstOrDefault();
                    feedbackMember.MemberAddressLine1 = homeAddress.Line1;
                    feedbackMember.MemberAddressLine2 = homeAddress.Line2;
                    feedbackMember.MemberAddressLine3 = homeAddress.Line3;
                    feedbackMember.MemberCity = homeAddress.City;
                    feedbackMember.MemberAddressStateProvince = homeAddress.StateProvince;
                    feedbackMember.MemberAddressStateProvinceID = homeAddress.StateProvinceID;
                    feedbackMember.MemberAddressPostalCode = homeAddress.PostalCode;
                    feedbackMember.MemberAddressCountryCode = homeAddress.CountryCode;
                    feedbackMember.MemberAddressCountryCodeID = homeAddress.CountryID;
                }

                var phoneRepository = new PhoneRepository();
                var phoneNumber = phoneRepository.Get(memberId.GetValueOrDefault(), EntityNames.MEMBER, PhoneTypeNames.Cell);
                if (phoneNumber != null)
                {
                    feedbackMember.MemberPhoneNumber = phoneNumber.PhoneNumber;
                }

                feedbackMember.CreateBy = loggedInUser;
                feedbackMember.CreateDate = DateTime.Now;
            }

            return feedbackMember;
        }

        /// <summary>
        /// Get CustomerFeedback Details by customer feedback id
        /// </summary>
        /// <param name="pc"></param>
        /// <param name="customerFeedbackId">Customer feedback Id</param>
        /// <returns></returns>
        public List<GetCustomerFeedbackDetails_Result> GetCustomerFeedbackDetails(PageCriteria criteria, int customerFeedbackId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetCustomerFeedbackDetails(criteria, customerFeedbackId);
        }

        /// <summary>
        /// Get vendor by po number
        /// </summary>
        /// <param name="purchaseOrderNumber">po number</param>
        /// <returns></returns>
        public Vendor GetVendorByPurchaseOrderNumber(string purchaseOrderNumber)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetVendorByPurchaseOrderNumber(purchaseOrderNumber);
        }

        public List<CustomerFeedbackSurveyList_Result> GetCustomerFeedbackSurveyList(PageCriteria pc)
        {
            CustomerFeedbackRepository customerFeedbackRepository = new CustomerFeedbackRepository();
            return customerFeedbackRepository.GetCustomerFeedbackSurveyList(pc);
        }
        /// <summary>
        /// Updates the Customer Survey
        /// </summary>
        /// <param name="surveyId">Identifier of the Survey to be updated</param>
        /// <param name="userAction">The user's performed action. Accepted Values: compliment(User clicks Compliment from screen), complaint(User clicks Complaint on screen), ignored(User clicks Ignored)</param>
        /// <param name="sessionId">Logged In Session</param>
        /// <param name="loggedInUser">Logged in user Name.</param>
        public void UpdateCustomerSurvey(int surveyId, string userAction, string sessionId, string loggedInUser, string eventSource)
        {
            CustomerFeedbackRepository customerFeedbackRepository = new CustomerFeedbackRepository();
            customerFeedbackRepository.UpdateCustomerSurvey(surveyId, userAction, sessionId, loggedInUser, eventSource);
            //var customerSurvey = customerFeedbackRepository.GetCustomerFeedbackSurvey(surveyId);
            //if (customerSurvey == null)
            //{
            //    throw new DMSException(string.Format("Unable to find a Survey with id : {0}", surveyId));
            //}
            //if (userAction.ToLower() != "ignored")
            //{
            //    #region Check for required records
            //    var customerFeedbackStatus = ReferenceDataRepository.GetCustomerFeedbackStatusByName(CustomerFeedbackStatusNames.PENDING);
            //    if (customerFeedbackStatus == null)
            //    {
            //        throw new DMSException(string.Format("CustomerFeedbackStatus with name - {0} is not found in the system", CustomerFeedbackStatusNames.PENDING));
            //    }

            //    var customerFeedbackSource = ReferenceDataRepository.GetCustomerFeedbackSourceByName(CustomerFeedbackSourceNames.SURVEY);
            //    if (customerFeedbackStatus == null)
            //    {
            //        throw new DMSException(string.Format("CustomerFeedbackSource with name - {0} is not found in the system", CustomerFeedbackSourceNames.SURVEY));
            //    }
            //    #endregion

            //    #region Insert Customer Feedback

            //    #region Intialize a new CustomerFeedback record

            //    var srResults = new List<GetCustomerFeedbackHeaderBySROrPO_Result>();
            //    var repository = new CustomerFeedbackRepository();
            //    string _membershipNumber = string.Empty;

            //    if (customerSurvey.ServiceRequestID != null)
            //    {
            //        srResults = repository.GetCustomerFeedbackBy(NumberTypeConstants.SERVICE_REQUEST, customerSurvey.ServiceRequestID.GetValueOrDefault().ToString());

            //        if (srResults.Count !=0)
            //        _membershipNumber = srResults[0].MembershipNumber;
            //    }

            //    var newCustomerFeedback = new CustomerFeedback()
            //    {
            //        CustomerFeedbackStatusID = customerFeedbackStatus.ID,
            //        CustomerFeedbackSourceID = customerFeedbackSource.ID,
            //        CustomerFeedbackPriorityID = customerFeedbackRepository.GetPrioritiesBySource(customerFeedbackSource.ID),
            //        MemberFirstName = customerSurvey.FirstName,
            //        MemberLastName = customerSurvey.LastName,
            //        Description = customerSurvey.AdditionalComments,
            //        ServiceRequestID = customerSurvey.ServiceRequestID,
            //        ReceiveDate = System.DateTime.Now, // TFS 1688
            //        MembershipNumber = _membershipNumber

            //    };
            //    #endregion

            //    #region Try to get the Member Details based on Customer Survey
            //    var searchResults = customerFeedbackRepository.GetCustomerFeedbackBy(NumberTypeConstants.SERVICE_REQUEST, customerSurvey.ServiceRequestID.GetValueOrDefault().ToString());
            //    if (searchResults == null)
            //    {
            //        searchResults = customerFeedbackRepository.GetCustomerFeedbackBy(NumberTypeConstants.PURCHASE_ORDER, customerSurvey.PurchaseOrderNumber.ToString());
            //    }
            //    #endregion

            //    if (searchResults != null && searchResults.Count > 0)
            //    {
            //        var customerFeedbackHeader = searchResults.FirstOrDefault();

            //        #region Get Member
            //        var memberId = customerFeedbackHeader.MemberID;
            //        var member = (new MemberRepository()).Get(memberId.GetValueOrDefault());
            //        if (member == null)
            //        {
            //            throw new DMSException(string.Format("Unable to find a member in database : {0}", memberId));
            //        }
            //        newCustomerFeedback.MemberEmail = member.Email;
            //        #endregion

            //        #region Get Address for Member and assign it on Feedback record
            //        var addressRepository = new AddressRepository();
            //        var addresses = addressRepository.GetAddresses(memberId.GetValueOrDefault(), EntityNames.MEMBER, AddressTypeNames.HOME);
            //        if (addresses != null && addresses.Count > 0)
            //        {
            //            var homeAddress = addresses.FirstOrDefault();
            //            newCustomerFeedback.MemberAddressLine1 = homeAddress.Line1;
            //            newCustomerFeedback.MemberAddressLine2 = homeAddress.Line2;
            //            newCustomerFeedback.MemberAddressLine3 = homeAddress.Line3;
            //            newCustomerFeedback.MemberAddressCity = homeAddress.City;
            //            newCustomerFeedback.MemberAddressStateProvince = homeAddress.StateProvince;
            //            newCustomerFeedback.MemberAddressStateProvinceID = homeAddress.StateProvinceID;
            //            newCustomerFeedback.MemberAddressPostalCode = homeAddress.PostalCode;
            //            newCustomerFeedback.MemberAddressCountryCode = homeAddress.CountryCode;
            //            newCustomerFeedback.MemberAddressCountryID = homeAddress.CountryID;
            //        }
            //        #endregion

            //        #region Get Phone for Member and assign it on Feedback record
            //        var phoneRepository = new PhoneRepository();
            //        var phoneNumber = phoneRepository.Get(memberId.GetValueOrDefault(), EntityNames.MEMBER, PhoneTypeNames.Cell);
            //        if (phoneNumber != null)
            //        {
            //            newCustomerFeedback.MemberPhoneNumber = phoneNumber.PhoneNumber;
            //        }
            //        #endregion


            //    }
            //    newCustomerFeedback.CreateBy = loggedInUser;
            //    newCustomerFeedback.CreateDate = DateTime.Now;

            //    logger.InfoFormat("Creating a new Customer Feedback record");
            //    customerFeedbackRepository.Save(newCustomerFeedback);
            //    #endregion

            //    #region Insert Customer Feedback Detail

            //    #region Get Customer Feed back Type
            //    string feedbackTypeName = userAction.ToLower() == "compliment" ? CustomerFeedbackTypeNames.COMPLIMENT : CustomerFeedbackTypeNames.COMPLAINT_NON_DAMAGE;
            //    var customerFeedbackType = ReferenceDataRepository.GetCustomerFeedbackTypeByName(feedbackTypeName);
            //    if (customerFeedbackType == null)
            //    {
            //        throw new DMSException(string.Format("CustomerFeedbackType with name - {0} is not found in the system", feedbackTypeName));
            //    }
            //    #endregion

            //    SaveCustomerFeedbackDetails(new CustomerFeedbackDetail()
            //    {
            //        CustomerFeedbackID = newCustomerFeedback.ID,
            //        CustomerFeedbackTypeID = customerFeedbackType.ID
            //    }, loggedInUser);

            //    #endregion

            //    #region Insert EventLog and EventLogLink
            //    var eventLogFacade = new EventLoggerFacade();
            //    var eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.INSERT_CUSTOMER_FEEDBACK, "Insert Customer Feedback from Survey", loggedInUser, newCustomerFeedback.ID, EntityNames.CUSTOMER_FEEDBACK, sessionId);
            //    logger.InfoFormat("Created eventlog and link records with logID = {0}", eventLogId);
            //    eventLogFacade.CreateRelatedLogLinkRecord(eventLogId, newCustomerFeedback.ID, EntityNames.CUSTOMER_FEEDBACK);
            //    #endregion

            //    #region Update Customer Survey
            //    customerSurvey.DecidedBy = loggedInUser;
            //    customerSurvey.DecidedDate = DateTime.Now;
            //    customerSurvey.CustomerFeedbackID = newCustomerFeedback.ID;
            //    customerSurvey.IsIgnore = null;
            //    #endregion

            //}
            //else
            //{
            //    #region Update Customer Survey
            //    customerSurvey.DecidedBy = loggedInUser;
            //    customerSurvey.DecidedDate = DateTime.Now;
            //    customerSurvey.CustomerFeedbackID = null;
            //    customerSurvey.IsIgnore = true;
            //    #endregion
            //}
            //customerFeedbackRepository.UpdateCustomerSurveyDecidedDetails(customerSurvey, loggedInUser);
        }


        public void SaveCustomerFeedbackDetails(CustomerFeedbackDetail customerFeedbackDetails, string LoggedInUserName)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            _repos.SaveCustomerFeedbackDetails(customerFeedbackDetails, LoggedInUserName);
        }

        public void UnlockIfOwner(int recordID, int currentUserID)
        {
            if (recordID > 0)
            {
                var repository = new CustomerFeedbackRepository();
                var customerFeedback = repository.GetCustomerFeedbackById(recordID);
                if (customerFeedback.AssignedToUserID != null && customerFeedback.AssignedToUserID == currentUserID)
                {
                    repository.UnlockCustomerFeedback(recordID);
                    logger.InfoFormat("Record {0} not unclocked ", recordID);
                }
                else
                {
                    logger.InfoFormat("Record {0} not unclocked CustomerFeedbackRecord as it is assigned to {1}", recordID, customerFeedback.AssignedToUserID);
                }
            }
        }


        public void OpenbyCXMgr(int recordID, int currentUserID)
        {
            if (recordID > 0)
            {
                var repository = new CustomerFeedbackRepository();
                var customerFeedback = repository.GetCustomerFeedbackById(recordID);
                if (customerFeedback.AssignedToUserID != null)
                {
                    repository.LockCustomerFeedback(recordID, currentUserID);
                    logger.InfoFormat("Record {0} not opened ", recordID);
                }
                else
                {
                    logger.InfoFormat("Record {0} not Open CustomerFeedbackRecord by CXMgr as it is assigned to {1}", recordID, customerFeedback.AssignedToUserID);
                }
            }
        }

        public void UnlockByCXMgr(int recordID, int currentUserID)
        {
            if (recordID > 0)
            {
                var repository = new CustomerFeedbackRepository();
                var customerFeedback = repository.GetCustomerFeedbackById(recordID);
                if (customerFeedback.AssignedToUserID != null)
                {
                    repository.UnlockCustomerFeedback(recordID);
                    logger.InfoFormat("Record {0} not unclocked ", recordID);
                }
                else
                {
                    logger.InfoFormat("Record {0} not unclocked CustomerFeedbackRecord by CXMgr as it is assigned to {1}", recordID, customerFeedback.AssignedToUserID);
                }
            }
        }


        public CustomerFeedbackDetail GetCustomerDetailsById(int customerDetailId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetCustomerDetailsById(customerDetailId);
        }

        public void DeleteCustomerFeedbackDetails(int customerFeedbackDetailId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            _repos.DeleteCustomerFeedbackDetails(customerFeedbackDetailId);
        }

        public List<DropDownEntityForString> GetUsersOrVendors(string categoryName)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetUsersOrVendors(categoryName);
        }

        public Vendor GetVendorById(int id)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetVendorById(id);
        }

        public List<dms_Users_By_Appconfig_Role_Setting_Get_Result> GetUsersByAppConfigSettings(string appConfigName)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetUsersByAppConfigSettings(appConfigName);
        }

        public bool IsCustomerFeedbackExistsForSR(int? serviceRequestId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.IsCustomerFeedbackExistsForSR(serviceRequestId);
        }

        public void UpdateCustomerFeedbackStatusToOpen(int customerFeedBackId, int customerFeedbackStatusId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            _repos.UpdateCustomerFeedbackStatusToOpen(customerFeedBackId, customerFeedbackStatusId);
        }

        #region Customer Feedback Gift Card
        public List<GetCustomerFeedbackGiftCard_Result> GetCustomerFeedbackGiftCard(PageCriteria criteria, int customerFeedbackId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetCustomerFeedbackGiftCard(criteria, customerFeedbackId);
        }

        public void AddCustomerFeedbackGiftCard(CustomerFeedbackGiftCard customerFeedbackGiftCard, string LoggedInUserName, string eventSource, string sessionId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            using (TransactionScope tran = new TransactionScope())
            {
                _repos.SaveCustomerFeedbackGiftCard(customerFeedbackGiftCard, LoggedInUserName);

                var eventLogFacade = new EventLoggerFacade();
                var eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.ADD_CUSTOMER_FEEDBACK_GIFT_CARD, "Add Gift Card to Customer Feedback", LoggedInUserName, customerFeedbackGiftCard.CustomerFeedbackID, EntityNames.CUSTOMER_FEEDBACK, sessionId);
                logger.InfoFormat("Created eventlog and link records with logID = {0}", eventLogId);
                tran.Complete();
            }
        }

        public void UpdateCustomerFeedbackGiftCard(CustomerFeedbackGiftCard customerFeedbackGiftCard, string LoggedInUserName, string eventSource, string sessionId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            using (TransactionScope tran = new TransactionScope())
            {
                _repos.SaveCustomerFeedbackGiftCard(customerFeedbackGiftCard, LoggedInUserName);

                var eventLogFacade = new EventLoggerFacade();
                var eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.UPDATE_CUSTOMER_FEEDBACK_GIFT_CARD, "Update Gift Card in Customer Feedback", LoggedInUserName, customerFeedbackGiftCard.CustomerFeedbackID, EntityNames.CUSTOMER_FEEDBACK, sessionId);

                logger.InfoFormat("Created eventlog and link records with logID = {0}", eventLogId);
                tran.Complete();
            }
        }

        public CustomerFeedbackGiftCard GetCustomerFeedbackGiftCardById(int customerFeedbackGiftCardId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            return _repos.GetCustomerFeedbackGiftCardById(customerFeedbackGiftCardId);
        }

        public void DeleteCustomerFeedbackGiftCard(int customerFeedbackGiftCardId, string LoggedInUserName, string eventSource, string sessionId)
        {
            CustomerFeedbackRepository _repos = new CustomerFeedbackRepository();
            var CustomerFeedbackGiftCardDetails = GetCustomerFeedbackGiftCardById(customerFeedbackGiftCardId);

            using (TransactionScope tran = new TransactionScope())
            {
                _repos.DeleteCustomerFeedbackGiftCard(customerFeedbackGiftCardId);

                var eventLogFacade = new EventLoggerFacade();
                var eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.DELEET_CUSTOMER_FEEDBACK_GIFT_CARD, "Delete Gift Card in Customer Feedback", LoggedInUserName, CustomerFeedbackGiftCardDetails.CustomerFeedbackID, EntityNames.CUSTOMER_FEEDBACK, sessionId);
                logger.InfoFormat("Created eventlog and link records with logID = {0}", eventLogId);
                tran.Complete();
            }
        }
        #endregion        
    }
}
