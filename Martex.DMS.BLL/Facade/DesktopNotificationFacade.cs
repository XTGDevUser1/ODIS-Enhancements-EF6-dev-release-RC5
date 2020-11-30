using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    public class DesktopNotificationFacade
    {
        public void CreateConnection(DesktopNotification connection)
        {
            DesktopNotificationRepository repository = new DesktopNotificationRepository();
            repository.CreateConnection(connection);
        }

        public void RemoveConnection(string connectionID)
        {
            DesktopNotificationRepository repository = new DesktopNotificationRepository();
            repository.RemoveConnection(connectionID);
        }

        public List<DesktopNotification> GetUserLiveConnections(string userName)
        {
            DesktopNotificationRepository repository = new DesktopNotificationRepository();
            return repository.GetUserLiveConnections(userName);
        }

        public int ActiveConnectionsCountExcept(string userName)
        {
            DesktopNotificationRepository repository = new DesktopNotificationRepository();
            return repository.ActiveConnectionsCountExcept(userName);
        }

        public int ActiveConnectionsCount()
        {
            DesktopNotificationRepository repository = new DesktopNotificationRepository();
            return repository.ActiveConnectionsCount();
        }
    }
}
