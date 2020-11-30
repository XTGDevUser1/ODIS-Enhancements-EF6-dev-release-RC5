using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    public class VendorTemporaryCCHistoryRepository
    {
        public List<TemporaryCCBatchList_Result> GetVendorCCProcessingList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetTemporaryCCBatchList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<TemporaryCCBatchList_Result>();
            }
        }

        public List<TemporaryCCBatchPaymentRunsList_Result> GetTemporaryCCBatchPaymentRunsList(PageCriteria pc, int batchID, string gLAccountName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetTemporaryCCBatchPaymentRunsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, batchID, gLAccountName).ToList<TemporaryCCBatchPaymentRunsList_Result>();
            }
        }

        public List<TempCCGLAccountList_Result> GetTempCCGLAccountList(PageCriteria pc, int batchID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetTempCCGLAccountList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, batchID).ToList<TempCCGLAccountList_Result>();
            }
        }
    }
}
