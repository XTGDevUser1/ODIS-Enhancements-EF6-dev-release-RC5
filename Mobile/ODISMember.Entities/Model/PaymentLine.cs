using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class PaymentLine
    {
        public decimal DiscountAmount { get; set; }
        public decimal FeeAmount { get; set; }
        public decimal ProductAmount { get; set; }
        public string ProductCode { get; set; }
    }
}
