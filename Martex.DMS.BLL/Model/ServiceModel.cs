using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using log4net;
using System.IO;
using System.Xml.Serialization;

namespace Martex.DMS.BLL.Model
{
    public class ServiceEligibilityModel
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ServiceEligibilityModel));
        public List<VerifyProgramServiceEventLimit_Result> ProgramServiceEventLimit { get; set; }
        public List<VerifyProgramServiceBenefit_Result> ServiceBenefit { get; set; }
        public string CaseDetailsMemberStatus { get; set; }
        public bool? CaseDetailsIsVehicleEligible { get; set; }

        public string PrimaryServiceCoverageDescription { get; set; }
        public string SecondaryServiceCoverageDescription { get; set; }

        public string PrimaryServiceEligiblityMessage { get; set; }
        public string SecondaryServiceEligiblityMessage { get; set; }

        public bool? IsPrimaryOverallCovered { get; set; }
        public bool? IsSecondaryOverallCovered { get; set; }

        public decimal? PrimaryCoverageLimit { get; set; }
        public decimal? SecondaryCoverageLimit { get; set; }

        public int? PrimaryCoverageLimitMileage { get; set; }
        public int? SecondaryCoverageLimitMileage { get; set; }

        public string MileageUOM { get; set; }
        public bool? IsServiceCovered { get; set; }
        public int? CurrencyTypeID { get; set; }
        public string CurrencyTypeName { get; set; }
        public int? ProgramServiceEventLimitID { get; set; }
        public bool? IsServiceCoverageBestValue { get; set; }
        public bool? IsReimbursementOnly { get; set; }
        public bool? IsServiceGuaranteed { get; set; }


        public bool? IsSecondaryProductCovered { get; set; }
        public bool? IsPrimaryProductCovered { get; set; }

        public bool? HasWarrantyApplies { get; set; }
        public bool? HasMemberEligibilityApplies { get; set; }
        public int? PrimaryProductID
        {
            get;
            set;
        }

        public bool IsFordProgram
        {
            get;
            set;
        }

        /// <summary>
        /// Returns a <see cref="System.String" /> that represents this instance.
        /// </summary>
        /// <returns>
        /// A <see cref="System.String" /> that represents this instance.
        /// </returns>
        public override string ToString()
        {
            StringWriter writer = new StringWriter();
            XmlSerializer ser = new XmlSerializer(typeof(ServiceEligibilityModel));
            ser.Serialize(writer, this);
            return writer.ToString();
        }

    }
}
