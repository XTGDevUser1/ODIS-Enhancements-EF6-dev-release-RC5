using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel.DataAnnotations;

namespace Martex.DMS.DAL
{
    [MetadataType(typeof(ACESPaymentList_ResultMetaData))]
    public partial class ACESPaymentList_Result
    {
        public decimal TotalAmountRequired
        {
            get
            {
                decimal totalAmount = (decimal)0;
                if (this.TotalAmount != null)
                {
                    totalAmount = this.TotalAmount.Value;
                }
                return totalAmount;
            }
            set
            {
                this.TotalAmount = value;
            }
        }

    }
    public partial class ACESPaymentList_ResultMetaData
    {

        [Required]
        public string CheckNumber { get; set; }

        [Required]
        public string PaymentType { get; set; }

        [Required]
        public DateTime? CheckDate { get; set; }

        [Required]
        [Range(typeof(decimal), "0", "79228162514264337593543950335")]
        public decimal TotalAmountRequired
        {
            get;
            set;
        }

        [Required]
        public DateTime? RecievedDate { get; set; }

    }
}
