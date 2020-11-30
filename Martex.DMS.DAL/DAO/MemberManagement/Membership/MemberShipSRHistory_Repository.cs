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
        /// Gets the member ship management SR history.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
        public List<MemberShipManagementSRHistory_Result> GetMemberShipManagementSRHistory(PageCriteria pc, int memberShipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberShipManagementSRHistory(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, memberShipID).ToList<MemberShipManagementSRHistory_Result>();
            }
        }
    }
}
