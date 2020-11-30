using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DMSBaseException
{
    public class DMSException : ApplicationException
    {
        public DMSException() : base(){}
        public DMSException(string message) : base(message) { }
        public DMSException(string message, System.Exception inner) : base(message, inner) { }
        // A constructor is needed for serialization when an 
       // exception propagates from a remoting server to the client.  
       protected DMSException(System.Runtime.Serialization.SerializationInfo info,
        System.Runtime.Serialization.StreamingContext context) { }
    }

}
