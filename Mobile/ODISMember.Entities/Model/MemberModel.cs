using System;

namespace ODISMember.Entities.Model
{
	public class MemberModel
	{
        public int PlanID
        {
            get;
            set;
        }
		public string Plan {
			get;
			set;
		}
		public string FirstName {
			get;
			set;
		}
		public string LastName {
			get;
			set;
		}
		public string Suffix {
			get;
			set;
		}
		public DateTime BirthDate {
			get;
			set;
		}
		public string Address1 {
			get;
			set;
		}
		public string Address2 {
			get;
			set;
		}
		public string City {
			get;
			set;
		}
		public string StateProvince {
			get;
			set;
		}
		public string PostalCode {
			get;
			set;
		}
		public string CountryCode {
			get;
			set;
		}
		public long HomePhoneNumber {
			get;
			set;
		}
		public long CellPhoneNumber {
			get;
			set;
		}
		public string Email {
			get;
			set;
		}

		public double AnnualDuesAmount {
			get;
			set;
		}
		public string PromotionalCode {
			get;
			set;
		}
		public double PaymentAmount {
			get;
			set;
		}

		public string CreditCardType {
			get;
			set;
		}
		public string CreditCardHolderName {
			get;
			set;
		}
		public string CreditCardNumber {
			get;
			set;
		}
		public string CreditCardExpirationDate {
			get;
			set;
		}

		public string CreditCardSecurityCode {
			get;
			set;
		}

		public string MemberFullName {
			get{ return this.FirstName + " " + this.LastName;}
		}
		public string StringDOB {
			get{ return this.BirthDate.ToString ("D");}
		}
	}
}

