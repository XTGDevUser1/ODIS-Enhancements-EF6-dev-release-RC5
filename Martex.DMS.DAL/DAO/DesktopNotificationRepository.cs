using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    public class DesktopNotificationRepository
    {
        public void CreateConnection(DesktopNotification connection)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                dbcontext.DesktopNotifications.Add(connection);
                dbcontext.SaveChanges();
            }
        }

        public int ActiveConnectionsCount()
        {
            int activeConnections = 0;
            using (DMSEntities dbcontext = new DMSEntities())
            {
                activeConnections = dbcontext.DesktopNotifications.Where(u => u.IsConnected == true).Count();
            }
            return activeConnections;
        }

        public int ActiveConnectionsCountExcept(string userName)
        {
            int activeConnections = 0; 
            using (DMSEntities dbcontext = new DMSEntities())
            {
                activeConnections = dbcontext.DesktopNotifications.Where(u => u.IsConnected == true && u.UserName != userName).Count();
            }
            return activeConnections;
        }

        public void RemoveConnection(string connectionID)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                var existingConnection = dbcontext.DesktopNotifications.Where(u => u.ConnectionID == connectionID).FirstOrDefault();
                if (existingConnection != null)
                {
                    dbcontext.DesktopNotifications.Remove(existingConnection);
                    dbcontext.SaveChanges();
                }        
            }
        }

        public List<DesktopNotification> GetUserLiveConnections(string userName)
        {
            using (DMSEntities dbcontext = new DMSEntities())
            {
                return dbcontext.DesktopNotifications.Where(u => u.UserName == userName && u.IsConnected == true).ToList();
            }
        }
    }
}
