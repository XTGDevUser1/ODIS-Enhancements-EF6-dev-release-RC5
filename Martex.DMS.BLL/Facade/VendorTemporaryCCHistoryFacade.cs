using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using System.Transactions;
using Martex.DMS.Areas.Application.Models;
using log4net;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade.VendorManagement.VendorBase;
using Martex.DMS.DAL;


namespace Martex.DMS.BLL.Facade
{
    public class VendorTemporaryCCHistoryFacade
    {
        public VendorTemporaryCCHistoryRepository repository = new VendorTemporaryCCHistoryRepository();

        public List<TemporaryCCBatchList_Result> GetVendorCCProcessingList(PageCriteria pc)
        {
            return repository.GetVendorCCProcessingList(pc);
        }

        public List<TemporaryCCBatchPaymentRunsList_Result> GetTemporaryCCBatchPaymentRunsList(PageCriteria pc, int batchID, string gLAccountName)
        {
            return repository.GetTemporaryCCBatchPaymentRunsList(pc, batchID, gLAccountName);
        }

        public List<TempCCGLAccountList_Result> TempCCGLAccountList(PageCriteria pc, int batchID)
        {
            return repository.GetTempCCGLAccountList(pc, batchID);

        }
    }
}
