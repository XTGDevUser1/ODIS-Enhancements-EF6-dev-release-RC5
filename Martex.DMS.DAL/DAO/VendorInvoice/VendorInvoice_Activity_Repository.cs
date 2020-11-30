using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorInvoiceRepository
    {
        /// <summary>
        /// Gets the vendor invoice activity list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public List<VendorInvoiceActivityList_Result> GetVendorInvoiceActivityList(PageCriteria pc, int vendorInvoiceID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<VendorInvoiceActivityList_Result> list = dbContext.GetVendorInvoiceActivityList(vendorInvoiceID, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<VendorInvoiceActivityList_Result>();
                return list;
            }
        }


        /// <summary>
        /// Saves the vendor invoice activity comments.
        /// </summary>
        /// <param name="comment">The comment.</param>
        public void SaveVendorInvoiceActivityComments(Comment comment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                comment.EntityID = dbContext.Entities.Where(a => a.Name == "VendorInvoice").Select(a => a.ID).FirstOrDefault();
                dbContext.Comments.Add(comment);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Saves the contact log.
        /// </summary>
        /// <param name="contactLog">The contact log.</param>
        public void SaveContactLog(ContactLog contactLog)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ContactLogs.Add(contactLog);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Saves the contact log reason.
        /// </summary>
        /// <param name="contactLogReason">The contact log reason.</param>
        public void SaveContactLogReason(ContactLogReason contactLogReason)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ContactLogReasons.Add(contactLogReason);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Saves the contact log action.
        /// </summary>
        /// <param name="contactLogAction">The contact log action.</param>
        public void SaveContactLogAction(ContactLogAction contactLogAction)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ContactLogActions.Add(contactLogAction);
                dbContext.SaveChanges();
            }
        }
    }
}
