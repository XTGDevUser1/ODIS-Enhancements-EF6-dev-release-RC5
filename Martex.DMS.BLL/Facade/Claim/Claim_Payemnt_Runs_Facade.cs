using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Claims Facade
    /// </summary>
    public partial class ClaimsFacade
    {
        /// <summary>
        /// Gets the claim batch list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ClaimBatchList_Result> GetClaimBatchList(PageCriteria pc)
        {
            return repository.GetClaimBatchList(pc);
        }

        /// <summary>
        /// Gets the claim batch payment runs list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="batchID">The batch ID.</param>
        /// <returns></returns>
        public List<ClaimBatchPaymentRunsList_Result> GetClaimBatchPaymentRunsList(PageCriteria pc,int? batchID)
        {
            return repository.GetClaimBatchPaymentRunsList(pc, batchID);
        }
    }
}
