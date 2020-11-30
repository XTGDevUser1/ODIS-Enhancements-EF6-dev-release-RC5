using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Runtime.Serialization;

namespace ClientPortalService
{
    public class ValidationError
    {
        public string Key { get; set; }
        public string Message { get; set; }
    }

    [DataContract]
    public class ValidationFault
    {
        [DataMember]
        public List<ValidationError> ValidationErros { get; set; }
    }
}