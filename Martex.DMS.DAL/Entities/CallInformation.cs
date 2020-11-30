using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Xml.Serialization;

namespace Martex.DMS.DAL.Entities
{
    [Serializable]
    public class CallInformation
    {
        public int MemberProgramID { get; set; }
        public int? ProgramId { get; set; }
        public int? CallTypeId { get; set; }
        public int? LanguageId { get; set; }
       
        public int? ContactPhoneTypeID  { get; set; }
        public string ContactPhoneNumber { get; set; }
        
        
        public int? ContactAltPhoneTypeID { get; set; }
        public string ContactAltPhoneNumber { get; set; }
        
        
        public int? MemberId { get; set; }
        public int? MembershipId { get; set; }
        public KeyValuePair<string,int?> UserProfile{ get; set; }
        public int InboundCallId { get; set; }
        public string EventSource { get; set; }
        public Dictionary<string, string> DynamicDataElements { get; set; }
        public int? CaseID { get; set; }

        public bool? isSafe { get; set; }

        public string ClientName { get; set; }

        //public override string ToString()
        //{
        //    StringWriter writer = new StringWriter();
        //    XmlSerializer ser = new XmlSerializer(typeof(CallInformation));
        //    ser.Serialize(writer, this);
        //    return writer.ToString();
        //}
    }
}
