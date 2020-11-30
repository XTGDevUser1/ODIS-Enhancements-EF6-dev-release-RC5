using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public partial class MemberManagementRepository
    {
        /// <summary>
        /// Gets the member management activity list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public List<MemberManagementActivityList_Result> GetMemberManagementActivityList(PageCriteria pc,int?memberID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetMemberManagementActivityList(memberID, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<MemberManagementActivityList_Result>();
            }
        }

        /// <summary>
        /// Saves the member activity comments.
        /// </summary>
        /// <param name="comment">The comment.</param>
        public void SaveMemberActivityComments(Comment comment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                comment.EntityID = dbContext.Entities.Where(a => a.Name == "Member").Select(a => a.ID).FirstOrDefault();
                dbContext.Comments.Add(comment);
                dbContext.SaveChanges();
            }
        }
    }
}
