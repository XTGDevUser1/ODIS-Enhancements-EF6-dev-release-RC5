using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Xml.Serialization;

namespace Martex.DMS.BLL.Model.VendorPortal
{
    public class VendorInvoiceModel
    {
        public int? VendorID { get; set; }
        public string PONumber { get; set; }
        public string InvoiceNumber { get; set; }
        public decimal InvoiceAmount { get; set; }
        public decimal? PayAmount { get; set; }
        public int? Hours { get; set; }
        public int? Minutes { get; set; }
        public string VIN { get; set; }
        public int? Mileage { get; set; }

        public DateTime? InvoiceDate { get; set; }
        public DateTime? ReceivedDate { get; set; }
        public int InvoiceID { get; set; }

        public DateTime? ToBePaidDate { get; set; }


        public bool AllowLowerPOAmount { get; set; }
        public bool AllowLapsedPOs { get; set; }
        //NP 10/15 : 
        public int? VendorInvoicePaymentDifferenceReasonCodeID { get; set; }

        /// <summary>
        /// Returns a <see cref="System.String" /> that represents this instance.
        /// </summary>
        /// <returns>
        /// A <see cref="System.String" /> that represents this instance.
        /// </returns>
        public override string ToString()
        {
            StringWriter writer = new StringWriter();
            XmlSerializer ser = new XmlSerializer(typeof(VendorInvoiceModel));
            ser.Serialize(writer, this);
            return writer.ToString();
        }
    }
}
