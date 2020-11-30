using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Xml.Serialization;

namespace Martex.DMS.DAL.Entities
{
    public class CallLog
    {
        public int? ContactActionID { get; set; }
        public int? ContactReasonID { get; set; }
        public string CallLogTalkedTo { get; set; }
        public string CallLogComments { get; set; }
        public string PhoneNumberCalled { get; set; }
        public string PhoneType { get; set; }
        public string Company { get; set; }
        public int? VendorID { get; set; }
        public int? VendorLocationID { get; set; }
        public Dictionary<string, string> DynamicDataElements { get; set; }
        
        //public override string ToString()
        //{
        //    StringWriter writer = new StringWriter();
        //    XmlSerializer ser = new XmlSerializer(typeof(CallLog));
        //    ser.Serialize(writer, this);
        //    return writer.ToString();
        //}
    }
}
