using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorInvoiceFacade
    {
        /// <summary>
        /// Gets the vendor invoice activity list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public List<VendorInvoiceActivityList_Result> GetVendorInvoiceActivityList(PageCriteria pc, int vendorInvoiceID)
        {
            return repository.GetVendorInvoiceActivityList(pc, vendorInvoiceID);
        }

        /// <summary>
        /// Saves the vendor invoice activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="VendorInvoiceID">The vendor invoice ID.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveVendorInvoiceActivityComments(int CommentType, string Comments, int VendorInvoiceID,string currentUser)
        {
            Comment comment = new Comment();
            comment.RecordID = VendorInvoiceID;
            comment.CommentTypeID = CommentType;
            comment.Description = Comments;
            comment.CreateBy = currentUser;
            comment.CreateDate = DateTime.Now;
            repository.SaveVendorInvoiceActivityComments(comment);
        }

        /// <summary>
        /// Saves the vendor invoice activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveVendorInvoiceActivityContact(Activity_AddContact model, string currentUser)
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
                ContactType contactType = staticDataRepo.GetTypeByName("Vendor");
                if (contactType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }
                ContactLog contactLog = new ContactLog();
                contactLog.ContactCategoryID = model.ContactCategory.GetValueOrDefault();// contactCategory.ID;
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
                contactLog.Description = "Vendor Invoice Processing";
                contactLog.Comments = model.Notes;
                contactLog.CreateBy = currentUser;
                contactLog.CreateDate = DateTime.Now;

                repository.SaveContactLog(contactLog);
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
                    repository.SaveContactLogReason(contactLogReason);
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
                    repository.SaveContactLogAction(contactLogAction);
                }

                contactRepository.CreateLinkRecord(contactLogID, EntityNames.VENDOR_INVOICE, model.VendorInvoiceID);
                contactRepository.CreateLinkRecord(contactLogID, EntityNames.VENDOR, model.VendorID);
                tran.Complete();
            }
        }        
    }
}
