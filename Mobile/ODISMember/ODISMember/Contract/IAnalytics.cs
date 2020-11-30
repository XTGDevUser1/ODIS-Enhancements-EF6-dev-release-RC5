using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Contract
{
    public interface IAnalytics
    {
        void CustomEvent(string eventName);
    }
}
