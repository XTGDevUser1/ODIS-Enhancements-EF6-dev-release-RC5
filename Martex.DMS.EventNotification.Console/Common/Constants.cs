using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.EventNotification.Console.Common
{
    public enum NotificationSender
    {
        wns,
        apns,
        gcm
    }

    public static class Constants
    {
        public const string AZURE_NOTIFICATION_LISTEN_CONNECTION_STRING = @"Endpoint=sb://membermobilenamespace.servicebus.windows.net/;SharedAccessKeyName=DefaultFullSharedAccessSignature;SharedAccessKey=OOW0mYWNwSuDj4RDRG/Xy3evrRqzQG21G1A/vtb0Krg=";
        public const string AZURE_NOTIFICATION_HUB_NAME = @"membermobilehub";
    }
}
