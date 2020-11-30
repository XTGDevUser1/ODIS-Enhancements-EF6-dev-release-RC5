using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using System.Transactions;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Manage Mobile Call for Service
    /// </summary>
    public class MobileCallForServiceFacade
    {
        /// <summary>
        /// Updates the relevant data.
        /// </summary>
        /// <param name="phoneLocation">The phone location.</param>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="memberID">The member ID.</param>
        /// <param name="mobileRecorId">The mobile recor id.</param>
        public void UpdateRelevantData(CasePhoneLocation phoneLocation, int inboundCallId, int? memberID, int mobileRecorId)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                new CasePhoneLocationFacade().Save(phoneLocation);

                // Update InboundCall with this member ID
                InboundCallRepository inboundCallRepo = new InboundCallRepository();
                if (memberID.HasValue)
                {
                    inboundCallRepo.SetMemberID(inboundCallId, memberID.Value);
                }
                inboundCallRepo.SetMobileID(inboundCallId, mobileRecorId);

                tran.Complete();
            }
        }
    }
}
