using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using log4net;

namespace Martex.DMS.DAL.DAO
{
    public class MemberMergeRepository
    {
        protected ILog logger = LogManager.GetLogger(typeof(MemberMergeRepository));
        /// <summary>
        /// Gets the member details.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public MemberManagementMemberDetails_Result GetMemberDetails(int memberID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetMemberManagementMemberDetails(memberID).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the member transaction list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public List<MemberManagementTransactions_Result> GetMemberTransactionList(int memberID,string sortColumnName,string sortOrder)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberManagementTransactions(sortColumnName,sortOrder,memberID).ToList<MemberManagementTransactions_Result>();
            }
        }

        /// <summary>
        /// Searches the member.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="memberId">The member unique identifier.</param>
        /// <returns></returns>
        public List<MatchedMembers_Result> SearchMemberByFindMatch(Common.PageCriteria pageCriteria, int memberId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 180;
                var list = dbContext.GetMemberManagementMembersByFindMatch(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, memberId).ToList<MatchedMembers_Result>();
                return list;
            }
        }

        public Dictionary<string,string> Merge(int sourceMemberID, int targetMemberID, string currentUser)
        {
            Dictionary<string, string> affectedRecords = new Dictionary<string, string>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                // Update Cases
                logger.Info("Processing cases");
                
                var sourceMember = dbContext.Members.Where(ms => ms.ID == sourceMemberID).FirstOrDefault();
                var targetMember = dbContext.Members.Where(ms => ms.ID == targetMemberID).FirstOrDefault();

                affectedRecords.Add("SOURCEMEMBERSHIP", sourceMember.MembershipID.ToString());
                affectedRecords.Add("TARGETMEMBERSHIP", targetMember.MembershipID.ToString());
                affectedRecords.Add("SOURCEMEMBER", sourceMemberID.ToString());
                affectedRecords.Add("TARGETMEMBER", targetMemberID.ToString());
               

                var cases = dbContext.Cases.Where(m => m.MemberID == sourceMemberID).ToList();
                List<string> affectedRelatedRecords = new List<string>();
                cases.ForEach(c =>
                {
                    c.ProgramID = targetMember.ProgramID;
                    c.MemberID = targetMemberID;
                    c.ModifyBy = currentUser;
                    c.ModifyDate = DateTime.Now;
                    //affectedRecords.Add("CASE_" + c.ID.ToString(), c.ID.ToString());
                    affectedRelatedRecords.Add(c.ID.ToString());
                });

                affectedRecords.Add("CASES", string.Join(",", affectedRelatedRecords));
                // Update EventLogLinks
                logger.Info("Processing EventLogLinks");
                var eventLogLinks = dbContext.EventLogLinks.Where(el => el.RecordID == sourceMemberID && el.Entity.Name == "Member").ToList();

                affectedRelatedRecords.Clear();
                eventLogLinks.ForEach(e =>
                {
                    e.RecordID = targetMemberID;
                    //affectedRecords.Add("EVENTLOGLINK_" + e.ID.ToString(), e.ID.ToString());
                    affectedRelatedRecords.Add(e.ID.ToString());
                });
                affectedRecords.Add("EVENTLOGLINKS", string.Join(",", affectedRelatedRecords));

                // Update ContactLogLinks
                logger.Info("Processing ContactLogLinks");
                var contactLogLinks = dbContext.ContactLogLinks.Where(cl => cl.RecordID == sourceMemberID && cl.Entity.Name == "Member").ToList();

                affectedRelatedRecords.Clear();
                contactLogLinks.ForEach(c =>
                {
                    c.RecordID = targetMemberID;
                    //affectedRecords.Add("CONTACTLOGLINK_" + c.ID.ToString(), c.ID.ToString());
                    affectedRelatedRecords.Add(c.ID.ToString());
                });
                affectedRecords.Add("CONTACTLOGLINKS", string.Join(",", affectedRelatedRecords));
                // Delete Source Member
                logger.Info("Processing Source Member");
                
                if (sourceMember != null)
                {
                    sourceMember.IsActive = false;
                    sourceMember.ModifyBy = currentUser;
                    sourceMember.ModifyDate = DateTime.Now;
                    
                    // (Delete Membership)
                    var activeMembers = dbContext.Members.Where(m => m.MembershipID == sourceMember.MembershipID && m.ID != sourceMemberID && m.IsActive == true).Count();

                    if (activeMembers == 0)
                    {
                        logger.Info("Processing Membership");
                        var sourceMembership = dbContext.Memberships.Where(ms => ms.ID == sourceMember.MembershipID).FirstOrDefault();
                        if (sourceMembership != null)
                        {
                            sourceMembership.IsActive = false;
                            sourceMembership.ModifyBy = currentUser;
                            sourceMembership.ModifyDate = DateTime.Now;
                            
                        }
                    }
                    else
                    {
                        logger.Info("There are active members under the current membership of source member!");
                    }
                }

                dbContext.SaveChanges();
                
            }

            return affectedRecords;
        }
    }
}
