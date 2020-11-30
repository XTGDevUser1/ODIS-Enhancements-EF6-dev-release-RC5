using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public class BatchRepository
    {

        /// <summary>
        /// Adds the specified attribute.
        /// </summary>
        /// <param name="b">The attribute.</param>
        /// <param name="batchType">Type of the batch.</param>
        /// <param name="batchStatus">The batch status.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// </exception>
        public long Add(Batch b, string batchType, string batchStatus)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var batchTypeFromDB = dbContext.BatchTypes.Where(bt => bt.Name == batchType).FirstOrDefault();
                if (batchTypeFromDB == null)
                {
                    throw new DMSException(string.Format("Batch type {0} is not set up in the system", batchType));
                }

                b.BatchTypeID = batchTypeFromDB.ID;

                var batchStatusFromDB = dbContext.BatchStatus.Where(bs => bs.Name == batchStatus).FirstOrDefault();
                if (batchStatusFromDB == null)
                {
                    throw new DMSException(string.Format("Batch Status {0} is not set up in the system", batchStatus));
                }

                b.BatchStatusID = batchStatusFromDB.ID;

                dbContext.Batches.Add(b);
                dbContext.SaveChanges();

                return b.ID;
            }
        }

        /// <summary>
        /// Updates the batch statistics.
        /// </summary>
        /// <param name="batchID">The batch unique identifier.</param>
        /// <param name="batchStatus">The batch status.</param>
        /// <param name="totalCount">The total count.</param>
        /// <param name="totalAmount">The total amount.</param>
        /// <param name="currentUser">The current user.</param>
        /// <exception cref="DMSException"></exception>
        public decimal UpdateBatchStatistics(long batchID, string batchStatus, List<int> invoicesOrClaims, string currentUser, string entity, long? unbilledBatchID = null)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //var batch = dbContext.Batches.Where(x => x.ID == batchID).FirstOrDefault();
                //if (batch != null)
                //{
                    decimal? totalAmount = 0;
                    StringBuilder invoicesOrClaimsXML = new StringBuilder();
                    if (EntityNames.VENDOR_INVOICE.Equals(entity, StringComparison.InvariantCultureIgnoreCase) || EntityNames.BILLING_INVOICE.Equals(entity, StringComparison.InvariantCultureIgnoreCase))
                    {
                        invoicesOrClaimsXML.Append("<Invoices>");

                        invoicesOrClaims.ForEach(i =>
                        {
                            invoicesOrClaimsXML.AppendFormat("<ID>{0}</ID>", i);
                        });
                        invoicesOrClaimsXML.Append("</Invoices>");
                    }
                    else if (EntityNames.CLAIM.Equals(entity, StringComparison.InvariantCultureIgnoreCase))
                    {
                        invoicesOrClaimsXML.Append("<Claims>");

                        invoicesOrClaims.ForEach(i =>
                        {
                            invoicesOrClaimsXML.AppendFormat("<ID>{0}</ID>", i);
                        });
                        invoicesOrClaimsXML.Append("</Claims>");
                    }

                    //var batchStatusFromDB = dbContext.BatchStatus.Where(b => b.Name == batchStatus).FirstOrDefault();
                    //if (batchStatusFromDB == null)
                    //{
                    //    throw new DMSException(string.Format("Batch status - {0} is not set up in the system", batchStatus));
                    //}
                    //batch.BatchStatusID = batchStatusFromDB.ID;
                    //batch.TotalCount = invoicesOrClaims.Count;
                    //batch.TotalAmount = totalAmount.GetValueOrDefault();
                    //batch.ModifyBy = currentUser;
                    //batch.ModifyDate = DateTime.Now;
                    totalAmount = dbContext.UpdateBatchStatistics(invoicesOrClaimsXML.ToString(), batchID, batchStatus, currentUser, entity, unbilledBatchID).SingleOrDefault<decimal?>();
                    dbContext.SaveChanges();

                    return totalAmount.GetValueOrDefault();
                //}

                //return 0;
            }
        }

    }
}
