using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.DAL
{
    public class MessageRepository : IMessageRepository
    {
        /// <summary>
        /// Gets the error message for a given organizationid and key combination
        /// </summary>
        /// <param name="organizationId">The organization identifier.</param>
        /// <param name="key">The key.</param>
        /// <returns>
        /// Error message
        /// </returns>        
        public string GetErrorMessage(int organizationId, string key)
        {
            using (APTIFYEntities dbContext = new APTIFYEntities())
            {
                var message = dbContext.NMCAPIMessages.Where(x => x.OrganizationID == organizationId && x.Name == key).FirstOrDefault();
                if (message != null)
                {
                    return message.MessageText;
                }
            }
            return string.Empty;
        }
    }
}
