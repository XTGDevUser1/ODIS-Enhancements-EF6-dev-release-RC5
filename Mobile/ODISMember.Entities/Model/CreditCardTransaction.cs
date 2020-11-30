using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
   public class CreditCardTransaction
    {
        public string AuthorizationCode;
        public ODISMember.Entities.Constants.EnumCreditCardAuthorizationType AuthType;
        public string CCNumber;
        public ODISMember.Entities.Constants.enumCreditCardType CreditCardType;
        public DateTime ExpirationDate;
        public string NameOnAccount;
        public string ProcessorReferenceNumber;
        public string ReferenceNumber;
        public DateTime TransactionDate;
    }
}
