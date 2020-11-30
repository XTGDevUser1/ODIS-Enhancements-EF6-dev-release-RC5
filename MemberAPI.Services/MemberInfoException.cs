using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services
{
    public class MemberInfoException : ApplicationException
    {
        public MemberInfoException() : base() { }
        public MemberInfoException(string message) : base(message) { }
        public MemberInfoException(string message, System.Exception inner) : base(message, inner) { }
        // A constructor is needed for serialization when an 
        // exception propagates from a remoting server to the client.  
        protected MemberInfoException(System.Runtime.Serialization.SerializationInfo info,
        System.Runtime.Serialization.StreamingContext context) { }
    }
}
