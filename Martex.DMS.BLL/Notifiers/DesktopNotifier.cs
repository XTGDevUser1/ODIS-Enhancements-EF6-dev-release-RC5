using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Configuration;
using Microsoft.AspNet.SignalR.Client.Hubs;
using Microsoft.AspNet.SignalR.Client;
using System.Threading.Tasks;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.Facade;
using log4net;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

namespace Martex.DMS.BLL.Communication
{
    public class DesktopNotifier : INotifier
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(DesktopNotifier));
        public void Notify(CommunicationQueue communicationQueue)
        {
            DesktopNotificationFacade facade = new DesktopNotificationFacade();
            var liveConnections = facade.GetUserLiveConnections(communicationQueue.NotificationRecipient);
            logger.InfoFormat("SIGNALR: Number of live connections for user - {0} = {1}", communicationQueue.NotificationRecipient, liveConnections == null ? 0 : liveConnections.Count);
            if (liveConnections.Count > 0)
            {
                Hashtable ht = new Hashtable();
                int autoCloseDelay = 0;
                try
                {
                    ht = communicationQueue.MessageData.XMLToKeyValuePairs();
                    if (ht.ContainsKey("AutoClose"))
                    {
                        int.TryParse(ht["AutoClose"].ToString(), out autoCloseDelay);
                    }
                }
                catch (Exception)
                {
                    // An attempt to get the AutoClose property failed, so make the window an always visible one.
                }

                var host = ConfigurationManager.AppSettings["Host"];

                var connection = new HubConnection(host);
                connection.TraceLevel = TraceLevels.All;
                connection.TraceWriter = Console.Out;
                var hubProxy = connection.CreateHubProxy("NotificationHub");
                connection.Start().Wait();

                Task t = hubProxy.Invoke("SendMessage", communicationQueue.NotificationRecipient, communicationQueue.MessageText, autoCloseDelay.ToString());

                dynamic result = t;
                var taskResult = result.Result;
                //Console.WriteLine("Status : " + taskResult.Status.ToString());
                if (!"Success".Equals(taskResult.Status.ToString(), StringComparison.InvariantCultureIgnoreCase))
                {
                    throw new Exception("Unable to notify the user. Possible reasons: User not online.");
                }
                connection.Stop();
            }
        }
    }
}
