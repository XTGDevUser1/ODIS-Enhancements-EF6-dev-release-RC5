using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class InitialPayment
    {
        public string MembershipNumber { get; set; }
        public CheckTransaction PMCCheckTransaction { get; set; }
        public CreditCardTransaction PMCCreditCardTransaction { get; set; }
        public PaymentLine PMCPaymentLine { get; set; }
        public decimal TransactionAmount { get; set; }
        public ODISMember.Entities.Constants.EnumPaymentTransactionType TransactionType { get; set; }
    }
}
