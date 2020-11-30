using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;
using System.IO;
using System.Text;

namespace VendorPortal.Models
{
    [Serializable]
    public class VendorSearchFilters
    {
        public string From { get; set; }
        public int Radius { get; set; }
        public bool ShowCalled { get; set; }
        public bool ShowNotCalled { get; set; }
        public bool ShowDoNotUse { get; set; }
        public string ProductOptions { get; set; }

        public override string ToString()
        {   
            StringWriter writer = new StringWriter();
            XmlSerializer ser = new XmlSerializer(typeof(VendorSearchFilters));
            ser.Serialize(writer, this);
            return writer.ToString();
        }

    }
}