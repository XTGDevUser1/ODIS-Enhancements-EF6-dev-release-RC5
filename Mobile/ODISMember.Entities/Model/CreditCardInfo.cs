using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class CreditCardInfo
    {
        public string BillingAddress1;
        public string BillingAddress2;
        public string BillingCity;
        public string BillingState;
        public string BillingZip;
        public string CardExpirationMM;
        public string CardExpirationYYYY;
        public ODISMember.Entities.Constants.CreditCardCardType CardType;
        public string CCNameOnCard;
        public string EncryptCardNumber;
        public decimal PaymentTotal;
    }
}
