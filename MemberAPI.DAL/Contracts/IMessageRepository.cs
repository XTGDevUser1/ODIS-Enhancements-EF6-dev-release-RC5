using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.DAL
{
    public interface IMessageRepository
    {
        /// <summary>
        /// Gets the error message for a given organizationid and key combination
        /// </summary>
        /// <param name="organizationId">The organization identifier.</param>
        /// <param name="key">The key.</param>
        /// <returns>Error message</returns>
        string GetErrorMessage(int organizationId, string key);
    }
}
