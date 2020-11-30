using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL
{
    [Serializable]
    public partial class PO_MemberPayDispatchFee_Result
    {
        public decimal? InternalDispatchFee { get; set; }
        public decimal? ClientDispatchFee { get; set; }
        public decimal? CreditCardProcessingFee { get; set; }
        public decimal? DispatchFee { get; set; }
        //TFS: 1251
        public int DispatchFeeAgentMinutes { get; set; }
        public int DispatchFeeTechMinutes { get; set; }
        public decimal? DispatchFeeTimeCost { get; set; }

        public string StringDispatchFee
        {
            get;
            set;
        }
    }
}
