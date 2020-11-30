using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class CnetInitialPaymentModel
    {
        public CnetCheckTransactionModel CnetCheckTransaction { get; set; }
        public CnetCreditCardTransactionModel CnetCreditCardTransaction { get; set; }
        public CnetPaymentLineModel CnetPaymentLine { get; set; }
        public string MembershipNumber { get; set; }
        public int TransactionAmount { get; set; }
        public int TransactionType { get; set; }
    }
}
