using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO.VendorPortal
{
    public class MessageRepository
    {
        public List<Message> GetMessages(string scope)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMessage(scope).ToList();
            }
        }
    }
}
