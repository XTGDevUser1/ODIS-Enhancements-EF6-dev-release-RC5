using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Interfaces
{
    public interface IPushNotification
    {

        /// <summary>
        /// Registers Device for Push Notifications
        /// </summary>
        /// <param name="userName">User Name of loggedin user</param>
        void Register(string userName);
    }
}
