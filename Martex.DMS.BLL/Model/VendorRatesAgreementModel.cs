using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Xml.Serialization;

namespace Martex.DMS.BLL.Model
{
    public class VendorRatesAgreementModel
    {
        public string PurposeForPreview { get; set; }
        public bool SendEmail { get; set; }
        public string Email { get; set; }
        public string AdditionalText { get; set; }
        public int VendorID { get; set; }
        public int RateScheduleID { get; set; }
        public string Source { get; set; }

        public DateTime? ApplicationDate { get; set; }

        public override string ToString()
        {
            StringWriter writer = new StringWriter();
            XmlSerializer ser = new XmlSerializer(typeof(VendorRatesAgreementModel));
            ser.Serialize(writer, this);
            return writer.ToString();
        }

    }
}
