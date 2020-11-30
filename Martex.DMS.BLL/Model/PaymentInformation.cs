using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// SendReceipt
    /// </summary>
    public class SendReceipt
    {
        public int PaymentID { get; set; }
        public int ContactMethodID { get; set; }
        public string ContactMethodName { get; set; }
        public string Email { get; set; }
        public string PhoneNumber { get; set; }
        public int? PhoneTypeID { get; set; }

        public int MemberID { get; set; }

    }
    /// <summary>
    /// PaymentInformation
    /// </summary>
    public class PaymentInformation
    {
        public Payment Payment { get; set; }
        public int CardExpirationYear { get; set; }
        public int CardExpirationMonth { get; set; }
        public decimal? DispatchFee { get; set; }
        public decimal? ISPCharge { get; set; }
        public decimal? FinalCharge { get; set; }
        public int? SecurityCode { get; set; }

        public double MaximunAmount { get; set; }
        public double MinimumAmount { get; set; }
        public double TotalPayment { get; set; }

        public List<Payment_List_Result> PaymentDetails { get; set; }
        public List<PaymentTransactionList_Result> PaymentTransactions { get; set; }
        public List<MemberPaymentMethodList_Result> MemberPaymentMethods { get; set; }

        public string Mode { get; set; }

        public int CurrentMonth {
            get {
                return DateTime.Now.Month;
            }
        }

        public int CurrentYear
        {
            get
            {
                return DateTime.Now.Year;
            }
        }

        public string PaymentStatus { get; set; }
        public string AuthorizationType { get; set; }
        public string AuthorizationCode { get; set; }
        public string TransactionReference { get; set; }

        public bool IsCreditProcessing { get; set; }
        public bool Credit_IsVoidTransaction { get; set; }
        public string Credit_CCOrderID { get; set; }
        public string Credit_ResponseTDate { get; set; }


        // For Sent Reciept
        public int? SR_ContactMethodID { get; set; }
        public string SR_Email { get; set; }
        public string SR_PhoneNumber { get; set; }
        public int SR_PaymentID { get; set; }

        public int MemberID { get; set; }
        public string ClientName { get; set; }
    }
}
