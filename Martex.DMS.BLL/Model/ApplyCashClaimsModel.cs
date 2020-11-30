using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    public class ApplyCashClaimsModel
    {
        public decimal? OnAccount { get; set; }
        public List<ClaimApplyCashClaimsList_Result> ClaimsList { get; set; }
        public decimal? AmountApplied { get; set; }
        public decimal? AmountRemaining { get; set; }
    }
}
