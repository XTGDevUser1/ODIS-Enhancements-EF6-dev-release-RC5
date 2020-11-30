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
    public partial class ClaimsFacade
    {
        /// <summary>
        /// Gets the claim activity list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="claimID">The claim ID.</param>
        /// <returns></returns>
        public List<ClaimActivityList_Result> GetClaimActivityList(PageCriteria pc, int claimID)
        {
            return repository.GetClaimActivityList(pc, claimID);
        }


        /// <summary>
        /// Saves the claim activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="ClaimID">The claim ID.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveClaimActivityComments(int CommentType, string Comments, int ClaimID, string currentUser)
        {
            Comment comment = new Comment();
            comment.RecordID = ClaimID;
            comment.CommentTypeID = CommentType;
            comment.Description = Comments;
            comment.CreateBy = currentUser;
            comment.CreateDate = DateTime.Now;
            repository.SaveClaimActivityComments(comment);
        }


        /// <summary>
        /// Saves the claim activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveClaimActivityContact(Activity_AddContact model, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactLogRepository contactRepository = new ContactLogRepository();
                string direction = "";
                if (model.IsInbound)
                {
                    direction = "Inbound";
                }
                else
                {
                    direction = "Outbound";
                }
                ContactType contactType = staticDataRepo.GetTypeByName("Claim");
                if (contactType == null)
                {
                    throw new DMSException("Contact Type - Claim is not set up in the system");
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
                contactLog.Description = "Claim Processing";
                contactLog.Comments = model.Notes;
                contactLog.CreateBy = currentUser;
                contactLog.CreateDate = DateTime.Now;

                viRepository.SaveContactLog(contactLog);
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
                    viRepository.SaveContactLogReason(contactLogReason);
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
                    viRepository.SaveContactLogAction(contactLogAction);
                }

                contactRepository.CreateLinkRecord(contactLogID, EntityNames.CLAIM, model.ClaimID);
                tran.Complete();
            }
        }

    }
}
