using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.DigitalDispatch
{
    public class RSPModel : DigitalDispatchHeaderModel
    {
        public string JobID { get; set; }
        public string AuthorizationNumber { get; set; }
        public string MotorClubResponseCode { get; set; }
        public string MemberID { get; set; }
        public string MemberCallBackNum { get; set; }
        public int? BenefitMileLimit { get; set; }
        public decimal? BenefitDollarLimit { get; set; }
        public decimal? OverMileageRate { get; set; }
        public int? ExpectedTowMiles { get; set; }
        public int? CashPaymentOnly { get; set; }
        public decimal? CoPayAmount { get; set; }
        
        public string Remarks { get; set; }
    }
}
