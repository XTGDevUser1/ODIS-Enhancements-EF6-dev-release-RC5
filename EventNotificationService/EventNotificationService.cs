using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using Martex.DMS.BLL.Facade;

using System.Configuration;
using log4net.Config;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using log4net;


namespace EventNotificationService
{
    public partial class EventNotificationService : ServiceBase
    {
        System.Timers.Timer t_Service = null;
        EventNotificationFacade notificationService = null;
        protected static readonly ILog logger = LogManager.GetLogger(typeof(EventNotificationService));


        private int timerInterval = 0;


        public EventNotificationService()
        {

            InitializeComponent();
        }



        protected override void OnStart(string[] args)
        {
            if (t_Service == null)
            {
                string timer_interval = AppConfigRepository.GetValue(AppConfigConstants.Event_Notification_Service_Sleep_Interval);
                logger.Info("Event Notification Service Sleep Interval is " + timer_interval);
                int.TryParse(timer_interval, out timerInterval);
                if (timerInterval == 0)
                {
                    timerInterval = 30000;
                }
                t_Service = new System.Timers.Timer();
                t_Service.Interval = timerInterval;

                t_Service.Elapsed += new System.Timers.ElapsedEventHandler(t_Service_Elapsed);

                t_Service.Enabled = true;
            }
            if (notificationService == null)
            {
                notificationService = new EventNotificationFacade();
            }
            logger.Info("Event Notification Service Started.");
            t_Service.Start();

        }

        void t_Service_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (!this.backgroundWorker_Event.IsBusy)
            {
                backgroundWorker_Event.RunWorkerAsync();
            }
        }

        protected override void OnStop()
        {
            if (t_Service != null)
            {
                t_Service.Stop();
                backgroundWorker_Event.CancelAsync();
                logger.Info("Event Notification Service Stopped.");
            }

        }

        private void backgroundWorker_Event_DoWork(object sender, DoWorkEventArgs e)
        {

            logger.Info("Event Notification Processing started");
            notificationService.ProcessEvents();

        }
    }
}
