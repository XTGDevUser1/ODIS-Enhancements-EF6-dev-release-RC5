using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{

    public class ClaimStatusSummary
    {
        public int Approved { get; set; }
        public decimal ApprovedAmount { get; set; }

        public int ReadyForPayment { get; set; }
        public decimal ReadyForPaymentAmount { get; set; }

        public int Rejected { get; set; }
        public decimal RejectedAmount { get; set; }

        public int OnHold { get; set; }
        public decimal OnHoldAmount { get; set; }

        public int InProcess { get; set; }
        public decimal InProcessAmount { get; set; }

        public int Received { get; set; }
        public decimal ReceivedAmount { get; set; }

        public int Cancelled { get; set; }
        public decimal CancelledAmount { get; set; }

        public int Paid { get; set; }
        public decimal PaidAmount { get; set; }

        public int Exceptions { get; set; }
        public decimal ExceptionsAmount { get; set; }

        protected List<int> claimsWithExceptions = new List<int>();
        public List<int> ClaimsWithExceptions
        {
            get
            {
                return claimsWithExceptions;
            }
        }

        protected List<int> claimsReadyForPayment = new List<int>();
        public List<int> ClaimsReadyForPayment
        {
            get
            {
                return claimsReadyForPayment;
            }
        }

    }
}


