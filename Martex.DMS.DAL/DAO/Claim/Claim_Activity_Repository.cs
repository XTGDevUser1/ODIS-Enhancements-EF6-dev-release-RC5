using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public partial class ClaimsRepository
    {
        /// <summary>
        /// Gets the claim activity list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="claimID">The claim ID.</param>
        /// <returns></returns>
        public List<ClaimActivityList_Result> GetClaimActivityList(PageCriteria pc, int claimID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetClaimActivityList(claimID, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<ClaimActivityList_Result>();
            }
        }

        /// <summary>
        /// Saves the claim activity comments.
        /// </summary>
        /// <param name="comment">The comment.</param>
        public void SaveClaimActivityComments(Comment comment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                comment.EntityID = dbContext.Entities.Where(a => a.Name == "Claim").Select(a => a.ID).FirstOrDefault();
                dbContext.Comments.Add(comment);
                dbContext.SaveChanges();
            }
        }
    }
}
