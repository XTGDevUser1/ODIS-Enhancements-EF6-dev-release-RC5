using ODISMember.Contract;
using ODISMember.Entities;
using ODISMember.Entities.Table;
using ODISMember.Services.Service;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Helpers.ModelHelper
{
    public class PushNotificationHelper
    {
        MemberService memberService;
        SQLite.Net.SQLiteConnection mConnection;
        public PushNotificationHelper(SQLite.Net.SQLiteConnection connection = null)
        {
            mConnection = connection;
            memberService = new MemberService();
        }
        
        public async Task<OperationResult> SendServiceRequestCompletedResponse(string contactLogID, string callStatus, string serviceStatus)
        {
            OperationResult registrationResult = await memberService.SendServiceRequestCompletedResponse(contactLogID, callStatus, serviceStatus);
            return registrationResult;
        }
        public void SaveNotificationIntoLocalDB(Notification notification)
        {
            if (mConnection != null)
            {
                mConnection.DeleteAll<Notification>();
                mConnection.Insert(notification);
            }
        }
        public Notification GetExistingNotification()
        {
            Data.DBRepository dbRepository = new Data.DBRepository();
            List<Notification> listNotifications = dbRepository.GetAllRecords<Notification>();
            if (listNotifications != null && listNotifications.Count > 0)
            {
                Notification localNotification = listNotifications[0];
                dbRepository.DeleteAllRecords<Notification>();
                return localNotification;
            }
            else
            {
                return null;
            }
        }
    }
}
