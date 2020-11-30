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
using Martex.DMS.BLL.Model;
using Martex.DMS.DAO;

namespace Martex.DMS.BLL.Facade
{
    public partial class ClaimsFacade
    {
        /// <summary>
        /// Gets the ACES payments list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ACESPaymentList_Result> GetACESPaymentsList(PageCriteria pc)
        {
            return repository.GetACESPaymentsList(pc);
        }


        /// <summary>
        /// Deletes the ACES payment.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <param name="currentUser">The current user.</param>
        public void DeleteACESPayment(ACESPaymentList_Result payment, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                decimal? oldPaymentValue = repository.DeleteACESPayment(payment, currentUser);
                repository.UpdateClientPaymentAmount(currentUser,oldPaymentValue.GetValueOrDefault(),(decimal)0);
                tran.Complete();
            }
        }


        /// <summary>
        /// Updates the ACES payment.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <param name="currentUser">The current user.</param>
        public void UpdateACESPayment(ACESPaymentList_Result payment, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                decimal? oldPaymentValue = repository.UpdateACESPayment(payment, currentUser);
                repository.UpdateClientPaymentAmount(currentUser,oldPaymentValue.GetValueOrDefault(),payment.TotalAmount.GetValueOrDefault());
                StringBuilder sb = new StringBuilder();
                sb.Append("Check " + payment.CheckNumber);
                sb.Append(" dated " + payment.CheckDate);
                sb.Append(" for " + payment.TotalAmount);
                sb.Append(" received on " + payment.RecievedDate);
                sb.Append(" Comment: " + payment.Comment);
                long eventID = eventLoggerFacade.LogEvent(EntityNames.CLIENT, EventNames.UPDATE_CLIENT_PAYMENT, sb.ToString(), currentUser, null);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, payment.ID, EntityNames.CLIENT_PAYMENT);
                tran.Complete();
            }
        }


        /// <summary>
        /// Inserts the ACES payment.
        /// </summary>
        /// <param name="payment">The payment.</param>
        /// <param name="currentUser">The current user.</param>
        public void InsertACESPayment(ACESPaymentList_Result payment, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                repository.InsertACESPayment(payment, currentUser);
                repository.UpdateClientPaymentAmount(currentUser, (decimal)0, payment.TotalAmount.GetValueOrDefault());
                StringBuilder sb = new StringBuilder();
                sb.Append("Check " + payment.CheckNumber);
                sb.Append(" dated " + payment.CheckDate);
                sb.Append(" for " + payment.TotalAmount);
                sb.Append(" received on " + payment.RecievedDate);
                sb.Append(" Comment: " + payment.Comment);
                long eventID = eventLoggerFacade.LogEvent(EntityNames.CLIENT, EventNames.ADD_CLIENT_PAYMENT, sb.ToString(), currentUser, null);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, payment.ID, EntityNames.CLIENT_PAYMENT);
                tran.Complete();
            }
        }

        /// <summary>
        /// Gets the apply cash claims list.
        /// </summary>
        /// <returns>ApplyCashClaimsModel</returns>
        public ApplyCashClaimsModel GetApplyCashClaimsDetails()
        {
            ApplyCashClaimsModel model = new ApplyCashClaimsModel();
            model.ClaimsList = repository.GetApplyCashClaimsList();
            model.OnAccount = 0;
            model.AmountApplied = 0;
            model.AmountRemaining = 0;
            return model;
        }

        public List<ClaimApplyCashClaimsList_Result> GetApplyCashClaimsList()
        {
            return repository.GetApplyCashClaimsList();
        }

        public void UpdateCashClaims(int clientId, string eventSource, string currentUser, string sessionID, string[] claimIds, decimal amountapplied, decimal amountbalance)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ClaimsRepository claimrepository = new ClaimsRepository();
                DateTime modifiedDate = DateTime.Now;
                Dictionary<string, string> eventLogDescription = new Dictionary<string, string>();
                ClientRepository clienrepository = new ClientRepository();
                Client client = clienrepository.Get(clientId);
                decimal oldBalance = (client.PaymentBalance != null) ? client.PaymentBalance.Value : 0;

                eventLogDescription.Add("StartingPaymentBalance", oldBalance.ToString());
                eventLogDescription.Add("TotalAppliedAmount", amountapplied.ToString());
                eventLogDescription.Add("EndingPaymentBalance", amountbalance.ToString());

                foreach (string claimId in claimIds)
                {
                    claimrepository.UpdateApplyCashClaims(modifiedDate, currentUser, int.Parse(claimId), modifiedDate, amountapplied);
                }

                claimrepository.UpdateClientBalance(amountbalance, clientId, currentUser, modifiedDate);

                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                long eventLogID = eventLoggerFacade.LogEvent(eventSource, EventNames.APPLY_CLIENT_PAYMENTS, eventLogDescription, currentUser, sessionID);

                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, clientId, EntityNames.CLAIM_PAYMENT);

                foreach (string claimId in claimIds)
                {
                    eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, int.Parse(claimId), EntityNames.CLAIM);
                }


                tran.Complete();
            }
        }
    }
}
