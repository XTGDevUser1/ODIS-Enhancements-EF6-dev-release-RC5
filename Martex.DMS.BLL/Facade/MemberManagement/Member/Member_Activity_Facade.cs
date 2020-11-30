using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Facade
{
    public partial class MemberManagementFacade
    {
        /// <summary>
        /// Gets the member management activity list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public List<MemberManagementActivityList_Result> GetMemberManagementActivityList(PageCriteria pc,int? memberID)
        {
            return repository.GetMemberManagementActivityList(pc, memberID);
        }

        /// <summary>
        /// Saves the member location activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="memberID">The member ID.</param>
        /// <param name="currentuser">The currentuser.</param>
        public void SaveMemberLocationActivityComments(int CommentType, string Comments, int memberID, string currentuser)
        {
            Comment comment = new Comment();
            comment.RecordID = memberID;
            comment.CommentTypeID = CommentType;
            comment.Description = Comments;
            comment.CreateBy = currentuser;
            comment.CreateDate = DateTime.Now;
            repository.SaveMemberActivityComments(comment);
        }

        /// <summary>
        /// Saves the member activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveMemberActivityContact(Activity_AddContact model, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactLogRepository contactRepository = new ContactLogRepository();
                VendorInvoiceRepository vendorInvoiceRepository = new VendorInvoiceRepository();
                string direction = "";
                if (model.IsInbound)
                {
                    direction = "Inbound";
                }
                else
                {
                    direction = "Outbound";
                }
                
                ContactType contactType = staticDataRepo.GetTypeByName("Member");
                if (contactType == null)
                {
                    throw new DMSException("Contact Type - Member is not set up in the system");
                }
                ContactLog contactLog = new ContactLog();
                contactLog.ContactCategoryID = model.ContactCategory;
                contactLog.ContactTypeID = contactType.ID;
                contactLog.ContactMethodID = model.ContactMethod;
                contactLog.TalkedTo = model.TalkedTo;
                contactLog.PhoneNumber = model.PhoneNumber;
                if (model.PhoneNumberType > 0)
                {
                    contactLog.PhoneTypeID = model.PhoneNumberType;
                }
                contactLog.Email = model.Email;
                contactLog.Direction = direction;
                contactLog.Description = "Membership Member Processing";
                contactLog.Comments = model.Notes;
                contactLog.CreateBy = currentUser;
                contactLog.CreateDate = DateTime.Now;

                vendorInvoiceRepository.SaveContactLog(contactLog);
                int contactLogID = contactLog.ID;
                foreach (var reasonRecord in model.ContactReasonID)
                {
                    ContactLogReason contactLogReason = new ContactLogReason();
                    contactLogReason.ContactLogID = contactLogID;
                    if (reasonRecord.HasValue)
                    {
                        contactLogReason.ContactReasonID = reasonRecord.GetValueOrDefault();
                    }
                    contactLogReason.CreateBy = currentUser;
                    contactLogReason.CreateDate = DateTime.Now;
                    vendorInvoiceRepository.SaveContactLogReason(contactLogReason);
                }

                foreach (var actionRecord in model.ContactActionID)
                {
                    ContactLogAction contactLogAction = new ContactLogAction();
                    contactLogAction.ContactLogID = contactLogID;
                    if (actionRecord.HasValue)
                    {
                        contactLogAction.ContactActionID = actionRecord.GetValueOrDefault();
                    }
                    contactLogAction.CreateBy = currentUser;
                    contactLogAction.CreateDate = DateTime.Now;
                    vendorInvoiceRepository.SaveContactLogAction(contactLogAction);
                }

                contactRepository.CreateLinkRecord(contactLogID, EntityNames.MEMBER, model.MemberID);
                //contactRepository.CreateLinkRecord(contactLogID, EntityNames.MEMBERSHIP, model.MembershipID);
                tran.Complete();
            }
        }
    }
}
