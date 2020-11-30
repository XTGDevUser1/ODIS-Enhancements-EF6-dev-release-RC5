using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Facade.MemberManagement.MemberBase;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;

namespace Martex.DMS.BLL.Facade
{
    public partial class MemberManagementFacade : MemberManagementBaseFacade
    {
        /// <summary>
        /// Searches the specified criteria.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<MemberManagementSearch_Result> Search(PageCriteria criteria)
        {
            logger.Info("Executing Member Search");
            return repository.Search(criteria);
        }

      
        /// <summary>
        /// Gets the members by membership ID.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<DropDownEntityForString> GetMembersByMembershipID(int membershipID)
        {
            List<DropDownEntityForString> membership = null;
            List<MembersByMembershipID_Result> list = repository.GetMembersByMembershipID(membershipID);
            membership = list.Select(u => new DropDownEntityForString()
            {
                Text = string.Join(" ", u.MemberName, u.Status),
                Value = u.ID.ToString()
            }).ToList();
            membership.Insert(0, new DropDownEntityForString() { 
                Text = "Membership Information",
                Value = "0"
            });
            return membership;
        }

        /// <summary>
        /// Creates the membership.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void CreateMembership(MembershipAddModel model, string userName,string sessionID)
        {
            model.PhoneInfomation.CreateBy = userName;
            model.PhoneInfomation.CreateDate = DateTime.Now;

            model.AddressInformation.CreateBy = userName;
            model.AddressInformation.CreateDate = DateTime.Now;

            var addressRepository = new AddressRepository();
            var phoneRepository = new PhoneRepository();
            var lookupRepository = new CommonLookUpRepository();
            var eventLog = new EventLoggerFacade();
            var memberCloneAddress = model.AddressInformation.Clone();
            var memberClonePhone = model.PhoneInfomation.Clone();

            var sourceSystemID = lookupRepository.GetSourceSystem(SourceSystemName.BACK_OFFICE).ID;
            model.MembershipInformation.SourceSystemID = sourceSystemID;
            model.MemberInformation.SourceSystemID = sourceSystemID;
           
            using (TransactionScope transaction = new TransactionScope())
            {
                repository.CreateMembership(model, userName);

                // For Membership
                model.AddressInformation.RecordID = model.MembershipInformation.ID;
                addressRepository.Save(model.AddressInformation, EntityNames.MEMBERSHIP);

                // For Membership
                model.PhoneInfomation.RecordID = model.MembershipInformation.ID;
                phoneRepository.Save(model.PhoneInfomation, EntityNames.MEMBERSHIP);

                // For Primary Member
                memberCloneAddress.RecordID = model.MemberInformation.ID;
                addressRepository.Save(memberCloneAddress, EntityNames.MEMBER);
               
                // For Primary Member
                memberClonePhone.RecordID = model.MemberInformation.ID;
                phoneRepository.Save(memberClonePhone, EntityNames.MEMBER);

                // Event Log
                long eventID = eventLog.LogEvent("Membership", EventNames.ADD_MEMBER, "Add Membership", userName, sessionID);
                eventLog.CreateRelatedLogLinkRecord(eventID, model.MembershipInformation.ID, EntityNames.MEMBERSHIP);
                eventLog.CreateRelatedLogLinkRecord(eventID, model.MemberInformation.ID, EntityNames.MEMBER);
                transaction.Complete();
            }
        }
    }
}
