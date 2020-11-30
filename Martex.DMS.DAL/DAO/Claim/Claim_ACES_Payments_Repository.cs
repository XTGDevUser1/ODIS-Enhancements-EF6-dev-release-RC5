using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class ClaimsRepository
    {
        /// <summary>
        /// Gets the ACES payments list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ACESPaymentList_Result> GetACESPaymentsList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetACESPaymentList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<ACESPaymentList_Result>();
            }
        }

        /// <summary>
        /// Deletes the ACES payment.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <param name="currentUser">The current user.</param>
        public decimal? DeleteACESPayment(ACESPaymentList_Result payment, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                ClientPayment existingPayment = dbContext.ClientPayments.Where(a => a.ID == payment.ID).FirstOrDefault();

                decimal? oldPaymentValue = existingPayment.TotalAmount;

                existingPayment.IsActive = false;
                existingPayment.ModifyBy = currentUser;
                existingPayment.ModifyDate = DateTime.Now;
                dbContext.Entry(existingPayment).State = EntityState.Modified;
                dbContext.SaveChanges();
                return oldPaymentValue;
            }
        }

        /// <summary>
        /// Updates the ACES payment.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <param name="currentUser">The current user.</param>
        public decimal? UpdateACESPayment(ACESPaymentList_Result payment, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                ClientPayment existingPayment = dbContext.ClientPayments.Where(a => a.ID == payment.ID).FirstOrDefault();
                decimal? oldPaymentValue = existingPayment.TotalAmount;

                existingPayment.CheckDate = payment.CheckDate;
                existingPayment.CheckNumber = payment.CheckNumber;
                existingPayment.TotalAmount = payment.TotalAmount;
                existingPayment.RecievedDate = payment.RecievedDate;
                existingPayment.Comment = payment.Comment;

                existingPayment.ModifyBy = currentUser;
                existingPayment.ModifyDate = DateTime.Now;
                dbContext.Entry(existingPayment).State = EntityState.Modified;
                dbContext.SaveChanges();
                return oldPaymentValue;
            }
        }


        /// <summary>
        /// Inserts the ACES payment.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <param name="currentUser">The current user.</param>
        public void InsertACESPayment(ACESPaymentList_Result payment, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                ClientPayment newPayment = new ClientPayment();
                PaymentType paymentType = dbContext.PaymentTypes.Where(a => a.Name == PaymentTypeName.CHECK).FirstOrDefault();
                if (paymentType == null)
                {
                    throw new DMSException("Payment Type - Check not found in database.");
                }
                newPayment.CheckDate = payment.CheckDate;
                newPayment.CheckNumber = payment.CheckNumber;
                newPayment.TotalAmount = payment.TotalAmount;
                newPayment.RecievedDate = payment.RecievedDate;
                newPayment.Comment = payment.Comment;
                newPayment.IsActive = true;
                newPayment.PaymentTypeID = paymentType.ID;
                newPayment.CreateBy = currentUser;
                newPayment.CreateDate = DateTime.Now;
                dbContext.ClientPayments.Add(newPayment);
                dbContext.SaveChanges();
            }
        }

        public void UpdateClientPaymentAmount(string currentUser, decimal oldPaymentValue, decimal newPaymentValue)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Client client = dbContext.Clients.Where(a => a.Name == CompanyNames.FORD).FirstOrDefault();
                if(client==null)
                {
                    throw new DMSException("There is no client named FORD in system");
                }
                if (client.PaymentBalance != null)
                {
                    client.PaymentBalance = client.PaymentBalance + (newPaymentValue - oldPaymentValue);
                }
                else
                {
                    client.PaymentBalance = (newPaymentValue - oldPaymentValue);
                }
                client.ModifyBy = currentUser;
                client.ModifyDate = DateTime.Now;
                dbContext.Entry(client).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        public void UpdateApplyCashClaims(DateTime acescleareddate, string modifiedUser, int claimId, DateTime modifiedOn, decimal amountapplied)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                CommonLookUpRepository lookup = new CommonLookUpRepository();
                ACESClaimStatu claimStatus = lookup.GetACESClaimStatus("Cleared");
                Claim existingClaim = dbContext.Claims.Where(c => c.ID == claimId).FirstOrDefault();
                //NP 10/25: Updating the ACESAmount column with Applied amount from screen Ref: Bug:2025 3.1

                decimal? appliedAmount = existingClaim.AmountApproved;
                if (existingClaim.ACESFeeAmount.HasValue)
                {
                    appliedAmount += existingClaim.ACESFeeAmount;
                }
                existingClaim.ACESAmount = appliedAmount;
                existingClaim.ACESClearedDate = acescleareddate;
                existingClaim.ModifyDate = modifiedOn;
                existingClaim.ModifyBy = modifiedUser;
                existingClaim.ACESClaimStatusID = claimStatus.ID;
                dbContext.Entry(existingClaim).State = EntityState.Modified;
                dbContext.SaveChanges();
            }


        }

        public void UpdateClientBalance(decimal paymentbalance, int clientId, string modifiedUser, DateTime modifiedOn)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Client existingClient = dbContext.Clients.Where(c => c.ID == clientId).FirstOrDefault();
                existingClient.PaymentBalance = paymentbalance;
                existingClient.ModifyBy = modifiedUser;
                existingClient.ModifyDate = modifiedOn;
                dbContext.Entry(existingClient).State = EntityState.Modified;
                dbContext.SaveChanges();
            }


        }

        /// <summary>
        /// Gets the apply cash claims list.
        /// </summary>
        /// <returns></returns>
        public List<ClaimApplyCashClaimsList_Result> GetApplyCashClaimsList()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClaimApplyCashClaims().ToList<ClaimApplyCashClaimsList_Result>();
            }
        }
    }
}
