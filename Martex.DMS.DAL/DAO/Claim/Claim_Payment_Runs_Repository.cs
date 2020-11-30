using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// Claims Repository
    /// </summary>
    public partial class ClaimsRepository
    {
        /// <summary>
        /// Gets the claim batch list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ClaimBatchList_Result> GetClaimBatchList(PageCriteria pc)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetClaimBatchList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<ClaimBatchList_Result>();
            }
        }

        /// <summary>
        /// Gets the claim batch payment runs list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="batchID">The batch ID.</param>
        /// <returns></returns>
        public List<ClaimBatchPaymentRunsList_Result>GetClaimBatchPaymentRunsList(PageCriteria pc,int? batchID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetClaimBatchPaymentRunsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, batchID).ToList<ClaimBatchPaymentRunsList_Result>();
            }
        }
    }
}
