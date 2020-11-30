using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Contract
{
    public interface ILoggerHelper
    {
        void Debug(string message);
        void Error(Exception exception);
        void Info(string message);
    }
}
