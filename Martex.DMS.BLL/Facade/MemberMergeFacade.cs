using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;
using System.Transactions;

namespace Martex.DMS.BLL.Facade
{
    public class MemberMergeFacade
    {
        MemberMergeRepository repository = new MemberMergeRepository();

        /// <summary>
        /// Gets the member details.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public MemberMergeDetails GetMemberDetails(int memberID,string transactionsortColumnName, string transactionsortOrder)
        {
            MemberMergeDetails model = new MemberMergeDetails();
            model.MemberDetailsResult = repository.GetMemberDetails(memberID);
            model.MemberId = model.MemberDetailsResult.MemberID.ToString();
            model.Transactions = repository.GetMemberTransactionList(memberID, transactionsortColumnName, transactionsortOrder);
            PhoneRepository phonerepository = new PhoneRepository();
            List<PhoneEntityExtended> phonesList = phonerepository.GetGenericPhoneNumber(memberID, "Member");
            if (phonesList == null)
            {
                phonesList = new List<PhoneEntityExtended>();
            }
            model.PhonesList = phonesList;
            return model;
        }

        /// <summary>
        /// Gets the transactions.
        /// </summary>
        /// <param name="sortColumnName">Name of the sort column.</param>
        /// <param name="sortOrder">The sort order.</param>
        /// <param name="memberID">The member unique identifier.</param>
        /// <returns></returns>
        public List<MemberManagementTransactions_Result> GetTransactions(string sortColumnName, string sortOrder, int memberID)
        {
            return repository.GetMemberTransactionList(memberID,sortColumnName, sortOrder);
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
        public List<SearchMember_Result> SearchMember(string loggedInUserName, string eventSource, PageCriteria pageCriteria, int programID, string sessionID)
        {   
            return new MemberRepository().SearchMember(pageCriteria, programID);
        }

        public List<SearchMember_Result> SearchMemberMerge(string loggedInUserName, string eventSource, PageCriteria pageCriteria, int? programID, string sessionID)
        {
            return new MemberRepository().SearchMemberMerge(pageCriteria, programID);
        }
        /// <summary>
        /// Searches the member by find match.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="memberId">The member unique identifier.</param>
        /// <returns></returns>
        public List<MatchedMembers_Result> SearchMemberByFindMatch(string loggedInUserName, string eventSource, PageCriteria pageCriteria, int memberId, string sessionID)
        {
            return repository.SearchMemberByFindMatch(pageCriteria, memberId);
        }

        /// <summary>
        /// Merges the specified source member unique identifier.
        /// </summary>
        /// <param name="sourceMemberID">The source member unique identifier.</param>
        /// <param name="targetMemberID">The target member unique identifier.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session unique identifier.</param>
        public void Merge(int sourceMemberID, int targetMemberID, string eventSource, string currentUser, string sessionID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                Dictionary<string, string> affectedRecords = repository.Merge(sourceMemberID, targetMemberID, currentUser);

                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                long eventLogID = eventLoggerFacade.LogEvent(eventSource, EventNames.MERGE_MEMBER, affectedRecords, currentUser, sessionID);

                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, sourceMemberID, EntityNames.MEMBER);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, targetMemberID, EntityNames.MEMBER);

                tran.Complete();
            }


        }
    }
}
