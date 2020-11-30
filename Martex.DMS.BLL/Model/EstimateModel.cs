using Martex.DMS.DAL;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model
{
    public class EstimateModel
    {
        public decimal? ServiceEstimate { get; set; }
        public List<ProgramInformation_Result> EstimateInstructions { get; set; }
        public int ServiceRequestID { get; set; }
        public bool? IsServiceEstimateAccepted { get; set; }
        public int? ServiceEstimateDenyReasonID { get; set; }
        public string EstimateDeclinedReasonOther { get; set; }
        public PaymentInformation PaymentInformation { get; set; }
        public string PaymentMode { get; set; }
        public decimal EstimatedTimeCost { get; set; }
    }
}
