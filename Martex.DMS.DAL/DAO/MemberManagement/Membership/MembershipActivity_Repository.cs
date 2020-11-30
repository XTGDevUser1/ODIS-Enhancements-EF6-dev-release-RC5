using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public partial class MemberManagementRepository
    {
        /// <summary>
        /// Gets the membership activity list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="MemberShipID">The member ship ID.</param>
        /// <returns></returns>
        public List<MembershipManagementActivityList_Result> GetMembershipActivityList(PageCriteria pc, int MemberShipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMembershipManagementActivityList(MemberShipID, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<MembershipManagementActivityList_Result>();
            }
        }

        /// <summary>
        /// Saves the membership activity comments.
        /// </summary>
        /// <param name="comment">The comment.</param>
        public void SaveMembershipActivityComments(Comment comment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                comment.EntityID = dbContext.Entities.Where(a => a.Name == "Membership").Select(a => a.ID).FirstOrDefault();
                dbContext.Comments.Add(comment);
                dbContext.SaveChanges();
            }
        }
    }
}
