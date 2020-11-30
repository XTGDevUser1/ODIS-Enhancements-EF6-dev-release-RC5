using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    public partial class MemberManagementFacade
    {
        /// <summary>
        /// Gets the member ship management SR history.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
        public List<MemberShipManagementSRHistory_Result> GetMemberShipManagementSRHistory(PageCriteria pc,int memberShipID)
        {
            return repository.GetMemberShipManagementSRHistory(pc, memberShipID);
        }
    }
}
