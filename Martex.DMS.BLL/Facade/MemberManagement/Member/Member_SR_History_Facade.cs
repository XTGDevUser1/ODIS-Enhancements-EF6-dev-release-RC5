using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Facade
{
    public partial class MemberManagementFacade
    {
        /// <summary>
        /// Gets the member management SR history.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public List<MemberManagementSRHistory_Result> GetMemberManagementSRHistory(PageCriteria pc,int? memberID)
        {
            return repository.GetMemberManagementSRHistory(pc, memberID);
        }
    }
}
