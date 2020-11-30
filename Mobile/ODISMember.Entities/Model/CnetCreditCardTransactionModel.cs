using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class CnetCreditCardTransactionModel
    {
        public int AuthType { get; set; }
        public string AuthorizationCode { get; set; }
        public string CCNumber { get; set; }
        public int CreditCardType { get; set; }
        public string ExpirationDate { get; set; }
        public string NameOnAccount { get; set; }
        public string ProcessorReferenceNumber { get; set; }
        public string ReferenceNumber { get; set; }
    }
}
