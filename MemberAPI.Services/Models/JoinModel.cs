using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services.Models
{
    public class JoinModel
    {
        public int PlanID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Suffix { get; set; }
        public DateTime? BirthDate { get; set; }
        public string Address1 { get; set; }
        public string Address2 { get; set; }
        public string City { get; set; }
        public string StateProvince { get; set; }
        public string PostalCode { get; set; }
        public string CountryCode { get; set; }
        public int HomePhoneNumber { get; set; }
        public int CellPhoneNumber { get; set; }
        public string Email { get; set; }
        public decimal AnnualDuesAmount { get; set; }
        public string PromotionalCode { get; set; }
        public decimal PaymentAmount { get; set; }
        public string CreditCardType { get; set; }
        public string CreditCardHolderName { get; set; }
        public string CreditCardNumber { get; set; }
        public string CreditCardExpirationDate { get; set; }
        public string CreditCardSecurityCode { get; set; }
    }
}
