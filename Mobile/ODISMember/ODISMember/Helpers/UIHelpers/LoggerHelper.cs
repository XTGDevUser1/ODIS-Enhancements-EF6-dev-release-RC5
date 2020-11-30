using ODISMember.Common;
using ODISMember.Contract;
using ODISMember.Data;
using ODISMember.Entities;
using ODISMember.Entities.Table;
using PCLStorage;
using Plugin.Messaging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Helpers.UIHelpers
{
    public class LoggerHelper : ILoggerHelper
    {
        public DBRepository dbRepository;
        public LoggerHelper()
        {
            dbRepository = new DBRepository();
        }
        public void SetIdentity(string userId)
        {
            //ApplicationInsights.SetAuthUserId(userId);
        }
        public void Debug(string message)
        {
            DependencyService.Get<IAnalytics>().CustomEvent("DEBUG: " + message);
        }

        public void Error(Exception exception)
        {
            if (exception != null)
            {
                DependencyService.Get<IAnalytics>().CustomEvent("ERROR: " + exception.ToString());
            }
            else
            {
                DependencyService.Get<IAnalytics>().CustomEvent("ERROR: exception is null");
            }
        }
        public void Info(string message)
        {
            System.Diagnostics.Debug.WriteLine("INFO: " + message);
        }
        public void Result(object message)
        {
            DependencyService.Get<IAnalytics>().CustomEvent("RESULT: " + Newtonsoft.Json.JsonConvert.SerializeObject(message));
        }

        public void TrackPageView(string pageName)
        {
        }
        public void Trace(string trace)
        {
            if (Constants.IS_LOGGING_ENABLED)
            {
                LoggerTable log = new LoggerTable();
                log.Trace = trace;
                log.CreatedDate = DateTime.Now;
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    dbRepository.InsertRecord(log);
                });
            }
        }

        public async void SendLog()
        {
            List<LoggerTable> logs = dbRepository.GetAllRecords<LoggerTable>();
            string logTrace = "no logs recorded";
            if (logs.Count > 0)
            {
                logTrace = string.Join("\r\n", logs.Where(a => a.Trace != null).Select(a => a.CreatedDate.ToString() + ": " + a.Trace).ToList());
            }
            IFolder rootFolder = FileSystem.Current.LocalStorage;
            IFolder folder = await rootFolder.CreateFolderAsync("Logs", CreationCollisionOption.OpenIfExists);
            IFile file = await folder.CreateFileAsync("Pinnacle_log.txt", CreationCollisionOption.ReplaceExisting);
            await file.WriteAllTextAsync(logTrace);
            var emailMessenger = CrossMessaging.Current.EmailMessenger;
            if (Device.OS == TargetPlatform.iOS)
            {
                var email = new EmailMessageBuilder()
                   .To("inforicaapps@gmail.com")
                   .Subject("Log_Pinnacle")
                   //.Body("check attachment")
                   .WithAttachment(file.Path, "text/plain")
                  .Build();
                emailMessenger.SendEmail(email);
            }
            else if (Device.OS == TargetPlatform.Android)
            {
                var email = new EmailMessageBuilder()
                   .To("inforicaapps@gmail.com")
                   .Subject("Log_Pinnacle")
                   .Body(logTrace)
                  // .WithAttachment(file.Path, "text/plain")
                  .Build();
                emailMessenger.SendEmail(email);
            }
        }
    }
}
