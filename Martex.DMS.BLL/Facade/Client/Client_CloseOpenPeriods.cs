using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using System.Transactions;

namespace Martex.DMS.BLL.Facade
{
    public partial class ClientsFacade
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="pc"></param>
        /// <returns></returns>
        public List<ClientClosePeriodList_Result> GetClientInvoiceClosePeriods(PageCriteria pc)
        {
            ClientRepository repository = new ClientRepository();
            return repository.GetClientInvoiceClosePeriods(pc);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="pc"></param>
        /// <returns></returns>
        public List<ClientOpenPeriodList_Result> GetClientInvoiceOpenPeriods(PageCriteria pc)
        {
            ClientRepository repository = new ClientRepository();
            return repository.GetClientInvoiceOpenPeriodList(pc);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="billingScheduleID"></param>
        /// <param name="billingScheduleListCommaSeparated"></param>
        /// <param name="userName"></param>
        /// <param name="sessionID"></param>
        public void ProcessClientCloseList(List<int> billingScheduleID, string billingScheduleListCommaSeparated, string userName, string sessionID, string pageReference)
        {
            ClientRepository repository = new ClientRepository();
            // Call SP To Process Records
            repository.ProcessClientClosePeriodList(billingScheduleListCommaSeparated, userName, sessionID, pageReference);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="billingScheduleID"></param>
        /// <param name="billingScheduleListCommaSeparated"></param>
        /// <param name="userName"></param>
        /// <param name="sessionID"></param>
        /// <param name="pageReference"></param>
        public void ProcessClientOpenList(int billingDefinitionInvoiceID, int billingScheduleID, int billingScheduleTypeID, int billingScheduleDateTypeID, int billingScheduleRangeTypeID, string userName, string sessionID, string pageReference)
        {
            ClientRepository repository = new ClientRepository();
            repository.ProcessClientOpenPeriodList(billingDefinitionInvoiceID, billingScheduleID, billingScheduleTypeID, billingScheduleDateTypeID, billingScheduleRangeTypeID, userName, sessionID, pageReference);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="userName"></param>
        /// <param name="sessionID"></param>
        /// <param name="pageReference"></param>
        /// <param name="billingScheduleIDList"></param>
        /// <param name="billingDefinitionInvoiceIdList"></param>
        public void CreateClientOpenPeriodProcessEventLogs(string userName, string sessionID, string pageReference, string billingScheduleIDList, string billingDefinitionInvoiceIdList)
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                ClientRepository repository = new ClientRepository();
                repository.CreateClientOpenPeriodProcessEventLogs(userName, sessionID, pageReference, billingScheduleIDList, billingDefinitionInvoiceIdList);
                transaction.Complete();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="billingScheduleListCommaSeparated"></param>
        /// <returns></returns>
        public List<ClientOpenPeriodToBeProcessRecords_Result> GetClientOpenPeriodToBeProcessRecords(string billingScheduleListCommaSeparated)
        {
            ClientRepository repository = new ClientRepository();
            return repository.GetClientOpenPeriodToBeProcessRecords(billingScheduleListCommaSeparated);
        }

    }
}
