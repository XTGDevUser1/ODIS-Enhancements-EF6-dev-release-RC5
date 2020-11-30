using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using System.Transactions;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    public partial class MemberManagementFacade
    {

        /// <summary>
        /// Gets the member ship info details.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public MemberShipInfoDetails GetMemberShipInfoDetails(int membershipID)
        {
            MemberShipInfoDetails model = null;
            CommonLookUpRepository common = new CommonLookUpRepository();
            model = repository.GetMemberShipInfoDetails(membershipID);
            return model;
        }

        /// <summary>
        /// Saves the membership info details.
        /// </summary>
        /// <param name="model">The model.</param>
        public void SaveMembershipInfoDetails(MemberShipInfoDetails model, string userName)
        {

            EventLoggerFacade eventLogFacade = new EventLoggerFacade();
            if (model.SuffixName.Equals("Select")) { model.SuffixName = null; }
            if (model.PrefixName.Equals("Select")) { model.PrefixName = null; }
            logger.InfoFormat("Trying to update membership details for the given id {0} and member details for the id {1}", model.MembershipID, model.MasterMemberID);
            using (TransactionScope transaction = new TransactionScope())
            {
                repository.UpdateMemberShipInfoDetails(model, userName);
                logger.Info("Trying to create event log entry");
                long eventID = eventLogFacade.LogEvent(null, EventNames.UPDATE_MEMBER_SHIP, "Saving Membership Info Details", userName, null);
                eventLogFacade.CreateRelatedLogLinkRecord(eventID, model.MembershipID, EntityNames.MEMBERSHIP);
                transaction.Complete();
            }
            logger.Info("Record updated successfully");
        }
    }
}
