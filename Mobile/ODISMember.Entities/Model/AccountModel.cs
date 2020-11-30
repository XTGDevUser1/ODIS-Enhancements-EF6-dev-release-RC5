using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class AccountModel
    {
        public AddressModel Address { get; set; }
        public List<AddressModel> Addresses { get; set; }
        public string ApplicationSource { get; set; }
        public bool AutoRenew { get; set; }
        public CnetInitialPaymentModel CnetInitialPayment { get; set; }
        public string EffectiveDate { get; set; }
        public string EmailAddress { get; set; }
        public string Frequency { get; set; }
        public Associate MasterMember;
        public List<Associate> Members { get; set; }
        public string MembershipNumber { get; set; }
        public string MembershipProductCode { get; set; }
        public int NumberOfDays { get; set; }
        public int NumberOfYears { get; set; }
        public string OrderSource { get; set; }
        public List<PhoneNumberModel> PhoneNumbers { get; set; }
        public string ProgramUser { get; set; }
        public string ProgramUserGroup { get; set; }
        public string PromoCode { get; set; }
        public int SalesChannelID { get; set; }
        public string SalesChannelName { get; set; }
        public string SocialClubMembershipNumber { get; set; }
        public string ExpirationDate { get; set; }
        public InitialPayment PMCInitialPayment { get; set; }
        public double PromoDiscountAmount { get; set; }
        public bool DirExclude { get; set; }
        public bool EmailExclude { get; set; }
        public EmailTemplateParams EmailParams { get; set; }

        public bool FaxExclude { get; set; }
        public decimal FeeAmount { get; set; }
        public string i5InternalMemberNumber { get; set; }
        public string i5MembershipNumber { get; set; }
        public string i5OriginalOrgID { get; set; }
        public bool MailExclude { get; set; }
        public DateTime NMCAppSubmissionDate { get; set; }
        public bool NMCInvoiceExclude { get; set; }
        public bool NMCPhoneExclude { get; set; }
        public bool NMCRenewToCompanyFlag { get; set; }
        public int NMCRenewToCompanyYears { get; set; }
        public bool PaymentPlan { get; set; }
        public CreditCardInfo PMCCreditCardInfo { get; set; }
        public Product PMCProduct { get; set; }
        public List<Product> Products { get; set; }
        public bool Towable { get; set; }
        //public List<VehicleInformation> Vehicles { get; set; }

        public string ExpirationDateString
        {
            get
            {
                DateTime dateTime;
                //if (!string.IsNullOrEmpty(ExpirationDate) && DateTime.TryParseExact(ExpirationDate, ODISMember.Entities.Constants.DateFormat, System.Globalization.DateTimeFormatInfo.InvariantInfo, System.Globalization.DateTimeStyles.None, out dateTime)) { 

                if (!string.IsNullOrEmpty(ExpirationDate) && DateTime.TryParse(ExpirationDate, out dateTime))
                {
                    return dateTime.ToString(ODISMember.Entities.Constants.DateFormat);
                }
                else
                {
                    return string.Empty;
                }
            }
        }


    }
}
