using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services
{
    public class MemberException : ApplicationException
    {
        public MemberException() : base() { }
        public MemberException(string message) : base(message) { }
        public MemberException(string message, System.Exception inner) : base(message, inner) { }
        // A constructor is needed for serialization when an 
        // exception propagates from a remoting server to the client.  
        protected MemberException(System.Runtime.Serialization.SerializationInfo info,
        System.Runtime.Serialization.StreamingContext context) { }
    }
}
