using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    public class NotificationRepository
    {
        public List<UsersOrRolesForNotification_Result> GetUsersOrRolesForNotification(int? recipientTypeID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetUsersOrRolesForNotification(recipientTypeID).ToList();
            }
        }
    }
}
