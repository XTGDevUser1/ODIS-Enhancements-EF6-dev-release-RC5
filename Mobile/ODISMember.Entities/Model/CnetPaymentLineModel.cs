using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class CnetPaymentLineModel
    {
        public int DiscountAmount { get; set; }
        public int FeeAmount { get; set; }
        public int ProductAmount { get; set; }
        public string ProductCode { get; set; }
    }
}
