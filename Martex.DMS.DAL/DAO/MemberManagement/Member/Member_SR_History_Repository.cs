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
        /// Gets the member management SR history.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public List<MemberManagementSRHistory_Result> GetMemberManagementSRHistory(PageCriteria pc,int? memberID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetMemberManagementSRHistory(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, memberID).ToList<MemberManagementSRHistory_Result>();
            }
        }
    }
}
