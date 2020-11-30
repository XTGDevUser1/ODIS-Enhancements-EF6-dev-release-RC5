using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.AspNet.SignalR;
using System.Threading.Tasks;
using System.Web.Security;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using System.Web.Mvc;
using log4net;

namespace Martex.DMS.Hubs
{

    public class NotificationHub : Hub
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(NotificationHub));
        #region Broad Cast Message to Every One Except Caller
        //Except Caller can be omitted by Current Connection ID
        public void Broadcast(string message)
        {
            DesktopNotificationFacade facade = new DesktopNotificationFacade();
            int activeConnectionCount = facade.ActiveConnectionsCountExcept(Context.User.Identity.Name);
            string[] activeConnections = facade.GetUserLiveConnections(Context.User.Identity.Name).Select(u => u.ConnectionID).ToArray();
            Clients.AllExcept(activeConnections).processBroadcastCallBack(message + " Processed From : " + System.Environment.MachineName);
            Clients.Caller.processBroadcastCallBackSuccess(string.Format("Message Broadcast to {0} Users", activeConnectionCount));
        }

        #endregion

        #region Send Message to Particular User

        //Before Sending the Message three things to do.
        //1.Detemine WHO, where who refers to target person to whom we are trying to send the message.
        //2.Validate WHO from membership and Check whether WHO is connected to system or not.
        //3.If who is connected then send a message other wise notify caller that Who is not online.

        public OperationResult SendMessage(string who, string message, int autoCloseDelay = 0)
        {
            OperationResult result = new OperationResult();
            try
            {
                var user = Context.User.Identity.Name;
                DesktopNotificationFacade facade = new DesktopNotificationFacade();
                MembershipUser reciever = System.Web.Security.Membership.GetUser(who);
                if (reciever != null)
                {
                    var liveConnections = facade.GetUserLiveConnections(who);
                    logger.InfoFormat("SIGNALR: Number of live connections for user - {0} = {1}", who, liveConnections == null ? 0 : liveConnections.Count);
                    if (liveConnections != null && liveConnections.Count > 0)
                    {
                        foreach (var connection in liveConnections)
                        {
                            //Clients.Client(connection.ConnectionID).sendMessageCallBack(string.Format("You have message from {0} and Message is {1}", user, message));
                            Clients.Client(connection.ConnectionID).sendMessageCallBack(message, autoCloseDelay);
                        }
                        Clients.Caller.sendMessageCallBackSuccess(string.Format("Message delivered to {0}", who));
                    }
                    else
                    {
                        string errorMesgage = string.Format("User {0} is no longer connected", who);
                        logger.InfoFormat("SIGNALR: {0}", errorMesgage);
                        result.Status = OperationStatus.ERROR;
                        result.ErrorMessage = errorMesgage;
                        Clients.Caller.showErrorMessageCallBack(errorMesgage);
                    }
                }
                else
                {
                    string errorMesgage = string.Format("We are unable to process your request. Unable to find user {0}", who);
                    result.Status = OperationStatus.ERROR;
                    result.ErrorMessage = errorMesgage;
                    Clients.Caller.showErrorMessageCallBack(errorMesgage);
                }
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
            }
            return result;
        }
        #endregion

        #region On Connected and Disconnected

        public override Task OnConnected()
        {
            DesktopNotificationFacade facade = new DesktopNotificationFacade();
            var userName = Context.User.Identity.Name;
            facade.CreateConnection(new DesktopNotification()
            {
                ConnectionID = Context.ConnectionId,
                UserAgent = Context.Request.Headers["User-Agent"],
                IsConnected = true,
                UserName = userName
            });
            return base.OnConnected();
        }

        public override Task OnDisconnected()
        {
            DesktopNotificationFacade facade = new DesktopNotificationFacade();
            facade.RemoveConnection(Context.ConnectionId);
            return base.OnDisconnected();
        }

        #endregion
    }
}