using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using System.Transactions;

namespace Martex.DMS.DAL.DAO
{
    public partial class MemberManagementRepository
    {
        /// <summary>
        /// Gets the membership members list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
        public List<MembershipMembersList_Result> GetMembershipMembersList(PageCriteria pc, int memberShipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMembershipMembersList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, memberShipID).ToList<MembershipMembersList_Result>();
            }
        }

        /// <summary>
        /// Saves the membership member.
        /// </summary>
        /// <param name="Member">The member.</param>
        /// <param name="currentUser">The current user.</param>
        /// <returns></returns>
        public int SaveMembershipMember(MemberModel Member, string currentUser)
        {
            CommonLookUpRepository repository = new CommonLookUpRepository();
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member mem = new Member();
                mem.MembershipID = Member.MembershipID;
                mem.ProgramID = Member.ProgramID;

                if (Member.Suffix != null)
                {
                    mem.Suffix = repository.GetSuffix(Member.Suffix.Value).Name;
                }
                if (Member.Prefix != null)
                {
                    mem.Prefix = repository.GetPrefix(Member.Prefix.Value).Name;
                }
                mem.FirstName = Member.FirstName;
                mem.LastName = Member.LastName;
                mem.MiddleName = Member.MiddleName;
                mem.Email = Member.Email;
                mem.EffectiveDate = Member.EffectiveDate;
                mem.ExpirationDate = Member.ExpirationDate;
                mem.IsPrimary = false;
                mem.IsActive = true;
                mem.CreateBy = currentUser;
                mem.CreateDate = DateTime.Now;

                dbContext.Members.Add(mem);
                dbContext.SaveChanges();
                return mem.ID;
            }
        }

        /// <summary>
        /// Deletes the membership member.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        public void DeleteMembershipMember(int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member member = dbContext.Members.Where(a => a.ID == memberID).FirstOrDefault();
                if (member != null)
                {
                    member.IsActive = false;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="memberID"></param>
        /// <param name="membershipID"></param>
        public void DeleteMemberAndMemberShip(int memberID, int membershipID)
        {
            int membersCount = MemberCount(membershipID);
            using (TransactionScope transaction = new TransactionScope())
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    Member member = dbContext.Members.Where(a => a.ID == memberID).FirstOrDefault();
                    member.IsActive = false;

                    // Double check for Last Member
                    if (membersCount == 1)
                    {
                        Membership membership = dbContext.Memberships.Where(u => u.ID == membershipID).FirstOrDefault();
                        membership.IsActive = false;
                    }
                    
                    dbContext.SaveChanges();
                }
                transaction.Complete();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="membershipID"></param>
        /// <returns></returns>
        public int MemberCount(int membershipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Members.Where(u => u.MembershipID == membershipID && u.IsActive == true).ToList().Count();
            }
        }
    }
}
